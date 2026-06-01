class_name GameState
extends RefCounted


const DICE_COUNT := 5
const MAX_ROLLS_PER_ROUND := 3
const TOTAL_CATEGORIES := 13

var dice_values: Array = [1, 1, 1, 1, 1]
var held: Array = [false, false, false, false, false]
var rolls_used: int = 0
var round_number: int = 1
var scores: Dictionary = {}
var used_categories: Dictionary = {}
var is_game_over: bool = false


func reset() -> void:
	dice_values = [1, 1, 1, 1, 1]
	held = [false, false, false, false, false]
	rolls_used = 0
	round_number = 1
	scores.clear()
	used_categories.clear()
	is_game_over = false


func get_total_score() -> int:
	var total := 0
	for value in scores.values():
		total += int(value)
	return total


func get_used_category_count() -> int:
	return used_categories.size()


func is_complete() -> bool:
	return get_used_category_count() >= TOTAL_CATEGORIES


func mark_category_used(category: String, score: int) -> void:
	scores[category] = score
	used_categories[category] = true
