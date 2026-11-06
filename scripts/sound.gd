extends Node
# Sonido del juego (autoload "Sound"): efectos y musica de fondo.
# Los archivos estan en res://assets/audio/sfx y res://assets/audio/music

const SFX_DIR = "res://assets/audio/sfx/"
const MUSIC_DIR = "res://assets/audio/music/"
const POOL_SIZE = 10

var players = []
var cache = {}
var last_played = {}
var music_player = null
var current_music = ""
var sfx_volume_db = -3.0
var music_volume_db = -5.0
var music_enabled = true


func _ready():
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = music_volume_db
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		toggle_music()


func toggle_music():
	music_enabled = not music_enabled
	apply_music_volume()


func apply_music_volume():
	if music_enabled:
		music_player.volume_db = music_volume_db
	else:
		music_player.volume_db = -80.0


func get_stream(path):
	if not cache.has(path):
		if ResourceLoader.exists(path):
			cache[path] = load(path)
		else:
			cache[path] = null
	return cache[path]


func play(sfx_name, volume_offset = 0.0):
	if sfx_name == "":
		return
	var now = Time.get_ticks_msec()
	if last_played.has(sfx_name) and now - last_played[sfx_name] < 40:
		return
	last_played[sfx_name] = now
	var stream = get_stream(SFX_DIR + sfx_name + ".wav")
	if stream == null:
		return
	var chosen = players[0]
	for p in players:
		if not p.playing:
			chosen = p
			break
	chosen.stream = stream
	chosen.volume_db = sfx_volume_db + volume_offset
	chosen.play()


func play_music(music_name):
	if music_name == current_music and music_player.playing:
		return
	var stream = get_stream(MUSIC_DIR + music_name + ".wav")
	if stream == null:
		return
	current_music = music_name
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = stream.data.size() / 2
	music_player.stream = stream
	apply_music_volume()
	music_player.play()


func stop_music():
	current_music = ""
	music_player.stop()


func _on_music_finished():
	if current_music != "":
		music_player.play()
