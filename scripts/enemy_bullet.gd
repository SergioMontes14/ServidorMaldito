extends Area2D
# Proyectil enemigo: daña al jugador y desaparece al chocar con paredes.

const LIFETIME = 4.0

var direction = Vector2.DOWN
var speed = 120.0
var damage = 1
var time_alive = 0.0


func _ready():
	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	position += direction * speed * delta
	time_alive += delta
	if time_alive >= LIFETIME:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage, global_position)
	queue_free()
