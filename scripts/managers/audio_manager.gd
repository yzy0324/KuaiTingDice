class_name AudioManager
extends Node

const DEFAULT_VOLUME_DB := -6.0
const SFX_PATHS := {
	"button_click": ["res://assets/audio/sfx_button_click.wav", "res://assets/audio/sfx_button_click.WAV"],
	"roll": ["res://assets/audio/sfx_roll.wav", "res://assets/audio/sfx_roll.WAV"],
	"hold": ["res://assets/audio/sfx_hold.wav", "res://assets/audio/sfx_hold.WAV"],
	"score": ["res://assets/audio/sfx_score.wav", "res://assets/audio/sfx_score.WAV"],
	"new_record": ["res://assets/audio/sfx_new_record.wav", "res://assets/audio/sfx_new_record.WAV"],
	"game_over": ["res://assets/audio/sfx_game_over.wav", "res://assets/audio/sfx_game_over.WAV"],
}

var players: Dictionary = {}
var warned_missing_paths: Dictionary = {}


func _ready() -> void:
	for key in SFX_PATHS.keys():
		var paths: Array = SFX_PATHS[key]
		_create_player(String(key), paths)


func play_button_click() -> void:
	_play("button_click")


func play_roll() -> void:
	_play("roll")


func play_hold() -> void:
	_play("hold")


func play_score() -> void:
	_play("score")


func play_new_record() -> void:
	_play("new_record")


func play_game_over() -> void:
	_play("game_over")


func _create_player(key: String, paths: Array) -> void:
	var player := AudioStreamPlayer.new()
	player.volume_db = DEFAULT_VOLUME_DB

	var stream_path := _find_existing_path(paths)
	if stream_path != "":
		player.stream = load(stream_path) as AudioStream
	else:
		_warn_missing_audio(String(paths[0]))

	add_child(player)
	players[key] = player


func _find_existing_path(paths: Array) -> String:
	for path in paths:
		var stream_path := String(path)
		if ResourceLoader.exists(stream_path):
			return stream_path
	return ""


func _play(key: String) -> void:
	if not players.has(key):
		return

	var player: AudioStreamPlayer = players[key]
	if player.stream == null:
		return

	player.stop()
	player.play()


func _warn_missing_audio(path: String) -> void:
	if warned_missing_paths.has(path):
		return

	warned_missing_paths[path] = true
	push_warning("Missing audio asset: " + path)
