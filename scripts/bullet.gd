extends Area2D

const SPEED = 260.0
const LIFETIME = 1.1

var direction = Vector2.DOWN
var damage = 1
var time_alive = 0.0

@onready var sprite = $Sprite2D


func _ready():
	body_entered.connect(_on_body_entered)
	if damage > 1:
		sprite.scale = Vector2(1.6, 1.6)
		sprite.modulate = Color(1.0, 0.85, 0.3)


func _physics_process(delta):
	position += direction * SPEED * delta
	time_alive += delta
	if time_alive >= LIFETIME:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
