class_name ResultScreen
extends Control

signal play_again_requested
signal back_to_menu_requested

var display_font: Font
var ui_font: Font
var audio_manager: Node

var final_score_label: Label
var best_score_label: Label
var new_record_label: Label
var upper_score_label: Label
var lower_score_label: Label
var used_count_label: Label
var leaderboard_label: Label
var message_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	_build_ui()


func show_result(final_score: int, upper_score: int, lower_score: int, used_count: int, best_score: int, is_new_record: bool, leaderboard: Array = []) -> void:
	final_score_label.text = "Final Score: %d" % final_score
	best_score_label.text = "Best Score: %d" % best_score
	best_score_label.visible = true
	new_record_label.visible = is_new_record
	new_record_label.text = "NEW RECORD"
	upper_score_label.text = "Upper Section: %d" % upper_score
	upper_score_label.visible = true
	lower_score_label.text = "Lower Section: %d" % lower_score
	lower_score_label.visible = true
	used_count_label.text = "Categories Used: %d / 13" % used_count
	used_count_label.visible = true
	leaderboard_label.text = _format_leaderboard(leaderboard)
	leaderboard_label.visible = true
	message_label.text = _get_result_message(final_score)


func show_local_two_player_result(player_1_score: int, player_2_score: int, winner_text: String) -> void:
	final_score_label.text = "Local Two Player Result"
	best_score_label.visible = false
	new_record_label.visible = false
	upper_score_label.visible = true
	upper_score_label.text = "Player 1 Final Score: %d" % player_1_score
	lower_score_label.visible = true
	lower_score_label.text = "Player 2 Final Score: %d" % player_2_score
	used_count_label.visible = true
	used_count_label.text = "Winner: %s" % winner_text
	leaderboard_label.visible = false
	message_label.text = "The table has spoken."


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	display_font = _load_font("res://assets/fonts/display_font.ttf")
	ui_font = _load_font("res://assets/fonts/ui_font.ttf")

	var bg := TextureRect.new()
	bg.texture = _load_first_existing_texture([
		"res://assets/art/backgrounds/bg_game_table_clean.png",
		"res://assets/art/backgrounds/bg_game_table.png",
		"res://assets/art/backgrounds/bg_start_menu_clean.png"
	])
	bg.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(680, 500)
	card.add_theme_stylebox_override("panel", _make_card_style())
	center.add_child(card)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 16)
	card.add_child(layout)

	var title := Label.new()
	title.text = "Final Result"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
	_apply_display_font(title)
	layout.add_child(title)

	final_score_label = _make_result_label(34, true)
	layout.add_child(final_score_label)

	best_score_label = _make_result_label(28, false)
	layout.add_child(best_score_label)

	new_record_label = _make_result_label(32, true)
	new_record_label.add_theme_color_override("font_color", Color(0.62, 0.92, 0.56, 1.0))
	new_record_label.visible = false
	layout.add_child(new_record_label)

	var score_panel := PanelContainer.new()
	score_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_panel.add_theme_stylebox_override("panel", _make_inner_panel_style())
	layout.add_child(score_panel)

	var score_layout := VBoxContainer.new()
	score_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_layout.add_theme_constant_override("separation", 8)
	score_panel.add_child(score_layout)

	upper_score_label = _make_result_label(24, false)
	score_layout.add_child(upper_score_label)

	lower_score_label = _make_result_label(24, false)
	score_layout.add_child(lower_score_label)

	used_count_label = _make_result_label(24, false)
	score_layout.add_child(used_count_label)

	leaderboard_label = _make_result_label(20, false)
	leaderboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	leaderboard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_layout.add_child(leaderboard_label)

	message_label = _make_result_label(24, true)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(message_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 18)
	layout.add_child(buttons)

	var play_again_button := _make_button("Play Again")
	play_again_button.pressed.connect(_on_play_again_pressed)
	buttons.add_child(play_again_button)

	var back_button := _make_button("Back to Menu")
	back_button.pressed.connect(_on_back_to_menu_pressed)
	buttons.add_child(back_button)


func _on_play_again_pressed() -> void:
	_play_button_click()
	play_again_requested.emit()


func _on_back_to_menu_pressed() -> void:
	_play_button_click()
	back_to_menu_requested.emit()


func set_audio_manager(manager: Node) -> void:
	audio_manager = manager


func _play_button_click() -> void:
	if audio_manager and audio_manager.has_method("play_button_click"):
		audio_manager.play_button_click()


func _make_result_label(font_size: int, use_display: bool) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82, 1.0))
	if use_display:
		_apply_display_font(label)
	else:
		_apply_ui_font(label)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 54)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.93, 0.91, 0.84, 1.0))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.09, 0.10, 0.10, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	_apply_ui_font(button)
	return button


func _get_result_message(final_score: int) -> String:
	if final_score >= 250:
		return "The table bows to you."
	if final_score >= 180:
		return "A sharp score. The house noticed."
	if final_score >= 120:
		return "A solid run. Fortune stayed nearby."
	return "The dice were hungry tonight."


func _format_leaderboard(leaderboard: Array) -> String:
	if leaderboard.is_empty():
		return "Local Leaderboard:\nNo scores yet."

	var lines := PackedStringArray(["Local Leaderboard Top 5:"])
	var count: int = min(leaderboard.size(), 5)
	for i in range(count):
		var entry = leaderboard[i]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		lines.append("%d. %d    %s" % [
			i + 1,
			int(entry.get("score", 0)),
			String(entry.get("date", "Unknown"))
		])
	return "\n".join(lines)


func _apply_display_font(control: Control) -> void:
	if display_font != null:
		control.add_theme_font_override("font", display_font)


func _apply_ui_font(control: Control) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)


func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.028, 0.82)
	style.border_color = Color(0.42, 0.18, 0.14, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 30
	style.content_margin_top = 28
	style.content_margin_right = 30
	style.content_margin_bottom = 28
	return style


func _make_inner_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.065, 0.06, 0.76)
	style.border_color = Color(0.28, 0.27, 0.22, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


func _load_first_existing_texture(paths: Array) -> Texture2D:
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _load_font(path: String) -> Font:
	if ResourceLoader.exists(path):
		return load(path) as Font
	return null
