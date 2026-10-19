class_name Room
extends Node2D
## Builds one ORION room from art/maps/rooms.json and runs its world rules: collisions,
## pathfinding, cracked marble, pits, fountains, doors, lights and the star-shrine escape.
##
## The room sits at the origin of the world viewport. Every position is a screen position in
## room space; Iso converts to grid space (tiles) for distances, angles and cells.

signal exit_reached
signal star_taken
signal player_fell
signal message(text: String)

const SOLID_LAYER := 1
const HAZARD_LAYER := 2
const LEDGE_LAYER := 4
const ACTOR_LAYER := 8

const WALKABLE := ".mxEDh^~p*"
const HAZARD := "_W"
const WALLS := "#Lv"
const BREAKABLE := "Ja"
## Prop collision footprint as a fraction of a full tile.
const FOOTPRINT := {
	"#": 1.0, "L": 1.0, "v": 1.0, "o": 0.55, "S": 0.7, "J": 0.9, "a": 0.55, "C": 0.75, "r": 0.8,
	"T": 0.55, "w": 0.9, "B": 0.5, "K": 0.6, "F": 1.0, "P": 0.65, "A": 0.8,
}
const CRACK_SHAKE := 0.6
const CRACK_BREAK := 1.2

var data: Dictionary
var id := ""
var display_name := ""
var grid: PackedStringArray
var size := Vector2i.ZERO
var is_outdoor := false

var floor_layer: Node2D
var cone_layer: Node2D
var world: Node2D
var pickups: Node2D
var player: Node = null
var guards: Array = []
var interactables: Array = []
var player_spawn := Vector2i.ZERO
var checkpoint := Vector2i.ZERO
var exit_locked := false

var _astar := AStar2D.new()
var _broken := {}
var _collapsed := {}
var _cracked := {}
var _hazard_bodies := {}
var _fountains: Array[Vector2i] = []
var _fading: Array = []
var _escape_active := false
var _escape_clock := 0.0
var _altar_cell := Vector2i(-1, -1)
var _floor_sprites := {}
var _rng := RandomNumberGenerator.new()
var _door_lights: Array[PointLight2D] = []
var _door_motes: Array[CPUParticles2D] = []
## Moonlight pools as (x, y, radius in px), so the torch can ease off inside them.
var moon_pools: Array[Vector3] = []
var _ambient: CanvasModulate
var _ambient_base := Color.WHITE


# =================================================================== building

func build(room_data: Dictionary) -> void:
	data = room_data
	id = data.get("id", "")
	display_name = data.get("name", id)
	grid = PackedStringArray(data.get("grid", []))
	size = Vector2i(grid[0].length() if grid.size() > 0 else 0, grid.size())
	is_outdoor = id == "lion-gate"
	_rng.seed = hash(id)
	var p: Array = data.get("player", [0, 0])
	player_spawn = Vector2i(int(p[0]), int(p[1]))
	checkpoint = player_spawn

	floor_layer = Node2D.new()
	floor_layer.name = "Floor"
	floor_layer.z_index = -100
	add_child(floor_layer)
	cone_layer = Node2D.new()
	cone_layer.name = "Cones"
	cone_layer.z_index = -60
	add_child(cone_layer)
	world = Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	add_child(world)
	pickups = Node2D.new()
	pickups.name = "Pickups"
	pickups.y_sort_enabled = true
	world.add_child(pickups)

	_ambient = CanvasModulate.new()
	_ambient_base = Color(0.46, 0.5, 0.74) if is_outdoor else Color(0.27, 0.26, 0.42)
	add_child(_ambient)
	_apply_brightness(Game.brightness)
	Game.brightness_changed.connect(_apply_brightness)

	var order: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			order.append(Vector2i(x, y))
	order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x + a.y < b.x + b.y or (a.x + a.y == b.x + b.y and a.x < b.x))
	for c in order:
		_build_floor(c)
	for c in order:
		_build_solid(c)
	_build_ledges()
	_build_moonlight()
	if id == "star-shrine":
		exit_locked = true
	rebuild_paths()
	player_spawn = _step_inside(player_spawn)
	checkpoint = player_spawn
	Atmosphere.dress(self, id)
	NoiseBus.noise.connect(_show_noise)


## The entrance door sits in the wall line, where walls hide the player; start one tile inside.
func _step_inside(c: Vector2i) -> Vector2i:
	if not (ch(c) in "ED"):
		return c
	for n in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if is_walkable(c + n) and not (ch(c + n) in "ED"):
			return c + n
	return c


func _apply_brightness(v: float) -> void:
	var c := _ambient_base * v
	c.a = 1.0
	_ambient.color = Color(minf(c.r, 1.0), minf(c.g, 1.0), minf(c.b, 1.0))


func ch(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= size.x or c.y >= size.y:
		return "#"
	return grid[c.y][c.x]


func cell_center(c: Vector2i) -> Vector2:
	return Iso.cell_to_screen(c)


func _add_floor_sprite(c: Vector2i, s: Sprite2D, lift := 0.0) -> void:
	s.position = cell_center(c) + Vector2(0, -lift)
	floor_layer.add_child(s)
	_floor_sprites[c] = s


func _prop_elevated(c: Vector2i) -> bool:
	var h := 0
	var low := 0
	for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var k := ch(c + n)
		if k == "h":
			h += 1
		elif k in ".mx*~":
			low += 1
	return h >= 1 and low <= h


func _build_floor(c: Vector2i) -> void:
	var k := ch(c)
	if k in WALLS:
		return
	match k:
		"h":
			_add_floor_sprite(c, Art.block_sprite("raised"))
		"^":
			_add_floor_sprite(c, Art.block_sprite("steps"))
		"_":
			_add_floor_sprite(c, Art.tile_sprite("pit"))
			_add_hazard(c)
		"W":
			_add_floor_sprite(c, _water("water_deep"))
			_add_hazard(c)
		"p":
			_add_floor_sprite(c, _water("water_deep"))
			var stone := Art.block_sprite("stepping_stone")
			stone.position = cell_center(c)
			floor_layer.add_child(stone)
		"~":
			_add_floor_sprite(c, _water("water_shallow"))
		"x":
			var s := Art.tile_sprite("floor_cracked_%d" % _rng.randi_range(0, 2))
			_add_floor_sprite(c, s)
			_cracked[c] = {"sprite": s, "stand": 0.0, "creaked": false, "due": -1.0}
		"m":
			_add_floor_sprite(c, Art.tile_sprite("floor_moon"))
		"E", "D":
			_add_floor_sprite(c, Art.tile_sprite("floor_door"))
		"*":
			_add_floor_sprite(c, Art.tile_sprite("floor_mark"))
			_make_mark(c)
		_:
			if not (k in WALKABLE) and _prop_elevated(c):
				_add_floor_sprite(c, Art.block_sprite("raised"))
			else:
				_add_floor_sprite(c, Art.tile_sprite(_plain_floor(c)))


## A plain marble slab with some variety: darker slabs, polished and stained ones, moss along
## the seams (mostly beside walls) and, in the open air, fallen olive leaves.
func _plain_floor(c: Vector2i) -> String:
	var by_wall := false
	for n in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]:
		if ch(c + n) in WALLS:
			by_wall = true
	var r := _rng.randf()
	if r < (0.3 if by_wall else 0.03):
		return "floor_marble_moss"
	r = _rng.randf()
	if r < 0.12:
		return "floor_marble_dark"
	if r < 0.2:
		return "floor_marble_worn"
	if r < 0.26:
		return "floor_marble_stain"
	if is_outdoor and r < 0.3:
		return "floor_marble_leaves"
	return "floor_marble"


## A brazier's fire: three hand-drawn frames, unshaded so it burns at full colour in the dark.
func _flame(at: Vector2) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 9.0)
	for i in 3:
		frames.add_frame("default", Art.tex("brazier_flame_%d" % i))
	var f := AnimatedSprite2D.new()
	f.sprite_frames = frames
	f.position = at
	f.offset = Vector2(0, -4)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	f.material = mat
	f.frame = _rng.randi_range(0, 2)
	f.play()
	return f


func _water(name: String) -> Sprite2D:
	var s := Art.tile_sprite(name)
	s.material = Atmosphere.water_material()
	return s


func _wall_is_tall(c: Vector2i) -> bool:
	if c.x == 0 or c.y == 0:
		return true
	var up := ch(c + Vector2i(0, -1))
	var left := ch(c + Vector2i(-1, 0))
	return (up in WALLS) and (left in WALLS)


func _body(c: Vector2i, k: String) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = cell_center(c)
	body.collision_layer = SOLID_LAYER
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = Iso.diamond(FOOTPRINT.get(k, 1.0))
	body.add_child(shape)
	body.set_meta("cell", c)
	body.set_meta("kind", k)
	world.add_child(body)
	return body


func _build_solid(c: Vector2i) -> void:
	var k := ch(c)
	if k in WALKABLE or k in HAZARD or k == "p" or k == " ":
		if k == "D":
			_make_door(c)
		return
	var lift := Iso.LEVEL_PX if (not (k in WALLS) and _prop_elevated(c)) else 0.0
	var body := _body(c, k)
	match k:
		"#", "L", "v":
			var tall := _wall_is_tall(c)
			var name := "wall_tall" if tall else "wall_low"
			if k == "v":
				name = "wall_tall_ivy"
			body.add_child(Art.block_sprite(name))
			if k == "L":
				var lamp := Art.feet_sprite("wall_lamp")
				lamp.position = Vector2(-6, -22 if tall else -8)
				body.add_child(lamp)
				_add_light(body, Vector2(-3, -24 if tall else -10), Color(1.0, 0.62, 0.3), 0.95, 76.0)
				var sparks := Atmosphere.embers(3, 1.0)
				sparks.position = Vector2(-5, -30 if tall else -16)
				body.add_child(sparks)
		"o":
			var col := Art.feet_sprite("column", 4)
			col.position.y = -lift
			body.add_child(col)
			_fading.append({"node": col, "body": body, "height": 56.0 + lift})
		"S":
			var st := Art.feet_sprite("statue", 3)
			st.position.y = -lift
			body.add_child(st)
			_fading.append({"node": st, "body": body, "height": 42.0 + lift})
		"J", "a":
			var b := Breakable.new()
			b.setup(self, c, k)
			body.add_child(b)
		"C":
			var chest := Chest.new()
			chest.setup(self, c)
			body.add_child(chest)
		"r":
			body.add_child(Art.feet_sprite("rubble", 3))
		"T":
			var tree := Art.feet_sprite("tree", 2)
			body.add_child(tree)
			_fading.append({"node": tree, "body": body, "height": 46.0})
		"w":
			body.add_child(Art.feet_sprite("well", 6))
			body.set_meta("well", true)
		"B":
			body.add_child(Art.feet_sprite("brazier", 2))
			body.add_child(_flame(Vector2(0, -10)))
			_add_light(body, Vector2(0, -16), Color(1.0, 0.6, 0.28), 1.05, 88.0)
			var sparks := Atmosphere.embers(6, 3.0)
			sparks.position = Vector2(0, -18)
			body.add_child(sparks)
		"K":
			var rack := Art.feet_sprite("weapon_rack", 3)
			body.add_child(rack)
			var it := Interactable.new().setup("Take the sword", "glyph_hand", 30.0)
			body.add_child(it)
			interactables.append(it)
			it.used.connect(func(_p):
				if Game.weapon_id == "":
					Game.give_weapon("xiphos")
					Game.toast.emit("You take a short sword from the rack. Attack: left click or J. Parry: right click or K.")
					Sfx.play("pickup")
					rack.texture = Art.tex("weapon_rack_empty")
					it.enabled = false
				else:
					Game.toast.emit("You already carry a sword."))
		"F":
			var spout := ch(c + Vector2i(1, 0)) == "F" and ch(c + Vector2i(-1, 0)) == "F" \
					and ch(c + Vector2i(0, 1)) == "F" and ch(c + Vector2i(0, -1)) == "F"
			var f := Art.feet_sprite("fountain_spout" if spout else "fountain")
			f.offset.y += 8
			body.add_child(f)
			_fountains.append(c)
		"P":
			var ph := Art.feet_sprite("phineus_se", 3)
			ph.position.y = -lift
			body.add_child(ph)
			_add_light(body, Vector2(0, -26 - lift), Color(1.0, 0.7, 0.4), 0.9, 70.0)
			var talk := Interactable.new().setup("Talk to Phineus", "glyph_hand", 34.0 + lift)
			talk.interact_range = 1.6
			body.add_child(talk)
			interactables.append(talk)
			talk.used.connect(func(_p): message.emit("shop"))
		"A":
			_altar_cell = c
			var altar := Art.feet_sprite("altar", 2)
			altar.position.y = -lift
			body.add_child(altar)
			var star := Art.feet_sprite("belt_star")
			star.position = Vector2(0, -20 - lift)
			star.name = "Star"
			body.add_child(star)
			var glow := _add_light(body, Vector2(0, -24 - lift), Color(0.65, 0.78, 1.0), 1.1, 70.0)
			var take := Interactable.new().setup("Take the Belt Star", "glyph_star", 36.0 + lift)
			take.interact_range = 1.7
			body.add_child(take)
			interactables.append(take)
			take.used.connect(func(_p):
				take.enabled = false
				star.queue_free()
				glow.energy = 0.3
				_begin_escape())


func _add_light(parent: Node2D, pos: Vector2, color: Color, energy: float, radius_px: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = Art.tex("light_radial")
	l.texture_scale = radius_px / 64.0
	l.color = color
	l.energy = energy
	l.position = pos
	l.scale = Vector2(1.0, 0.7)
	parent.add_child(l)
	return l


func _make_door(c: Vector2i) -> void:
	var holder := Node2D.new()
	holder.position = cell_center(c)
	world.add_child(holder)
	# The Lion Gate itself: lintel and lion relief over the two-cell doorway in the north wall.
	if id == "lion-gate" and ch(c + Vector2i(1, 0)) == "D" and ch(c - Vector2i(1, 0)) in WALLS:
		var gate := Sprite2D.new()
		gate.texture = Art.tex("lion_gate")
		gate.centered = false
		gate.offset = Vector2(-4, -59)
		gate.position = cell_center(c) + Vector2(-16, 0)
		world.add_child(gate)
	# Warm light spilling through from the room beyond: the way on, readable from across the hall.
	var glow := _add_light(holder, Vector2(0, -6 - elevation_px(c)), Color(1.0, 0.7, 0.4), 0.0, 64.0)
	glow.scale = Vector2(1.0, 0.6)
	_door_lights.append(glow)
	var motes := Atmosphere.embers(3, 1.5)
	motes.position = Vector2(0, -8 - elevation_px(c))
	holder.add_child(motes)
	_door_motes.append(motes)
	var it := Interactable.new().setup("Enter", "glyph_door", 22.0)
	holder.add_child(it)
	interactables.append(it)
	it.used.connect(func(_p):
		if exit_locked:
			Game.toast.emit("The door is sealed. The star on the altar holds it shut.")
			Sfx.play("deny")
		else:
			exit_reached.emit())


func _make_mark(c: Vector2i) -> void:
	var holder := Node2D.new()
	holder.position = cell_center(c)
	world.add_child(holder)
	var it := Interactable.new().setup("Read the mark", "glyph_star", 14.0)
	it.interact_range = 1.0
	holder.add_child(it)
	interactables.append(it)
	it.used.connect(func(_p):
		it.enabled = false
		Game.stats.marks += 1
		Game.toast.emit("Seven scratched dots: the Pleiades. Alcyone was dragged past here, and she left you a sign.")
		Sfx.play("mark"))


func _add_hazard(c: Vector2i) -> void:
	if _hazard_bodies.has(c):
		return
	var body := StaticBody2D.new()
	body.position = cell_center(c)
	body.collision_layer = HAZARD_LAYER
	body.collision_mask = 0
	var shape := CollisionPolygon2D.new()
	shape.polygon = Iso.diamond(0.92)
	body.add_child(shape)
	add_child(body)
	_hazard_bodies[c] = body


## Raised floor ('h') can only be climbed by the steps ('^'); other edges block walking.
func _build_ledges() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = LEDGE_LAYER
	body.collision_mask = 0
	add_child(body)
	var edges := {
		Vector2i(1, 0): [Vector2(16, 0), Vector2(0, 8)],
		Vector2i(-1, 0): [Vector2(-16, 0), Vector2(0, -8)],
		Vector2i(0, 1): [Vector2(0, 8), Vector2(-16, 0)],
		Vector2i(0, -1): [Vector2(0, -8), Vector2(16, 0)],
	}
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			if ch(c) != "h":
				continue
			for n in edges:
				var nk := ch(c + n)
				if nk in ".mx*~" or (nk in "ED" and elevation_px(c + n) < 12.0):
					var seg := SegmentShape2D.new()
					seg.a = cell_center(c) + edges[n][0]
					seg.b = cell_center(c) + edges[n][1]
					var cs := CollisionShape2D.new()
					cs.shape = seg
					body.add_child(cs)


func _build_moonlight() -> void:
	var seen := {}
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			if ch(c) != "m" or seen.has(c):
				continue
			var group: Array[Vector2i] = []
			var stack: Array[Vector2i] = [c]
			while not stack.is_empty():
				var cur: Vector2i = stack.pop_back()
				if seen.has(cur) or ch(cur) != "m":
					continue
				seen[cur] = true
				group.append(cur)
				for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					stack.append(cur + n)
			var centre := Vector2.ZERO
			for g in group:
				centre += cell_center(g)
			centre /= group.size()
			var holder := Node2D.new()
			holder.position = centre
			add_child(holder)
			var l := _add_light(holder, Vector2.ZERO, Color(0.55, 0.68, 1.0), 0.9, 22.0 + 12.0 * sqrt(group.size()))
			l.scale = Vector2(1.0, 0.5)
			moon_pools.append(Vector3(centre.x, centre.y, 22.0 + 12.0 * sqrt(group.size())))
			var r := sqrt(group.size()) * 9.0
			var dust := Atmosphere.motes(Vector2(r, r * 0.5 + 6.0), 4 + group.size())
			dust.position = Vector2(0, -10)
			holder.add_child(dust)


## Noise spreads as rings (the design doc): the player's and the world's noises are drawn; the
## guards' own shouts are not.
func _show_noise(pos: Vector2, radius: float, source: Node) -> void:
	if source is Guard or not is_inside_tree():
		return
	Fx.noise_ring(world, pos, radius)


## How deep in a moonlight pool a point is: 0 outside, 1 at the centre. Lights add up and pale
## marble clips to white, so the torch and lanterns ease off where the moon already falls.
func moonlight_at(pos: Vector2) -> float:
	var moon := 0.0
	for m in moon_pools:
		var d := (pos - Vector2(m.x, m.y)) * Vector2(1.0, 2.0)
		moon = maxf(moon, 1.0 - smoothstep(m.z * 0.5, m.z * 1.4, d.length()))
	return moon

## One Guard per entry in rooms.json's "guards" list. Counts them once per visit for Dawn Rank.
func spawn_guards() -> void:
	for entry in data.get("guards", []):
		var g := Guard.new().setup(self, entry)
		g.name = "Guard_%s" % entry.get("id", "g")
		world.add_child(g)
		guards.append(g)
	if not Game.stats.rooms_counted.has(id):
		Game.stats.rooms_counted[id] = true
		Game.stats.guards_total += guards.size()


func alive_guards() -> Array:
	return guards.filter(func(g): return is_instance_valid(g) and not g.is_ko())


## Highest awareness among the conscious guards, 0..100 (drives the tension music).
func max_awareness() -> float:
	var m := 0.0
	for g in alive_guards():
		m = maxf(m, g.awareness)
	return m


# =================================================================== cell queries

func is_walkable(c: Vector2i) -> bool:
	if _collapsed.has(c):
		return false
	if _broken.has(c):
		return true
	return ch(c) in WALKABLE


func is_hazard(c: Vector2i) -> bool:
	return _collapsed.has(c) or ch(c) in HAZARD


func is_well(c: Vector2i) -> bool:
	return ch(c) == "w"


## Floor height in pixels: raised floor 16, steps 8, stepping stones 4.
func elevation_px(c: Vector2i) -> float:
	match ch(c):
		"h":
			return Iso.LEVEL_PX
		"^":
			return Iso.LEVEL_PX * 0.5
		"p":
			return 4.0
		"D", "E":
			# A door in the wall of a raised floor opens at that floor's height.
			for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if ch(c + n) == "h":
					return Iso.LEVEL_PX
	return 0.0


func cell_at(screen_pos: Vector2) -> Vector2i:
	return Iso.cell_of_screen(screen_pos)


## Footsteps are silent within 3 tiles of a fountain.
func is_masked(screen_pos: Vector2) -> bool:
	var g := Iso.screen_to_grid(screen_pos)
	for f in _fountains:
		if g.distance_to(Vector2(f)) <= 3.0:
			return true
	return false


func is_cracked(c: Vector2i) -> bool:
	return _cracked.has(c) and not _collapsed.has(c)


## True when nothing solid stands between two screen points (pits and ledges don't block sight).
func line_of_sight(a: Vector2, b: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(a, b, SOLID_LAYER)
	var hit := space.intersect_ray(q)
	return hit.is_empty()


## The first wall hit along a ray, or b if none: a lobbed knucklebone clears pots and columns
## but not walls.
func wall_ray_end(a: Vector2, b: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(a, b, SOLID_LAYER)
	for i in 12:
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return b
		var kind: String = (hit.collider as Node).get_meta("kind", "") if hit.collider is Node else ""
		if kind != "" and kind in WALLS:
			return hit.position
		q.exclude = q.exclude + [hit.rid]
	return b


## The first solid hit along a ray, or b if nothing is hit. Used to shape the vision cones.
func ray_end(a: Vector2, b: Vector2) -> Vector2:
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(a, b, SOLID_LAYER)
	var hit := space.intersect_ray(q)
	return b if hit.is_empty() else hit.position


# =================================================================== pathfinding

func _pid(c: Vector2i) -> int:
	return c.y * size.x + c.x


func _can_step(a: Vector2i, b: Vector2i) -> bool:
	if not is_walkable(a) or not is_walkable(b):
		return false
	return absf(elevation_px(a) - elevation_px(b)) < 12.0


func rebuild_paths() -> void:
	_astar.clear()
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			if is_walkable(c):
				_astar.add_point(_pid(c), Vector2(c))
	for y in size.y:
		for x in size.x:
			var c := Vector2i(x, y)
			if not _astar.has_point(_pid(c)):
				continue
			for n in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
				var d: Vector2i = c + n
				if not _astar.has_point(_pid(d)) or not _can_step(c, d):
					continue
				if n.x != 0 and n.y != 0:
					if not _can_step(c, Vector2i(d.x, c.y)) or not _can_step(c, Vector2i(c.x, d.y)):
						continue
				_astar.connect_points(_pid(c), _pid(d))


func nearest_walkable(c: Vector2i) -> Vector2i:
	if _astar.has_point(_pid(c)):
		return c
	var id_ := _astar.get_closest_point(Vector2(c))
	if id_ < 0:
		return c
	var p := _astar.get_point_position(id_)
	return Vector2i(int(p.x), int(p.y))


## Screen-space waypoints from one screen point to another (excluding the start cell).
func find_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	var a := nearest_walkable(cell_at(from_pos))
	var b := nearest_walkable(cell_at(to_pos))
	var out := PackedVector2Array()
	if not _astar.has_point(_pid(a)) or not _astar.has_point(_pid(b)):
		return out
	var pts := _astar.get_point_path(_pid(a), _pid(b))
	for i in range(1, pts.size()):
		out.append(Iso.grid_to_screen(pts[i]))
	if out.size() > 0:
		out[out.size() - 1] = to_pos if is_walkable(cell_at(to_pos)) else out[out.size() - 1]
	return out


func reachable(from_c: Vector2i, to_c: Vector2i) -> bool:
	if not _astar.has_point(_pid(from_c)) or not _astar.has_point(_pid(to_c)):
		return false
	return _astar.get_id_path(_pid(from_c), _pid(to_c)).size() > 0


# =================================================================== dynamic world

func on_broken(c: Vector2i) -> void:
	_broken[c] = true
	rebuild_paths()


func spawn_obols(pos: Vector2, total: int) -> void:
	var left := total
	while left > 0:
		var n := mini(left, _rng.randi_range(1, 3))
		left -= n
		var dir := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized() * 0.9
		var p := Pickup.new().setup(self, "obol", n, dir)
		p.position = pos
		pickups.add_child(p)


func spawn_sword(pos: Vector2) -> void:
	var p := Pickup.new().setup(self, "sword", 1, Vector2(0.5, 0.5))
	p.position = pos
	pickups.add_child(p)


func _actors() -> Array:
	var out: Array = []
	if player != null and is_instance_valid(player):
		out.append(player)
	for g in guards:
		if is_instance_valid(g):
			out.append(g)
	return out


func _physics_process(delta: float) -> void:
	_update_cracked(delta)
	if _escape_active:
		_escape_clock += delta


func _update_cracked(delta: float) -> void:
	if _cracked.is_empty():
		return
	var occupied := {}
	for a in _actors():
		if not a.has_method("stands_on_floor") or not a.stands_on_floor():
			continue
		var c := cell_at(a.global_position)
		if not is_cracked(c):
			continue
		if a.is_heavy():
			_collapse(c)
			continue
		occupied[c] = true
	for c in _cracked:
		if _collapsed.has(c):
			continue
		var t: Dictionary = _cracked[c]
		if t.due >= 0.0 and _escape_clock >= t.due:
			_collapse(c)
			continue
		if occupied.has(c):
			t.stand += delta
		else:
			t.stand = maxf(0.0, t.stand - delta * 1.5)
		var s: Sprite2D = t.sprite
		s.position = cell_center(c)
		if t.stand >= CRACK_SHAKE or (t.due >= 0.0 and t.due - _escape_clock < 0.5):
			s.position += Vector2(_rng.randi_range(-1, 1), _rng.randi_range(-1, 0))
			if not t.creaked:
				t.creaked = true
				Sfx.play("creak", cell_center(c))
		if t.stand >= CRACK_BREAK:
			_collapse(c)


func _collapse(c: Vector2i) -> void:
	if _collapsed.has(c):
		return
	_collapsed[c] = true
	var t: Dictionary = _cracked[c]
	(t.sprite as Sprite2D).texture = Art.tex("pit")
	(t.sprite as Sprite2D).position = cell_center(c)
	_add_hazard(c)
	rebuild_paths()
	Sfx.play("crumble", cell_center(c))
	NoiseBus.emit_noise(cell_center(c), 4.0, self)
	for a in _actors():
		if a.has_method("stands_on_floor") and a.stands_on_floor() and cell_at(a.global_position) == c:
			a.fall()


func _restore_cracked() -> void:
	for c in _cracked:
		var t: Dictionary = _cracked[c]
		t.stand = 0.0
		t.creaked = false
		t.due = -1.0
		if _collapsed.has(c):
			_collapsed.erase(c)
			(t.sprite as Sprite2D).texture = Art.tex("floor_cracked_%d" % _rng.randi_range(0, 2))
			if _hazard_bodies.has(c):
				_hazard_bodies[c].queue_free()
				_hazard_bodies.erase(c)
	rebuild_paths()


## Taking the Belt Star unseals the door and brings the cracked ring down behind you.
func _begin_escape() -> void:
	exit_locked = false
	star_taken.emit()
	Game.toast.emit("The Belt Star is yours. The floor groans. Run for the door, and jump the gap!")
	Sfx.play("star")
	checkpoint = Vector2i(6, 3) if is_walkable(Vector2i(6, 3)) else player_spawn
	_arm_escape(2.0)


func _arm_escape(delay: float) -> void:
	_escape_active = true
	_escape_clock = 0.0
	for c in _cracked:
		var d := Vector2(c).distance_to(Vector2(_altar_cell))
		_cracked[c].due = delay + d * 0.28


## Called by the player after falling: during the escape, the floor resets so it can be retried.
func on_player_fell() -> void:
	Game.stats.falls += 1
	if _escape_active:
		_restore_cracked()
		_arm_escape(2.5)
	player_fell.emit()


func respawn_point() -> Vector2:
	return cell_center(nearest_walkable(checkpoint))


func set_checkpoint(c: Vector2i) -> void:
	checkpoint = c


# =================================================================== per-frame view helpers

func _process(_delta: float) -> void:
	# Exit doors breathe a warm glow, but a sealed door stays dark.
	var t := Time.get_ticks_msec() / 1000.0
	for l in _door_lights:
		l.energy = 0.0 if exit_locked else 0.75 + 0.15 * sin(t * 2.2)
	for m in _door_motes:
		m.emitting = not exit_locked
	if player == null or not is_instance_valid(player):
		return
	var pp: Vector2 = player.global_position
	for it in interactables:
		if is_instance_valid(it):
			it.refresh(pp)
	for f in _fading:
		var body: Node2D = f.body
		if not is_instance_valid(body):
			continue
		var bp := body.global_position
		var behind: bool = pp.y < bp.y and pp.y > bp.y - f.height and absf(pp.x - bp.x) < 13.0
		(f.node as CanvasItem).modulate.a = 0.45 if behind else 1.0


func closest_interactable(pos: Vector2) -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for it in interactables:
		if not is_instance_valid(it) or not it.in_reach(pos):
			continue
		var d := Iso.tiles_between(it.global_position, pos)
		if d < best_d:
			best_d = d
			best = it
	return best


## Screen-space bounds of the room, for the camera limits.
func bounds() -> Rect2:
	var pts := [
		cell_center(Vector2i(0, 0)), cell_center(Vector2i(size.x - 1, 0)),
		cell_center(Vector2i(0, size.y - 1)), cell_center(Vector2i(size.x - 1, size.y - 1)),
	]
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r.grow_individual(24, 56, 24, 24)
