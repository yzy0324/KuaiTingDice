from __future__ import annotations

from collections import deque
from pathlib import Path
from typing import Iterable

from PIL import Image


# Generic conservative thresholds
MAX_CHANNEL_DELTA = 8
MIN_BRIGHTNESS = 120
MIN_ALPHA = 8

# Dice-specific thresholds
DICE_NEUTRAL_DELTA = 20
DICE_BRIGHTNESS_MIN = 45
DICE_BRIGHTNESS_MAX = 245
DICE_PADDING = 8


ASSET_PATHS = [
    "assets/art/backgrounds/bg_start_menu.png.png",
    "assets/art/logo/logo_main_title.png.png",
    "assets/art/ui/btn_lever_normal.png.png",
    "assets/art/ui/btn_lever_pressed.png.png",
    "assets/art/ui/ninepatch_iron_box.png.png",
    "assets/art/ui/ninepatch_paper_row.png.png",
    "assets/art/ui/fx_hold_chains.png",
    "assets/art/ui/fx_hold_chains.png.png",
]


def is_neutral_checker_pixel(r: int, g: int, b: int, a: int) -> bool:
    if a < MIN_ALPHA:
        return False
    if abs(r - g) >= MAX_CHANNEL_DELTA:
        return False
    if abs(g - b) >= MAX_CHANNEL_DELTA:
        return False
    brightness = (r + g + b) // 3
    return brightness >= MIN_BRIGHTNESS


def is_dice_bg_candidate(r: int, g: int, b: int, a: int) -> bool:
    if a < MIN_ALPHA:
        return False
    if (max(r, g, b) - min(r, g, b)) >= DICE_NEUTRAL_DELTA:
        return False
    brightness = (r + g + b) // 3
    return DICE_BRIGHTNESS_MIN < brightness < DICE_BRIGHTNESS_MAX


def iter_border_coords(width: int, height: int) -> Iterable[tuple[int, int]]:
    for x in range(width):
        yield x, 0
        if height > 1:
            yield x, height - 1
    for y in range(1, height - 1):
        yield 0, y
        if width > 1:
            yield width - 1, y


def _clean_name(name: str) -> str:
    if name.endswith(".png.png"):
        return name[: -len(".png.png")] + "_clean.png"
    if name.endswith(".png"):
        return name[: -len(".png")] + "_clean.png"
    return name + "_clean.png"


def clean_image(src_path: Path) -> tuple[Path, int, int]:
    img = Image.open(src_path).convert("RGBA")
    px = img.load()
    w, h = img.size

    candidate = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            candidate[y][x] = is_neutral_checker_pixel(r, g, b, a)

    q: deque[tuple[int, int]] = deque()
    visited = [[False] * w for _ in range(h)]
    for x, y in iter_border_coords(w, h):
        if candidate[y][x] and not visited[y][x]:
            visited[y][x] = True
            q.append((x, y))

    removed = 0
    while q:
        x, y = q.popleft()
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)
        removed += 1
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and candidate[ny][nx] and not visited[ny][nx]:
                visited[ny][nx] = True
                q.append((nx, ny))

    out_path = src_path.with_name(_clean_name(src_path.name))
    img.save(out_path)
    return out_path, removed, w * h


def clean_hold_chains(root: Path) -> None:
    candidates = [
        root / "assets/art/ui/fx_hold_chains_clean.png",
        root / "assets/art/ui/fx_hold_chains.png",
        root / "assets/art/ui/fx_hold_chains.png.png",
    ]
    src = next((p for p in candidates if p.exists()), None)
    if src is None:
        print("- SKIP hold chain cleanup: source not found")
        return

    img = Image.open(src).convert("RGBA")
    px = img.load()
    w, h = img.size

    def is_protected_chain_pixel(r: int, g: int, b: int) -> bool:
        brightness = (r + g + b) // 3
        neutral = max(r, g, b) - min(r, g, b)
        greenish = g > r + 12 and g > b + 8
        rusty = r > g + 10 and g >= b - 10
        very_dark = brightness < 45
        non_neutral = neutral >= 18
        return greenish or rusty or very_dark or non_neutral

    def is_checker_like(r: int, g: int, b: int, a: int) -> bool:
        if a <= 0:
            return False
        neutral = max(r, g, b) - min(r, g, b)
        brightness = (r + g + b) // 3
        return neutral < 18 and 55 < brightness < 235

    # Pass 1: global checkerboard cleanup with chain-pixel protection.
    global_removed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_checker_like(r, g, b, a) and not is_protected_chain_pixel(r, g, b):
                px[x, y] = (r, g, b, 0)
                global_removed += 1

    # Pass 2: border-connected checker-like cleanup (catches outer fake transparency).
    candidate = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            candidate[y][x] = is_checker_like(r, g, b, a) and (not is_protected_chain_pixel(r, g, b))

    visited = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    for x, y in iter_border_coords(w, h):
        if candidate[y][x] and not visited[y][x]:
            visited[y][x] = True
            q.append((x, y))

    border_removed = 0
    while q:
        x, y = q.popleft()
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)
        border_removed += 1
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and candidate[ny][nx] and not visited[ny][nx]:
                visited[ny][nx] = True
                q.append((nx, ny))

    # Pass 3: larger inner window cleanup for residual checkerboard inside the frame.
    left = int(w * 0.12)
    right = int(w * 0.88)
    top = int(h * 0.12)
    bottom = int(h * 0.88)
    center_cleared = 0
    for y in range(top, bottom):
        for x in range(left, right):
            r, g, b, a = px[x, y]
            if is_checker_like(r, g, b, a) and not is_protected_chain_pixel(r, g, b):
                px[x, y] = (r, g, b, 0)
                center_cleared += 1

    # Pass 4: remove isolated checker-like leftovers surrounded by transparency.
    isolate_removed = 0
    snapshot = img.copy()
    sx = snapshot.load()
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            r, g, b, a = sx[x, y]
            if not is_checker_like(r, g, b, a) or is_protected_chain_pixel(r, g, b):
                continue
            transparent_neighbors = 0
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1), (x + 1, y + 1)):
                if sx[nx, ny][3] == 0:
                    transparent_neighbors += 1
            if transparent_neighbors >= 6:
                px[x, y] = (r, g, b, 0)
                isolate_removed += 1

    # Keep original canvas size for overlay alignment.
    out_path = root / "assets/art/ui/fx_hold_chains_clean.png"
    img.save(out_path)
    total_removed = global_removed + border_removed + center_cleared + isolate_removed
    pct = (total_removed / (w * h) * 100.0) if w * h else 0.0
    print(
        f"- HOLD chains: {src.name} -> {out_path.name} | "
        f"global={global_removed}, border={border_removed}, center={center_cleared}, isolated={isolate_removed}, "
        f"total={total_removed}/{w*h} ({pct:.2f}%), "
        f"center-rect=({left},{top})-({right},{bottom})"
    )


def clean_dice_sheet_to_faces(root: Path) -> None:
    dice_candidates = [
        root / "assets/art/dice/dice_sheet_clean.png",
        root / "assets/art/dice/dice_sheet.png",
        root / "assets/art/dice/dice_sheet.png.png",
    ]
    sheet_path = next((p for p in dice_candidates if p.exists()), None)
    if sheet_path is None:
        print("- SKIP dice face export: dice_sheet source not found")
        return

    sheet = Image.open(sheet_path).convert("RGBA")
    w, h = sheet.size
    cell_w = w // 6
    if cell_w <= 0:
        print(f"- SKIP dice face export: invalid sheet size {w}x{h}")
        return

    out_dir = root / "assets/art/dice/faces"
    out_dir.mkdir(parents=True, exist_ok=True)
    px = sheet.load()

    print(f"- Dice face export source: {sheet_path.name} ({w}x{h})")
    for i in range(6):
        x0 = i * cell_w
        x1 = w if i == 5 else (i + 1) * cell_w
        cell = sheet.crop((x0, 0, x1, h))
        cell_px = cell.load()
        cw, ch = cell.size

        candidate = [[False] * cw for _ in range(ch)]
        for y in range(ch):
            for x in range(cw):
                r, g, b, a = cell_px[x, y]
                candidate[y][x] = is_dice_bg_candidate(r, g, b, a)

        visited = [[False] * cw for _ in range(ch)]
        q: deque[tuple[int, int]] = deque()
        for x, y in iter_border_coords(cw, ch):
            if candidate[y][x] and not visited[y][x]:
                visited[y][x] = True
                q.append((x, y))

        removed = 0
        while q:
            x, y = q.popleft()
            r, g, b, _a = cell_px[x, y]
            cell_px[x, y] = (r, g, b, 0)
            removed += 1
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < cw and 0 <= ny < ch and candidate[ny][nx] and not visited[ny][nx]:
                    visited[ny][nx] = True
                    q.append((nx, ny))

        bbox = cell.getbbox()
        if bbox is None:
            print(f"  - WARN die {i+1}: no opaque pixels after cleanup, fallback to original cell")
            final_img = sheet.crop((x0, 0, x1, h))
        else:
            bx0, by0, bx1, by1 = bbox
            bx0 = max(0, bx0 - DICE_PADDING)
            by0 = max(0, by0 - DICE_PADDING)
            bx1 = min(cw, bx1 + DICE_PADDING)
            by1 = min(ch, by1 + DICE_PADDING)
            if (bx1 - bx0) < 24 or (by1 - by0) < 24:
                print(f"  - WARN die {i+1}: crop too small, fallback to original cell")
                final_img = sheet.crop((x0, 0, x1, h))
            else:
                final_img = cell.crop((bx0, by0, bx1, by1))

        out_path = out_dir / f"dice_{i + 1}_clean.png"
        final_img.save(out_path)
        total = cw * ch
        pct = (removed / total * 100.0) if total else 0.0
        print(
            f"  - die_{i+1}: cell={cw}x{ch}, out={final_img.size[0]}x{final_img.size[1]}, "
            f"transparentized={removed}/{total} ({pct:.2f}%) -> {out_path.name}"
        )


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    print("Checkerboard cleanup run")

    for rel in ASSET_PATHS:
        src = root / rel
        if not src.exists():
            print(f"- SKIP missing: {src}")
            continue
        out, removed, total = clean_image(src)
        pct = (removed / total * 100.0) if total else 0.0
        print(f"- OK {src.name} -> {out.name} | transparentized: {removed}/{total} ({pct:.2f}%)")

    clean_hold_chains(root)
    clean_dice_sheet_to_faces(root)


if __name__ == "__main__":
    main()
