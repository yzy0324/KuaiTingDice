class_name SaveManager
extends RefCounted

const SAVE_PATH := "user://kuai_ting_dice_save.json"

var best_score: int = 0


func load_save() -> void:
	best_score = 0
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open save file for reading.")
		return

	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is corrupted. Resetting best score.")
		best_score = 0
		return

	best_score = int(parsed.get("best_score", 0))


func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not open save file for writing.")
		return

	var data := {
		"best_score": best_score
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
