extends Node
## AudioManager (Autoload)
## Manages BGM, Ambient sounds, and provides an object pool for SFX.

@export var pool_size: int = 16

var _sfx_pool: Array[AudioStreamPlayer2D] = []
var _bgm_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

func _ready() -> void:
	_setup_buses()
	_initialize_players()

## Assign the default bus layout
func _setup_buses() -> void:
	# Note: In a real project you'd set this in Project Settings,
	# but we can enforce it programmatically if needed.
	# AudioServer.set_bus_layout(load("res://assets/audio/buses/default_bus_layout.tres"))
	pass

func _initialize_players() -> void:
	# Initialize BGM Player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Music"
	add_child(_bgm_player)

	# Initialize Ambient Player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)

	# Initialize SFX Pool
	for i in range(pool_size):
		var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)

## Play a background music stream
func play_music(stream: AudioStream, crossfade_time: float = 1.0) -> void:
	# Implementation for crossfading would go here.
	# For scaffolding, we just swap the stream and play.
	if _bgm_player.stream == stream and _bgm_player.playing:
		return

	_bgm_player.stream = stream
	_bgm_player.play()

## Play an ambient loop
func play_ambient(stream: AudioStream) -> void:
	if _ambient_player.stream == stream and _ambient_player.playing:
		return

	_ambient_player.stream = stream
	_ambient_player.play()

## Stop all background audio
func stop_all_bgm() -> void:
	_bgm_player.stop()
	_ambient_player.stop()

## Play a sound effect from the pool at a specific position
func play_sfx(stream: AudioStream, position: Vector2 = Vector2.ZERO) -> void:
	for player in _sfx_pool:
		if not player.playing:
			player.stream = stream
			player.global_position = position
			player.play()
			return

	push_warning("AudioManager: SFX Pool exhausted. Consider increasing pool size.")
