extends Node
## Sound effects and the two-layer adaptive music.
##
## Effects are WAV files in res://audio/sfx/<name>.wav (missing ones are skipped silently, so
## sounds can be swapped or added by file name). Music is two loops of the same length that start
## together: "explore" (lyre and drone) and "tension" (frame drums), mixed by the guards' highest
## awareness, as the design doc describes.

const SFX_DIR := "res://audio/sfx/"
const MUSIC_EXPLORE := "res://audio/music/explore.wav"
const MUSIC_TENSION := "res://audio/music/tension.wav"
const VOICES := 12

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _explore: AudioStreamPlayer
var _tension: AudioStreamPlayer
var _tension_target := 0.0
var _tension_level := 0.0
var music_volume_db := -8.0
var listener_pos := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_explore = _make_music(MUSIC_EXPLORE)
	_tension = _make_music(MUSIC_TENSION)


func _make_music(path: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	if ResourceLoader.exists(path):
		var s: AudioStream = load(path)
		if s is AudioStreamWAV:
			var wav := s as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)
		p.stream = s
	p.volume_db = -80.0
	return p


func _stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := SFX_DIR + name + ".wav"
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = s
	return s


## Plays an effect. With a world position, the volume falls off with distance from the player.
func play(name: String, world_pos: Variant = null, volume_db := 0.0, pitch_jitter := 0.06, pitch := 1.0) -> void:
	var s := _stream(name)
	if s == null:
		return
	var vol := volume_db
	if world_pos != null:
		var d := Iso.tiles_between(world_pos, listener_pos)
		if d > 14.0:
			return
		vol += -1.6 * d
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.volume_db = vol
	p.pitch_scale = pitch * (1.0 + randf_range(-pitch_jitter, pitch_jitter))
	p.play()


func start_music() -> void:
	if _explore.stream and not _explore.playing:
		_explore.play()
		_tension.play()
	_explore.volume_db = music_volume_db


func stop_music() -> void:
	_explore.stop()
	_tension.stop()


## 0 = all calm, 1 = a guard is fully alert.
func set_tension(t: float) -> void:
	_tension_target = clampf(t, 0.0, 1.0)


func _process(delta: float) -> void:
	_tension_level = move_toward(_tension_level, _tension_target, delta * 1.0)
	if _tension.playing:
		_tension.volume_db = linear_to_db(maxf(0.0001, _tension_level)) + music_volume_db
	if _explore.playing:
		_explore.volume_db = music_volume_db - _tension_level * 4.0
