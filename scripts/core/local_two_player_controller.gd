class_name LocalTwoPlayerController
extends RefCounted

const GameControllerScript = preload("res://scripts/core/game_controller.gd")

var player_controllers: Array = []
var active_player_index: int = 0


func new_match() -> void:
	player_controllers = [GameControllerScript.new(), GameControllerScript.new()]
	for controller in player_controllers:
		controller.new_game()
	active_player_index = 0


func get_active_controller():
	return player_controllers[active_player_index]


func get_active_player_index() -> int:
	return active_player_index


func get_active_player_number() -> int:
	return active_player_index + 1


func switch_turn() -> void:
	if is_match_over():
		return
	active_player_index = 1 - active_player_index


func is_match_over() -> bool:
	return player_controllers.size() == 2 and player_controllers[0].is_game_over() and player_controllers[1].is_game_over()


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


func get_used_count(player_index: int) -> int:
	if player_index < 0 or player_index >= player_controllers.size():
		return 0
	return player_controllers[player_index].state.get_used_category_count()
