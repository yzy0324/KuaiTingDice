class_name ModeSelectScreen
extends Control

signal single_player_requested
signal local_two_player_requested
signal lan_multiplayer_requested
signal back_requested

var display_font: Font
var ui_font: Font
var audio_manager: Node
var coming_soon_label: Label
var content_root: Control
var content_center: CenterContainer
var rotate_prompt: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	_build_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_orientation_guard()


func set_audio_manager(manager: Node) -> void:
	audio_manager = manager


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	display_font = _load_font("res://assets/fonts/display_font.ttf")
	ui_font = _load_font("res://assets/fonts/ui_font.ttf")

	var bg := TextureRect.new()
	bg.texture = _load_first_existing_texture([
		"res://assets/art/backgrounds/bg_start_menu_clean.png",
		"res://assets/art/backgrounds/bg_start_menu.png",
		"res://assets/art/backgrounds/bg_game_table.png"
	])
	bg.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll)
	content_root = scroll

	var center := CenterContainer.new()
	content_center = center
	center.custom_minimum_size = get_viewport_rect().size
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

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
	title.text = "Select Mode"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
	_apply_display_font(title)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Choose how you want to face the dice."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.84, 0.8, 0.95))
	_apply_ui_font(subtitle)
	layout.add_child(subtitle)

	var single_button := _make_mode_button("Single Player")
	single_button.pressed.connect(_on_single_player_pressed)
	layout.add_child(single_button)

	var local_button := _make_mode_button("Local Two Player")
	local_button.pressed.connect(_on_local_two_player_pressed)
	layout.add_child(local_button)

	var lan_button := _make_mode_button("LAN Multiplayer")
	lan_button.pressed.connect(_on_lan_multiplayer_pressed)
	layout.add_child(lan_button)

	coming_soon_label = Label.new()
	coming_soon_label.text = ""
	coming_soon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming_soon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coming_soon_label.add_theme_font_size_override("font_size", 20)
	coming_soon_label.add_theme_color_override("font_color", Color(0.62, 0.92, 0.56, 1.0))
	_apply_ui_font(coming_soon_label)
	layout.add_child(coming_soon_label)

	var back_button := _make_small_button("Back")
	back_button.pressed.connect(_on_back_pressed)
	layout.add_child(back_button)

	_add_rotate_prompt()
	_add_crt_overlay()
	_apply_orientation_guard()


func _on_single_player_pressed() -> void:
	_play_button_click()
	single_player_requested.emit()


func _on_local_two_player_pressed() -> void:
	_play_button_click()
	coming_soon_label.text = ""
	local_two_player_requested.emit()


func _on_lan_multiplayer_pressed() -> void:
	_play_button_click()
	coming_soon_label.text = ""
	lan_multiplayer_requested.emit()


func _on_back_pressed() -> void:
	_play_button_click()
	back_requested.emit()


func _play_button_click() -> void:
	if audio_manager and audio_manager.has_method("play_button_click"):
		audio_manager.play_button_click()


func _make_mode_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(440, 70)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.09, 0.1, 0.1, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	_apply_ui_font(button)
	return button


func _make_small_button(text: String) -> Button:
	var button := _make_mode_button(text)
	button.custom_minimum_size = Vector2(260, 56)
	button.add_theme_font_size_override("font_size", 24)
	return button


func _apply_display_font(control: Control) -> void:
	if display_font != null:
		control.add_theme_font_override("font", display_font)


func _apply_ui_font(control: Control) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)


func _is_mobile_portrait() -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	return viewport_size.x < 800 and viewport_size.y > viewport_size.x


func _apply_orientation_guard() -> void:
	if content_center:
		content_center.custom_minimum_size = get_viewport_rect().size
	var portrait: bool = _is_mobile_portrait()
	if content_root:
		content_root.visible = not portrait
	if rotate_prompt:
		rotate_prompt.visible = portrait


func _add_rotate_prompt() -> void:
	rotate_prompt = CenterContainer.new()
	rotate_prompt.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	rotate_prompt.visible = false
	add_child(rotate_prompt)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 210)
	panel.add_theme_stylebox_override("panel", _make_rotate_prompt_style())
	rotate_prompt.add_child(panel)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "Please rotate your device"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
	_apply_display_font(title)
	layout.add_child(title)

	var body := Label.new()
	body.text = "This game is designed for landscape play."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.84, 0.84, 0.8, 0.96))
	_apply_ui_font(body)
	layout.add_child(body)


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
	crt.modulate.a = 0.14
	add_child(crt)


func _make_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.035, 0.03, 0.84)
	style.border_color = Color(0.36, 0.31, 0.27, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 34
	style.content_margin_top = 30
	style.content_margin_right = 34
	style.content_margin_bottom = 30
	return style


func _make_rotate_prompt_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.03, 0.028, 0.9)
	style.border_color = Color(0.42, 0.18, 0.14, 0.92)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_top = 24
	style.content_margin_right = 28
	style.content_margin_bottom = 24
	return style


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
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
