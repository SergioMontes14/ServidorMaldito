extends CanvasLayer

var message_left = 0.0
var info_left = 0.0

@onready var hearts = $Hearts.get_children()
@onready var message = $Message
@onready var key_slot = $Items/KeySlot
@onready var vial_count = $Items/VialCount
@onready var disk_count = $Items/DiskCount
@onready var boss_bar = $BossBar
@onready var info_bg = $InfoBg
@onready var info = $Info


func _process(delta):
	if message_left > 0.0:
		message_left -= delta
		if message_left <= 0.0:
			message.visible = false
	if info_left > 0.0:
		info_left -= delta
		if info_left <= 0.0:
			info.visible = false
			info_bg.visible = false


func update_hearts(hp):
	for i in range(hearts.size()):
		if i < hp:
			hearts[i].modulate = Color.WHITE
		else:
			hearts[i].modulate = Color(0.2, 0.2, 0.2)


func update_items():
	if Game.has_key:
		key_slot.modulate = Color.WHITE
	else:
		key_slot.modulate = Color(0.25, 0.25, 0.25)
	vial_count.text = "x%d" % Game.vials
	if Game.disks >= Game.TOTAL_DISKS:
		disk_count.text = "ANTIVIRUS"
	else:
		disk_count.text = "%d/%d" % [Game.disks, Game.TOTAL_DISKS]


func show_message(text, seconds):
	message.text = text
	message.visible = true
	message_left = seconds


func update_boss(hp, max_hp):
	boss_bar.visible = true
	boss_bar.max_value = max_hp
	boss_bar.value = hp


func hide_boss():
	boss_bar.visible = false


func show_info(text, seconds):
	info.text = text
	info.visible = true
	info_bg.visible = true
	info_left = seconds
	Sound.play("message")
