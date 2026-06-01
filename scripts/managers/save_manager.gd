class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://kuai_ting_dice_save.json"
const DEFAULT_SFX_VOLUME := 0.8

var best_score: int = 0
var sfx_volume: float = DEFAULT_SFX_VOLUME
var sfx_muted: bool = false


func load_save() -> void:
	best_score = 0
	sfx_volume = DEFAULT_SFX_VOLUME
	sfx_muted = false
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open save file for reading.")
		return

	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is corrupted. Resetting save data.")
		best_score = 0
		sfx_volume = DEFAULT_SFX_VOLUME
		sfx_muted = false
		return

	best_score = int(parsed.get("best_score", 0))
	sfx_volume = clampf(float(parsed.get("sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	sfx_muted = bool(parsed.get("sfx_muted", false))


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return

	var data := {
		"best_score": best_score,
		"sfx_volume": sfx_volume,
		"sfx_muted": sfx_muted
	}
	file.store_string(JSON.stringify(data, "\t"))


func get_best_score() -> int:
	return best_score


func submit_score(score: int) -> bool:
	if score > best_score:
		best_score = score
		save()
		return true
	return false


func get_sfx_volume() -> float:
	return sfx_volume


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	save()


func get_sfx_muted() -> bool:
	return sfx_muted


func set_sfx_muted(value: bool) -> void:
	sfx_muted = value
	save()
