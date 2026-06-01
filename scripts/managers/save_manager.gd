class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://kuai_ting_dice_save.json"
const DEFAULT_SFX_VOLUME := 0.8

var best_score: int = 0
var sfx_volume: float = DEFAULT_SFX_VOLUME
var sfx_muted: bool = false
var single_player_leaderboard: Array = []


func load_save() -> void:
	best_score = 0
	sfx_volume = DEFAULT_SFX_VOLUME
	sfx_muted = false
	single_player_leaderboard = []
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
		single_player_leaderboard = []
		return

	best_score = int(parsed.get("best_score", 0))
	sfx_volume = clampf(float(parsed.get("sfx_volume", DEFAULT_SFX_VOLUME)), 0.0, 1.0)
	sfx_muted = bool(parsed.get("sfx_muted", false))
	single_player_leaderboard = _sanitize_leaderboard(parsed.get("single_player_leaderboard", []))


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return

	var data := {
		"best_score": best_score,
		"sfx_volume": sfx_volume,
		"sfx_muted": sfx_muted,
		"single_player_leaderboard": single_player_leaderboard
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


func submit_single_player_score(score: int) -> bool:
	var is_new_best := score > best_score
	if is_new_best:
		best_score = score

	single_player_leaderboard.append({
		"score": score,
		"date": _get_today_string()
	})
	single_player_leaderboard.sort_custom(Callable(self, "_sort_leaderboard_desc"))
	if single_player_leaderboard.size() > 10:
		single_player_leaderboard = single_player_leaderboard.slice(0, 10)
	save()
	return is_new_best


func get_single_player_leaderboard() -> Array:
	return single_player_leaderboard.duplicate(true)


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


func _sanitize_leaderboard(raw_value) -> Array:
	var sanitized: Array = []
	if typeof(raw_value) != TYPE_ARRAY:
		return sanitized

	for entry in raw_value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		sanitized.append({
			"score": int(entry.get("score", 0)),
			"date": String(entry.get("date", "Unknown"))
		})

	sanitized.sort_custom(Callable(self, "_sort_leaderboard_desc"))
	if sanitized.size() > 10:
		sanitized = sanitized.slice(0, 10)
	return sanitized


func _sort_leaderboard_desc(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("score", 0)) > int(b.get("score", 0))


func _get_today_string() -> String:
	var date := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(date["year"]), int(date["month"]), int(date["day"])]
