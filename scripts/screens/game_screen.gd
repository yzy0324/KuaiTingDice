class_name GameScreen
extends Control

signal back_to_menu_requested
signal game_finished(final_score: int, upper_score: int, lower_score: int, used_count: int)

const GameControllerScript = preload("res://scripts/core/game_controller.gd")

const DICE_COUNT := 5
const MAX_ROLLS_PER_ROUND := 3
const UPPER_CATEGORIES := ["Ones", "Twos", "Threes", "Fours", "Fives", "Sixes"]
const LOWER_CATEGORIES := [
	"Three of a Kind",
	"Four of a Kind",
	"Full House",
	"Small Straight",
	"Large Straight",
	"Yahtzee",
	"Chance"
]
const CATEGORIES := UPPER_CATEGORIES + LOWER_CATEGORIES

var game_controller: RefCounted
var is_animating: bool = false

var title_label: Label
var info_label: Label
var rolls_left_label: Label
var game_over_label: Label
var roll_button: Button
var new_game_button: Button
var back_button: Button
var dice_buttons: Array[Button] = []
var dice_face_rects: Array[TextureRect] = []
var dice_hold_overlays: Array[TextureRect] = []
var dice_value_labels: Array[Label] = []
var category_buttons: Dictionary = {}
var dice_face_textures: Array[Texture2D] = []
var dice_blur_texture: Texture2D
var dice_shadow_texture: Texture2D
var dice_hold_texture: Texture2D
var warned_missing_assets: Dictionary = {}
var rolling_indices: Dictionary = {}
var display_font: Font
var ui_font: Font
var result_emitted: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	game_controller = GameControllerScript.new()
	_build_ui()
	start_new_game()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	dice_buttons.clear()
	dice_face_rects.clear()
	dice_hold_overlays.clear()
	dice_value_labels.clear()
	category_buttons.clear()
	display_font = _load_font("res://assets/fonts/display_font.ttf")
	ui_font = _load_font("res://assets/fonts/ui_font.ttf")
	_load_dice_assets()

	var bg := TextureRect.new()
	bg.texture = _load_first_existing_texture([
		"res://assets/art/backgrounds/bg_game_table_clean.png",
		"res://assets/art/backgrounds/bg_game_table.png"
	])
	bg.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var screen_margin := MarginContainer.new()
	screen_margin.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	screen_margin.offset_left = 56
	screen_margin.offset_top = 34
	screen_margin.offset_right = -56
	screen_margin.offset_bottom = -28
	add_child(screen_margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	screen_margin.add_child(scroll)

	var root_layout := VBoxContainer.new()
	root_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_layout.add_theme_constant_override("separation", 14)
	scroll.add_child(root_layout)

	var hud_panel := PanelContainer.new()
	hud_panel.custom_minimum_size = Vector2(740, 0)
	hud_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hud_panel.add_theme_stylebox_override("panel", _make_hud_panel_style())
	root_layout.add_child(hud_panel)

	var hud_layout := VBoxContainer.new()
	hud_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_layout.add_theme_constant_override("separation", 4)
	hud_panel.add_child(hud_layout)

	title_label = Label.new()
	title_label.text = "快艇骰子"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 58)
	_apply_display_font(title_label)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 1.0))
	hud_layout.add_child(title_label)

	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_size_override("font_size", 26)
	_apply_ui_font(info_label)
	info_label.add_theme_color_override("font_color", Color(0.88, 0.87, 0.83, 1.0))
	hud_layout.add_child(info_label)

	rolls_left_label = Label.new()
	rolls_left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rolls_left_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolls_left_label.add_theme_font_size_override("font_size", 26)
	_apply_ui_font(rolls_left_label)
	rolls_left_label.add_theme_color_override("font_color", Color(0.62, 0.76, 0.55, 1.0))
	hud_layout.add_child(rolls_left_label)

	var dice_tray := PanelContainer.new()
	dice_tray.custom_minimum_size = Vector2(860, 0)
	dice_tray.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dice_tray.add_theme_stylebox_override("panel", _make_dice_panel_style())
	root_layout.add_child(dice_tray)

	var dice_layout := VBoxContainer.new()
	dice_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dice_layout.add_theme_constant_override("separation", 12)
	dice_tray.add_child(dice_layout)

	var dice_row := HBoxContainer.new()
	dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_row.add_theme_constant_override("separation", 12)
	dice_layout.add_child(dice_row)

	for i in range(DICE_COUNT):
		var die_button := Button.new()
		die_button.custom_minimum_size = Vector2(130, 130)
		die_button.add_theme_font_size_override("font_size", 18)
		die_button.clip_contents = true
		die_button.pressed.connect(_on_dice_pressed.bind(i))
		_apply_dice_button_style(die_button, false)
		dice_buttons.append(die_button)
		dice_row.add_child(die_button)

		var shadow_rect := TextureRect.new()
		shadow_rect.texture = dice_shadow_texture
		shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow_rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		shadow_rect.position = Vector2(4, 5)
		die_button.add_child(shadow_rect)

		var face_rect := TextureRect.new()
		face_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face_rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		face_rect.z_index = 1
		die_button.add_child(face_rect)
		dice_face_rects.append(face_rect)

		var hold_overlay := TextureRect.new()
		hold_overlay.texture = dice_hold_texture
		hold_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hold_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hold_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hold_overlay.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		hold_overlay.z_index = 2
		hold_overlay.modulate = Color(1, 1, 1, 0.95)
		hold_overlay.visible = false
		die_button.add_child(hold_overlay)
		dice_hold_overlays.append(hold_overlay)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		value_label.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		value_label.add_theme_font_size_override("font_size", 20)
		_apply_ui_font(value_label)
		value_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88, 1.0))
		die_button.add_child(value_label)
		dice_value_labels.append(value_label)

	roll_button = Button.new()
	roll_button.text = "ROLL"
	roll_button.custom_minimum_size = Vector2(380, 62)
	roll_button.add_theme_font_size_override("font_size", 30)
	_apply_display_font(roll_button)
	roll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_roll_button_style()
	roll_button.pressed.connect(_on_roll_pressed)
	dice_layout.add_child(roll_button)

	var score_panel := PanelContainer.new()
	score_panel.custom_minimum_size = Vector2(980, 0)
	score_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	score_panel.add_theme_stylebox_override("panel", _make_score_panel_style())
	root_layout.add_child(score_panel)

	var score_area := HBoxContainer.new()
	score_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_area.add_theme_constant_override("separation", 18)
	score_panel.add_child(score_area)

	var upper_section := PanelContainer.new()
	upper_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upper_section.add_theme_stylebox_override("panel", _make_column_panel_style())
	score_area.add_child(upper_section)

	var upper_layout := VBoxContainer.new()
	upper_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upper_layout.add_theme_constant_override("separation", 8)
	upper_section.add_child(upper_layout)

	var upper_label := Label.new()
	upper_label.text = "Upper Section"
	upper_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upper_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upper_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.84, 1.0))
	upper_label.add_theme_font_size_override("font_size", 24)
	_apply_display_font(upper_label)
	upper_layout.add_child(upper_label)

	for category in UPPER_CATEGORIES:
		var upper_button := Button.new()
		upper_button.custom_minimum_size = Vector2(360, 50)
		upper_button.add_theme_font_size_override("font_size", 21)
		_apply_ui_font(upper_button)
		upper_button.pressed.connect(_on_category_pressed.bind(category))
		category_buttons[category] = upper_button
		upper_layout.add_child(upper_button)

	var lower_section := PanelContainer.new()
	lower_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower_section.add_theme_stylebox_override("panel", _make_column_panel_style())
	score_area.add_child(lower_section)

	var lower_layout := VBoxContainer.new()
	lower_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower_layout.add_theme_constant_override("separation", 8)
	lower_section.add_child(lower_layout)

	var lower_label := Label.new()
	lower_label.text = "Lower Section"
	lower_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lower_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.84, 1.0))
	lower_label.add_theme_font_size_override("font_size", 24)
	_apply_display_font(lower_label)
	lower_layout.add_child(lower_label)

	for category in LOWER_CATEGORIES:
		var lower_button := Button.new()
		lower_button.custom_minimum_size = Vector2(360, 50)
		lower_button.add_theme_font_size_override("font_size", 21)
		_apply_ui_font(lower_button)
		lower_button.pressed.connect(_on_category_pressed.bind(category))
		category_buttons[category] = lower_button
		lower_layout.add_child(lower_button)

	var bottom_buttons := HBoxContainer.new()
	bottom_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_buttons.add_theme_constant_override("separation", 16)
	bottom_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_layout.add_child(bottom_buttons)

	new_game_button = Button.new()
	new_game_button.text = "New Game"
	new_game_button.custom_minimum_size = Vector2(220, 48)
	new_game_button.add_theme_font_size_override("font_size", 22)
	_apply_ui_font(new_game_button)
	new_game_button.add_theme_color_override("font_color", Color(0.93, 0.91, 0.84, 1.0))
	new_game_button.add_theme_stylebox_override("normal", _make_std_button_style(Color(0.09, 0.10, 0.10, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	new_game_button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	new_game_button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	new_game_button.pressed.connect(_on_new_game_pressed)
	bottom_buttons.add_child(new_game_button)

	back_button = Button.new()
	back_button.text = "Back to Menu"
	back_button.custom_minimum_size = Vector2(220, 48)
	back_button.add_theme_font_size_override("font_size", 22)
	_apply_ui_font(back_button)
	back_button.add_theme_color_override("font_color", Color(0.93, 0.91, 0.84, 1.0))
	back_button.add_theme_stylebox_override("normal", _make_std_button_style(Color(0.09, 0.10, 0.10, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	back_button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	back_button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	back_button.pressed.connect(_on_back_to_menu_pressed)
	bottom_buttons.add_child(back_button)

	game_over_label = Label.new()
	game_over_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.add_theme_font_size_override("font_size", 34)
	_apply_display_font(game_over_label)
	game_over_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.80, 1.0))
	game_over_label.visible = false
	root_layout.add_child(game_over_label)

	_add_crt_overlay()


func start_new_game() -> void:
	if game_controller == null:
		game_controller = GameControllerScript.new()
	game_controller.new_game()
	is_animating = false
	result_emitted = false
	_refresh_ui()


func _on_roll_pressed() -> void:
	if is_animating:
		return
	if not game_controller.can_roll():
		return

	var indices_to_roll: Array = game_controller.get_indices_to_roll()
	if indices_to_roll.is_empty():
		return

	is_animating = true
	rolling_indices.clear()
	for index in indices_to_roll:
		var idx: int = int(index)
		rolling_indices[idx] = true
		_show_die_blur(idx)
	_refresh_ui()
	await get_tree().create_timer(0.12).timeout
	game_controller.apply_roll_result(indices_to_roll)
	is_animating = false
	rolling_indices.clear()
	_refresh_ui()


func _on_dice_pressed(index: int) -> void:
	if is_animating or game_controller.is_game_over():
		return
	if game_controller.state.rolls_used == 0:
		return
	game_controller.toggle_hold(index)
	_refresh_ui()


func _on_category_pressed(category: String) -> void:
	if is_animating or game_controller.is_game_over():
		return
	if not game_controller.can_score_category(category):
		return
	game_controller.score_category(category)
	_refresh_ui()
	_emit_game_finished_if_needed()


func _on_new_game_pressed() -> void:
	start_new_game()


func _on_back_to_menu_pressed() -> void:
	back_to_menu_requested.emit()


func _emit_game_finished_if_needed() -> void:
	if result_emitted or not game_controller.is_game_over():
		return
	result_emitted = true
	game_finished.emit(
		game_controller.get_total_score(),
		_get_section_score(UPPER_CATEGORIES),
		_get_section_score(LOWER_CATEGORIES),
		game_controller.state.get_used_category_count()
	)


func _get_section_score(categories: Array) -> int:
	var total := 0
	for category in categories:
		if game_controller.state.scores.has(category):
			total += int(game_controller.state.scores[category])
	return total


func _apply_display_font(control: Control) -> void:
	if display_font != null:
		control.add_theme_font_override("font", display_font)


func _apply_ui_font(control: Control) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)


func _refresh_ui() -> void:
	if game_controller == null:
		return

	var rolls_left: int = MAX_ROLLS_PER_ROUND - game_controller.state.rolls_used
	info_label.text = "Round: %d / 13      Total Score: %d" % [game_controller.state.round_number, game_controller.get_total_score()]
	rolls_left_label.text = "Rolls Left: %d" % rolls_left
	roll_button.text = "ROLL (%d left)" % rolls_left
	roll_button.disabled = is_animating or (not game_controller.can_roll())

	for i in range(DICE_COUNT):
		var held: bool = game_controller.state.held[i]
		if is_animating and rolling_indices.has(i):
			_show_die_blur(i)
			dice_hold_overlays[i].visible = false
		else:
			_update_die_visual(i, game_controller.state.dice_values[i], held)
		dice_buttons[i].disabled = is_animating or game_controller.is_game_over() or game_controller.state.rolls_used == 0
		_apply_dice_button_style(dice_buttons[i], held)

	for category in CATEGORIES:
		var button: Button = category_buttons[category]
		var preview_score: int = game_controller.get_preview_score(category)
		if game_controller.state.used_categories.has(category):
			button.text = "%s: %d (USED)" % [category, game_controller.state.scores[category]]
			button.disabled = true
			button.add_theme_color_override("font_disabled_color", Color(0.64, 0.62, 0.56, 0.95))
			button.add_theme_stylebox_override("normal", _make_used_category_style())
			button.add_theme_stylebox_override("disabled", _make_used_category_style())
		else:
			button.text = "%s: %d" % [category, preview_score]
			button.disabled = is_animating or game_controller.is_game_over() or game_controller.state.rolls_used == 0
			_apply_category_button_style(button)

	if game_controller.is_game_over():
		game_over_label.visible = true
		game_over_label.text = "Game Over! Final Score: %d" % game_controller.get_total_score()
	else:
		game_over_label.visible = false
		game_over_label.text = ""


func _apply_roll_button_style() -> void:
	roll_button.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
	roll_button.add_theme_color_override("font_disabled_color", Color(0.62, 0.61, 0.56, 0.95))
	roll_button.add_theme_stylebox_override("normal", _make_std_button_style(Color(0.09, 0.1, 0.1, 0.98), Color(0.42, 0.38, 0.32, 0.92)))
	roll_button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.12, 0.14, 0.13, 1.0), Color(0.47, 0.58, 0.36, 0.95)))
	roll_button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.32, 0.4, 0.24, 0.95)))
	roll_button.add_theme_stylebox_override("disabled", _make_std_button_style(Color(0.08, 0.08, 0.08, 0.8), Color(0.28, 0.28, 0.28, 0.8)))


func _apply_dice_button_style(button: Button, held: bool) -> void:
	if held:
		button.add_theme_stylebox_override("normal", _make_std_button_style(Color(0.15, 0.09, 0.09, 0.95), Color(0.66, 0.24, 0.20, 1.0)))
		button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.18, 0.1, 0.1, 1.0), Color(0.75, 0.30, 0.25, 1.0)))
		button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.12, 0.07, 0.07, 1.0), Color(0.6, 0.2, 0.18, 1.0)))
	else:
		button.add_theme_stylebox_override("normal", _make_std_button_style(Color(0.1, 0.12, 0.11, 0.95), Color(0.35, 0.45, 0.36, 0.95)))
		button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.12, 0.15, 0.13, 1.0), Color(0.45, 0.58, 0.47, 1.0)))
		button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.08, 0.1, 0.09, 1.0), Color(0.3, 0.4, 0.32, 1.0)))


func _apply_category_button_style(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.57, 0.52, 0.95))
	button.add_theme_stylebox_override("normal", _make_std_button_style(Color(0.08, 0.09, 0.09, 0.94), Color(0.36, 0.34, 0.3, 0.9)))
	button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.11, 0.12, 0.12, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.36, 0.15, 0.12, 0.95)))
	button.add_theme_stylebox_override("disabled", _make_std_button_style(Color(0.06, 0.06, 0.06, 0.7), Color(0.24, 0.24, 0.24, 0.7)))


func _make_used_category_style() -> StyleBoxFlat:
	return _make_std_button_style(Color(0.05, 0.05, 0.05, 0.6), Color(0.22, 0.22, 0.22, 0.6))


func _load_dice_assets() -> void:
	dice_face_textures.clear()
	for i in range(1, 7):
		var face := _load_first_existing_texture([
			"res://assets/art/dice/faces/dice_%d_clean.png" % i
		])
		if face == null:
			_warn_missing_asset("res://assets/art/dice/faces/dice_%d_clean.png" % i)
		dice_face_textures.append(face)

	dice_blur_texture = _load_first_existing_texture([
		"res://assets/art/dice/dice_blur_clean.png",
		"res://assets/art/dice/dice_blur.png",
		"res://assets/art/dice/dice_blur.png.png"
	])
	if dice_blur_texture == null:
		_warn_missing_asset("res://assets/art/dice/dice_blur.png")

	dice_shadow_texture = _load_first_existing_texture([
		"res://assets/art/dice/fx_shadow_die_clean.png",
		"res://assets/art/dice/fx_shadow_die.png",
		"res://assets/art/dice/fx_shadow_die.png.png"
	])
	if dice_shadow_texture == null:
		_warn_missing_asset("res://assets/art/dice/fx_shadow_die.png")

	dice_hold_texture = _load_first_existing_texture([
		"res://assets/art/ui/fx_hold_chains_clean.png",
		"res://assets/art/ui/fx_hold_chains.png"
	])
	if dice_hold_texture == null:
		_warn_missing_asset("res://assets/art/ui/fx_hold_chains_clean.png")


func _update_die_visual(index: int, value: int, held: bool) -> void:
	var face_rect: TextureRect = dice_face_rects[index]
	var overlay: TextureRect = dice_hold_overlays[index]
	var label: Label = dice_value_labels[index]

	if value >= 1 and value <= dice_face_textures.size():
		face_rect.texture = dice_face_textures[value - 1]
		label.visible = false
	else:
		face_rect.texture = null
		label.visible = true

	label.text = "🎲 %d%s" % [value, " [HOLD]" if held else ""]
	overlay.visible = held and dice_hold_texture != null


func _show_die_blur(index: int) -> void:
	var face_rect: TextureRect = dice_face_rects[index]
	var label: Label = dice_value_labels[index]
	if dice_blur_texture != null:
		face_rect.texture = dice_blur_texture
		label.visible = false
	else:
		label.visible = true
		label.text = "🎲 ..."


func _warn_missing_asset(path: String) -> void:
	if warned_missing_assets.has(path):
		return
	warned_missing_assets[path] = true
	push_warning("Missing dice asset: " + path)


func _add_crt_overlay() -> void:
	var crt := TextureRect.new()
	crt.texture = _load_first_existing_texture([
		"res://assets/art/decor/fx_crt_overlay.png",
		"res://assets/art/decor/fx_crt_overlay.png.png"
	])
	crt.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	crt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt.modulate.a = 0.12
	add_child(crt)


func _make_hud_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.028, 0.74)
	style.border_color = Color(0.34, 0.38, 0.27, 0.86)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 24
	style.content_margin_top = 10
	style.content_margin_right = 24
	style.content_margin_bottom = 12
	return style


func _make_dice_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.05, 0.038, 0.70)
	style.border_color = Color(0.42, 0.18, 0.14, 0.88)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style


func _make_score_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.028, 0.68)
	style.border_color = Color(0.32, 0.30, 0.24, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style


func _make_column_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.055, 0.72)
	style.border_color = Color(0.26, 0.25, 0.21, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


func _make_std_button_style(bg: Color, border: Color) -> StyleBoxFlat:
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
