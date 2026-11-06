extends Node2D
# Nivel generico: lee su configuracion de level_data.gd segun "level_index".
# Si la capa "Ground" esta vacia, el mapa se genera por codigo.
# Si usted pinta el mapa a mano en el editor, esa parte se omite.

@export var level_index: int = 0

const LevelData = preload("res://scripts/level_data.gd")

const ROOM_TILES_W = 40
const ROOM_TILES_H = 22
const ROOM_W = 640
const ROOM_H = 352
const TILE_SIZE = 16
const SOURCE_ID = 0

const TILE_FLOOR = Vector2i(0, 0)
const TILE_FLOOR_ALT = Vector2i(1, 0)
const TILE_WALL = Vector2i(2, 0)
const TILE_WALL_ALT = Vector2i(3, 0)
const TILE_RACK = Vector2i(4, 0)
const TILE_TERMINAL = Vector2i(5, 0)

const ENEMY_SCENES = {
	"spider": preload("res://scenes/enemy_spider.tscn"),
	"bot": preload("res://scenes/enemy_bot.tscn"),
	"worm": preload("res://scenes/enemy_worm.tscn"),
	"adware": preload("res://scenes/enemy_adware.tscn"),
	"keylogger": preload("res://scenes/enemy_keylogger.tscn"),
	"trojan": preload("res://scenes/enemy_trojan.tscn"),
	"ghost": preload("res://scenes/enemy_ghost.tscn"),
	"spyware": preload("res://scenes/enemy_spyware.tscn"),
	"elite_rootkit": preload("res://scenes/enemy_elite_rootkit.tscn"),
	"elite_trojan": preload("res://scenes/enemy_elite_trojan.tscn"),
	"boss": preload("res://scenes/boss.tscn"),
}

var data = {}
var rooms_x = 2
var rooms_y = 2
var current_room = Vector2i(-1, -1)
var boss = null
var finished = false
var finish_time = 0.0

@onready var player = $Player
@onready var hud = $HUD
@onready var ground = $Ground
@onready var camera = $Camera
@onready var goal = $Goal
@onready var enemies = $Enemies
@onready var pickups = $Pickups


func _enter_tree():
	Game.current_level = level_index
	Game.begin_level()


func _ready():
	data = LevelData.LEVELS[level_index]
	rooms_x = data["rooms_x"]
	rooms_y = data["rooms_y"]
	if ground.get_used_cells().is_empty():
		build_level()
	var s = data["start"]
	player.position = tile_to_world(s[0], s[1], s[2], s[3])
	spawn_enemies()
	spawn_disk()
	spawn_items()
	setup_goal()
	player.hp_changed.connect(hud.update_hearts)
	hud.update_hearts(player.hp)
	Game.inventory_changed.connect(hud.update_items)
	Game.message_requested.connect(hud.show_message)
	hud.update_items()
	Game.info_requested.connect(hud.show_info)
	hud.show_message("NIVEL %d: %s" % [level_index + 1, data["name"]], 3.0)
	hud.show_info(data["tip"], 7.0)
	Sound.play_music("level%d" % (level_index + 1))
	update_room(true)


func _physics_process(_delta):
	update_room(false)


func _process(delta):
	if finished:
		finish_time += delta
	if Input.is_action_just_pressed("restart"):
		if not (finished and level_index == 3):
			Game.restart_level()
	if finished and level_index == 3 and finish_time > 3.0:
		if Input.is_action_just_pressed("ui_accept"):
			Game.start_final_trivia()


func tile_to_world(rx, ry, lx, ly):
	return Vector2(rx * ROOM_W + lx * TILE_SIZE + 8, ry * ROOM_H + ly * TILE_SIZE + 8)


func world_tile(rx, ry, lx, ly):
	return Vector2i(rx * ROOM_TILES_W + lx, ry * ROOM_TILES_H + ly)


func update_room(instant):
	var room = Vector2i(floori(player.global_position.x / ROOM_W), floori(player.global_position.y / ROOM_H))
	if room == current_room:
		return
	current_room = room
	var target = Vector2(room.x * ROOM_W + ROOM_W / 2.0, room.y * ROOM_H + ROOM_H / 2.0)
	if instant:
		camera.position = target
	else:
		var tween = create_tween()
		tween.tween_property(camera, "position", target, 0.25)


func spawn_enemies():
	for e in data["enemies"]:
		var type = e[0]
		if type == "rnd":
			var pool = data["pool"]
			type = pool[randi() % pool.size()]
		var enemy = ENEMY_SCENES[type].instantiate()
		enemy.position = tile_to_world(e[1], e[2], e[3], e[4])
		enemies.add_child(enemy)
		if type == "boss":
			boss = enemy
			boss.boss_hp_changed.connect(hud.update_boss)
			boss.boss_defeated.connect(_on_boss_defeated)


func spawn_disk():
	var d = data["disk"]
	if d.is_empty():
		return
	Game.spawn_pickup(pickups, tile_to_world(d[0], d[1], d[2], d[3]), "disk")


func spawn_items():
	for it in data["items"]:
		Game.spawn_pickup(pickups, tile_to_world(it[1], it[2], it[3], it[4]), it[0], true)


func setup_goal():
	var t = data["terminal"]
	if t.is_empty():
		goal.queue_free()
		return
	goal.position = tile_to_world(t[0], t[1], t[2], t[3])
	goal.body_entered.connect(_on_goal_body_entered)


func _on_goal_body_entered(body):
	if finished or not body.is_in_group("player"):
		return
	if not Game.has_key:
		Sound.play("locked")
		hud.show_message("El terminal está bloqueado.\nDerrota al virus élite para obtener la llave.", 3.0)
		return
	finished = true
	Sound.play("level_complete")
	hud.show_message("TERMINAL DESBLOQUEADO\nCargando el siguiente nivel...", 3.0)
	player.set_physics_process(false)
	get_tree().create_timer(1.5).timeout.connect(Game.go_to_next_level)


func _on_boss_defeated():
	finished = true
	Sound.stop_music()
	Sound.play("victory")
	hud.hide_boss()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != boss:
			e.queue_free()
	var text = "¡VICTORIA!\nEl Glitch Final ha sido eliminado."
	if Game.disks >= Game.TOTAL_DISKS:
		text += "\nAntivirus Definitivo instalado: sistema 100% limpio."
	text += "\nPulse ENTER para la evaluación final."
	hud.show_message(text, 9999.0)
	player.set_physics_process(false)


func build_level():
	for ry in range(rooms_y):
		for rx in range(rooms_x):
			build_room(rx, ry)
	for w in data["walls"]:
		for dy in range(w[5]):
			for dx in range(w[4]):
				ground.set_cell(world_tile(w[0], w[1], w[2] + dx, w[3] + dy), SOURCE_ID, TILE_WALL_ALT)
	for r in data["racks"]:
		for i in range(r[4]):
			ground.set_cell(world_tile(r[0], r[1], r[2] + i, r[3]), SOURCE_ID, TILE_RACK)
	var t = data["terminal"]
	if not t.is_empty():
		ground.set_cell(world_tile(t[0], t[1], t[2], t[3]), SOURCE_ID, TILE_TERMINAL)


func build_room(rx, ry):
	var has_left = rx > 0
	var has_right = rx < rooms_x - 1
	var has_up = ry > 0
	var has_down = ry < rooms_y - 1
	for ly in range(ROOM_TILES_H):
		for lx in range(ROOM_TILES_W):
			var wall = lx < 2 or lx >= ROOM_TILES_W - 2 or ly < 2 or ly >= ROOM_TILES_H - 2
			if has_left and lx < 2 and ly >= 9 and ly <= 12:
				wall = false
			if has_right and lx >= ROOM_TILES_W - 2 and ly >= 9 and ly <= 12:
				wall = false
			if has_up and ly < 2 and lx >= 18 and lx <= 21:
				wall = false
			if has_down and ly >= ROOM_TILES_H - 2 and lx >= 18 and lx <= 21:
				wall = false
			var cell = world_tile(rx, ry, lx, ly)
			if wall:
				ground.set_cell(cell, SOURCE_ID, TILE_WALL if (lx + ly) % 2 == 0 else TILE_WALL_ALT)
			else:
				ground.set_cell(cell, SOURCE_ID, TILE_FLOOR_ALT if (lx * 7 + ly * 3) % 11 == 0 else TILE_FLOOR)
