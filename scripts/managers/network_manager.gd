class_name NetworkManager
extends Node

signal connection_status_changed(message: String)
signal peer_connected_to_lobby(peer_id: int)
signal peer_disconnected_from_lobby(peer_id: int)
signal room_state_changed
signal ready_state_changed(local_ready: bool, remote_ready: bool)
signal lan_match_start_requested

var peer: ENetMultiplayerPeer
var hosting: bool = false
var current_host_port: int = 0
var local_player_number: int = 0
var remote_player_number: int = 0
var local_ready: bool = false
var remote_ready: bool = false
var room_started: bool = false
var connected_peer_count: int = 0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(port: int) -> bool:
	if not _is_valid_port(port):
		_emit_status("Invalid port.")
		return false

	disconnect_from_game()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 2)
	if error != OK:
		peer = null
		hosting = false
		current_host_port = 0
		_emit_status("Could not host on port %d." % port)
		return false

	hosting = true
	current_host_port = port
	local_player_number = 1
	remote_player_number = 2
	local_ready = false
	remote_ready = false
	room_started = false
	connected_peer_count = 0
	multiplayer.multiplayer_peer = peer
	_emit_status("Hosting on port %d." % port)
	_emit_room_state_changed()
	return true


func join_game(address: String, port: int) -> bool:
	var clean_address := address.strip_edges()
	if clean_address.is_empty():
		_emit_status("Enter a host IP address.")
		return false
	if not _is_valid_port(port):
		_emit_status("Invalid port.")
		return false

	disconnect_from_game()
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(clean_address, port)
	if error != OK:
		peer = null
		hosting = false
		current_host_port = 0
		_emit_status("Could not connect to %s:%d." % [clean_address, port])
		return false

	hosting = false
	current_host_port = 0
	local_player_number = 2
	remote_player_number = 1
	local_ready = false
	remote_ready = false
	room_started = false
	connected_peer_count = 0
	multiplayer.multiplayer_peer = peer
	_emit_status("Connecting to %s:%d..." % [clean_address, port])
	_emit_room_state_changed()
	return true


func disconnect_from_game() -> void:
	if peer != null:
		peer.close()
	peer = null
	hosting = false
	current_host_port = 0
	_reset_room_state()
	multiplayer.multiplayer_peer = null
	_emit_status("Disconnected.")


func is_host() -> bool:
	return hosting


func is_connected_to_game() -> bool:
	return peer != null and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func get_local_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return 0
	return multiplayer.get_unique_id()


func set_local_ready(value: bool) -> void:
	if not is_connected_to_game():
		_emit_status("Connect to a LAN room first.")
		return
	if room_started:
		return

	local_ready = value
	_emit_ready_state_changed()
	_emit_room_state_changed()
	rpc("_rpc_set_remote_ready", value)


func can_start_lan_match() -> bool:
	return hosting and is_connected_to_game() and connected_peer_count > 0 and local_ready and remote_ready and not room_started


func request_start_lan_match() -> void:
	if not can_start_lan_match():
		_emit_status("Both players must be connected and ready.")
		return

	room_started = true
	_emit_status("LAN match started. Game sync coming next.")
	_emit_room_state_changed()
	lan_match_start_requested.emit()
	rpc("_rpc_start_lan_match")


func get_local_lan_addresses() -> Array:
	var preferred: Array = []
	var fallback: Array = []
	var addresses := IP.get_local_addresses()

	for address in addresses:
		var clean_address := String(address).strip_edges()
		if not _is_useful_ipv4_address(clean_address):
			continue
		if _is_preferred_lan_address(clean_address):
			preferred.append(clean_address)
		else:
			fallback.append(clean_address)

	return preferred + fallback


@rpc("any_peer", "reliable")
func _rpc_set_remote_ready(value: bool) -> void:
	remote_ready = value
	_emit_ready_state_changed()
	_emit_room_state_changed()


@rpc("any_peer", "reliable")
func _rpc_start_lan_match() -> void:
	room_started = true
	_emit_status("LAN match started. Game sync coming next.")
	_emit_room_state_changed()
	lan_match_start_requested.emit()


func _is_valid_port(port: int) -> bool:
	return port > 0 and port <= 65535


func _is_useful_ipv4_address(address: String) -> bool:
	if address == "127.0.0.1" or address == "0.0.0.0":
		return false
	if address.contains(":"):
		return false

	var parts := address.split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
		var value := int(part)
		if value < 0 or value > 255:
			return false
	return true


func _is_preferred_lan_address(address: String) -> bool:
	if address.begins_with("192.168.") or address.begins_with("10."):
		return true
	if address.begins_with("172."):
		var parts := address.split(".")
		if parts.size() >= 2 and parts[1].is_valid_int():
			var second := int(parts[1])
			return second >= 16 and second <= 31
	return false


func _emit_status(message: String) -> void:
	connection_status_changed.emit(message)


func _emit_ready_state_changed() -> void:
	ready_state_changed.emit(local_ready, remote_ready)


func _emit_room_state_changed() -> void:
	room_state_changed.emit()


func _reset_room_state() -> void:
	local_player_number = 0
	remote_player_number = 0
	local_ready = false
	remote_ready = false
	room_started = false
	connected_peer_count = 0
	_emit_ready_state_changed()
	_emit_room_state_changed()


func _on_peer_connected(peer_id: int) -> void:
	if hosting:
		remote_player_number = 2
		remote_ready = false
		connected_peer_count += 1
		rpc_id(peer_id, "_rpc_set_remote_ready", local_ready)
	peer_connected_to_lobby.emit(peer_id)
	_emit_status("Peer %d connected. Game sync coming next." % peer_id)
	_emit_ready_state_changed()
	_emit_room_state_changed()


func _on_peer_disconnected(peer_id: int) -> void:
	remote_ready = false
	room_started = false
	connected_peer_count = max(connected_peer_count - 1, 0)
	peer_disconnected_from_lobby.emit(peer_id)
	_emit_status("Peer %d disconnected." % peer_id)
	_emit_ready_state_changed()
	_emit_room_state_changed()


func _on_connected_to_server() -> void:
	connected_peer_count = 1
	_emit_status("Connected. Game sync coming next.")
	_emit_room_state_changed()


func _on_connection_failed() -> void:
	peer = null
	hosting = false
	current_host_port = 0
	_reset_room_state()
	_emit_status("Connection failed.")


func _on_server_disconnected() -> void:
	peer = null
	hosting = false
	current_host_port = 0
	_reset_room_state()
	_emit_status("Server disconnected.")
