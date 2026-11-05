extends Node

## Base directory for audio files when passing relative paths to play()
@export_dir var base_audio_dir: String = "res://audio"

# Cache loaded audio streams in memory to prevent repeated disk access
var _sound_cache: Dictionary = {}

## Play a preloaded AudioStream directly (Best for latency-critical sounds like hits, jumps, UI)
func play_stream(stream: AudioStream, pitch_variance: float = 0.0) -> AudioStreamPlayer:
	if not stream:
		push_warning("AudioManager: Attempted to play a null AudioStream.")
		return null

	var bus_name := _resolve_bus(stream.resource_path)
	return _spawn_player(stream, bus_name, pitch_variance)


## Play via relative path or sound ID (Best for non-critical/infrequent sounds like music, ambiance)
## Example: AudioManager.play("sfx/player/jump") or AudioManager.play("music/title_theme")
func play(sound_path: String, pitch_variance: float = 0.0) -> AudioStreamPlayer:
	var full_path := sound_path
	if not full_path.begins_with("res://"):
		full_path = base_audio_dir.path_join(sound_path)

	# Auto-detect missing file extension (.wav or .mp3)
	if not ResourceLoader.exists(full_path):
		if ResourceLoader.exists(full_path + ".wav"):
			full_path += ".wav"
		elif ResourceLoader.exists(full_path + ".mp3"):
			full_path += ".mp3"
		else:
			push_warning("AudioManager: File not found at '%s'" % full_path)
			return null

	# Fetch from memory cache or load from disk
	var stream: AudioStream
	if _sound_cache.has(full_path):
		stream = _sound_cache[full_path]
	else:
		stream = load(full_path) as AudioStream
		if stream:
			_sound_cache[full_path] = stream

	if not stream:
		return null

	var bus_target := _resolve_bus(full_path)
	return _spawn_player(stream, bus_target, pitch_variance)


## Case-insensitive bus resolver: checks path segments against all existing buses in AudioServer
func _resolve_bus(file_path: String) -> String:
	var segments := file_path.to_lower().split("/")

	for bus_idx in AudioServer.bus_count:
		var bus_name := AudioServer.get_bus_name(bus_idx)
		var bus_lower := bus_name.to_lower()

		# Skip "Master" so specific subfolders take precedence
		if bus_lower == "master":
			continue

		# If any directory in the path matches this bus name
		if bus_lower in segments:
			print(bus_name)
			print(bus_lower)
			return bus_name # Returns the exact casing required by AudioServer (e.g., "SFX")

	return "Master"


## Instantiates, configures, and cleans up the AudioStreamPlayer node
func _spawn_player(stream: AudioStream, bus_name: String, pitch_variance: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	print("DETECTED BUS: " + player.bus)

	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)

	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


## Clear cached audio files when unloading scenes to free memory
func clear_cache() -> void:
	_sound_cache.clear()

# ==========================================
# --- BACKGROUND MUSIC (BGM) SYSTEM ---
# ==========================================

var _bgm_player: AudioStreamPlayer

## Plays looping background music. If music is already playing, it swaps it.
func play_music(sound_path: String) -> void:
	var full_path := sound_path
	if not full_path.begins_with("res://"):
		full_path = base_audio_dir.path_join(sound_path)

	# Auto-detect extension
	if not ResourceLoader.exists(full_path):
		if ResourceLoader.exists(full_path + ".ogg"):
			full_path += ".ogg"
		elif ResourceLoader.exists(full_path + ".mp3"):
			full_path += ".mp3"
		else:
			push_warning("AudioManager: Music file not found at '%s'" % full_path)
			return

	# Load the stream (using the existing cache system)
	var stream: AudioStream
	if _sound_cache.has(full_path):
		stream = _sound_cache[full_path]
	else:
		stream = load(full_path) as AudioStream
		if stream:
			_sound_cache[full_path] = stream

	if not stream:
		return

	# Create the persistent BGM player if it doesn't exist yet
	if not is_instance_valid(_bgm_player):
		_bgm_player = AudioStreamPlayer.new()
		add_child(_bgm_player)

	# Prevent restarting the track if the exact same song is already playing
	if _bgm_player.stream == stream and _bgm_player.playing:
		return

	# Route to the correct bus, assign the track, and play
	_bgm_player.bus = _resolve_bus(full_path)
	_bgm_player.stream = stream
	_bgm_player.play()


## Stops the currently playing background music
func stop_music() -> void:
	if is_instance_valid(_bgm_player) and _bgm_player.playing:
		_bgm_player.stop()


## Fades out the currently playing music over X seconds
func fade_out_music(duration: float = 1.0) -> void:
	if is_instance_valid(_bgm_player) and _bgm_player.playing:
		var tween := create_tween()
		# Fade volume to -80dB (silent)
		tween.tween_property(_bgm_player, "volume_db", -80.0, duration)
		tween.tween_callback(_bgm_player.stop)
		# Reset the volume back to normal for the next song
		tween.tween_callback(func(): _bgm_player.volume_db = 0.0)
