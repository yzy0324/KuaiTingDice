extends Control

const StartMenuScript = preload("res://scripts/screens/start_menu.gd")
const GameScreenScript = preload("res://scripts/screens/game_screen.gd")
const ResultScreenScript = preload("res://scripts/screens/result_screen.gd")
const SaveManagerScript = preload("res://scripts/managers/save_manager.gd")
const AudioManagerScript = preload("res://scripts/managers/audio_manager.gd")
const ScoringTestsScript = preload("res://scripts/tests/scoring_tests.gd")

var start_menu: Control
var game_screen: Control
var result_screen: Control
var save_manager: RefCounted
var audio_manager: Node


func _ready() -> void:
	# 确保根画布全屏且暗色基调
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	ScoringTestsScript.run()
	save_manager = SaveManagerScript.new()
	save_manager.load_save()
	audio_manager = AudioManagerScript.new()
	add_child(audio_manager)
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

	game_screen = GameScreenScript.new()
	game_screen.back_to_menu_requested.connect(_on_back_to_menu_pressed)
	game_screen.game_finished.connect(_on_game_finished)
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
	if result_screen:
		result_screen.visible = false


func _show_game_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if game_screen:
		_force_full_rect(game_screen)
		game_screen.visible = true
	if result_screen:
		result_screen.visible = false


func _show_result_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if game_screen:
		game_screen.visible = false
	if result_screen:
		_force_full_rect(result_screen)
		result_screen.visible = true


func _on_start_game_pressed() -> void:
	_show_game_screen()
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()


func _on_back_to_menu_pressed() -> void:
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()
	_show_start_menu()


func _on_game_finished(final_score: int, upper_score: int, lower_score: int, used_count: int) -> void:
	var is_new_record: bool = save_manager.submit_score(final_score)
	var best_score: int = save_manager.get_best_score()
	if audio_manager and audio_manager.has_method("play_game_over"):
		audio_manager.play_game_over()
	if is_new_record and audio_manager and audio_manager.has_method("play_new_record"):
		audio_manager.play_new_record()
	if result_screen and result_screen.has_method("show_result"):
		result_screen.show_result(final_score, upper_score, lower_score, used_count, best_score, is_new_record)
	_show_result_screen()


func _on_play_again_pressed() -> void:
	_show_game_screen()
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()


func _on_result_back_to_menu_pressed() -> void:
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()
	_show_start_menu()
