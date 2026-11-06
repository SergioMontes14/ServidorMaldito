extends Node
# Registra los controles del juego por codigo (autoload).


func _ready():
	register_keys("move_left", [KEY_A, KEY_LEFT])
	register_keys("move_right", [KEY_D, KEY_RIGHT])
	register_keys("move_up", [KEY_W, KEY_UP])
	register_keys("move_down", [KEY_S, KEY_DOWN])
	register_keys("shoot", [KEY_J, KEY_SPACE])
	register_mouse("shoot", MOUSE_BUTTON_LEFT)
	register_keys("use_item", [KEY_E, KEY_Q])
	register_keys("restart", [KEY_R])


func register_keys(action_name, keys):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var ev = InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action_name, ev)


func register_mouse(action_name, button):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev = InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action_name, ev)
