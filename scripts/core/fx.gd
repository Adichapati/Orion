class_name Fx
extends RefCounted
## Small visual effects: sparks that light the room for a moment, sword swings and dust.


## Sparks on a clash or parry. Each burst carries a short-lived light, so in a dark room every
## parry lights the area for a fraction of a second.
static func sparks(parent: Node, pos: Vector2, count := 7, strong := false) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node2D.new()
	holder.position = pos
	holder.z_index = 40
	parent.add_child(holder)
	var light := PointLight2D.new()
	light.texture = Art.tex("light_radial")
	light.texture_scale = 1.4 if strong else 0.9
	light.color = Color(1.0, 0.9, 0.7)
	light.energy = 1.6 if strong else 1.1
	holder.add_child(light)
	var tw := holder.create_tween().set_parallel(true)
	for i in count:
		var s := Sprite2D.new()
		s.texture = Art.tex("spark")
		holder.add_child(s)
		var a := randf() * TAU
		var r := randf_range(6.0, 14.0 if strong else 10.0)
		tw.tween_property(s, "position", Vector2(cos(a) * r, sin(a) * r * 0.6 - 4.0), 0.22)
		tw.tween_property(s, "modulate:a", 0.0, 0.25)
	tw.tween_property(light, "energy", 0.0, 0.14)
	tw.chain().tween_callback(holder.queue_free)


## A pale arc in front of a swinging blade, drawn in iso-squashed space.
static func swing(parent: Node, pos: Vector2, grid_dir: Vector2, reach_tiles: float, color := Color(1, 1, 1, 0.75)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var arc := SwingArc.new()
	arc.position = pos
	arc.dir = grid_dir
	arc.reach = reach_tiles
	arc.color = color
	arc.z_index = 30
	parent.add_child(arc)


## A puff of floor dust that spreads along the ground and drifts up (footfalls, landings, KOs).
static func dust(parent: Node, pos: Vector2, count := 6, spread := 9.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node2D.new()
	holder.position = pos
	holder.z_index = 20
	parent.add_child(holder)
	var tw := holder.create_tween().set_parallel(true)
	for i in count:
		var s := Sprite2D.new()
		s.texture = _dot()
		s.modulate = Color(0.72, 0.7, 0.66, 0.75)
		holder.add_child(s)
		var a := randf() * TAU
		var r := spread * randf_range(0.5, 1.0)
		var t := randf_range(0.3, 0.5)
		tw.tween_property(s, "position", Vector2(cos(a) * r, sin(a) * r * 0.45 - randf_range(2.0, 5.0)).round(), t).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(s, "modulate:a", 0.0, t + 0.05)
	tw.chain().tween_callback(holder.queue_free)


## An expanding bright ring, flattened to the floor plane (perfect parries).
static func ring(parent: Node, pos: Vector2, color := Color(0.9, 0.95, 1.0)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var r := Ring.new()
	r.position = pos
	r.color = color
	r.z_index = 45
	parent.add_child(r)


## Noise made visible: a dotted ring that spreads to the noise's real radius (in tiles) and fades.
## Footsteps get a faint one; pots, clashes and knucklebones a stronger one.
static func noise_ring(parent: Node, pos: Vector2, radius_tiles: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var r := NoiseRing.new()
	r.position = pos
	r.radius = radius_tiles
	r.z_index = 44
	parent.add_child(r)


## Gold glints rising from a collected obol.
static func glitter(parent: Node, pos: Vector2) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node2D.new()
	holder.position = pos
	holder.z_index = 45
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	parent.add_child(holder)
	var tw := holder.create_tween().set_parallel(true)
	for i in 4:
		var s := Sprite2D.new()
		s.texture = _dot()
		s.material = mat
		s.modulate = Color(1.0, 0.85, 0.35)
		holder.add_child(s)
		var x := randf_range(-5.0, 5.0)
		tw.tween_property(s, "position", Vector2(x, -randf_range(8.0, 15.0)).round(), 0.35).set_ease(Tween.EASE_OUT)
		tw.tween_property(s, "modulate:a", 0.0, 0.4).set_delay(0.1)
	tw.chain().tween_callback(holder.queue_free)


static var _dot_tex: Texture2D


static func _dot() -> Texture2D:
	if _dot_tex == null:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		img.set_pixel(0, 0, Color.WHITE)
		_dot_tex = ImageTexture.create_from_image(img)
	return _dot_tex


class Ring extends Node2D:
	var color := Color.WHITE
	var _t := 0.0

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _process(delta: float) -> void:
		_t += delta / maxf(0.05, Engine.time_scale) * 0.6
		queue_redraw()
		if _t > 0.3:
			queue_free()

	func _draw() -> void:
		var k := _t / 0.3
		var r := 4.0 + k * 22.0
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24.0
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.5).round())
		var c := color
		c.a = 1.0 - k
		draw_polyline(pts, c, 1.0)


class NoiseRing extends Node2D:
	var radius := 2.0
	var _t := 0.0
	const LIFE := 0.6

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > LIFE:
			queue_free()

	func _draw() -> void:
		var k := _t / LIFE
		var grow := 1.0 - pow(1.0 - k, 3.0)
		var r := radius * (0.25 + 0.75 * grow)
		var strength := clampf(radius / 6.0, 0.25, 1.0)
		var c := Color(0.75, 0.85, 1.0, (1.0 - k) * 0.5 * strength)
		# Dots spaced about four pixels apart around an iso ellipse of r tiles.
		var n := maxi(12, int(r * 22.0))
		for i in n:
			var a := TAU * i / n
			var p := Iso.grid_to_screen(Vector2(cos(a), sin(a)) * r)
			draw_rect(Rect2(p.round(), Vector2(2, 1)), c)


class SwingArc extends Node2D:
	var dir := Vector2(1, 0)
	var reach := 1.0
	var color := Color.WHITE
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()
		if _t > 0.14:
			queue_free()

	func _draw() -> void:
		var pts := PackedVector2Array()
		var steps := 9
		for i in steps + 1:
			var a := lerpf(-1.1, 1.1, float(i) / steps)
			pts.append(Iso.grid_to_screen(dir.rotated(a) * reach * 0.9) + Vector2(0, -10))
		var c := color
		c.a *= 1.0 - _t / 0.14
		draw_polyline(pts, c, 1.0)
