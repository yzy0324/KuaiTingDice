class_name GameScreen
extends Control

signal back_to_menu_requested
signal game_finished(final_score: int, upper_score: int, lower_score: int, used_count: int)
signal local_two_player_finished(player_1_score: int, player_2_score: int, winner_text: String)
signal lan_match_finished(player_1_score: int, player_2_score: int, winner_text: String)

const GameControllerScript = preload("res://scripts/core/game_controller.gd")
const LocalTwoPlayerControllerScript = preload("res://scripts/core/local_two_player_controller.gd")

const DICE_COUNT = 5
const MAX_ROLLS_PER_ROUND = 3
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

var game_controller
var local_two_player_controller
var game_mode: String = "single_player"
var is_animating: bool = false

var title_label: Label
var info_label: Label
var rolls_left_label: Label
var game_over_label: Label
var roll_button: Button
var new_game_button: Button
var back_button: Button
var single_score_panel: PanelContainer
var local_score_panel: PanelContainer
var dice_buttons: Array[Button] = []
var dice_face_rects: Array[TextureRect] = []
var dice_hold_overlays: Array[TextureRect] = []
var dice_value_labels: Array[Label] = []
var category_buttons: Dictionary = {}
var local_player_buttons: Array = []
var dice_face_textures: Array[Texture2D] = []
var dice_blur_texture: Texture2D
var dice_shadow_texture: Texture2D
var dice_hold_texture: Texture2D
var warned_missing_assets: Dictionary = {}
var rolling_indices: Dictionary = {}
var display_font: Font
var ui_font: Font
var result_emitted: bool = false
var audio_manager: Node
var network_manager: Node
var lan_snapshot: Dictionary = {}
var lan_snapshot_connected: bool = false


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
	local_player_buttons = [{}, {}]
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

	single_score_panel = PanelContainer.new()
	single_score_panel.custom_minimum_size = Vector2(980, 0)
	single_score_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	single_score_panel.add_theme_stylebox_override("panel", _make_score_panel_style())
	root_layout.add_child(single_score_panel)

	var score_area := HBoxContainer.new()
	score_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_area.add_theme_constant_override("separation", 18)
	single_score_panel.add_child(score_area)

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

	local_score_panel = PanelContainer.new()
	local_score_panel.custom_minimum_size = Vector2(1020, 0)
	local_score_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	local_score_panel.add_theme_stylebox_override("panel", _make_score_panel_style())
	local_score_panel.visible = false
	root_layout.add_child(local_score_panel)

	var table_layout := GridContainer.new()
	table_layout.columns = 3
	table_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_layout.add_theme_constant_override("h_separation", 10)
	table_layout.add_theme_constant_override("v_separation", 8)
	local_score_panel.add_child(table_layout)

	_add_table_header(table_layout, "Category")
	_add_table_header(table_layout, "Player 1")
	_add_table_header(table_layout, "Player 2")

	for category in CATEGORIES:
		var category_label := Label.new()
		category_label.text = category
		category_label.custom_minimum_size = Vector2(300, 46)
		category_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		category_label.add_theme_font_size_override("font_size", 20)
		category_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82, 1.0))
		_apply_ui_font(category_label)
		table_layout.add_child(category_label)

		for player_index in range(2):
			var cell_button := Button.new()
			cell_button.custom_minimum_size = Vector2(280, 46)
			cell_button.add_theme_font_size_override("font_size", 20)
			_apply_ui_font(cell_button)
			cell_button.pressed.connect(_on_local_category_pressed.bind(category, player_index))
			local_player_buttons[player_index][category] = cell_button
			table_layout.add_child(cell_button)

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
	if game_mode == "local_two_player":
		start_local_two_player_game()
	elif game_mode == "lan_multiplayer":
		_refresh_ui()
	else:
		start_single_player_game()


func start_single_player_game() -> void:
	game_mode = "single_player"
	if game_controller == null:
		game_controller = GameControllerScript.new()
	game_controller.new_game()
	is_animating = false
	result_emitted = false
	_refresh_ui()


func start_local_two_player_game() -> void:
	game_mode = "local_two_player"
	if local_two_player_controller == null:
		local_two_player_controller = LocalTwoPlayerControllerScript.new()
	local_two_player_controller.new_match()
	is_animating = false
	result_emitted = false
	_refresh_ui()


func start_lan_multiplayer_game(manager: Node) -> void:
	game_mode = "lan_multiplayer"
	network_manager = manager
	lan_snapshot = {}
	is_animating = false
	result_emitted = false
	if network_manager and not lan_snapshot_connected:
		network_manager.connect("lan_state_snapshot_received", _on_lan_state_snapshot_received)
		lan_snapshot_connected = true
	_refresh_ui()
	if network_manager and network_manager.has_method("request_lan_state_snapshot"):
		network_manager.call("request_lan_state_snapshot")


func _on_roll_pressed() -> void:
	if is_animating:
		return
	if game_mode == "lan_multiplayer":
		if not _can_lan_local_act():
			return
		_play_audio("play_roll")
		if network_manager and network_manager.has_method("request_lan_roll"):
			network_manager.call("request_lan_roll")
		return

	var active_controller = _get_active_controller()
	if not active_controller.can_roll():
		return

	var indices_to_roll: Array = active_controller.get_indices_to_roll()
	if indices_to_roll.is_empty():
		return

	_play_audio("play_roll")
	is_animating = true
	rolling_indices.clear()
	for index in indices_to_roll:
		var idx: int = int(index)
		rolling_indices[idx] = true
		_show_die_blur(idx)
	_refresh_ui()
	await get_tree().create_timer(0.12).timeout
	active_controller.apply_roll_result(indices_to_roll)
	is_animating = false
	rolling_indices.clear()
	_refresh_ui()


func _on_dice_pressed(index: int) -> void:
	if game_mode == "lan_multiplayer":
		if not _can_lan_local_act():
			return
		var active_player: Dictionary = _get_lan_active_player_snapshot()
		if int(active_player.get("rolls_used", 0)) == 0:
			return
		_play_audio("play_hold")
		if network_manager and network_manager.has_method("request_lan_toggle_hold"):
			network_manager.call("request_lan_toggle_hold", index)
		return

	var active_controller = _get_active_controller()
	if is_animating or active_controller.is_game_over():
		return
	if active_controller.state.rolls_used == 0:
		return
	_play_audio("play_hold")
	active_controller.toggle_hold(index)
	_refresh_ui()


func _on_category_pressed(category: String) -> void:
	if game_mode == "lan_multiplayer":
		_on_lan_category_pressed(category)
		return
	if game_mode == "local_two_player":
		_on_local_category_pressed(category, local_two_player_controller.get_active_player_index())
		return

	if is_animating or game_controller.is_game_over():
		return
	if not game_controller.can_score_category(category):
		return
	_play_audio("play_score")
	game_controller.score_category(category)
	_refresh_ui()
	_emit_game_finished_if_needed()


func _on_local_category_pressed(category: String, player_index: int) -> void:
	if game_mode == "lan_multiplayer":
		if player_index == int(lan_snapshot.get("active_player_index", 0)):
			_on_lan_category_pressed(category)
		return
	if game_mode != "local_two_player" or local_two_player_controller == null:
		return
	if player_index != local_two_player_controller.get_active_player_index():
		return

	var active_controller = local_two_player_controller.get_active_controller()
	if is_animating or active_controller.is_game_over():
		return
	if not active_controller.can_score_category(category):
		return

	_play_audio("play_score")
	active_controller.score_category(category)
	if local_two_player_controller.is_match_over():
		_refresh_ui()
		_emit_local_two_player_finished_if_needed()
	else:
		local_two_player_controller.switch_turn()
		_refresh_ui()


func _on_lan_category_pressed(category: String) -> void:
	if not _can_lan_local_act():
		return
	var active_player: Dictionary = _get_lan_active_player_snapshot()
	var used_categories: Dictionary = active_player.get("used_categories", {})
	if used_categories.has(category):
		return
	if int(active_player.get("rolls_used", 0)) == 0:
		return

	_play_audio("play_score")
	if network_manager and network_manager.has_method("request_lan_score_category"):
		network_manager.call("request_lan_score_category", category)


func _on_new_game_pressed() -> void:
	_play_audio("play_button_click")
	start_new_game()


func _on_back_to_menu_pressed() -> void:
	_play_audio("play_button_click")
	back_to_menu_requested.emit()


func set_audio_manager(manager: Node) -> void:
	audio_manager = manager


func _play_audio(method_name: String) -> void:
	if audio_manager and audio_manager.has_method(method_name):
		audio_manager.call(method_name)


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


func _emit_local_two_player_finished_if_needed() -> void:
	if result_emitted or local_two_player_controller == null or not local_two_player_controller.is_match_over():
		return
	result_emitted = true
	local_two_player_finished.emit(
		local_two_player_controller.get_player_score(0),
		local_two_player_controller.get_player_score(1),
		local_two_player_controller.get_winner_text()
	)


func _emit_lan_match_finished_if_needed() -> void:
	if result_emitted or lan_snapshot.is_empty() or not bool(lan_snapshot.get("match_over", false)):
		return
	result_emitted = true
	lan_match_finished.emit(
		int(lan_snapshot.get("player_1_score", 0)),
		int(lan_snapshot.get("player_2_score", 0)),
		String(lan_snapshot.get("winner_text", "Draw"))
	)


func _get_active_controller():
	if game_mode == "local_two_player" and local_two_player_controller != null:
		return local_two_player_controller.get_active_controller()
	return game_controller


func _get_section_score(categories: Array) -> int:
	var total: int = 0
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
	if game_mode == "lan_multiplayer":
		_refresh_lan_ui()
		return

	var active_controller = _get_active_controller()
	if active_controller == null:
		return

	if game_mode == "local_two_player":
		title_label.text = "Local Two Player"
	else:
		title_label.text = "快艇骰子"

	var rolls_left: int = MAX_ROLLS_PER_ROUND - int(active_controller.state.rolls_used)
	if game_mode == "local_two_player" and local_two_player_controller != null:
		info_label.text = "PLAYER %d TURN      P1 Score: %d      P2 Score: %d" % [
			local_two_player_controller.get_active_player_number(),
			local_two_player_controller.get_player_score(0),
			local_two_player_controller.get_player_score(1)
		]
	else:
		info_label.text = "Round: %d / 13      Total Score: %d" % [active_controller.state.round_number, active_controller.get_total_score()]
	rolls_left_label.text = "Rolls Left: %d" % rolls_left
	roll_button.text = "ROLL (%d left)" % rolls_left
	roll_button.disabled = is_animating or (not active_controller.can_roll())

	if single_score_panel:
		single_score_panel.visible = game_mode == "single_player"
	if local_score_panel:
		local_score_panel.visible = game_mode == "local_two_player"

	for i in range(DICE_COUNT):
		var held: bool = bool(active_controller.state.held[i])
		if is_animating and rolling_indices.has(i):
			_show_die_blur(i)
			dice_hold_overlays[i].visible = false
		else:
			_update_die_visual(i, active_controller.state.dice_values[i], held)
		dice_buttons[i].disabled = is_animating or active_controller.is_game_over() or active_controller.state.rolls_used == 0
		_apply_dice_button_style(dice_buttons[i], held)

	if game_mode == "local_two_player":
		_refresh_local_score_table()
	else:
		_refresh_single_score_buttons(active_controller)

	if _is_current_game_over():
		game_over_label.visible = true
		if game_mode == "local_two_player" and local_two_player_controller != null:
			game_over_label.text = "Match Over! %s" % local_two_player_controller.get_winner_text()
		else:
			game_over_label.text = "Game Over! Final Score: %d" % active_controller.get_total_score()
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


func _refresh_single_score_buttons(controller) -> void:
	for category in CATEGORIES:
		var button: Button = category_buttons[category]
		var preview_score: int = controller.get_preview_score(category)
		if controller.state.used_categories.has(category):
			button.text = "%s: %d (USED)" % [category, controller.state.scores[category]]
			button.disabled = true
			button.add_theme_color_override("font_disabled_color", Color(0.64, 0.62, 0.56, 0.95))
			button.add_theme_stylebox_override("normal", _make_used_category_style())
			button.add_theme_stylebox_override("disabled", _make_used_category_style())
		else:
			button.text = "%s: %d" % [category, preview_score]
			button.disabled = is_animating or controller.is_game_over() or controller.state.rolls_used == 0
			_apply_category_button_style(button)


func _refresh_local_score_table() -> void:
	if local_two_player_controller == null:
		return

	var active_index: int = local_two_player_controller.get_active_player_index()
	for player_index in range(2):
		var controller = local_two_player_controller.player_controllers[player_index]
		for category in CATEGORIES:
			var button: Button = local_player_buttons[player_index][category]
			var is_active: bool = player_index == active_index
			var used: bool = bool(controller.state.used_categories.has(category))

			if used:
				button.text = "%d USED" % int(controller.state.scores[category])
				button.disabled = true
				button.add_theme_color_override("font_disabled_color", Color(0.72, 0.69, 0.62, 0.95))
				button.add_theme_stylebox_override("normal", _make_local_cell_style(is_active, true))
				button.add_theme_stylebox_override("disabled", _make_local_cell_style(is_active, true))
			elif is_active:
				button.text = "%d" % controller.get_preview_score(category)
				button.disabled = is_animating or controller.is_game_over() or controller.state.rolls_used == 0
				button.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
				button.add_theme_color_override("font_disabled_color", Color(0.62, 0.61, 0.56, 0.95))
				button.add_theme_stylebox_override("normal", _make_local_cell_style(true, false))
				button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.13, 0.14, 0.12, 0.98), Color(0.50, 0.62, 0.36, 0.95)))
				button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.06, 0.07, 0.06, 1.0), Color(0.34, 0.45, 0.24, 0.95)))
				button.add_theme_stylebox_override("disabled", _make_local_cell_style(true, false))
			else:
				button.text = "-"
				button.disabled = true
				button.add_theme_color_override("font_disabled_color", Color(0.45, 0.44, 0.40, 0.9))
				button.add_theme_stylebox_override("normal", _make_local_cell_style(false, false))
				button.add_theme_stylebox_override("disabled", _make_local_cell_style(false, false))


func _refresh_lan_ui() -> void:
	if single_score_panel:
		single_score_panel.visible = false
	if local_score_panel:
		local_score_panel.visible = true

	title_label.text = "LAN Multiplayer"
	if lan_snapshot.is_empty():
		info_label.text = "Waiting for host snapshot..."
		rolls_left_label.text = "Connected LAN match"
		roll_button.text = "ROLL"
		roll_button.disabled = true
		for i in range(DICE_COUNT):
			_update_die_visual(i, 1, false)
			dice_buttons[i].disabled = true
			_apply_dice_button_style(dice_buttons[i], false)
		_refresh_lan_score_table()
		game_over_label.visible = false
		return

	var active_player: Dictionary = _get_lan_active_player_snapshot()
	var local_player_number: int = _get_lan_local_player_number()
	var active_player_number: int = int(lan_snapshot.get("active_player_number", 1))
	var local_can_act: bool = _can_lan_local_act()
	var rolls_left: int = MAX_ROLLS_PER_ROUND - int(active_player.get("rolls_used", 0))
	var p1_score: int = int(lan_snapshot.get("player_1_score", 0))
	var p2_score: int = int(lan_snapshot.get("player_2_score", 0))

	info_label.text = "You are Player %d      Current Turn: Player %d      P1: %d      P2: %d" % [
		local_player_number,
		active_player_number,
		p1_score,
		p2_score
	]
	rolls_left_label.text = "Rolls Left: %d" % rolls_left
	roll_button.text = "ROLL (%d left)" % rolls_left
	roll_button.disabled = is_animating or (not local_can_act) or rolls_left <= 0

	var dice_values: Array = active_player.get("dice_values", [1, 1, 1, 1, 1])
	var held_values: Array = active_player.get("held", [false, false, false, false, false])
	for i in range(DICE_COUNT):
		var held: bool = bool(held_values[i])
		_update_die_visual(i, int(dice_values[i]), held)
		dice_buttons[i].disabled = is_animating or (not local_can_act) or int(active_player.get("rolls_used", 0)) == 0
		_apply_dice_button_style(dice_buttons[i], held)

	_refresh_lan_score_table()

	if bool(lan_snapshot.get("match_over", false)):
		game_over_label.visible = true
		game_over_label.text = "LAN Match Over! %s" % String(lan_snapshot.get("winner_text", "Draw"))
		_emit_lan_match_finished_if_needed()
	else:
		game_over_label.visible = false
		game_over_label.text = ""


func _refresh_lan_score_table() -> void:
	if local_player_buttons.size() < 2:
		return

	var players: Array = lan_snapshot.get("players", [])
	var active_index: int = int(lan_snapshot.get("active_player_index", 0))
	var local_can_act: bool = _can_lan_local_act()

	for player_index in range(2):
		var player_data: Dictionary = {}
		if player_index < players.size() and typeof(players[player_index]) == TYPE_DICTIONARY:
			player_data = players[player_index]

		var used_categories: Dictionary = player_data.get("used_categories", {})
		var scores: Dictionary = player_data.get("scores", {})
		var preview_scores: Dictionary = player_data.get("preview_scores", {})
		var rolls_used: int = int(player_data.get("rolls_used", 0))

		for category in CATEGORIES:
			var button: Button = local_player_buttons[player_index][category]
			var is_active: bool = player_index == active_index
			var used: bool = used_categories.has(category)

			if used:
				button.text = "%d USED" % int(scores.get(category, 0))
				button.disabled = true
				button.add_theme_color_override("font_disabled_color", Color(0.72, 0.69, 0.62, 0.95))
				button.add_theme_stylebox_override("normal", _make_local_cell_style(is_active, true))
				button.add_theme_stylebox_override("disabled", _make_local_cell_style(is_active, true))
			elif is_active:
				button.text = "%d" % int(preview_scores.get(category, 0))
				button.disabled = (not local_can_act) or rolls_used == 0 or bool(lan_snapshot.get("match_over", false))
				button.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
				button.add_theme_color_override("font_disabled_color", Color(0.62, 0.61, 0.56, 0.95))
				button.add_theme_stylebox_override("normal", _make_local_cell_style(true, false))
				button.add_theme_stylebox_override("hover", _make_std_button_style(Color(0.13, 0.14, 0.12, 0.98), Color(0.50, 0.62, 0.36, 0.95)))
				button.add_theme_stylebox_override("pressed", _make_std_button_style(Color(0.06, 0.07, 0.06, 1.0), Color(0.34, 0.45, 0.24, 0.95)))
				button.add_theme_stylebox_override("disabled", _make_local_cell_style(true, false))
			else:
				button.text = "-"
				button.disabled = true
				button.add_theme_color_override("font_disabled_color", Color(0.45, 0.44, 0.40, 0.9))
				button.add_theme_stylebox_override("normal", _make_local_cell_style(false, false))
				button.add_theme_stylebox_override("disabled", _make_local_cell_style(false, false))


func _is_current_game_over() -> bool:
	if game_mode == "lan_multiplayer":
		return bool(lan_snapshot.get("match_over", false))
	if game_mode == "local_two_player" and local_two_player_controller != null:
		return local_two_player_controller.is_match_over()
	return game_controller != null and game_controller.is_game_over()


func _on_lan_state_snapshot_received(snapshot: Dictionary) -> void:
	lan_snapshot = snapshot.duplicate(true)
	is_animating = false
	rolling_indices.clear()
	_refresh_ui()


func _get_lan_active_player_snapshot() -> Dictionary:
	var players: Array = lan_snapshot.get("players", [])
	var active_index: int = int(lan_snapshot.get("active_player_index", 0))
	if active_index >= 0 and active_index < players.size() and typeof(players[active_index]) == TYPE_DICTIONARY:
		return players[active_index]
	return {}


func _get_lan_local_player_number() -> int:
	if network_manager == null:
		return 0
	return int(network_manager.get("local_player_number"))


func _can_lan_local_act() -> bool:
	if is_animating or network_manager == null or lan_snapshot.is_empty():
		return false
	if bool(lan_snapshot.get("match_over", false)):
		return false
	return _get_lan_local_player_number() == int(lan_snapshot.get("active_player_number", 1))


func _make_used_category_style() -> StyleBoxFlat:
	return _make_std_button_style(Color(0.05, 0.05, 0.05, 0.6), Color(0.22, 0.22, 0.22, 0.6))


func _make_local_cell_style(active: bool, used: bool) -> StyleBoxFlat:
	if used and active:
		return _make_std_button_style(Color(0.10, 0.10, 0.08, 0.86), Color(0.50, 0.58, 0.34, 0.9))
	if used:
		return _make_std_button_style(Color(0.06, 0.06, 0.055, 0.72), Color(0.26, 0.25, 0.21, 0.78))
	if active:
		return _make_std_button_style(Color(0.09, 0.12, 0.09, 0.92), Color(0.46, 0.62, 0.34, 0.95))
	return _make_std_button_style(Color(0.045, 0.047, 0.045, 0.62), Color(0.18, 0.18, 0.16, 0.7))


func _add_table_header(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(220, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	_apply_display_font(label)
	parent.add_child(label)


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
