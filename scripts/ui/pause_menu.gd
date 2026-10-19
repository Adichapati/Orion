class_name PauseMenu
extends Control
## Esc menu: resume, the controls list, brightness and volume sliders, a screen-shake toggle,
## restart the room, back to the title.

signal resumed
signal restart_room
signal to_title

const CONTROLS := "Move  WASD / arrows      Run  hold Ctrl      Sneak  hold Shift      Jump  Space\nDodge  C      Attack  J / left click      Parry  K / right click      Shove  F\nTorch thrust  Q      Knucklebones  G (toward the mouse)      Pomegranate  H\nInteract  E (hold for chests)      Fullscreen  F11      Debug overlay  F3"

var _controls: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	var bl := UiKit.label("Brightness", 15)
	bl.custom_minimum_size = Vector2(70, 0)
	row.add_child(bl)
	var slider := HSlider.new()
	slider.min_value = 0.6
	slider.max_value = 1.8
	slider.step = 0.05
	slider.value = Game.brightness
	slider.custom_minimum_size = Vector2(200, 20)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(func(x: float): Game.set_brightness(x))
	row.add_child(slider)
	# Volume for the whole mix (master bus), for a loud hall or a quiet projector.
	var vrow := UiKit.hbox(10)
	v.add_child(vrow)
	var vl := UiKit.label("Volume", 15)
	vl.custom_minimum_size = Vector2(70, 0)
	vrow.add_child(vl)
	var vol := HSlider.new()
	vol.min_value = 0.0
	vol.max_value = 1.0
	vol.step = 0.05
	vol.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	vol.custom_minimum_size = Vector2(200, 20)
	vol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vol.value_changed.connect(func(x: float):
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(x, 0.0001)))
		AudioServer.set_bus_mute(0, x <= 0.0))
	vrow.add_child(vol)
	var shake := CheckButton.new()
	shake.text = "Screen shake"
	shake.button_pressed = Game.screen_shake
	shake.add_theme_font_size_override("font_size", UiKit.px(15))
	shake.toggled.connect(func(on: bool): Game.screen_shake = on)
	v.add_child(shake)
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
