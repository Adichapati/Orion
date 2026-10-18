class_name DebugOverlay
extends Node2D
## F3 overlay drawn in world space: noise rings, guard states, awareness and sight ranges, the
## player's cell and the frame rate.

var room: Room


func _ready() -> void:
	z_index = 200
	z_as_relative = false


func _process(_delta: float) -> void:
	visible = Game.debug_overlay
	if visible:
		queue_redraw()


func _draw() -> void:
	if room == null or not is_instance_valid(room):
		return
	var font := ThemeDB.fallback_font
	for n in NoiseBus.recent:
		_ring(n.pos, n.radius, Color(0.4, 0.8, 1.0, 1.0 - n.age / 0.8))
	for g in room.guards:
		if not is_instance_valid(g):
			continue
		var p: Vector2 = g.global_position
		var c := Color(0.6, 1.0, 0.6)
		if g.is_alert():
			c = Color(1, 0.3, 0.2)
		elif g.state != Guard.S.PATROL:
			c = Color(1, 0.85, 0.3)
		draw_string(font, p + Vector2(-20, -52), "%s %d" % [Guard.S.keys()[g.state], int(g.awareness)], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, c)
		if not g.is_ko():
			_ring(p, g.sight_range(), Color(c, 0.25))
			draw_line(p, p + Iso.grid_to_screen(g.facing * 1.5), c, 1.0)
	if room.player and is_instance_valid(room.player):
		var pp: Vector2 = room.player.global_position
		var cell: Vector2i = room.player.cell()
		draw_string(font, pp + Vector2(-16, 14), "%d,%d %s" % [cell.x, cell.y, room.ch(cell)], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		draw_string(font, pp + Vector2(-16, 24), "FPS %d" % Engine.get_frames_per_second(), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)


## A circle of `radius` tiles in grid space, drawn as the iso ellipse it becomes on screen.
func _ring(centre: Vector2, radius: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(centre + Iso.grid_to_screen(Vector2(cos(a), sin(a)) * radius))
	draw_polyline(pts, color, 1.0)
