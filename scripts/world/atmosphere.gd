class_name Atmosphere
extends RefCounted
## The mood layer of a room: the night sky behind it (Orion is the clock), a dithered vignette,
## torch and lamp embers, dust motes in the moonlight and glinting water. Everything is drawn in
## whole pixels from the ORION palette.

const NIGHT_0 := Color("0d0b1a")
const NIGHT_1 := Color("1b1834")
const NIGHT_2 := Color("2e3a5c")
const MOON_0 := Color("7fa6d8")
const MOON_1 := Color("cfe3ff")
const FIRE_1 := Color("e0782c")
const FIRE_2 := Color("ffc857")
const FIRE_3 := Color("fff1c1")
const POOL := Color("5fb3b0")


static var _dot: Texture2D
static var _water_mat: ShaderMaterial
static var _vignette_tex: Texture2D
static var _danger_tex: Texture2D


static func dot() -> Texture2D:
	if _dot == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.set_pixel(0, 0, Color.WHITE)
		_dot = ImageTexture.create_from_image(img)
	return _dot


static func unshaded() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return m


## Adds the sky (behind) and the vignette (in front) to a room.
static func dress(room: Node2D, room_id: String) -> void:
	var back := CanvasLayer.new()
	back.layer = -10
	back.name = "Sky"
	room.add_child(back)
	var sky := NightSky.new()
	back.add_child(sky)
	# Far islands with ruins and lit braziers, and low cloud banks, drifting at their own depths.
	var distance := CanvasLayer.new()
	distance.layer = -9
	distance.name = "Distance"
	room.add_child(distance)
	var far := FarSky.new()
	far.seed_from(room_id)
	distance.add_child(far)
	var front := CanvasLayer.new()
	front.layer = 3
	front.name = "Vignette"
	room.add_child(front)
	var v := TextureRect.new()
	v.texture = vignette_texture()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size = Vector2(480, 270)
	front.add_child(v)
	# The same dithered edge in white, tinted red and faded in by the room as guards grow aware.
	var danger := TextureRect.new()
	danger.texture = vignette_texture(true)
	danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger.size = Vector2(480, 270)
	danger.modulate = Color(0.85, 0.16, 0.12, 0.0)
	front.add_child(danger)
	room.set("danger_vignette", danger)


## A 480x270 vignette with ordered-dither alpha in three steps, so it stays pixel art.
static func vignette_texture(white := false) -> Texture2D:
	if white and _danger_tex:
		return _danger_tex
	if not white and _vignette_tex:
		return _vignette_tex
	var w := 480
	var h := 270
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	for y in h:
		for x in w:
			var d := Vector2((x - w / 2.0) / (w / 2.0), (y - h / 2.0) / (h / 2.0)).length()
			var k := clampf((d - 0.62) / 0.6, 0.0, 1.0)
			var threshold: float = (bayer[(y % 4) * 4 + (x % 4)] + 0.5) / 16.0
			var a := 0.0
			if k > threshold:
				a = 0.22 + 0.3 * k
			img.set_pixel(x, y, Color(Color.WHITE if white else NIGHT_0, a))
	if white:
		_danger_tex = ImageTexture.create_from_image(img)
		return _danger_tex
	_vignette_tex = ImageTexture.create_from_image(img)
	return _vignette_tex


## Rising sparks for a torch, lamp or brazier.
static func embers(amount := 5, spread := 2.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = dot()
	p.material = unshaded()
	p.amount = amount
	p.lifetime = 0.9
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(spread, 1.0)
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(0, -18.0)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 14.0
	p.damping_min = 4.0
	p.damping_max = 8.0
	var g := Gradient.new()
	g.set_color(0, FIRE_3)
	g.set_color(1, Color(FIRE_1, 0.0))
	g.add_point(0.35, FIRE_2)
	p.color_ramp = g
	p.z_index = 30
	return p


## Slow motes drifting through a pool of moonlight.
static func motes(extent: Vector2, amount := 8) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = dot()
	p.material = unshaded()
	p.amount = amount
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extent
	p.direction = Vector2(0.3, -1)
	p.spread = 40.0
	p.gravity = Vector2(0, -1.5)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	var g := Gradient.new()
	g.set_color(0, Color(MOON_1, 0.0))
	g.set_color(1, Color(MOON_1, 0.0))
	g.add_point(0.3, Color(MOON_1, 0.55))
	g.add_point(0.7, Color(MOON_0, 0.4))
	p.color_ramp = g
	p.z_index = 25
	return p


## A thin curl of smoke from a lamp that has just been put out.
static func smoke() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = dot()
	# Unshaded but faint, so it reads in the dark the way smoke catches what little light there is.
	p.material = unshaded()
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.amount = 8
	p.lifetime = 2.6
	p.preprocess = 2.6
	p.local_coords = false
	p.direction = Vector2(0, -1)
	p.spread = 8.0
	p.gravity = Vector2(0.6, -4.0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 5.0
	p.tangential_accel_min = -2.0
	p.tangential_accel_max = 2.0
	var g := Gradient.new()
	g.set_color(0, Color(0.75, 0.74, 0.8, 0.0))
	g.set_color(1, Color(0.6, 0.6, 0.68, 0.0))
	g.add_point(0.15, Color(0.7, 0.7, 0.78, 0.4))
	g.add_point(0.6, Color(0.55, 0.55, 0.65, 0.18))
	p.color_ramp = g
	p.z_index = 25
	return p


## A shared material that runs slow glints across water tiles (in screen pixels, so it lines up
## across neighbouring tiles).
static func water_material() -> ShaderMaterial:
	if _water_mat:
		return _water_mat
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec4 glint : source_color = vec4(0.373, 0.702, 0.690, 1.0);
uniform vec4 crest : source_color = vec4(0.812, 0.890, 1.0, 1.0);
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 p = floor(FRAGCOORD.xy);
	float w = sin(p.x * 0.31 + p.y * 0.83 + TIME * 1.5) * sin(p.x * 0.09 - p.y * 0.47 - TIME * 0.9);
	if (c.a > 0.5 && w > 0.78) {
		c.rgb = mix(c.rgb, glint.rgb, 0.7);
	}
	if (c.a > 0.5 && w > 0.95) {
		c.rgb = crest.rgb;
	}
	COLOR = c;
}"""
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = sh
	return _water_mat


## Where Orion hangs: high in the east at the start of the run, low in the west at the end.
static func orion_progress() -> float:
	var rooms := maxf(1.0, float(Game.rooms.size()))
	var into := clampf(Game.elapsed_seconds() / 900.0, 0.0, 1.0) if not Game.stats.is_empty() else 0.0
	return clampf((Game.room_index + 0.5) / rooms * 0.8 + into * 0.2, 0.0, 1.0)


class NightSky extends Node2D:
	var stars := true
	var _field: Array = []
	var _t := 0.0
	static var _bands: Texture2D

	# Orion's main stars (x right, y down, in "units"; north is up): name, position, size, colour.
	const ORION := [
		["Betelgeuse", Vector2(-1.0, -1.6), 2, Color("e0782c")],
		["Bellatrix", Vector2(1.0, -1.4), 1, Color("cfe3ff")],
		["Meissa", Vector2(0.05, -2.15), 0, Color("cfe3ff")],
		["Alnitak", Vector2(-0.38, 0.06), 1, Color("fff1c1")],
		["Alnilam", Vector2(0.0, -0.1), 1, Color("fff1c1")],
		["Mintaka", Vector2(0.36, -0.27), 1, Color("fff1c1")],
		["Saiph", Vector2(-0.8, 1.6), 1, Color("cfe3ff")],
		["Rigel", Vector2(1.15, 1.35), 2, Color("cfe3ff")],
	]
	const LINES := [[0, 2], [2, 1], [0, 3], [1, 5], [3, 4], [4, 5], [3, 6], [5, 7]]

	func _ready() -> void:
		if _bands == null:
			# Bands of night, darkest at the top, the lower sky lifted by a dithered haze.
			var img := Image.create(480, 270, false, Image.FORMAT_RGBA8)
			img.fill(NIGHT_0)
			for y in range(150, 270):
				var k := (y - 150) / 120.0
				for x in 480:
					if ((x + y) % 4 == 0 and k > 0.15) or (k > 0.55 and (x + y) % 2 == 0):
						img.set_pixel(x, y, NIGHT_1)
			_bands = ImageTexture.create_from_image(img)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 150:
			_field.append([Vector2(rng.randi_range(0, 520), rng.randi_range(0, 300)),
					rng.randf(), rng.randf_range(0.6, 2.2)])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_texture(_bands, Vector2.ZERO)
		var cam := get_viewport().get_canvas_transform().origin
		var shift := Vector2(roundf(cam.x * 0.04), roundf(cam.y * 0.04))
		for s in _field:
			var p: Vector2 = s[0] + shift
			p = Vector2(fposmod(p.x, 500.0) - 10.0, fposmod(p.y, 290.0) - 10.0)
			var tw := 0.5 + 0.5 * sin(_t * s[2] + s[1] * TAU)
			var c := MOON_0 if s[1] < 0.8 else MOON_1
			c.a = 0.25 + 0.5 * tw if s[1] < 0.8 else 0.6 + 0.4 * tw
			draw_rect(Rect2(p.round(), Vector2.ONE), c)
		# The moon, top left, with a soft halo.
		var moon := Vector2(70, 34) + shift
		for r in [14, 11]:
			draw_circle(moon, r, Color(MOON_0, 0.06 if r == 14 else 0.08))
		draw_circle(moon, 6, MOON_1)
		draw_circle(moon + Vector2(2, -1), 5, Color(MOON_0, 0.55))
		draw_rect(Rect2(moon + Vector2(-3, 1), Vector2(2, 1)), Color(MOON_0, 0.6))
		# Orion sinks from high in the east toward the western horizon as the night runs out.
		var k := Atmosphere.orion_progress()
		# (Kept to the top right, which the rooms leave open.)
		var centre := Vector2(lerpf(360.0, 440.0, k), lerpf(46.0, 120.0, k)) + shift
		var unit := 15.0
		var pts: Array = []
		for st in ORION:
			pts.append((centre + (st[1] as Vector2) * unit).round())
		for l in LINES:
			_dotted(pts[l[0]], pts[l[1]], Color(MOON_0, 0.22))
		for i in ORION.size():
			var st: Array = ORION[i]
			var p: Vector2 = pts[i]
			var c: Color = st[3]
			var pulse := 0.8 + 0.2 * sin(_t * 1.7 + i)
			match int(st[2]):
				2:
					draw_rect(Rect2(p - Vector2(1, 0), Vector2(3, 1)), Color(c, 0.7 * pulse))
					draw_rect(Rect2(p - Vector2(0, 1), Vector2(1, 3)), Color(c, 0.7 * pulse))
					draw_rect(Rect2(p, Vector2.ONE), Color(1, 1, 1, pulse))
				1:
					draw_rect(Rect2(p - Vector2(1, 0), Vector2(3, 1)), Color(c, 0.35 * pulse))
					draw_rect(Rect2(p, Vector2.ONE), Color(c, pulse))
				_:
					draw_rect(Rect2(p, Vector2.ONE), Color(c, 0.8 * pulse))

	func _dotted(a: Vector2, b: Vector2, c: Color) -> void:
		var n := int(a.distance_to(b) / 3.0)
		for i in range(1, n):
			draw_rect(Rect2(a.lerp(b, float(i) / n).round(), Vector2.ONE), c)


## The far distance: ruined islands floating in the haze, a brazier or two still burning on them,
## and banks of moonlit cloud below, each at its own parallax depth. Drawn in screen space behind
## the room; the camera's movement shifts each layer by its depth.
class FarSky extends Node2D:
	# texture name, screen position, parallax depth, bob phase
	var _islands: Array = []
	var _fires: Array = []
	var _clouds: Array = []
	var _t := 0.0
	var _rng := RandomNumberGenerator.new()
	const SPOTS := [
		[0, Vector2(14, 92), 0.10], [1, Vector2(418, 170), 0.14],
		[2, Vector2(70, 196), 0.16], [3, Vector2(236, 18), 0.07],
	]

	func seed_from(room_id: String) -> void:
		_rng.seed = hash(room_id)

	func _ready() -> void:
		var meta: Variant = null
		if FileAccess.file_exists("res://art/greybox/far_islands.json"):
			meta = JSON.parse_string(FileAccess.get_file_as_string("res://art/greybox/far_islands.json"))
		# Each room shows the far islands shuffled a little, so the sky isn't the same twice.
		for s in SPOTS:
			var i: int = s[0]
			var tex := Art.tex("far_island_%d" % i)
			if tex == null:
				continue
			var pos: Vector2 = s[1] + Vector2(_rng.randi_range(-18, 18), _rng.randi_range(-10, 10))
			_islands.append([tex, pos, float(s[2]), _rng.randf() * TAU])
			if meta is Array and i < meta.size():
				for f in meta[i].get("fires", []):
					_fires.append([_islands.size() - 1, Vector2(float(f[0]), float(f[1])), _rng.randf() * TAU])
		for i in 3:
			var tex := Art.tex("cloud_%d" % i)
			if tex:
				# texture, y, parallax depth, drift speed (px/s), x offset
				_clouds.append([tex, [214.0, 236.0, 252.0][i], [0.2, 0.28, 0.38][i], [2.0, -3.0, 4.5][i], _rng.randf() * 480.0])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var cam := get_viewport().get_canvas_transform().origin
		for isl in _islands:
			var depth: float = isl[2]
			var bob := roundf(sin(_t * 0.6 + float(isl[3])) * 1.5)
			var p: Vector2 = isl[1] + Vector2(roundf(cam.x * depth), roundf(cam.y * depth) + bob)
			draw_texture(isl[0], p)
		for f in _fires:
			var isl: Array = _islands[f[0]]
			var depth: float = isl[2]
			var bob := roundf(sin(_t * 0.6 + float(isl[3])) * 1.5)
			var p: Vector2 = isl[1] + Vector2(roundf(cam.x * depth), roundf(cam.y * depth) + bob) + (f[1] as Vector2)
			var flick := 0.7 + 0.3 * sin(_t * 9.0 + float(f[2])) * sin(_t * 5.3 + float(f[2]) * 2.0)
			draw_circle(p, 5.0, Color(FIRE_1, 0.08 * flick))
			draw_circle(p, 3.0, Color(FIRE_1, 0.14 * flick))
			draw_rect(Rect2(p - Vector2(0, 1), Vector2(1, 2)), Color(FIRE_2, flick))
			draw_rect(Rect2(p + Vector2(-1, 1), Vector2(3, 1)), Color(FIRE_1, 0.9))
		for c in _clouds:
			var tex: Texture2D = c[0]
			var depth: float = c[2]
			var x := fposmod(float(c[4]) + _t * float(c[3]) + cam.x * depth, 480.0)
			var y := float(c[1]) + roundf(cam.y * depth)
			draw_texture(tex, Vector2(roundf(x) - 480.0, y))
			draw_texture(tex, Vector2(roundf(x), y))


## A thin stream of water pouring off the island's edge into the void: streaks run down it and
## it frays into mist as it falls.
class Waterfall extends Node2D:
	var length := 100.0
	var _t := 0.0

	func _ready() -> void:
		material = Atmosphere.unshaded()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var n := int(length)
		for y in n:
			var k := float(y) / n
			# it widens a little and thins out as it falls
			var half := 1 + int(k * 2.5)
			for x in range(-half, half + 1):
				var phase := fposmod(y - _t * 46.0 + x * 7.0, 11.0)
				var a := (0.7 if phase < 2.5 else 0.42) * (1.0 - k * 0.9)
				if k > 0.5 and (x + y) % 2 == 0:
					continue
				var c := MOON_1 if phase < 2.0 else MOON_0
				c.a = a * (0.8 if absi(x) == half else 1.0)
				draw_rect(Rect2(Vector2(x, y), Vector2.ONE), c)
		# a lip of white where it spills over
		draw_rect(Rect2(Vector2(-2, -1), Vector2(5, 1)), Color(MOON_1, 0.6))
