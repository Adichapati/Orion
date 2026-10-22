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
	sky.room = room
	back.add_child(sky)
	# Far islands with ruins and lit braziers, and low cloud banks, drifting at their own depths.
	var distance := CanvasLayer.new()
	distance.layer = -9
	distance.name = "Distance"
	room.add_child(distance)
	var far := FarSky.new()
	far.room = room
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


## How far tall back walls rise above their cell's ground diamond, in pixels (wall_tall is 32x48).
const WALL_RISE := 32.0


## The top edge of the room's back walls on screen (viewport pixels), from its left corner over
## the top corner to its right corner: below it the room hides the sky. A wall's top diamond peaks
## 8 px above its cell's centre. Empty before the room is built.
static func skyline(room: Node2D, xf: Transform2D) -> PackedVector2Array:
	if room == null or not room.has_method("cell_center"):
		return PackedVector2Array()
	var size: Vector2i = room.get("size")
	if size.x <= 0 or size.y <= 0:
		return PackedVector2Array()
	var left: Vector2 = room.cell_center(Vector2i(0, size.y - 1)) + Vector2(-16, -WALL_RISE)
	var top: Vector2 = room.cell_center(Vector2i(0, 0)) + Vector2(0, -WALL_RISE - 8)
	var right: Vector2 = room.cell_center(Vector2i(size.x - 1, 0)) + Vector2(16, -WALL_RISE)
	return PackedVector2Array([xf * room.to_global(left), xf * room.to_global(top), xf * room.to_global(right)])


## The skyline's highest and lowest y over the screen columns x0..x1 (x: highest, y: lowest), or
## (INF, INF) where it doesn't reach them.
static func skyline_span(line: PackedVector2Array, x0: float, x1: float) -> Vector2:
	var hi_y := INF
	var lo_y := -INF
	for i in range(line.size() - 1):
		var a := line[i]
		var b := line[i + 1]
		var lo := maxf(x0, minf(a.x, b.x))
		var hi := minf(x1, maxf(a.x, b.x))
		if lo > hi:
			continue
		for x: float in [lo, hi]:
			var t: float = 0.0 if is_equal_approx(a.x, b.x) else (x - a.x) / (b.x - a.x)
			var y := lerpf(a.y, b.y, t)
			hi_y = minf(hi_y, y)
			lo_y = maxf(lo_y, y)
	return Vector2(hi_y, lo_y) if hi_y != INF else Vector2(INF, INF)


## A sky object spanning screen box `r` "peeks" when part of it shows just over the room's walls,
## as if resting on them. Returns the vertical shift that fixes it: up (negative) until it clears
## the walls by `margin`, or down (positive) until the walls hide it, whichever is shorter; 0 if
## it doesn't peek. `max_up` caps the lift (Orion must stay on screen).
static func unpeek(line: PackedVector2Array, r: Rect2, margin: float, max_up := INF) -> float:
	var span := skyline_span(line, r.position.x, r.end.x)
	if span.x == INF or r.end.y <= span.x - margin or r.position.y >= span.y:
		return 0.0
	var up := r.end.y - (span.x - margin)
	var down := span.y - r.position.y + 1.0
	if up <= down and up <= max_up:
		return -up
	return down


## Where Orion hangs: high in the east at the start of the run, low in the west at the end.
static func orion_progress() -> float:
	var rooms := maxf(1.0, float(Game.rooms.size()))
	var into := clampf(Game.elapsed_seconds() / 900.0, 0.0, 1.0) if not Game.stats.is_empty() else 0.0
	return clampf((Game.room_index + 0.5) / rooms * 0.8 + into * 0.2, 0.0, 1.0)


class NightSky extends Node2D:
	var stars := true
	## The room whose walls Orion must clear (null on the title screen).
	var room: Node2D
	## Orion's stars on screen this frame (viewport pixels), for tests.
	var orion_box := Rect2()
	var _field: Array = []
	var _t := 0.0
	var _off := Vector2.ZERO
	var _off_set := false
	var _moon := Vector2(70, 34)
	var _scale := 1.0
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
			# The haze fades in through a 4x4 ordered dither, so it has no hard top edge.
			const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
			for y in range(130, 270):
				var density := smoothstep(0.0, 1.0, (y - 130) / 140.0) * 0.55
				for x in 480:
					if (BAYER[(y % 4) * 4 + x % 4] + 0.5) / 16.0 < density:
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
		_moon = moon
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
		# Where a room's back walls rise into his corner (the statue court, the star shrine), he
		# moves to the nearest open patch of sky above them (up first, then sideways) instead of
		# setting behind them, and stays there until the walls cover it; he never leaves the screen.
		# Where even that is too tight he draws a little smaller.
		var want := _off
		if room:
			var line := Atmosphere.skyline(room, get_viewport().get_canvas_transform())
			if not _fits(line, centre + _off, unit * _scale):
				var spot := _find_spot(line, centre, unit)
				if spot.z > 0.0:
					want = Vector2(spot.x, spot.y)
					_scale = spot.z
		_off = want if not _off_set else _off.move_toward(want, 240.0 * get_process_delta_time())
		_off_set = true
		centre += _off.round()
		unit *= _scale
		orion_box = _stars_box(centre, unit)
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

	## The box round Orion's stars when centred at `c`.
	func _stars_box(c: Vector2, unit: float) -> Rect2:
		return Rect2(c + Vector2(-1.15, -2.15) * unit, Vector2(2.3, 3.75) * unit).grow(2.0)

	## Orion centred at `c` is wholly on screen and clear of the room's walls.
	func _fits(line: PackedVector2Array, c: Vector2, unit: float) -> bool:
		var b := _stars_box(c, unit)
		var view := get_viewport_rect().size
		if b.position.x < 2.0 or b.position.y < 2.0 or b.end.x > view.x - 2.0:
			return false
		# clear of the moon and of the HUD along the top: hearts, the objective line, the obols
		for keep_out in [Rect2(_moon - Vector2(16, 16), Vector2(32, 32)), Rect2(0, 0, 64, 18),
				Rect2(90, 0, 300, 16), Rect2(440, 0, 40, 18)]:
			if b.intersects(keep_out):
				return false
		var span := Atmosphere.skyline_span(line, b.position.x, b.end.x)
		return span.x == INF or b.end.y <= span.x - 6.0

	## The smallest move from `c` that puts Orion in open sky (up first, then sideways), full size
	## if he fits, else at 80%: (dx, dy, scale), or scale 0 if the walls fill the sky.
	func _find_spot(line: PackedVector2Array, c: Vector2, unit: float) -> Vector3:
		for sc in [1.0, 0.8]:
			for i in 41:
				var dx := 12.0 * ceilf(i / 2.0) * (1.0 if i % 2 == 1 else -1.0)
				for k in 16:
					var d := Vector2(dx, -8.0 * k)
					if _fits(line, c + d, unit * sc):
						return Vector3(d.x, d.y, sc)
		return Vector3.ZERO

	func _dotted(a: Vector2, b: Vector2, c: Color) -> void:
		var n := int(a.distance_to(b) / 3.0)
		for i in range(1, n):
			draw_rect(Rect2(a.lerp(b, float(i) / n).round(), Vector2.ONE), c)


## The far distance: ruined islands floating in the haze, a brazier or two still burning on them,
## and banks of moonlit cloud below, each at its own parallax depth. Drawn in screen space behind
## the room; the camera's movement shifts each layer by its depth.
class FarSky extends Node2D:
	## The room whose walls the islands must not rest on.
	var room: Node2D
	# texture name, screen position, parallax depth, bob phase, vertical shift off the walls
	var _islands: Array = []
	var _shift_set := false
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
			_islands.append([tex, pos, float(s[2]), _rng.randf() * TAU, 0.0])
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
		# An island that would show just over the room's walls, as if resting on them, eases up
		# clear of them or sinks out of sight behind them, whichever is the shorter way.
		var line := Atmosphere.skyline(room, get_viewport().get_canvas_transform()) if room else PackedVector2Array()
		for isl in _islands:
			var r := _box(isl, 0.0)
			var want: float = float(isl[4]) + Atmosphere.unpeek(line, r.grow(1.0), 4.0) if not line.is_empty() else 0.0
			# keep an island that is already clear where it is, rather than drifting back
			if not line.is_empty() and Atmosphere.unpeek(line, _box(isl, 0.0, 0.0).grow(1.0), 4.0) == 0.0:
				want = 0.0
			isl[4] = want if not _shift_set else move_toward(float(isl[4]), want, 160.0 * delta)
		_shift_set = true
		queue_redraw()

	## Where an island is drawn this frame (its texture's box), with `shift` instead of its own.
	func _box(isl: Array, extra: float, shift: Variant = null) -> Rect2:
		var cam := get_viewport().get_canvas_transform().origin
		var depth: float = isl[2]
		var bob := roundf(sin(_t * 0.6 + float(isl[3])) * 1.5)
		var s: float = float(isl[4]) if shift == null else float(shift)
		var p: Vector2 = isl[1] + Vector2(roundf(cam.x * depth), roundf(cam.y * depth) + bob + roundf(s) + extra)
		return Rect2(p, (isl[0] as Texture2D).get_size())

	## Every far island's box on screen this frame, for tests.
	func island_boxes() -> Array:
		return _islands.map(func(isl): return _box(isl, 0.0))

	func _draw() -> void:
		var cam := get_viewport().get_canvas_transform().origin
		for isl in _islands:
			draw_texture(isl[0], _box(isl, 0.0).position)
		for f in _fires:
			var isl: Array = _islands[f[0]]
			var p: Vector2 = _box(isl, 0.0).position + (f[1] as Vector2)
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
