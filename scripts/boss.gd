extends CharacterBody2D
# Jefe final: El Glitch Final. Tiene 3 fases segun su vida restante.

signal boss_hp_changed(hp, max_hp)
signal boss_defeated

const MAX_HP = 18
const SPEED = 22.0
const DASH_SPEED = 190.0
const DASH_INTERVAL = 8.0
const CONTACT_DAMAGE = 1
const ACTIVATE_RANGE = 300.0
const BULLET_SCENE = preload("res://scenes/enemy_bullet.tscn")
const MINION_SCENE = preload("res://scenes/enemy_bot.tscn")

var hp = MAX_HP
var player = null
var active = false
var dead = false
var time = 0.0
var state = "chase"
var state_left = 0.0
var dash_left = DASH_INTERVAL
var dash_direction = Vector2.ZERO
var attack_left = 3.5
var minion_left = 10.0

@onready var sprite = $AnimatedSprite2D
@onready var hitbox = $Hitbox


func _ready():
	add_to_group("enemies")
	add_to_group("boss")


func get_phase():
	if hp > MAX_HP * 0.66:
		return 1
	elif hp > MAX_HP * 0.33:
		return 2
	return 3


func _physics_process(delta):
	if dead:
		return
	time += delta
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	sprite.position.y = sin(time * 3.0) * 4.0
	if not active:
		if global_position.distance_to(player.global_position) < ACTIVATE_RANGE:
			active = true
			Sound.play("boss_roar")
			Game.introduce("boss")
			boss_hp_changed.emit(hp, MAX_HP)
		return
	var phase = get_phase()
	update_movement(delta, phase)
	update_attacks(delta, phase)
	move_and_slide()
	check_contact_damage()


func update_movement(delta, phase):
	state_left -= delta
	if state == "windup":
		velocity = Vector2.ZERO
		sprite.modulate = Color(1.0, 0.5, 0.9)
		if state_left <= 0.0:
			dash_direction = (player.global_position - global_position).normalized()
			state = "dash"
			state_left = 0.6
			sprite.modulate = Color.WHITE
	elif state == "dash":
		velocity = dash_direction * DASH_SPEED
		if state_left <= 0.0 or get_slide_collision_count() > 0:
			state = "recover"
			state_left = 0.8
	elif state == "recover":
		velocity = Vector2.ZERO
		if state_left <= 0.0:
			state = "chase"
			dash_left = DASH_INTERVAL
	else:
		var move_speed = SPEED
		if phase == 3:
			move_speed = SPEED * 1.3
		velocity = (player.global_position - global_position).normalized() * move_speed
		dash_left -= delta
		if phase >= 2 and dash_left <= 0.0:
			state = "windup"
			state_left = 1.0
			Sound.play("boss_dash")


func update_attacks(delta, phase):
	if state != "chase":
		return
	attack_left -= delta
	if attack_left <= 0.0:
		attack_left = 4.6 - 0.5 * phase
		Sound.play("boss_shoot")
		shoot_ring(5 + phase)
		if phase == 3:
			shoot_aimed()
	if phase == 3:
		minion_left -= delta
		if minion_left <= 0.0:
			minion_left = 14.0
			spawn_minions()


func fire_bullet(dir):
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = dir
	bullet.speed = 80.0
	bullet.position = global_position
	get_tree().current_scene.call_deferred("add_child", bullet)


func shoot_ring(count):
	var offset = time
	for i in range(count):
		fire_bullet(Vector2.from_angle(offset + TAU * i / count))


func shoot_aimed():
	var aim = (player.global_position - global_position).angle()
	for a in [0.0]:
		fire_bullet(Vector2.from_angle(aim + a))


func spawn_minions():
	var enemies = get_tree().current_scene.get_node("Enemies")
	for offset in [Vector2(0, 60)]:
		var minion = MINION_SCENE.instantiate()
		minion.position = global_position + offset
		enemies.call_deferred("add_child", minion)


func check_contact_damage():
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(CONTACT_DAMAGE, global_position)


func take_damage(amount):
	if dead:
		return
	hp -= amount
	Sound.play("hit")
	boss_hp_changed.emit(max(hp, 0), MAX_HP)
	if state != "windup":
		sprite.modulate = Color(1.0, 0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0:
		die()


func die():
	dead = true
	Sound.play("boss_die")
	boss_defeated.emit()
	hitbox.set_deferred("monitoring", false)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 1.2)
	tween.tween_callback(queue_free)
