class_name TitleScreen
extends Control
## The title: ORION and Begin / Quit on the left, the hunter drawing himself on the right, and the
## Star Citadel black against the sky with its vigil lamps along the walls.

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
	# The menu sits in the left half; Orion stands in the right.
	var c := CenterContainer.new()
	c.position = Vector2(30, 40)
	c.size = Vector2(470, 400)
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
	hint.position = Vector2(0, 500)
	hint.size = Vector2(960, 0)
	add_child(hint)
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
const CENTRE := Vector2(690, 214)
const UNIT := 72.0
const SKY_INK := Color(0.012, 0.012, 0.035)
## The citadel's walls and towers: x, width, height above the ground line at y 470.
const WALLS := [[0, 140, 22], [120, 34, 58], [150, 190, 30], [330, 40, 70], [365, 210, 26], [560, 30, 52], [585, 375, 34]]
const LINE_TIME := 0.32


func _draw() -> void:
	# A faint band of the Milky Way, then the stars.
	for i in 60:
		var x := fmod(i * 97.0, 960.0)
		var y := 60.0 + x * 0.35 + fmod(i * 53.0, 70.0) - 35.0
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, 2)), Color(0.55, 0.6, 0.85, 0.12 + 0.06 * sin(_t + i)))
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
	_skyline()


## The Star Citadel against the sky: walls, towers, cypresses and the temple on the summit, with
## the vigil lamps flickering along the parapet.
func _skyline() -> void:
	draw_rect(Rect2(0, 470, 960, 70), SKY_INK)
	for w in WALLS:
		draw_rect(Rect2(w[0], 470 - w[2], w[1], w[2]), SKY_INK)
		if w[1] < 50:  # towers get crenellations
			for k in range(0, w[1], 8):
				draw_rect(Rect2(w[0] + k, 470 - w[2] - 4, 4, 4), SKY_INK)
	for cx in [70, 260, 520, 640]:
		for k in 14:
			var hw := int(5.0 * sin(PI * (k + 1) / 15.0)) + 1
			draw_rect(Rect2(cx - hw, 446 - k * 4, hw * 2, 4), SKY_INK)
	var tx := 700.0
	draw_rect(Rect2(tx, 424, 200, 12), SKY_INK)
	draw_rect(Rect2(tx + 8, 416, 184, 8), SKY_INK)
	for k in 8:
		draw_rect(Rect2(tx + 14 + k * 23, 372, 10, 44), SKY_INK)
	draw_rect(Rect2(tx + 6, 362, 188, 10), SKY_INK)
	for k in 18:
		var hw := 94.0 * (1.0 - k / 18.0)
		draw_rect(Rect2(tx + 100 - hw, 360 - k * 2, hw * 2, 2), SKY_INK)
	for i in 14:
		var x := 40.0 + i * 66.0 + fmod(i * 37.0, 20.0)
		var top := 470.0
		for w in WALLS:
			if x >= w[0] and x < w[0] + w[1]:
				top = 470.0 - w[2]
		var f := 0.7 + 0.3 * sin(_t * (5.0 + i) + i * 2.1)
		draw_rect(Rect2(Vector2(x, top - 4).round(), Vector2(2, 2)), Color(1.0, 0.72, 0.35, f))
		draw_rect(Rect2(Vector2(x - 2, top - 6).round(), Vector2(6, 6)), Color(1.0, 0.6, 0.3, 0.12 * f))
