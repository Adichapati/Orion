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


static func dust(parent: Node, pos: Vector2) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var holder := Node2D.new()
	holder.position = pos
	holder.z_index = 20
	parent.add_child(holder)
	var tw := holder.create_tween().set_parallel(true)
	for i in 6:
		var s := Sprite2D.new()
		s.texture = Art.tex("spark")
		s.modulate = Color(0.75, 0.72, 0.66, 0.9)
		holder.add_child(s)
		var a := randf() * TAU
		tw.tween_property(s, "position", Vector2(cos(a) * 9.0, sin(a) * 4.0 - 3.0), 0.4)
		tw.tween_property(s, "modulate:a", 0.0, 0.45)
	tw.chain().tween_callback(holder.queue_free)


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
