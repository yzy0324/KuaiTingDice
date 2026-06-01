class_name LanMatchController
extends RefCounted

const GameControllerScript = preload("res://scripts/core/game_controller.gd")

const UPPER_CATEGORIES = ["Ones", "Twos", "Threes", "Fours", "Fives", "Sixes"]
const LOWER_CATEGORIES = [
	"Three of a Kind",
	"Four of a Kind",
	"Full House",
	"Small Straight",
	"Large Straight",
	"Yahtzee",
	"Chance"
]
const CATEGORIES = UPPER_CATEGORIES + LOWER_CATEGORIES

var player_controllers: Array = []
var active_player_index: int = 0
var match_over: bool = false


func new_match() -> void:
	player_controllers = [GameControllerScript.new(), GameControllerScript.new()]
	for controller in player_controllers:
		controller.new_game()
	active_player_index = 0
	match_over = false


func can_player_act(player_number: int) -> bool:
	return not match_over and player_number == active_player_index + 1


func apply_roll_for_player(player_number: int) -> bool:
	if not can_player_act(player_number):
		return false

	var controller = _get_active_controller()
	if controller == null or not controller.can_roll():
		return false

	var indices_to_roll: Array = controller.get_indices_to_roll()
	if indices_to_roll.is_empty():
		return false

	controller.apply_roll_result(indices_to_roll)
	return true


func apply_toggle_hold_for_player(player_number: int, index: int) -> bool:
	if not can_player_act(player_number):
		return false
	if index < 0 or index >= 5:
		return false

	var controller = _get_active_controller()
	if controller == null or controller.is_game_over() or controller.state.rolls_used == 0:
		return false

	controller.toggle_hold(index)
	return true


func apply_score_for_player(player_number: int, category: String) -> bool:
	if not can_player_act(player_number):
		return false
	if not CATEGORIES.has(category):
		return false

	var controller = _get_active_controller()
	if controller == null or not controller.can_score_category(category):
		return false

	controller.score_category(category)
	_update_match_after_score()
	return true


func get_snapshot() -> Dictionary:
	var players: Array = []
	for i in range(2):
		players.append(_get_player_snapshot(i))

	return {
		"active_player_index": active_player_index,
		"active_player_number": active_player_index + 1,
		"match_over": match_over,
		"players": players,
		"player_1_score": get_player_score(0),
		"player_2_score": get_player_score(1),
		"winner_text": get_winner_text()
	}


func get_player_score(player_index: int) -> int:
	if player_index < 0 or player_index >= player_controllers.size():
		return 0
	return player_controllers[player_index].get_total_score()


func get_winner_text() -> String:
	var p1_score: int = get_player_score(0)
	var p2_score: int = get_player_score(1)
	if p1_score > p2_score:
		return "Player 1 Wins"
	if p2_score > p1_score:
		return "Player 2 Wins"
	return "Draw"


func _get_active_controller():
	if active_player_index < 0 or active_player_index >= player_controllers.size():
		return null
	return player_controllers[active_player_index]


func _update_match_after_score() -> void:
	if player_controllers[0].is_game_over() and player_controllers[1].is_game_over():
		match_over = true
		return

	var next_index: int = 1 - active_player_index
	if not player_controllers[next_index].is_game_over():
		active_player_index = next_index
	elif not player_controllers[active_player_index].is_game_over():
		active_player_index = active_player_index


func _get_player_snapshot(player_index: int) -> Dictionary:
	var controller = player_controllers[player_index]
	var preview_scores: Dictionary = {}
	for category in CATEGORIES:
		preview_scores[category] = controller.get_preview_score(category)

	return {
		"player_number": player_index + 1,
		"dice_values": controller.state.dice_values.duplicate(),
		"held": controller.state.held.duplicate(),
		"rolls_used": int(controller.state.rolls_used),
		"round_number": int(controller.state.round_number),
		"scores": controller.state.scores.duplicate(),
		"used_categories": controller.state.used_categories.duplicate(),
		"is_game_over": bool(controller.state.is_game_over),
		"total_score": controller.get_total_score(),
		"used_count": controller.state.get_used_category_count(),
		"preview_scores": preview_scores
	}
