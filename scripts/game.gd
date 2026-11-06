extends Node
# Estado global del juego (autoload "Game"): progreso, inventario, drops y evaluacion.

signal inventory_changed
signal message_requested(text, seconds)
signal info_requested(text, seconds)

const MAX_HP = 5
const MAX_VIALS = 3
const TOTAL_DISKS = 3
const LEVEL_SCENES = [
	"res://scenes/level1.tscn",
	"res://scenes/level2.tscn",
	"res://scenes/level3.tscn",
	"res://scenes/level4.tscn",
]
const MENU_SCENE = "res://scenes/menu.tscn"
const PICKUP_SCENE = preload("res://scenes/pickup.tscn")
const LOOT_HEART_CHANCE = 0.2
const LOOT_VIAL_CHANCE = 0.12
const LOOT_CD_CHANCE = 0.04
const OVERCLOCK_SECONDS = 10.0

# Bestiario: [titulo, explicacion]. Se muestra la primera vez que se encuentra cada virus.
const BESTIARY = {
	"spider": ["BUG", "Un bug es un error de programación. Si alguien lo aprovecha, se convierte en una vulnerabilidad."],
	"bot": ["BOT", "Un bot es un equipo infectado que obedece órdenes a distancia. Muchos bots juntos forman una botnet."],
	"trojan": ["TROYANO", "Un troyano se disfraza de programa legítimo para engañarte; una vez dentro, abre la puerta a otros virus."],
	"elite_trojan": ["TROYANO ÉLITE", "Los troyanos no se copian solos: necesitan que tú los ejecutes. Derrótalo para obtener la llave."],
	"ghost": ["RANSOMWARE", "El ransomware cifra tus archivos y exige un rescate. La mejor defensa: copias de seguridad (backups)."],
	"spyware": ["SPYWARE", "El spyware espía en secreto lo que haces (contraseñas, hábitos) y lo envía a terceros."],
	"rootkit": ["ROOTKIT", "Un rootkit se oculta en el sistema con privilegios altos y es muy difícil de detectar. Derrótalo para obtener la llave."],
	"worm": ["GUSANO (WORM)", "Un gusano se copia a sí mismo y se propaga por la red sin que nadie haga nada. ¡Se divide al morir!"],
	"adware": ["ADWARE", "El adware llena la pantalla de publicidad no deseada (ventanas emergentes), a veces rastreando lo que haces."],
	"keylogger": ["KEYLOGGER", "Un keylogger registra las teclas que pulsas para robar contraseñas. Suele permanecer invisible."],
	"boss": ["GLITCH FINAL", "Es la corrupción total del sistema. Con el Antivirus Definitivo (3 discos de respaldo) le haces el doble de daño."],
}

var current_level = 0
var hp = MAX_HP
var vials = 0
var disks = 0
var has_key = false
var saved_vials = 0
var saved_disks = 0
var trivia_mode = ""
var pre_answers = []
var post_answers = []
var seen = {}


func begin_level():
	has_key = false
	hp = MAX_HP
	saved_vials = vials
	saved_disks = disks


func restart_level():
	vials = saved_vials
	disks = saved_disks
	has_key = false
	hp = MAX_HP
	get_tree().reload_current_scene()


func go_to_next_level():
	current_level += 1
	if current_level >= LEVEL_SCENES.size():
		current_level = LEVEL_SCENES.size() - 1
	get_tree().change_scene_to_file(LEVEL_SCENES[current_level])


func new_game():
	current_level = 0
	vials = 0
	disks = 0
	has_key = false
	hp = MAX_HP
	seen = {}
	get_tree().change_scene_to_file(LEVEL_SCENES[0])


func start_final_trivia():
	trivia_mode = "final"
	get_tree().change_scene_to_file(MENU_SCENE)


func reset_to_menu():
	trivia_mode = ""
	pre_answers = []
	post_answers = []
	current_level = 0
	vials = 0
	disks = 0
	has_key = false
	hp = MAX_HP
	seen = {}
	get_tree().change_scene_to_file(MENU_SCENE)


func player_damage():
	if disks >= TOTAL_DISKS:
		return 2
	return 1


func introduce(kind_id):
	if kind_id == "" or seen.has("enemy_" + kind_id) or not BESTIARY.has(kind_id):
		return
	seen["enemy_" + kind_id] = true
	var entry = BESTIARY[kind_id]
	info_requested.emit("%s: %s" % [entry[0], entry[1]], 7.0)


func info_once(id, text):
	if seen.has(id):
		return
	seen[id] = true
	info_requested.emit(text, 7.0)


func collect(kind, player):
	if kind == "heart":
		if player.hp >= MAX_HP:
			return false
		player.heal(1)
		return true
	if kind == "vial":
		if vials >= MAX_VIALS:
			return false
		vials += 1
		Sound.play("pickup")
		message_requested.emit("Vial de código recogido (E para usarlo)", 2.0)
		info_once("item_vial", "VIAL DE CÓDIGO: es como un parche de seguridad; repara el sistema y te cura 2 vidas.")
	elif kind == "key":
		has_key = true
		Sound.play("key")
		message_requested.emit("¡Llave criptográfica obtenida!\nVaya al terminal.", 3.0)
		info_once("item_key", "LLAVE CRIPTOGRÁFICA: la criptografía protege la información; sin la clave correcta nadie puede acceder a ella.")
	elif kind == "disk":
		disks += 1
		Sound.play("disk")
		if disks >= TOTAL_DISKS:
			message_requested.emit("¡ANTIVIRUS DEFINITIVO ENSAMBLADO!\nTus disparos hacen doble daño.", 4.0)
		else:
			message_requested.emit("Disco de respaldo %d/%d" % [disks, TOTAL_DISKS], 2.5)
		info_once("item_disk", "DISCO DE RESPALDO: una copia de seguridad (backup) guarda tus datos a salvo; es la mejor defensa contra el ransomware.")
	elif kind == "cd":
		Sound.play("overclock")
		player.activate_overclock(OVERCLOCK_SECONDS)
		message_requested.emit("¡OVERCLOCK! Disparo rápido por %d s" % int(OVERCLOCK_SECONDS), 2.0)
	else:
		return false
	inventory_changed.emit()
	return true


func use_vial(player):
	if vials <= 0 or player.hp >= MAX_HP:
		return
	vials -= 1
	Sound.play("use_vial")
	player.heal(2)
	inventory_changed.emit()


func spawn_pickup(parent, pos, kind, persistent = false):
	var pickup = PICKUP_SCENE.instantiate()
	pickup.kind = kind
	pickup.persistent = persistent
	pickup.position = pos
	parent.call_deferred("add_child", pickup)


func drop_loot(parent, pos, extra_heart_chance = 0.0):
	var r = randf()
	var heart_limit = LOOT_HEART_CHANCE + extra_heart_chance
	var vial_limit = heart_limit + LOOT_VIAL_CHANCE
	var cd_limit = vial_limit + LOOT_CD_CHANCE
	if r < heart_limit:
		spawn_pickup(parent, pos, "heart")
	elif r < vial_limit:
		spawn_pickup(parent, pos, "vial")
	elif r < cd_limit:
		spawn_pickup(parent, pos, "cd")
