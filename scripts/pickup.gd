extends Area2D
# Objeto recogible: heart, vial, key, disk, cd

const LIFETIME = 15.0

var kind = "heart"
var persistent = false
var time = 0.0

@onready var sprite = $Sprite2D


func _ready():
	sprite.texture = load("res://assets/items/%s.png" % kind)
	body_entered.connect(_on_body_entered)


func _process(delta):
	time += delta
	sprite.position.y = sin(time * 4.0) * 2.0
	if not persistent and (kind == "heart" or kind == "vial" or kind == "cd"):
		if time >= LIFETIME:
			queue_free()
		elif time >= LIFETIME - 3.0:
			sprite.visible = int(time * 8.0) % 2 == 0


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	if Game.collect(kind, body):
		queue_free()
