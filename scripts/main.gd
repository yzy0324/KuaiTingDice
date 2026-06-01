extends Control

const StartMenuScript = preload("res://scripts/screens/start_menu.gd")
const ModeSelectScreenScript = preload("res://scripts/screens/mode_select_screen.gd")
const GameScreenScript = preload("res://scripts/screens/game_screen.gd")
const ResultScreenScript = preload("res://scripts/screens/result_screen.gd")
const LanLobbyScreenScript = preload("res://scripts/screens/lan_lobby_screen.gd")
const SaveManagerScript = preload("res://scripts/managers/save_manager.gd")
const AudioManagerScript = preload("res://scripts/managers/audio_manager.gd")
const NetworkManagerScript = preload("res://scripts/managers/network_manager.gd")
const ScoringTestsScript = preload("res://scripts/tests/scoring_tests.gd")

var start_menu: Control
var mode_select_screen: Control
var game_screen: Control
var result_screen: Control
var lan_lobby_screen: Control
var save_manager: RefCounted
var audio_manager: Node
var network_manager: Node
var current_mode := "single_player"


func _ready() -> void:
	# 确保根画布全屏且暗色基调
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	ScoringTestsScript.run()
	save_manager = SaveManagerScript.new()
	save_manager.load_save()
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
	network_manager = NetworkManagerScript.new()
	add_child(network_manager)
	if audio_manager.has_method("set_sfx_volume_linear"):
		audio_manager.call("set_sfx_volume_linear", float(save_manager.call("get_sfx_volume")))
	if audio_manager.has_method("set_muted"):
		audio_manager.call("set_muted", bool(save_manager.call("get_sfx_muted")))
	_build_screens()
	_show_start_menu()


func _build_screens() -> void:
	start_menu = StartMenuScript.new()
	start_menu.start_requested.connect(_on_start_game_pressed)
	if start_menu.has_method("set_audio_manager"):
		start_menu.set_audio_manager(audio_manager)
	if start_menu.has_method("set_save_manager"):
		start_menu.set_save_manager(save_manager)
	add_child(start_menu)
	_force_full_rect(start_menu)

	mode_select_screen = ModeSelectScreenScript.new()
	mode_select_screen.single_player_requested.connect(_on_single_player_requested)
	mode_select_screen.local_two_player_requested.connect(_on_local_two_player_requested)
	mode_select_screen.lan_multiplayer_requested.connect(_on_lan_multiplayer_requested)
	mode_select_screen.back_requested.connect(_on_mode_select_back_requested)
	if mode_select_screen.has_method("set_audio_manager"):
		mode_select_screen.set_audio_manager(audio_manager)
	add_child(mode_select_screen)
	_force_full_rect(mode_select_screen)

	game_screen = GameScreenScript.new()
	game_screen.back_to_menu_requested.connect(_on_back_to_menu_pressed)
	game_screen.game_finished.connect(_on_game_finished)
	game_screen.local_two_player_finished.connect(_on_local_two_player_finished)
	if game_screen.has_method("set_audio_manager"):
		game_screen.set_audio_manager(audio_manager)
	add_child(game_screen)
	_force_full_rect(game_screen)

	result_screen = ResultScreenScript.new()
	result_screen.play_again_requested.connect(_on_play_again_pressed)
	result_screen.back_to_menu_requested.connect(_on_result_back_to_menu_pressed)
	if result_screen.has_method("set_audio_manager"):
		result_screen.set_audio_manager(audio_manager)
	add_child(result_screen)
	_force_full_rect(result_screen)

	lan_lobby_screen = LanLobbyScreenScript.new()
	lan_lobby_screen.back_requested.connect(_on_lan_lobby_back_requested)
	if lan_lobby_screen.has_method("set_audio_manager"):
		lan_lobby_screen.set_audio_manager(audio_manager)
	if lan_lobby_screen.has_method("set_network_manager"):
		lan_lobby_screen.set_network_manager(network_manager)
	add_child(lan_lobby_screen)
	_force_full_rect(lan_lobby_screen)


func _force_full_rect(control: Control) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


func _show_start_menu() -> void:
	if start_menu:
		_force_full_rect(start_menu)
		start_menu.visible = true
	if game_screen:
		game_screen.visible = false
	if mode_select_screen:
		mode_select_screen.visible = false
	if result_screen:
		result_screen.visible = false
	if lan_lobby_screen:
		lan_lobby_screen.visible = false


func _show_mode_select_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if mode_select_screen:
		_force_full_rect(mode_select_screen)
		mode_select_screen.visible = true
	if game_screen:
		game_screen.visible = false
	if result_screen:
		result_screen.visible = false
	if lan_lobby_screen:
		lan_lobby_screen.visible = false


func _show_game_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if mode_select_screen:
		mode_select_screen.visible = false
	if game_screen:
		_force_full_rect(game_screen)
		game_screen.visible = true
	if result_screen:
		result_screen.visible = false
	if lan_lobby_screen:
		lan_lobby_screen.visible = false


func _show_result_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if mode_select_screen:
		mode_select_screen.visible = false
	if game_screen:
		game_screen.visible = false
	if result_screen:
		_force_full_rect(result_screen)
		result_screen.visible = true
	if lan_lobby_screen:
		lan_lobby_screen.visible = false


func _show_lan_lobby_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if mode_select_screen:
		mode_select_screen.visible = false
	if game_screen:
		game_screen.visible = false
	if result_screen:
		result_screen.visible = false
	if lan_lobby_screen:
		_force_full_rect(lan_lobby_screen)
		lan_lobby_screen.visible = true


func _on_start_game_pressed() -> void:
	_show_mode_select_screen()


func _on_single_player_requested() -> void:
	current_mode = "single_player"
	_show_game_screen()
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()


func _on_local_two_player_requested() -> void:
	current_mode = "local_two_player"
	_show_game_screen()
	if game_screen.has_method("start_local_two_player_game"):
		game_screen.start_local_two_player_game()


func _on_lan_multiplayer_requested() -> void:
	current_mode = "lan_multiplayer"
	_show_lan_lobby_screen()


func _on_mode_select_back_requested() -> void:
	_show_start_menu()


func _on_lan_lobby_back_requested() -> void:
	_show_mode_select_screen()


func _on_back_to_menu_pressed() -> void:
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()
	_show_start_menu()


func _on_game_finished(final_score: int, upper_score: int, lower_score: int, used_count: int) -> void:
	var is_new_record: bool = false
	if current_mode == "single_player" and save_manager.has_method("submit_single_player_score"):
		is_new_record = bool(save_manager.call("submit_single_player_score", final_score))
	else:
		is_new_record = save_manager.submit_score(final_score)
	var best_score: int = save_manager.get_best_score()
	var leaderboard: Array = []
	if save_manager.has_method("get_single_player_leaderboard"):
		leaderboard = save_manager.call("get_single_player_leaderboard")
	if audio_manager and audio_manager.has_method("play_game_over"):
		audio_manager.play_game_over()
	if is_new_record and audio_manager and audio_manager.has_method("play_new_record"):
		audio_manager.play_new_record()
	if result_screen and result_screen.has_method("show_result"):
		result_screen.show_result(final_score, upper_score, lower_score, used_count, best_score, is_new_record, leaderboard)
	_show_result_screen()


func _on_local_two_player_finished(player_1_score: int, player_2_score: int, winner_text: String) -> void:
	if audio_manager and audio_manager.has_method("play_game_over"):
		audio_manager.play_game_over()
	if result_screen and result_screen.has_method("show_local_two_player_result"):
		result_screen.show_local_two_player_result(player_1_score, player_2_score, winner_text)
	_show_result_screen()


func _on_play_again_pressed() -> void:
	_show_game_screen()
	if current_mode == "local_two_player" and game_screen.has_method("start_local_two_player_game"):
		game_screen.start_local_two_player_game()
	elif game_screen.has_method("start_single_player_game"):
		game_screen.start_single_player_game()


func _on_result_back_to_menu_pressed() -> void:
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()
	_show_start_menu()
