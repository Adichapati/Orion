extends Node
## Registers ORION's input actions at startup, so the key map lives in one readable place.
## Keyboard and mouse is the main scheme; gamepad bindings follow the design doc's Controls table.

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"run": [KEY_CTRL],
	"sneak": [KEY_SHIFT],
	"jump": [KEY_SPACE],
	"dodge": [KEY_C],
	"attack": [KEY_J],
	"parry": [KEY_K],
	"interact": [KEY_E],
	"shove": [KEY_F],
	"thrust": [KEY_Q],
	"toss": [KEY_G],
	"pause": [KEY_ESCAPE],
	"debug_overlay": [KEY_F3],
	"fullscreen": [KEY_F11],
	"ui_confirm": [KEY_ENTER, KEY_KP_ENTER],
}

const MOUSE := {
	"attack": MOUSE_BUTTON_LEFT,
	"parry": MOUSE_BUTTON_RIGHT,
}

const PAD_BUTTONS := {
	"jump": JOY_BUTTON_A,
	"dodge": JOY_BUTTON_B,
	"attack": JOY_BUTTON_X,
	"interact": JOY_BUTTON_Y,
	"parry": JOY_BUTTON_RIGHT_SHOULDER,
	"shove": JOY_BUTTON_LEFT_SHOULDER,
	"run": JOY_BUTTON_LEFT_STICK,
	"pause": JOY_BUTTON_START,
	"ui_confirm": JOY_BUTTON_A,
}

const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"sneak": [JOY_AXIS_TRIGGER_LEFT, 1.0],
	"thrust": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
}


func _enter_tree() -> void:
	for action in KEYS:
		_ensure(action)
		for key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for action in MOUSE:
		_ensure(action)
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE[action]
		InputMap.action_add_event(action, mb)
	for action in PAD_BUTTONS:
		_ensure(action)
		var jb := InputEventJoypadButton.new()
		jb.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, jb)
	for action in PAD_AXES:
		_ensure(action)
		var jm := InputEventJoypadMotion.new()
		jm.axis = PAD_AXES[action][0]
		jm.axis_value = PAD_AXES[action][1]
		InputMap.action_add_event(action, jm)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
