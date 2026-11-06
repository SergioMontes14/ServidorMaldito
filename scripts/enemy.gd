extends CharacterBody2D
# Enemigo generico. El comportamiento se elige con "behavior":
#   "wander"  : deambula y persigue al jugador (bug, bot, gusano)
#   "charger" : avisa y embiste en linea recta (troyano)
#   "ghost"   : flota, atraviesa paredes y persigue (ransomware, rootkit)
#   "shooter" : mantiene distancia y dispara proyectiles (spyware)
#   "spreader": dispara abanicos de proyectiles lentos (adware)
#   "stealth" : casi invisible hasta que el jugador se acerca (keylogger)

@export var behavior: String = "wander"
@export var hp: int = 3
@export var speed: float = 35.0
@export var chase_speed: float = 55.0
@export var detect_range: float = 130.0
@export var contact_damage: int = 1
@export var drops_key: bool = false
@export var extra_heart_chance: float = 0.0
@export var kind_id: String = ""
@export var alert_sound: String = ""
@export var die_sound: String = "die_bug"
@export var split_scene: PackedScene

const WANDER_TIME_MIN = 0.8
const WANDER_TIME_MAX = 2.0
const CHARGE_WINDUP = 0.8
const CHARGE_TIME = 0.5
const CHARGE_SPEED = 170.0
const CHARGE_COOLDOWN = 1.6
const SHOOT_INTERVAL = 2.6
const KEEP_DISTANCE = 110.0
const HOME_RADIUS = 110.0
const BOB_SPEED = 4.0
const BULLET_SCENE = preload("res://scenes/enemy_bullet.tscn")

var direction = Vector2.ZERO
var wander_left = 0.0
var player = null
var home = Vector2.ZERO
var time = 0.0
var state = "move"
var state_left = 0.0
var shoot_left = 1.0
var charge_direction = Vector2.ZERO
var dead = false
var alerted = false
var alert_cooldown = 0.0
var reveal_left = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox


func _ready():
	add_to_group("enemies")
	home = global_position
	pick_new_direction()


func _physics_process(delta):
	if dead:
		return
	time += delta
	find_player()
	update_alert(delta)
	if behavior == "charger":
		update_charger(delta)
	elif behavior == "shooter":
		update_shooter(delta)
	elif behavior == "spreader":
		update_spreader(delta)
	elif behavior == "stealth":
		update_stealth(delta)
	else:
		update_wander(delta)
	move_and_slide()
	update_animation()
	check_contact_damage()


func find_player():
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")


func player_in_range():
	return player != null and global_position.distance_to(player.global_position) < detect_range


func update_alert(delta):
	alert_cooldown -= delta
	if player_in_range():
		if not alerted:
			alerted = true
			Game.introduce(kind_id)
		if alert_cooldown <= 0.0:
			alert_cooldown = 5.0
			Sound.play(alert_sound)
	else:
		alerted = false


func pick_new_direction():
	wander_left = randf_range(WANDER_TIME_MIN, WANDER_TIME_MAX)
	if randf() < 0.25:
		direction = Vector2.ZERO
	else:
		direction = Vector2.from_angle(randf() * TAU)


func update_wander(delta):
	if player_in_range():
		direction = (player.global_position - global_position).normalized()
		velocity = direction * chase_speed
	else:
		wander_left -= delta
		if wander_left <= 0.0 or get_slide_collision_count() > 0:
			pick_new_direction()
		if behavior != "wander" and global_position.distance_to(home) > HOME_RADIUS:
			direction = (home - global_position).normalized()
		velocity = direction * speed


func update_charger(delta):
	state_left -= delta
	if state == "windup":
		velocity = Vector2.ZERO
		if state_left <= 0.0:
			if player != null:
				charge_direction = (player.global_position - global_position).normalized()
			state = "charge"
			state_left = CHARGE_TIME
			sprite.modulate = Color.WHITE
	elif state == "charge":
		velocity = charge_direction * CHARGE_SPEED
		if state_left <= 0.0 or get_slide_collision_count() > 0:
			state = "cooldown"
			state_left = CHARGE_COOLDOWN
	elif state == "cooldown":
		velocity = Vector2.ZERO
		if state_left <= 0.0:
			state = "move"
	else:
		update_wander(delta)
		if player_in_range() and global_position.distance_to(player.global_position) < detect_range * 0.7:
			state = "windup"
			state_left = CHARGE_WINDUP
			sprite.modulate = Color(1.0, 0.6, 0.2)


func update_shooter(delta):
	if player_in_range():
		var to_player = player.global_position - global_position
		var dist = to_player.length()
		if dist < KEEP_DISTANCE - 15.0:
			velocity = -to_player.normalized() * speed
		elif dist > KEEP_DISTANCE + 15.0:
			velocity = to_player.normalized() * speed
		else:
			velocity = Vector2.ZERO
		shoot_left -= delta
		if shoot_left <= 0.0:
			shoot_left = SHOOT_INTERVAL
			fire_bullet(to_player.normalized(), 100.0)
	else:
		update_wander(delta)


func update_spreader(delta):
	if player_in_range():
		var to_player = player.global_position - global_position
		velocity = to_player.normalized().rotated(PI / 2.0) * speed * sin(time * 1.5)
		shoot_left -= delta
		if shoot_left <= 0.0:
			shoot_left = 3.2
			var aim = to_player.angle()
			for a in [-0.4, 0.0, 0.4]:
				fire_bullet(Vector2.from_angle(aim + a), 75.0)
	else:
		update_wander(delta)


func update_stealth(delta):
	reveal_left = max(reveal_left - delta, 0.0)
	var near = player != null and global_position.distance_to(player.global_position) < 85.0
	if near or reveal_left > 0.0:
		sprite.self_modulate.a = 1.0
	else:
		sprite.self_modulate.a = 0.12
	update_wander(delta)


func fire_bullet(dir, bullet_speed):
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = dir
	bullet.speed = bullet_speed
	bullet.position = global_position
	get_tree().current_scene.call_deferred("add_child", bullet)
	Sound.play("enemy_shoot")


func update_animation():
	if sprite.sprite_frames.has_animation("walk_side"):
		if velocity.length() < 1.0:
			sprite.pause()
			return
		if abs(velocity.x) > abs(velocity.y):
			sprite.play("walk_side")
			sprite.flip_h = velocity.x > 0.0
		else:
			sprite.play("walk_front")
			sprite.flip_h = false
	else:
		sprite.position.y = sin(time * BOB_SPEED) * 3.0
		if velocity.x != 0.0:
			sprite.flip_h = velocity.x > 0.0


func check_contact_damage():
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(contact_damage, global_position)


func take_damage(amount):
	if dead:
		return
	hp -= amount
	reveal_left = 1.5
	Sound.play("hit")
	sprite.modulate = Color(1.0, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		die()


func die():
	dead = true
	Sound.play(die_sound)
	var pickups = get_tree().current_scene.get_node("Pickups")
	if drops_key:
		Game.spawn_pickup(pickups, global_position, "key")
		Game.message_requested.emit("¡El virus élite soltó la llave criptográfica!", 3.0)
		Game.drop_loot(pickups, global_position + Vector2(18, 0), extra_heart_chance)
	else:
		Game.drop_loot(pickups, global_position, extra_heart_chance)
	if split_scene != null:
		var parent = get_parent()
		for offset in [Vector2(-12, 0), Vector2(12, 0)]:
			var piece = split_scene.instantiate()
			piece.position = global_position + offset
			parent.call_deferred("add_child", piece)
	queue_free()
