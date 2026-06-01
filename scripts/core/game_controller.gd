class_name GameController
extends RefCounted

const GameStateScript = preload("res://scripts/core/game_state.gd")
const ScoringRulesScript = preload("res://scripts/core/scoring_rules.gd")
const DiceRollerScript = preload("res://scripts/core/dice_roller.gd")

var state: RefCounted = GameStateScript.new()


func new_game() -> void:
	state.reset()


func can_roll() -> bool:
	return (not state.is_game_over) and state.rolls_used < GameStateScript.MAX_ROLLS_PER_ROUND


func get_indices_to_roll() -> Array:
	var indices: Array = []
	for i in range(GameStateScript.DICE_COUNT):
		if state.rolls_used == 0 or not state.held[i]:
			indices.append(i)
	return indices


func apply_roll_result(indices_to_roll: Array) -> void:
	state.dice_values = DiceRollerScript.roll_indices(state.dice_values, indices_to_roll)
	state.rolls_used += 1


func toggle_hold(index: int) -> void:
	if state.is_game_over or state.rolls_used == 0:
		return
	state.held[index] = not state.held[index]


func can_score_category(category: String) -> bool:
	return (not state.is_game_over) and state.rolls_used > 0 and (not state.used_categories.has(category))


func score_category(category: String) -> int:
	var score: int = ScoringRulesScript.calculate_score(category, state.dice_values)
	state.mark_category_used(category, score)
	if state.is_complete():
		state.is_game_over = true
	else:
		state.round_number += 1
		state.rolls_used = 0
		for i in range(GameStateScript.DICE_COUNT):
			state.held[i] = false
	return score


func get_preview_score(category: String) -> int:
	return ScoringRulesScript.calculate_score(category, state.dice_values)


func get_total_score() -> int:
	return state.get_total_score()


func is_game_over() -> bool:
	return state.is_game_over
