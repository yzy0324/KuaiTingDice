class_name LanLobbyScreen
extends Control

signal back_requested
signal lan_match_ready_requested

const DEFAULT_PORT := 24567

var display_font: Font
var ui_font: Font
var audio_manager: Node
var network_manager: Node

var host_port_edit: LineEdit
var join_ip_edit: LineEdit
var join_port_edit: LineEdit
var status_label: Label
var players_label: Label
var host_instructions_label: Label
var role_label: Label
var opponent_label: Label
var local_ready_label: Label
var remote_ready_label: Label
var match_status_label: Label
var ready_button: Button
var start_match_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT, true)
	_build_ui()


func set_audio_manager(manager: Node) -> void:
	audio_manager = manager


func set_network_manager(manager: Node) -> void:
	network_manager = manager
	if network_manager == null:
		return
	if network_manager.has_signal("connection_status_changed"):
		network_manager.connect("connection_status_changed", Callable(self, "_on_connection_status_changed"))
	if network_manager.has_signal("peer_connected_to_lobby"):
		network_manager.connect("peer_connected_to_lobby", Callable(self, "_on_peer_changed"))
	if network_manager.has_signal("peer_disconnected_from_lobby"):
		network_manager.connect("peer_disconnected_from_lobby", Callable(self, "_on_peer_changed"))
	if network_manager.has_signal("room_state_changed"):
		network_manager.connect("room_state_changed", Callable(self, "_on_room_state_changed"))
	if network_manager.has_signal("ready_state_changed"):
		network_manager.connect("ready_state_changed", Callable(self, "_on_ready_state_changed"))
	if network_manager.has_signal("lan_match_start_requested"):
		network_manager.connect("lan_match_start_requested", Callable(self, "_on_lan_match_start_requested"))
	if network_manager.has_signal("lan_connection_lost"):
		network_manager.connect("lan_connection_lost", Callable(self, "_on_lan_connection_lost"))


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	display_font = _load_font("res://assets/fonts/display_font.ttf")
	ui_font = _load_font("res://assets/fonts/ui_font.ttf")

	var bg := TextureRect.new()
	bg.texture = _load_first_existing_texture([
		"res://assets/art/backgrounds/bg_start_menu_clean.png",
		"res://assets/art/backgrounds/bg_game_table.png",
		"res://assets/art/backgrounds/bg_start_menu.png"
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
	card.custom_minimum_size = Vector2(760, 560)
	card.add_theme_stylebox_override("panel", _make_card_style())
	center.add_child(card)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	card.add_child(layout)

	var title := Label.new()
	title.text = "LAN Multiplayer"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(0.95, 0.93, 0.86, 1.0))
	_apply_display_font(title)
	layout.add_child(title)

	var host_panel := _make_section_panel()
	layout.add_child(host_panel)
	var host_layout := VBoxContainer.new()
	host_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_layout.add_theme_constant_override("separation", 8)
	host_panel.add_child(host_layout)

	host_layout.add_child(_make_section_label("Host Game"))
	host_port_edit = _make_line_edit(str(DEFAULT_PORT), "Port")
	host_layout.add_child(host_port_edit)
	var host_button := _make_button("Host")
	host_button.pressed.connect(_on_host_pressed)
	host_layout.add_child(host_button)
	host_instructions_label = _make_status_label("")
	host_instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	host_layout.add_child(host_instructions_label)

	var join_panel := _make_section_panel()
	layout.add_child(join_panel)
	var join_layout := VBoxContainer.new()
	join_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_layout.add_theme_constant_override("separation", 8)
	join_panel.add_child(join_layout)

	join_layout.add_child(_make_section_label("Join Game"))
	var join_hint := _make_status_label("Player 2: enter Player 1's Host IP and Port.")
	join_layout.add_child(join_hint)
	join_ip_edit = _make_line_edit("127.0.0.1", "Host IP")
	join_layout.add_child(join_ip_edit)
	join_port_edit = _make_line_edit(str(DEFAULT_PORT), "Port")
	join_layout.add_child(join_port_edit)
	var join_button := _make_button("Join")
	join_button.pressed.connect(_on_join_pressed)
	join_layout.add_child(join_button)

	status_label = _make_status_label("Not connected.")
	layout.add_child(status_label)

	players_label = _make_status_label("Connected players: 1")
	layout.add_child(players_label)

	var room_panel := _make_section_panel()
	layout.add_child(room_panel)
	var room_layout := VBoxContainer.new()
	room_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_layout.add_theme_constant_override("separation", 8)
	room_panel.add_child(room_layout)

	room_layout.add_child(_make_section_label("Room State"))

	role_label = _make_status_label("You are not connected.")
	room_layout.add_child(role_label)

	opponent_label = _make_status_label("No opponent connected.")
	room_layout.add_child(opponent_label)

	local_ready_label = _make_status_label("You: Not Ready")
	room_layout.add_child(local_ready_label)

	remote_ready_label = _make_status_label("Opponent: Not Ready")
	room_layout.add_child(remote_ready_label)

	var room_buttons := HBoxContainer.new()
	room_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	room_buttons.add_theme_constant_override("separation", 14)
	room_layout.add_child(room_buttons)

	ready_button = _make_button("Ready")
	ready_button.pressed.connect(_on_ready_pressed)
	room_buttons.add_child(ready_button)

	start_match_button = _make_button("Start Match")
	start_match_button.pressed.connect(_on_start_match_pressed)
	room_buttons.add_child(start_match_button)

	match_status_label = _make_status_label("")
	room_layout.add_child(match_status_label)

	var back_button := _make_button("Back")
	back_button.custom_minimum_size = Vector2(220, 50)
	back_button.pressed.connect(_on_back_pressed)
	layout.add_child(back_button)

	_add_crt_overlay()
	_refresh_room_state_ui()


func _on_host_pressed() -> void:
	_play_button_click()
	if network_manager == null:
		_set_status("Network manager is missing.")
		return
	var port := _get_port_from_text(host_port_edit.text)
	var success := bool(network_manager.call("host_game", port))
	if success:
		_show_host_join_instructions(port)
	else:
		_clear_host_join_instructions()
	_refresh_players_label()
	_refresh_room_state_ui()


func _on_join_pressed() -> void:
	_play_button_click()
	if network_manager == null:
		_set_status("Network manager is missing.")
		return
	_clear_host_join_instructions()
	network_manager.call("join_game", join_ip_edit.text, _get_port_from_text(join_port_edit.text))
	_refresh_players_label()
	_refresh_room_state_ui()


func _on_back_pressed() -> void:
	_play_button_click()
	if network_manager and network_manager.has_method("disconnect_from_game"):
		network_manager.call("disconnect_from_game")
	back_requested.emit()


func _on_connection_status_changed(message: String) -> void:
	_set_status(message)
	_refresh_players_label()


func _on_peer_changed(_peer_id: int) -> void:
	_refresh_players_label()
	_refresh_room_state_ui()


func _on_room_state_changed() -> void:
	_refresh_players_label()
	_refresh_room_state_ui()


func _on_ready_state_changed(_local_ready: bool, _remote_ready: bool) -> void:
	_refresh_room_state_ui()


func _on_lan_match_start_requested() -> void:
	if match_status_label:
		match_status_label.text = "LAN match started."
	_refresh_room_state_ui()


func _on_lan_connection_lost(message: String) -> void:
	_set_status(message)
	if match_status_label:
		match_status_label.text = message
	_refresh_players_label()
	_refresh_room_state_ui()


func _get_port_from_text(text: String) -> int:
	return int(text.strip_edges())


func _refresh_players_label() -> void:
	if players_label == null:
		return
	if network_manager == null or not network_manager.has_method("is_connected_to_game") or not bool(network_manager.call("is_connected_to_game")):
		players_label.text = "Connected players: 1"
		return
	if network_manager.has_method("is_host") and bool(network_manager.call("is_host")):
		players_label.text = "Connected players: host + peers"
	else:
		players_label.text = "Connected players: connected to host"


func _refresh_room_state_ui() -> void:
	if role_label == null:
		return

	if network_manager == null or not network_manager.has_method("is_connected_to_game") or not bool(network_manager.call("is_connected_to_game")):
		role_label.text = "You are not connected."
		opponent_label.text = "No opponent connected."
		local_ready_label.text = "You: Not Ready"
		remote_ready_label.text = "Opponent: Not Ready"
		ready_button.text = "Ready"
		ready_button.disabled = true
		start_match_button.visible = false
		match_status_label.text = ""
		return

	var local_player_number := int(network_manager.get("local_player_number"))
	var local_ready := bool(network_manager.get("local_ready"))
	var remote_ready := bool(network_manager.get("remote_ready"))
	var room_started := bool(network_manager.get("room_started"))
	var is_host := network_manager.has_method("is_host") and bool(network_manager.call("is_host"))

	if local_player_number == 1:
		role_label.text = "You are Player 1 (Host)"
	elif local_player_number == 2:
		role_label.text = "You are Player 2 (Client)"
	else:
		role_label.text = "You are connected."

	if is_host:
		if remote_ready or _has_remote_peer():
			opponent_label.text = "Player 2 connected"
		else:
			opponent_label.text = "Waiting for Player 2..."
	else:
		opponent_label.text = "Connected to Player 1"

	local_ready_label.text = "You: %s" % _ready_text(local_ready)
	remote_ready_label.text = "Opponent: %s" % _ready_text(remote_ready)

	ready_button.text = "Cancel Ready" if local_ready else "Ready"
	ready_button.disabled = room_started

	start_match_button.visible = is_host
	if start_match_button.visible:
		if network_manager.has_method("can_start_lan_match"):
			start_match_button.disabled = not bool(network_manager.call("can_start_lan_match"))
		else:
			start_match_button.disabled = true

	if room_started:
		match_status_label.text = "LAN match started."
	elif match_status_label.text == "LAN match started.":
		match_status_label.text = ""


func _has_remote_peer() -> bool:
	return network_manager != null and int(network_manager.get("connected_peer_count")) > 0 and bool(network_manager.call("is_connected_to_game"))


func _ready_text(value: bool) -> String:
	return "Ready" if value else "Not Ready"


func _set_status(message: String) -> void:
	if status_label:
		status_label.text = message


func _on_ready_pressed() -> void:
	_play_button_click()
	if network_manager == null or not network_manager.has_method("set_local_ready"):
		return
	var next_ready := not bool(network_manager.get("local_ready"))
	network_manager.call("set_local_ready", next_ready)
	_refresh_room_state_ui()


func _on_start_match_pressed() -> void:
	_play_button_click()
	if network_manager and network_manager.has_method("request_start_lan_match"):
		network_manager.call("request_start_lan_match")
	_refresh_room_state_ui()


func _show_host_join_instructions(port: int) -> void:
	if host_instructions_label == null:
		return
	if network_manager == null or not network_manager.has_method("get_local_lan_addresses"):
		host_instructions_label.text = "LAN Room Created\nYou are Player 1\n\nCould not detect LAN IP. Check your network settings.\nYou can manually find it with ipconfig on Windows."
		return

	var addresses: Array = network_manager.call("get_local_lan_addresses")
	if addresses.is_empty():
		host_instructions_label.text = "LAN Room Created\nYou are Player 1\n\nCould not detect LAN IP. Check your network settings.\nYou can manually find it with ipconfig on Windows.\n\nPort: %d" % port
		return

	var lines := PackedStringArray()
	lines.append("LAN Room Created")
	lines.append("You are Player 1")
	lines.append("")
	lines.append("Tell Player 2 to join using:")
	lines.append("")
	if addresses.size() == 1:
		lines.append("IP: %s" % String(addresses[0]))
	else:
		lines.append("Possible Host IPs:")
		for address in addresses:
			lines.append(String(address))
	lines.append("Port: %d" % port)
	lines.append("")
	lines.append("Player 2 should try the IP that matches the same Wi-Fi / LAN.")
	host_instructions_label.text = "\n".join(lines)


func _clear_host_join_instructions() -> void:
	if host_instructions_label:
		host_instructions_label.text = ""


func _play_button_click() -> void:
	if audio_manager and audio_manager.has_method("play_button_click"):
		audio_manager.play_button_click()


func _make_section_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_section_style())
	return panel


func _make_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	_apply_display_font(label)
	return label


func _make_status_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.84, 0.84, 0.8, 0.95))
	_apply_ui_font(label)
	return label


func _make_line_edit(text: String, placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.text = text
	edit.placeholder_text = placeholder
	edit.custom_minimum_size = Vector2(420, 44)
	edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	edit.add_theme_font_size_override("font_size", 20)
	edit.add_theme_color_override("font_color", Color(0.93, 0.91, 0.84, 1.0))
	_apply_ui_font(edit)
	return edit


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(260, 52)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(0.94, 0.92, 0.86, 1.0))
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.09, 0.1, 0.1, 0.95), Color(0.42, 0.38, 0.32, 0.9)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.13, 0.14, 0.14, 0.98), Color(0.52, 0.2, 0.16, 0.95)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.06, 0.07, 0.07, 1.0), Color(0.35, 0.15, 0.12, 0.95)))
	_apply_ui_font(button)
	return button


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


func _make_section_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.06, 0.055, 0.72)
	style.border_color = Color(0.26, 0.25, 0.21, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_top = 12
	style.content_margin_right = 16
	style.content_margin_bottom = 12
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
