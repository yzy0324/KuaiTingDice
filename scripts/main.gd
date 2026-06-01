extends Control

const StartMenuScript = preload("res://scripts/screens/start_menu.gd")
const GameScreenScript = preload("res://scripts/screens/game_screen.gd")
const ScoringTestsScript = preload("res://scripts/tests/scoring_tests.gd")

var start_menu: Control
var game_screen: Control


func _ready() -> void:
	# 确保根画布全屏且暗色基调
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	ScoringTestsScript.run()
	_build_screens()
	_show_start_menu()


func _build_screens() -> void:
	start_menu = StartMenuScript.new()
	start_menu.start_requested.connect(_on_start_game_pressed)
	add_child(start_menu)
	_force_full_rect(start_menu)

	game_screen = GameScreenScript.new()
	game_screen.back_to_menu_requested.connect(_on_back_to_menu_pressed)
	add_child(game_screen)
	_force_full_rect(game_screen)


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


func _show_game_screen() -> void:
	if start_menu:
		start_menu.visible = false
	if game_screen:
		_force_full_rect(game_screen)
		game_screen.visible = true


func _on_start_game_pressed() -> void:
	_show_game_screen()
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()


func _on_back_to_menu_pressed() -> void:
	if game_screen.has_method("start_new_game"):
		game_screen.start_new_game()
	_show_start_menu()
