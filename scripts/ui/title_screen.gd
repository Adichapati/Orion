class_name TitleScreen
extends Control
## The title: ORION over a night sky with the hunter's belt, and Begin / Quit.

signal begin

var _t := 0.0
var _stars: Array = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 90:
		_stars.append({"p": Vector2(rng.randf() * 960.0, rng.randf() * 540.0), "s": rng.randf_range(0.3, 1.0), "ph": rng.randf() * TAU})
	var c := UiKit.center()
	add_child(c)
	var v := UiKit.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	v.add_child(UiKit.label("ORION", 64, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UiKit.label("Be the eyes of the hunter.", 18, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	v.add_child(gap)
	var start := UiKit.button("Begin the night", 18)
	start.pressed.connect(func(): begin.emit())
	v.add_child(start)
	var quit := UiKit.button("Quit", 16)
	for b in [start, quit]:
		b.custom_minimum_size = Vector2(260, 0)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(func(): get_tree().quit())
	v.add_child(quit)
	var hint := UiKit.label("WASD move · Ctrl run · Shift sneak · Space jump · J / click attack · K / right click parry\nC dodge · F shove · Q torch · G knucklebones · E interact · H pomegranate · Esc pause",
			12, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(hint)
	start.grab_focus()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for s in _stars:
		var a: float = 0.4 + 0.6 * s.s * (0.75 + 0.25 * sin(_t * 2.0 + s.ph))
		draw_rect(Rect2(s.p, Vector2(2, 2)), Color(0.85, 0.88, 1.0, a))
	# Orion's belt, low over the title.
	for i in 3:
		var p := Vector2(400 + i * 80, 110 - i * 14)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Color(0.8, 0.88, 1.0, 0.9))
		draw_rect(Rect2(p - Vector2(5, 0), Vector2(11, 1)), Color(0.8, 0.88, 1.0, 0.35))
