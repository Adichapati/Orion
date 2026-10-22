class_name EndCard
extends Control
## The Dawn Rank card after the star shrine, in the colours of a black-figure vase: terracotta
## ground, a black glaze band where Orion draws himself in reserved clay, the rank stamped in gold,
## and the night's numbers in a frieze below.

signal to_title

const INK := Color(0.07, 0.04, 0.03)
const CLAY := Color(0.62, 0.31, 0.15)
const CLAY_DARK := Color(0.36, 0.17, 0.09)
const CLAY_LIGHT := Color(0.86, 0.5, 0.26)
const BAND := Rect2(60, 148, 840, 132)

var rank := {}
var _t := 0.0
var _grade: Label
var _score: Label
var _shown_score := 0.0
var _stamped := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	rank = Game.dawn_rank()
	_place(_ink("The first Belt Star", 30), Vector2(0, 82), 960)
	_place(_ink("Orion is sinking. Alcyone waits at the summit.", 16), Vector2(0, 118), 960)

	var cap := UiKit.label("DAWN RANK", 16, CLAY_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	cap.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_place(cap, Vector2(300, 162), 360)
	_grade = UiKit.label(str(rank.grade), 60, Color(0.98, 0.84, 0.46), HORIZONTAL_ALIGNMENT_CENTER)
	_grade.add_theme_color_override("font_shadow_color", Color(0.5, 0.22, 0.06))
	_grade.add_theme_constant_override("shadow_offset_x", 0)
	_grade.add_theme_constant_override("shadow_offset_y", 3)
	_place(_grade, Vector2(300, 190), 360)
	_grade.pivot_offset = Vector2(180, 25)
	_grade.modulate.a = 0.0
	_score = UiKit.label("Score 0", 16, CLAY_LIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	_score.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	_place(_score, Vector2(300, 248), 360)

	# The frieze: each number over its name, four to a row.
	var cells := [
		[rank.time, "time"], [str(rank.spotted), "spotted"], [str(rank.ghosted), "guards ghosted"],
		[str(rank.marks), "marks read"], [str(rank.kos), "knock-outs"], [str(rank.env_kos), "by the world"],
		[str(rank.obols), "obols found"], [str(rank.damage), "hearts lost"],
	]
	for i in cells.size():
		var x := 120.0 + (i % 4) * 180.0
		var y := 300.0 + (i / 4) * 58.0
		var n := _ink(cells[i][0], 16)
		_place(n, Vector2(x, y), 180)
		var name := _ink(cells[i][1], 12)
		name.add_theme_color_override("font_color", Color(INK, 0.7))
		_place(name, Vector2(x, y + 24), 180)
		for c in [n, name]:
			c.modulate.a = 0.0
			create_tween().tween_property(c, "modulate:a", 1.0, 0.3).set_delay(2.0 + i * 0.07)

	var b := UiKit.button("Back to the title")
	b.pressed.connect(func(): to_title.emit())
	add_child(b)
	b.position = Vector2(330, 426)
	b.size = Vector2(300, 0)
	b.custom_minimum_size = Vector2(300, 0)
	# Black glaze for the button too, so nothing on the card is blue.
	for st in ["normal", "hover", "focus", "pressed"]:
		var box := (b.get_theme_stylebox(st) as StyleBoxFlat).duplicate() as StyleBoxFlat
		box.bg_color = INK
		box.border_color = CLAY_LIGHT if st != "normal" else CLAY
		box.shadow_size = 0
		b.add_theme_stylebox_override(st, box)
	b.add_theme_color_override("font_color", CLAY_LIGHT)
	b.add_theme_color_override("font_focus_color", Color(0.98, 0.84, 0.46))
	b.add_theme_color_override("font_hover_color", Color(0.98, 0.84, 0.46))
	b.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func _ink(t: String, size: int) -> Label:
	var x := UiKit.label(t, size, INK, HORIZONTAL_ALIGNMENT_CENTER)
	x.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return x


func _place(c: Control, pos: Vector2, w: float) -> void:
	add_child(c)
	c.position = pos
	c.size = Vector2(w, 0)
	c.custom_minimum_size = Vector2(w, 0)


func _process(delta: float) -> void:
	_t += delta
	# The rank stamps in once Orion is drawn, then the score counts up.
	if _t > 1.5 and not _stamped:
		_stamped = true
		_grade.scale = Vector2(2.2, 2.2)
		var tw := create_tween().set_parallel()
		tw.tween_property(_grade, "modulate:a", 1.0, 0.08)
		tw.tween_property(_grade, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play("parry", null, -4.0, 0.0, 0.8)
	if _stamped and _shown_score < rank.score:
		_shown_score = minf(rank.score, _shown_score + delta * maxf(60.0, rank.score * 1.4))
		_score.text = "Score %d" % roundi(_shown_score)
	queue_redraw()


func _draw() -> void:
	VaseBorder.draw_ground(self)
	VaseBorder.draw_on(self, INK)
	# The black glaze band, with a thin reserved line above and below.
	draw_rect(BAND, INK)
	draw_rect(Rect2(BAND.position.x, BAND.position.y + 5, BAND.size.x, 2), CLAY)
	draw_rect(Rect2(BAND.position.x, BAND.end.y - 7, BAND.size.x, 2), CLAY)
	# Orion on both sides of the rank, drawn line by line like the title.
	_orion(Vector2(180, 218), 25.0, false)
	_orion(Vector2(780, 218), 25.0, true)


func _orion(centre: Vector2, unit: float, mirror: bool) -> void:
	var pts: Array = []
	for st in TitleScreen.ORION:
		var p: Vector2 = st[1]
		if mirror:
			p.x = -p.x
		pts.append((centre + p * unit).round())
	for i in TitleScreen.LINES.size():
		var k := clampf((_t - 0.3 - i * 0.12) / 0.12, 0.0, 1.0)
		if k <= 0.0:
			continue
		var a: Vector2 = pts[TitleScreen.LINES[i][0]]
		var b: Vector2 = a.lerp(pts[TitleScreen.LINES[i][1]], k)
		var n := int(a.distance_to(b) / 5.0)
		for j in n + 1:
			draw_rect(Rect2(a.lerp(b, float(j) / maxf(1, n)).round(), Vector2(2, 2)), CLAY)
	for i in TitleScreen.ORION.size():
		var appear := clampf((_t - 0.2 - i * 0.1) * 4.0, 0.0, 1.0)
		if appear <= 0.0:
			continue
		var r: int = TitleScreen.ORION[i][2] + 1
		var col := CLAY_LIGHT if i != 0 else Color(1.0, 0.7, 0.4)
		col.a = appear
		draw_rect(Rect2(pts[i] - Vector2(r, r), Vector2(r * 2, r * 2)), col)
