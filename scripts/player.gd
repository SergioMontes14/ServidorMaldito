extends CharacterBody2D

signal hp_changed(new_hp)

const SPEED = 95.0
const SHOOT_ANIM_TIME = 0.2
const KNOCKBACK_SPEED = 160.0
const KNOCKBACK_TIME = 0.15
const SHOOT_COOLDOWN = 0.3
const OVERCLOCK_COOLDOWN = 0.15
const BULLET_SCENE = preload("res://scenes/bullet.tscn")

var hp = 5
var facing = "down"
var facing_vector = Vector2.DOWN
var invulnerable = false
var can_shoot = true
var dead = false
var shoot_anim_left = 0.0
var knockback_left = 0.0
var knockback_velocity = Vector2.ZERO
var walk_time = 0.0
var overclock_left = 0.0
var step_left = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Muzzle
@onready var shoot_timer = $ShootTimer
@onready var invul_timer = $InvulnerabilityTimer


func _ready():
	hp = Game.hp
	add_to_group("player")
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	invul_timer.timeout.connect(_on_invul_timer_timeout)


func _physics_process(delta):
	if dead:
		return

	overclock_left = max(overclock_left - delta, 0.0)
	var current_speed = SPEED
	if overclock_left > 0.0:
		current_speed = SPEED * 1.25

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if knockback_left > 0.0:
		knockback_left -= delta
		velocity = knockback_velocity
	else:
		velocity = input_vector * current_speed
		if input_vector != Vector2.ZERO:
			update_facing(input_vector)

	if input_vector != Vector2.ZERO and knockback_left <= 0.0:
		step_left -= delta
		if step_left <= 0.0:
			step_left = 0.3
			Sound.play("step")

	if Input.is_action_just_pressed("shoot"):
		shoot()
	if Input.is_action_just_pressed("use_item"):
		Game.use_vial(self)

	shoot_anim_left = max(shoot_anim_left - delta, 0.0)
	update_animation(input_vector, delta)
	move_and_slide()


func update_facing(v):
	if abs(v.x) > abs(v.y):
		facing = "side"
		facing_vector = Vector2(sign(v.x), 0)
	elif v.y > 0:
		facing = "down"
		facing_vector = Vector2.DOWN
	else:
		facing = "up"
		facing_vector = Vector2.UP


func update_animation(input_vector, delta):
	var prefix = "idle"
	if shoot_anim_left > 0.0:
		prefix = "shoot"
	elif input_vector != Vector2.ZERO:
		prefix = "walk"

	sprite.play(prefix + "_" + facing)
	sprite.flip_h = facing == "side" and facing_vector.x < 0

	if prefix == "walk":
		walk_time += delta
		sprite.position.y = sin(walk_time * 14.0) * 1.5
	else:
		sprite.position.y = 0.0

	update_muzzle()


func update_muzzle():
	if facing == "side":
		muzzle.position = Vector2(14.0 * facing_vector.x, 0.0)
	elif facing == "up":
		muzzle.position = Vector2(7.0, -12.0)
	else:
		muzzle.position = Vector2(-6.0, 10.0)


func shoot():
	if not can_shoot:
		return
	can_shoot = false
	if overclock_left > 0.0:
		shoot_timer.start(OVERCLOCK_COOLDOWN)
	else:
		shoot_timer.start(SHOOT_COOLDOWN)
	shoot_anim_left = SHOOT_ANIM_TIME
	Sound.play("shoot")
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = facing_vector
	bullet.damage = Game.player_damage()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position


func _on_shoot_timer_timeout():
	can_shoot = true


func heal(amount):
	hp = min(hp + amount, Game.MAX_HP)
	Game.hp = hp
	hp_changed.emit(hp)
	Sound.play("heal")


func activate_overclock(seconds):
	overclock_left = seconds


func take_damage(amount, from_position = Vector2.ZERO):
	if invulnerable or dead:
		return
	hp -= amount
	Game.hp = hp
	hp_changed.emit(hp)
	invulnerable = true
	invul_timer.start()
	var push = global_position - from_position
	if push == Vector2.ZERO:
		push = -facing_vector
	knockback_velocity = push.normalized() * KNOCKBACK_SPEED
	knockback_left = KNOCKBACK_TIME
	sprite.modulate = Color(1, 0.3, 0.3)
	Sound.play("hurt")
	if hp <= 0:
		die()


func _on_invul_timer_timeout():
	invulnerable = false
	sprite.modulate = Color.WHITE


func die():
	if dead:
		return
	dead = true
	Sound.play("player_die")
	Game.call_deferred("restart_level")
