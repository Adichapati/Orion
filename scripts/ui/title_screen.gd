class_name TitleScreen
extends Control
## The title: ORION and Begin / Quit on the left, the hunter drawing himself in the upper right,
## and floating islands over a moonlit sea of clouds: one near island with a ruined temple, a lit
## brazier and a waterfall, and two far ones in the haze. The art (tools/gen_title.py) is drawn at
## the game's 480x270 pixel size and shown at 2x, so its pixels match the game's.

signal begin

var _t := 0.0
var _stars: Array = []
## Islands that bob: [node, rest position, amplitude in game pixels, phase, speed].
var _bobbers: Array = []
## Cloud bands that drift: [node, speed in game pixels a second].
var _clouds: Array = []
var _fx: Control
var _fx_back: Control

## Where each piece sits, in game pixels (480x270).
const MAIN_AT := Vector2(190, 85)
const BACK_AT := [Vector2(14, 10), Vector2(214, 22)]
const MOON_AT := Vector2(160, 14)
## Spots on the island art, matching tools/gen_title.py.
const BRAZIER := Vector2(178, 74)
const FALLS_X := 150
const FALLS_W := 6
const FALLS_TOP := 101
const BACK_BRAZIER := Vector2(56, 23)
## Cloud bands: texture, top y, drift speed. The first sits behind the near island.
const CLOUDS := [["title_cloud_0", 194, 2.0], ["title_cloud_1", 224, 4.0], ["title_cloud_2", 236, 7.0]]


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
	_build_islands()
	# The menu sits in the left half, over a soft dark panel; Orion stands in the upper right.
	var shade := Control.new()
	shade.name = "MenuShade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.draw.connect(_draw_shade.bind(shade))
	add_child(shade)
	var c := CenterContainer.new()
	c.name = "Menu"
	c.position = Vector2(10, 50)
	c.size = Vector2(400, 400)
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
	for b in _bobbers:
		var n: Control = b[0]
		n.position = b[1] + Vector2(0, roundf(sin(_t * b[4] + b[3]) * b[2]) * 2.0)
	for cl in _clouds:
		var n: Control = cl[0]
		n.position.x = -roundf(fmod(_t * cl[1], 480.0)) * 2.0
	_fx.queue_redraw()
	_fx_back.queue_redraw()
	queue_redraw()


## A 2x, nearest-filtered sprite of one of the title's textures, placed in game pixels.
func _sprite(tex_name: String, at: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = Art.tex(tex_name)
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.stretch_mode = TextureRect.STRETCH_KEEP
	r.scale = Vector2(2, 2)
	r.position = at * 2.0
	if r.texture:
		r.size = r.texture.get_size()
	add_child(r)
	return r


func _build_islands() -> void:
	for i in 2:
		var b := _sprite("title_island_back_%d" % i, BACK_AT[i])
		b.name = "IslandBack%d" % i
		_bobbers.append([b, b.position, 1.0, 1.7 + i * 2.4, 0.55 + i * 0.12])
		if i == 1:
			_fx_back = Control.new()
			_fx_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fx_back.draw.connect(_draw_back_fx)
			b.add_child(_fx_back)
	for i in CLOUDS.size():
		var cl := _sprite(CLOUDS[i][0], Vector2(0, CLOUDS[i][1]))
		cl.name = "Cloud%d" % i
		cl.stretch_mode = TextureRect.STRETCH_TILE
		cl.size = Vector2(960, cl.size.y)
		_clouds.append([cl, CLOUDS[i][2]])
		if i == 0:
			var m := _sprite("title_island_main", MAIN_AT)
			m.name = "IslandMain"
			_bobbers.append([m, m.position, 2.0, 0.0, 0.7])
			_fx = Control.new()
			_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_fx.draw.connect(_draw_main_fx)
			m.add_child(_fx)


## The near island's brazier flame and glow, the waterfall's falling streaks and its mist, in
## the island's own pixels.
func _draw_main_fx() -> void:
	var f := 0.75 + 0.25 * sin(_t * 9.0) * sin(_t * 5.3 + 1.0)
	var b := BRAZIER
	for k in 3:
		_fx.draw_circle(b + Vector2(0, -10), (9.0 + k * 7.0) * f, Color(1.0, 0.6, 0.25, 0.08))
	var flick := int(_t * 10.0)
	var h: int = [10, 12, 9, 13, 11, 12][flick % 6]
	for i in h:
		var w := maxi(0, int((h - i) * 0.45))
		var sway := int(round(sin(_t * 7.0 + i * 0.9) * (i * 0.25)))
		var col := Color("ffc857") if i < h * 2 / 3 else Color("e0782c")
		if i < 3 and w > 0:
			col = Color("fff1c1")
		if i == 0:
			col = Color("e0782c")
		_fx.draw_rect(Rect2(b.x - w + sway, b.y - 9 - i, w * 2 + 1, 1), col)
	if flick % 3 == 0:
		_fx.draw_rect(Rect2(b.x + 2 - (flick % 5), b.y - 11 - h, 1, 1), Color("ffc857"))
	# Embers rising off the flame and fading.
	for i in 4:
		var life := fmod(_t * 0.6 + i * 0.25, 1.0)
		var e := Vector2(b.x + sin(_t * 2.0 + i * 2.7) * 3.0 + (i - 1.5) * 2.0, b.y - 14 - life * 26.0)
		_fx.draw_rect(Rect2(e.round(), Vector2(1, 1)), Color("ffc857", 1.0 - life))
	# Falling streaks down the waterfall.
	for i in 9:
		var x := FALLS_X + (i * 5) % FALLS_W
		var y := FALLS_TOP + fmod(_t * 38.0 + i * 13.7, 110.0)
		_fx.draw_rect(Rect2(x, int(y), 1, 3 + i % 3), Color("cfe3ff", 0.85))
	# Mist where the falls meet the clouds.
	var mist_y: float = CLOUDS[1][1] - MAIN_AT.y + 6.0
	for i in 7:
		var p := Vector2(FALLS_X + 3 + sin(_t * 0.8 + i * 1.9) * (6 + i), mist_y - 2 + fmod(i * 3.0, 5.0))
		_fx.draw_rect(Rect2(p.round(), Vector2(4 + i % 3 * 2, 2)), Color("cfe3ff", 0.4 + 0.15 * sin(_t * 2.0 + i)))


func _draw_back_fx() -> void:
	var f := 0.6 + 0.4 * absf(sin(_t * 6.0 + sin(_t * 2.3)))
	_fx_back.draw_circle(BACK_BRAZIER + Vector2(0, -3), 6.0 * f, Color(1.0, 0.6, 0.25, 0.08))
	_fx_back.draw_rect(Rect2(BACK_BRAZIER + Vector2(-1, -5), Vector2(2, 2)), Color("e0782c", f))
	_fx_back.draw_rect(Rect2(BACK_BRAZIER + Vector2(0, -6 - int(f * 1.5)), Vector2(1, 1)), Color("ffc857", f))


## A soft dark panel behind the menu: dense at the left edge, dithering out to the right.
func _draw_shade(n: Control) -> void:
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var ink := Color(0.03, 0.03, 0.08, 0.6)
	for gx in 120:
		var k := 1.0 - gx / 120.0
		for gy in 135:
			var e: float = 1.0 - absf(gy - 64.0) / 90.0
			if bayer[(gy % 4) * 4 + gx % 4] < k * e * 22.0:
				n.draw_rect(Rect2(gx * 4, gy * 4, 4, 4), ink)
	# And a dark strip along the bottom so the controls line reads over the clouds.
	for gy in range(120, 135):
		var d := (gy - 120) / 6.0
		for gx in 240:
			if bayer[(gy % 4) * 4 + gx % 4] < d * 16.0:
				n.draw_rect(Rect2(gx * 4, gy * 4, 4, 4), ink)


## Orion's main stars (the same figure as the in-game sky), drawn line by line as the title
## opens: name, position in units, size.
const ORION := [
	["Betelgeuse", Vector2(-1.0, -1.6), 3], ["Bellatrix", Vector2(1.0, -1.4), 2],
	["Meissa", Vector2(0.05, -2.15), 1], ["Alnitak", Vector2(-0.38, 0.06), 2],
	["Alnilam", Vector2(0.0, -0.1), 2], ["Mintaka", Vector2(0.36, -0.27), 2],
	["Saiph", Vector2(-0.8, 1.6), 2], ["Rigel", Vector2(1.15, 1.35), 3],
]
const LINES := [[3, 4], [4, 5], [0, 3], [1, 5], [0, 2], [2, 1], [3, 6], [5, 7]]
## Up and right of the near island's temple and rim.
const CENTRE := Vector2(790, 140)
const UNIT := 52.0
const LINE_TIME := 0.32


func _draw() -> void:
	# A faint band of the Milky Way, then the stars and the moon.
	for i in 60:
		var x := fmod(i * 97.0, 960.0)
		var y := 60.0 + x * 0.35 + fmod(i * 53.0, 70.0) - 35.0
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, 2)), Color(0.55, 0.6, 0.85, 0.12 + 0.06 * sin(_t + i)))
	for s in _stars:
		var a: float = 0.4 + 0.6 * s.s * (0.75 + 0.25 * sin(_t * 2.0 + s.ph))
		draw_rect(Rect2(s.p.round(), Vector2(2, 2)), Color(0.85, 0.88, 1.0, a))
	var moon := Art.tex("title_moon")
	if moon:
		var mc := MOON_AT * 2.0 + moon.get_size()
		for k in 3:
			draw_circle(mc, 28.0 + k * 12.0, Color(0.5, 0.65, 0.9, 0.025))
		draw_texture_rect(moon, Rect2(MOON_AT * 2.0, moon.get_size() * 2.0), false)
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
