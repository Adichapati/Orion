class_name PauseMenu
extends Control
## Esc menu: resume, the controls list, a brightness slider, restart the room, back to the title.

signal resumed
signal restart_room
signal to_title

const CONTROLS := "Move  WASD / arrows      Run  hold Ctrl      Sneak  hold Shift      Jump  Space\nDodge  C      Attack  J / left click      Parry  K / right click      Shove  F\nTorch thrust  Q      Knucklebones  G (toward the mouse)      Pomegranate  H\nInteract  E (hold for chests)      Fullscreen  F11      Debug overlay  F3"

var _controls: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.backdrop(0.6))
	var c := UiKit.center()
	add_child(c)
	var p := UiKit.panel()
	c.add_child(p)
	var v := UiKit.vbox(8)
	p.add_child(v)
	v.add_child(UiKit.label("Paused", 24, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var resume := UiKit.button("Resume")
	resume.pressed.connect(func(): resumed.emit())
	v.add_child(resume)
	var ctl := UiKit.button("Controls")
	ctl.pressed.connect(func(): _controls.visible = not _controls.visible)
	v.add_child(ctl)
	var row := UiKit.hbox(10)
	v.add_child(row)
	row.add_child(UiKit.label("Brightness", 15))
	var slider := HSlider.new()
	slider.min_value = 0.6
	slider.max_value = 1.8
	slider.step = 0.05
	slider.value = Game.brightness
	slider.custom_minimum_size = Vector2(200, 20)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(x: float): Game.set_brightness(x))
	row.add_child(slider)
	var restart := UiKit.button("Restart room")
	restart.pressed.connect(func(): restart_room.emit())
	v.add_child(restart)
	var title := UiKit.button("Quit to title")
	title.pressed.connect(func(): to_title.emit())
	v.add_child(title)
	_controls = UiKit.label(CONTROLS, 12, UiKit.DIM)
	_controls.visible = false
	v.add_child(_controls)
	resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resumed.emit()
