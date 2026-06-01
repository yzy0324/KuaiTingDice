class_name StartMenu
extends Control

signal start_requested

var display_font: Font
var ui_font: Font
var audio_manager: Node
var save_manager: RefCounted
var settings_panel: PanelContainer
var sfx_slider: HSlider
var mute_check: CheckButton


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	display_font = _load_font("res://assets/fonts/display_font.ttf")
	ui_font = _load_font("res://assets/fonts/ui_font.ttf")

	var bg := TextureRect.new()
	bg.texture = _load_first_existing_texture([
		"res://assets/art/backgrounds/bg_start_menu_clean.png",
		"res://assets/art/backgrounds/bg_start_menu.png",
		"res://assets/art/backgrounds/bg_start_menu.png.png"
	])
	bg.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT, true)
	add_child(center)

	var menu_card := PanelContainer.new()
	menu_card.custom_minimum_size = Vector2(680, 420)
	menu_card.add_theme_stylebox_override("panel", _make_menu_card_style())
	center.add_child(menu_card)

	var root_layout := VBoxContainer.new()
	root_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	root_layout.add_theme_constant_override("separation", 16)
	menu_card.add_child(root_layout)

	var title := Label.new()
	title.text = "快艇骰子"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	_apply_display_font(title)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	root_layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A dice scoring game inspired by Yacht / Yahtzee"
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.84, 0.8, 0.95))
	subtitle.add_theme_font_size_override("font_size", 22)
	_apply_ui_font(subtitle)
	root_layout.add_child(subtitle)

	var rules_panel := PanelContainer.new()
	rules_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_panel.custom_minimum_size = Vector2(600, 0)
	rules_panel.add_theme_stylebox_override("panel", _make_rules_panel_style())
	root_layout.add_child(rules_panel)

	var rules := Label.new()
	rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 18)
	_apply_ui_font(rules)
	rules.add_theme_color_override("font_color", Color(0.88, 0.87, 0.83, 0.98))
	rules.text = "Rules:\n- Roll 5 dice.\n- You may roll up to 3 times each round.\n- Click dice to HOLD them.\n- Choose one unused score category each round.\n- The game ends after all 13 categories are used."
	rules_panel.add_child(rules)

	var start_button := Button.new()
	start_button.text = "Start Game"
	start_button.custom_minimum_size = Vector2(420, 64)
	start_button.add_theme_font_size_override("font_size", 28)
	_apply_ui_font(start_button)
	start_button.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	start_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.09, 0.1, 0.1, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	start_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	start_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	start_button.pressed.connect(_on_start_button_pressed)
	root_layout.add_child(start_button)

	var settings_button := Button.new()
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(260, 48)
	settings_button.add_theme_font_size_override("font_size", 20)
	_apply_ui_font(settings_button)
	settings_button.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	settings_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.08, 0.09, 0.09, 0.92), Color(0.34, 0.32, 0.28, 0.85)))
	settings_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.12, 0.13, 0.13, 0.96), Color(0.45, 0.52, 0.34, 0.95)))
	settings_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.28, 0.34, 0.24, 0.95)))
	settings_button.pressed.connect(_on_settings_button_pressed)
	root_layout.add_child(settings_button)

	_build_settings_panel(root_layout)
	_add_crt_overlay()


func _on_start_button_pressed() -> void:
	_play_button_click()
	start_requested.emit()


func set_audio_manager(manager: Node) -> void:
	audio_manager = manager
	_sync_settings_controls()


func set_save_manager(manager: RefCounted) -> void:
	save_manager = manager
	_sync_settings_controls()


func _play_button_click() -> void:
	if audio_manager and audio_manager.has_method("play_button_click"):
		audio_manager.play_button_click()


func _build_settings_panel(parent: Control) -> void:
	settings_panel = PanelContainer.new()
	settings_panel.visible = false
	settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_panel.add_theme_stylebox_override("panel", _make_settings_panel_style())
	parent.add_child(settings_panel)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	settings_panel.add_child(layout)

	var title := Label.new()
	title.text = "Audio Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	_apply_display_font(title)
	layout.add_child(title)

	var volume_label := Label.new()
	volume_label.text = "SFX Volume"
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	volume_label.add_theme_font_size_override("font_size", 18)
	volume_label.add_theme_color_override("font_color", Color(0.88, 0.87, 0.83, 0.98))
	_apply_ui_font(volume_label)
	layout.add_child(volume_label)

	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = 0.8
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	layout.add_child(sfx_slider)

	mute_check = CheckButton.new()
	mute_check.text = "Mute SFX"
	mute_check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mute_check.add_theme_font_size_override("font_size", 18)
	mute_check.add_theme_color_override("font_color", Color(0.88, 0.87, 0.83, 0.98))
	_apply_ui_font(mute_check)
	mute_check.toggled.connect(_on_mute_toggled)
	layout.add_child(mute_check)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(180, 44)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	close_button.add_theme_stylebox_override("normal", _make_button_style(Color(0.09, 0.1, 0.1, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	close_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	close_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	_apply_ui_font(close_button)
	close_button.pressed.connect(_on_settings_close_pressed)
	layout.add_child(close_button)

	_sync_settings_controls()


func _on_settings_button_pressed() -> void:
	_play_button_click()
	if settings_panel:
		settings_panel.visible = not settings_panel.visible


func _on_settings_close_pressed() -> void:
	_play_button_click()
	if settings_panel:
		settings_panel.visible = false


func _on_sfx_volume_changed(value: float) -> void:
	if audio_manager and audio_manager.has_method("set_sfx_volume_linear"):
		audio_manager.call("set_sfx_volume_linear", value)
	if save_manager and save_manager.has_method("set_sfx_volume"):
		save_manager.call("set_sfx_volume", value)


func _on_mute_toggled(button_pressed: bool) -> void:
	if audio_manager and audio_manager.has_method("set_muted"):
		audio_manager.call("set_muted", button_pressed)
	if save_manager and save_manager.has_method("set_sfx_muted"):
		save_manager.call("set_sfx_muted", button_pressed)


func _sync_settings_controls() -> void:
	if sfx_slider == null or mute_check == null:
		return

	if save_manager:
		if save_manager.has_method("get_sfx_volume"):
			sfx_slider.set_value_no_signal(float(save_manager.call("get_sfx_volume")))
		if save_manager.has_method("get_sfx_muted"):
			mute_check.set_pressed_no_signal(bool(save_manager.call("get_sfx_muted")))
	elif audio_manager:
		if audio_manager.has_method("get_sfx_volume_linear"):
			sfx_slider.set_value_no_signal(float(audio_manager.call("get_sfx_volume_linear")))
		if audio_manager.has_method("is_muted"):
			mute_check.set_pressed_no_signal(bool(audio_manager.call("is_muted")))


func _apply_display_font(control: Control) -> void:
	if display_font != null:
		control.add_theme_font_override("font", display_font)


func _apply_ui_font(control: Control) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)


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
	crt.modulate.a = 0.16
	add_child(crt)


func _make_menu_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.035, 0.03, 0.82)
	style.border_color = Color(0.36, 0.31, 0.27, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 30
	style.content_margin_top = 28
	style.content_margin_right = 30
	style.content_margin_bottom = 28
	return style


func _make_rules_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.075, 0.07, 0.82)
	style.border_color = Color(0.3, 0.28, 0.24, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	return style


func _make_settings_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.05, 0.045, 0.9)
	style.border_color = Color(0.32, 0.38, 0.27, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 20
	style.content_margin_top = 16
	style.content_margin_right = 20
	style.content_margin_bottom = 16
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
