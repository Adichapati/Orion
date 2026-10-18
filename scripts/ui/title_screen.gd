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
	v.add_child(UiKit.label("ORION", 80, UiKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
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


## Orion's main stars (the same figure as the in-game sky), drawn line by line as the title
## opens: name, position in units, size.
const ORION := [
	["Betelgeuse", Vector2(-1.0, -1.6), 3], ["Bellatrix", Vector2(1.0, -1.4), 2],
	["Meissa", Vector2(0.05, -2.15), 1], ["Alnitak", Vector2(-0.38, 0.06), 2],
	["Alnilam", Vector2(0.0, -0.1), 2], ["Mintaka", Vector2(0.36, -0.27), 2],
	["Saiph", Vector2(-0.8, 1.6), 2], ["Rigel", Vector2(1.15, 1.35), 3],
]
const LINES := [[3, 4], [4, 5], [0, 3], [1, 5], [0, 2], [2, 1], [3, 6], [5, 7]]
const CENTRE := Vector2(480, 262)
const UNIT := 82.0
const LINE_TIME := 0.32


func _draw() -> void:
	for s in _stars:
		var a: float = 0.4 + 0.6 * s.s * (0.75 + 0.25 * sin(_t * 2.0 + s.ph))
		draw_rect(Rect2(s.p.round(), Vector2(2, 2)), Color(0.85, 0.88, 1.0, a))
	var pts: Array = []
	for st in ORION:
		pts.append((CENTRE + (st[1] as Vector2) * UNIT).round())
	# The figure draws itself: the belt first, then shoulders, head and legs.
	for i in LINES.size():
		var k := clampf((_t - 0.4 - i * LINE_TIME) / LINE_TIME, 0.0, 1.0)
		if k <= 0.0:
			continue
		var a: Vector2 = pts[LINES[i][0]]
		var b: Vector2 = a.lerp(pts[LINES[i][1]], k)
		var n := int(a.distance_to(b) / 6.0)
		for j in n + 1:
			draw_rect(Rect2(a.lerp(b, float(j) / maxf(1, n)).round(), Vector2(2, 2)), Color(0.5, 0.65, 0.85, 0.35))
	for i in ORION.size():
		var appear := clampf((_t - 0.2 - i * 0.18) * 3.0, 0.0, 1.0)
		if appear <= 0.0:
			continue
		var p: Vector2 = pts[i]
		var r: int = ORION[i][2]
		var col := Color(1.0, 0.62, 0.35) if i == 0 else Color(0.85, 0.92, 1.0)
		var tw := 0.85 + 0.15 * sin(_t * 2.3 + i)
		col.a = appear * tw
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2, r * 2)), col)
		draw_rect(Rect2(p - Vector2(r * 3, 1), Vector2(r * 6, 2)), Color(col, col.a * 0.3))
		draw_rect(Rect2(p - Vector2(1, r * 3), Vector2(2, r * 6)), Color(col, col.a * 0.3))
