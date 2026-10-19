class_name Guard
extends CharacterBody2D
## A palace guard: patrols with a lantern, sees in a cone, hears noises, investigates, chases and
## duels. Watchman, Spearman and Hoplite differ only by their GuardType resource.

enum S { PATROL, SUSPICIOUS, ALERT, SEARCH, RETURN, STUNNED, SHOVED, FALLING, KO }

const SUSPICIOUS_AT := 30.0
const ALERT_AT := 100.0
const DECAY := 12.0
const LOOK_SWAY := 35.0
const LOOK_PERIOD := 3.5
const REPATH := 0.3
const LOSE_SIGHT := 3.0
const SEARCH_TIME := 10.0
const SEARCH_RADIUS := 3.0
const SUSPICIOUS_GIVE_UP := 6.0
const ALARM_RADIUS := 6.0
const CIRCLE_DIST := 2.0
## Radians per second.
const TURN_RATE := 6.0

var type: GuardType
var room: Room
var guard_id := ""
var state := S.PATROL
var facing := Vector2(1, 0)
var awareness := 0.0
var hp := 3
var on_edge := false
var elev := 0.0

var _waypoints: Array[Vector2] = []
var _wp := 0
var _wait := 0.0
var _base_face := Vector2(1, 0)
var _look_face := Vector2(1, 0)
var _look_t := 0.0
var _path := PackedVector2Array()
var _path_i := 0
var _path_goal := Vector2.INF
var _repath_t := 0.0
var _goal := Vector2.ZERO
var _last_known := Vector2.ZERO
var _lost_t := 0.0
var _phase := ""
var _phase_t := 0.0
var _state_t := 0.0
var _search_target := Vector2.INF
var _sees := false
var _stun_t := 0.0
var _knock := Vector2.ZERO
var _attack: AttackData = null
var _cooldown := 0.0
var _circle_sign := 1.0
var _shove_from := Vector2.ZERO
var _shove_to := Vector2.ZERO
var _shove_end := ""
var _floor_pos := Vector2.ZERO

var body_node: Node2D
var sprite: Sprite2D
var _glow: PointLight2D
var lantern_pivot: Node2D
var lantern_rot: Node2D
var lantern: PointLight2D
var cone: Polygon2D
var mark: Sprite2D
var meter: AwarenessMeter
var glint: Sprite2D
var life: Life
var daze: DazeStars
var _shape: CollisionShape2D
var _shake_t := 0.0


## Reads one guard entry of rooms.json: {id, type, at, face, path}.
func setup(p_room: Room, entry: Dictionary) -> Guard:
	room = p_room
	type = Game.guard_types.get(String(entry.get("type", "watchman")))
	if type == null:
		type = Game.guard_types["watchman"]
	guard_id = "%s:%s" % [room.id, entry.get("id", "g")]
	hp = type.hp
	var at: Array = entry.get("at", [0, 0])
	position = room.cell_center(Vector2i(int(at[0]), int(at[1])))
	var f: Array = entry.get("face", [1, 0])
	facing = Vector2(float(f[0]), float(f[1])).normalized()
	_base_face = facing
	for p in entry.get("path", [at]):
		_waypoints.append(room.cell_center(Vector2i(int(p[0]), int(p[1]))))
	if _waypoints.is_empty():
		_waypoints.append(position)
	# Start heading for the nearest waypoint, so a guard placed mid-route carries on along it.
	var best := INF
	for i in _waypoints.size():
		var d := position.distance_to(_waypoints[i])
		if d < best:
			best = d
			_wp = i
	if _waypoints.size() > 1 and best < 4.0:
		_wp = (_wp + 1) % _waypoints.size()
	_circle_sign = 1.0 if randf() < 0.5 else -1.0
	return self


func _ready() -> void:
	add_to_group("guard")
	collision_layer = Room.ACTOR_LAYER
	collision_mask = Room.SOLID_LAYER | Room.HAZARD_LAYER | Room.LEDGE_LAYER | Room.ACTOR_LAYER
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.5
	_shape.shape = circle
	add_child(_shape)

	body_node = Node2D.new()
	add_child(body_node)
	sprite = Art.feet_sprite(type.sprite_se)
	body_node.add_child(sprite)
	var h := sprite.texture.get_height() if sprite.texture else 40
	life = Life.new()
	add_child(life)
	life.setup(body_node, sprite, int(h * 0.4))
	daze = DazeStars.new()
	daze.position = Vector2(0, -h + 2)
	daze.z_index = 60
	daze.visible = false
	body_node.add_child(daze)

	lantern_pivot = Node2D.new()
	lantern_pivot.scale = Vector2(1.0, 0.5)
	lantern_pivot.position = Vector2(0, -10)
	body_node.add_child(lantern_pivot)
	lantern_rot = Node2D.new()
	lantern_pivot.add_child(lantern_rot)
	lantern = PointLight2D.new()
	lantern.texture = Art.tex("light_cone")
	lantern.color = type.lantern_color
	lantern.energy = 1.0
	lantern_rot.add_child(lantern)
	var glow := PointLight2D.new()
	glow.texture = Art.tex("light_radial")
	glow.texture_scale = 0.45
	glow.color = type.lantern_color
	glow.energy = 0.7
	glow.position = Vector2(0, -12)
	glow.name = "Glow"
	body_node.add_child(glow)
	_glow = glow

	mark = Sprite2D.new()
	mark.position = Vector2(0, -h - 6)
	mark.z_index = 60
	mark.visible = false
	body_node.add_child(mark)
	meter = AwarenessMeter.new()
	meter.position = Vector2(0, -h - 1)
	meter.z_index = 60
	body_node.add_child(meter)
	glint = Sprite2D.new()
	glint.z_index = 61
	glint.visible = false
	body_node.add_child(glint)

	cone = Polygon2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	cone.material = mat
	if room and room.cone_layer:
		room.cone_layer.add_child(cone)
	NoiseBus.noise.connect(_on_noise)
	_floor_pos = global_position


func _exit_tree() -> void:
	if is_instance_valid(cone):
		cone.queue_free()
	if NoiseBus.noise.is_connected(_on_noise):
		NoiseBus.noise.disconnect(_on_noise)
	Game.release_attack_token(self)


# ============================================================== queries other scripts use

func grid_pos() -> Vector2:
	return Iso.screen_to_grid(global_position)


func cell() -> Vector2i:
	return Iso.cell_of_screen(global_position)


func is_hittable() -> bool:
	return state != S.KO and state != S.FALLING


func is_unaware() -> bool:
	return state != S.ALERT


func is_alert() -> bool:
	return state == S.ALERT


func is_ko() -> bool:
	return state == S.KO


func wants_token() -> bool:
	return state == S.ALERT and (_phase == "windup" or _phase == "recover")


func stands_on_floor() -> bool:
	return state != S.FALLING and state != S.KO and state != S.SHOVED


func is_heavy() -> bool:
	return type.heavy


## True when this guard's shield stops an attack coming from the player's grid position.
func blocks_attack_from(player_grid: Vector2) -> bool:
	if not type.blocks_front or state in [S.STUNNED, S.SHOVED, S.FALLING, S.KO]:
		return false
	var to := player_grid - grid_pos()
	if to.length() < 0.01:
		return true
	return absf(rad_to_deg(facing.angle_to(to))) <= 70.0


# ============================================================== frame

func _physics_process(delta: float) -> void:
	_state_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_update_senses(delta)
	match state:
		S.PATROL:
			_patrol(delta)
		S.SUSPICIOUS:
			_suspicious(delta)
		S.ALERT:
			_alert(delta)
		S.SEARCH:
			_search(delta)
		S.RETURN:
			if _walk_to(_waypoints[_wp], type.walk_speed, delta):
				_set_state(S.PATROL)
		S.STUNNED:
			_stunned(delta)
		S.SHOVED:
			_shoved_step()
		S.FALLING, S.KO:
			velocity = Vector2.ZERO
	if stands_on_floor() and room.is_walkable(cell()):
		_floor_pos = global_position
	_update_visuals(delta)


func _set_state(s: S) -> void:
	state = s
	_state_t = 0.0
	_phase = ""
	_phase_t = 0.0
	_path = PackedVector2Array()
	_path_goal = Vector2.INF


# ============================================================== senses

func _player() -> Node:
	if room == null or room.player == null or not is_instance_valid(room.player):
		return null
	return room.player


## Current sight range in tiles.
func sight_range() -> float:
	var r := type.sight_range
	if on_edge:
		r *= 1.2
	if state == S.ALERT:
		r *= 1.25
	return r


func sight_half_angle() -> float:
	return maxf(type.half_angle, 70.0) if state == S.ALERT else type.half_angle


## True when the player stands inside this guard's cone with nothing solid in between.
func can_see_player() -> bool:
	var p := _player()
	if p == null or not p.is_targetable() or state in [S.STUNNED, S.SHOVED, S.FALLING, S.KO]:
		return false
	var to: Vector2 = p.grid_pos() - grid_pos()
	var d := to.length()
	if d > sight_range():
		return false
	var close := state == S.ALERT and d <= 2.0
	if not close and d > 0.3 and absf(rad_to_deg(facing.angle_to(to))) > sight_half_angle():
		return false
	return room.line_of_sight(global_position + Vector2(0, -4), p.global_position + Vector2(0, -4))


func _update_senses(delta: float) -> void:
	if state == S.KO or state == S.FALLING:
		_sees = false
		return
	_sees = can_see_player()
	var p := _player()
	if _sees:
		var d: float = p.grid_pos().distance_to(grid_pos())
		var closeness := clampf(1.0 - d / sight_range(), 0.0, 1.0)
		awareness = minf(ALERT_AT, awareness + (30.0 + 110.0 * closeness) * delta)
		if state == S.ALERT:
			_last_known = p.global_position
			_lost_t = 0.0
		elif state in [S.STUNNED, S.SHOVED]:
			pass
		elif awareness >= ALERT_AT:
			_enter_alert(p.global_position)
		elif awareness >= SUSPICIOUS_AT:
			if state == S.PATROL or state == S.RETURN:
				_investigate(p.global_position)
			elif state == S.SUSPICIOUS or state == S.SEARCH:
				_goal = p.global_position
				_state_t = minf(_state_t, 1.0)
	elif state != S.ALERT:
		awareness = maxf(0.0, awareness - DECAY * delta)


func _on_noise(pos: Vector2, radius: float, source: Node) -> void:
	if source == self or state == S.KO or state == S.FALLING:
		return
	if Iso.tiles_between(pos, global_position) > radius:
		return
	if state == S.ALERT:
		if source != null and source.is_in_group("player"):
			_last_known = pos
			_lost_t = minf(_lost_t, 1.0)
		return
	awareness = minf(95.0, maxf(awareness + 25.0, 35.0))
	if state in [S.STUNNED, S.SHOVED]:
		return
	_investigate(pos)


## Another guard shouted: come and look.
func hear_alarm(pos: Vector2) -> void:
	if state == S.ALERT or not is_hittable() or state in [S.STUNNED, S.SHOVED]:
		return
	awareness = maxf(awareness, 45.0)
	_investigate(pos)


func _investigate(pos: Vector2) -> void:
	var first := state != S.SUSPICIOUS
	_goal = pos
	if first:
		_set_state(S.SUSPICIOUS)
		_phase = "turn"
		Sfx.play("suspicious", global_position, -4.0)
	else:
		_phase = "walk" if _phase == "look" else _phase
		_state_t = 0.0


func _enter_alert(target: Vector2, shout := true) -> void:
	var was := state
	_set_state(S.ALERT)
	awareness = ALERT_AT
	_last_known = target
	_lost_t = 0.0
	if not shout or was == S.ALERT:
		return
	_bark("Ekei!", Color(1.0, 0.4, 0.3))
	Sfx.play("alert", global_position)
	Game.record_alert(guard_id)
	for g in room.guards:
		if g != self and is_instance_valid(g) and Iso.tiles_between(g.global_position, global_position) <= ALARM_RADIUS:
			g.hear_alarm(target)


func _bark(text: String, color := Color(1, 1, 1)) -> void:
	Game.floating_text.emit(global_position + Vector2(0, -44 - elev), text, color)


# ============================================================== movement

func _turn_toward(dir: Vector2, delta: float, rate := TURN_RATE) -> void:
	if dir.length_squared() < 0.0001:
		return
	var a := facing.angle_to(dir.normalized())
	facing = facing.rotated(clampf(a, -rate * delta, rate * delta)).normalized()


func _move_grid(dir: Vector2, speed: float, delta: float, turn := true) -> void:
	velocity = Iso.grid_vel_to_screen(dir.normalized() * speed) if dir != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
	if turn and dir != Vector2.ZERO:
		_turn_toward(dir, delta)


func _stop() -> void:
	velocity = Vector2.ZERO


## Follows a path to a screen point. Returns true on arrival (or when no path exists).
func _walk_to(target: Vector2, speed: float, delta: float, repath := false) -> bool:
	_repath_t -= delta
	if _path_goal == Vector2.INF or _path_goal.distance_to(target) > 6.0 or (repath and _repath_t <= 0.0):
		_path = room.find_path(global_position, target)
		_path_i = 0
		_path_goal = target
		_repath_t = REPATH
	var me := grid_pos()
	if Iso.screen_to_grid(target).distance_to(me) < 0.15:
		_stop()
		return true
	if _path.is_empty():
		_stop()
		return true
	while _path_i < _path.size() and Iso.screen_to_grid(_path[_path_i]).distance_to(me) < 0.15:
		_path_i += 1
	if _path_i >= _path.size():
		_stop()
		return true
	var dir := Iso.screen_to_grid(_path[_path_i]) - me
	_move_grid(dir, speed, delta)
	return false


# ============================================================== states

func _patrol(delta: float) -> void:
	if _waypoints.size() == 1:
		if grid_pos().distance_to(Iso.screen_to_grid(_waypoints[0])) > 0.3:
			_walk_to(_waypoints[0], type.walk_speed, delta)
			return
		_stop()
		_look_t += delta
		var sway := sin(_look_t / LOOK_PERIOD * TAU)
		_turn_toward(_base_face.rotated(deg_to_rad(LOOK_SWAY) * sway), delta, 1.5)
		return
	if _wait > 0.0:
		_wait -= delta
		_stop()
		return
	if _walk_to(_waypoints[_wp], type.walk_speed, delta):
		_wp = (_wp + 1) % _waypoints.size()
		_wait = randf_range(1.0, 1.6)
		_path_goal = Vector2.INF


func _suspicious(delta: float) -> void:
	_phase_t += delta
	if _state_t >= SUSPICIOUS_GIVE_UP:
		_give_up()
		return
	match _phase:
		"turn":
			_stop()
			_turn_toward(Iso.screen_to_grid(_goal) - grid_pos(), delta, 4.0)
			if _phase_t >= 0.5:
				_phase = "walk"
				_phase_t = 0.0
		"walk":
			if _walk_to(_goal, type.walk_speed, delta) or grid_pos().distance_to(Iso.screen_to_grid(_goal)) < 0.8:
				_stop()
				_phase = "look"
				_phase_t = 0.0
				_look_face = facing
		"look":
			_stop()
			var sway := sin(_phase_t / 2.5 * TAU * 1.5)
			_turn_toward(_look_face.rotated(deg_to_rad(60.0) * sway), delta, 3.0)
			if _phase_t >= 2.5:
				_give_up()
		_:
			_phase = "turn"


func _give_up() -> void:
	_bark("...rats.", Color(0.85, 0.85, 0.75))
	_set_state(S.RETURN)


func _alert(delta: float) -> void:
	var p := _player()
	if p == null or not p.is_targetable():
		_release()
		_set_state(S.SEARCH)
		_search_target = Vector2.INF
		return
	if not _sees:
		_lost_t += delta
	if _phase == "windup" or _phase == "recover":
		_attacking(delta, p)
		return
	if _lost_t >= LOSE_SIGHT:
		_release()
		_set_state(S.SEARCH)
		_search_target = Vector2.INF
		_bark("Pou?", Color(1.0, 0.85, 0.4))
		return
	var to: Vector2 = p.grid_pos() - grid_pos()
	var d := to.length()
	if not _sees or d > 3.0:
		_walk_to(_last_known, type.chase_speed, delta, true)
		return
	_turn_toward(to, delta)
	var pick := _pick_attack(d)
	if pick != null and _cooldown <= 0.0 and absf(facing.angle_to(to)) < 0.5:
		if Game.request_attack_token(self):
			_begin_attack(pick)
			_stop()
			return
		_circle(to, d, delta)
		return
	if type.keep_distance > 1.2 and d < 1.2:
		_move_grid(-to, type.walk_speed, delta, false)
	elif d > type.keep_distance + 0.25:
		if Game.request_attack_token(self) or d > CIRCLE_DIST + 0.4:
			_move_grid(to, type.chase_speed * 0.7, delta, false)
		else:
			_circle(to, d, delta)
	else:
		_stop()


## Others wait their turn at about two tiles, sidestepping around the player.
func _circle(to: Vector2, d: float, delta: float) -> void:
	var tangent := to.orthogonal() * _circle_sign
	var radial := -to.normalized() * clampf(CIRCLE_DIST - d, -1.0, 1.0)
	_move_grid(tangent.normalized() * 0.6 + radial, type.walk_speed * 0.6, delta, false)
	if get_slide_collision_count() > 0:
		_circle_sign = -_circle_sign


func _pick_attack(d: float) -> AttackData:
	var total := 0.0
	var options: Array = []
	for a in type.attacks:
		if a is AttackData and a.reach + 0.1 >= d:
			options.append(a)
			total += a.weight
	if options.is_empty():
		return null
	var r := randf() * total
	for a in options:
		r -= a.weight
		if r <= 0.0:
			return a
	return options[-1]


func _begin_attack(a: AttackData) -> void:
	_attack = a
	_phase = "windup"
	_phase_t = 0.0
	var glint_name := "glint_white" if a.parryable else "glint_red"
	glint.texture = Art.tex(glint_name)
	glint.visible = true
	Sfx.play(glint_name, global_position, -2.0, 0.0)


func _attacking(delta: float, p: Node) -> void:
	_phase_t += delta
	_stop()
	if _phase == "windup":
		if _phase_t < _attack.windup - 0.15:
			_turn_toward(p.grid_pos() - grid_pos(), delta, 3.0)
		if _phase_t >= _attack.windup:
			glint.visible = false
			_strike(p)
			_phase = "recover"
			_phase_t = 0.0
	elif _phase_t >= _attack.recover:
		_release()
		_phase = ""
		_cooldown = randf_range(0.4, 0.9)


func _strike(p: Node) -> void:
	Fx.swing(room.world, global_position + Vector2(0, -elev), facing, _attack.reach, Color(1, 0.85, 0.7, 0.8))
	Sfx.play("swing", global_position, -4.0)
	var to: Vector2 = p.grid_pos() - grid_pos()
	if to.length() > _attack.reach + 0.3:
		return
	if to.length() > 0.3 and absf(rad_to_deg(facing.angle_to(to))) > _attack.half_angle:
		return
	if p.try_parry(_attack, self):
		_release()
		_stun(0.9)
		return
	p.take_hit(_attack.damage, global_position, _attack.knockback)


func _release() -> void:
	glint.visible = false
	Game.release_attack_token(self)


func _search(delta: float) -> void:
	if _state_t >= SEARCH_TIME:
		on_edge = true
		_set_state(S.RETURN)
		return
	if _search_target == Vector2.INF:
		_search_target = _last_known
		_phase = "walk"
	match _phase:
		"walk":
			if _walk_to(_search_target, type.walk_speed * 1.2, delta):
				_phase = "look"
				_phase_t = 0.0
				_look_face = facing
		"look":
			_phase_t += delta
			_stop()
			_turn_toward(_look_face.rotated(sin(_phase_t * 2.5) * 1.1), delta, 3.0)
			if _phase_t >= 1.6:
				_search_target = _random_point_near(_last_known, SEARCH_RADIUS)
				_path_goal = Vector2.INF
				_phase = "walk"


func _random_point_near(pos: Vector2, radius: float) -> Vector2:
	var centre := Iso.screen_to_grid(pos)
	for i in 12:
		var g := centre + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		var c := Iso.cell_of_grid(g)
		if room.is_walkable(c) and room.reachable(room.nearest_walkable(cell()), c):
			return room.cell_center(c)
	return pos


func _stun(t: float) -> void:
	_release()
	var was_alert := state == S.ALERT
	_set_state(S.STUNNED)
	_stun_t = t
	_shake_t = 0.18
	life.squash(Vector2(1.16, 0.86))
	if was_alert:
		awareness = ALERT_AT


func _stunned(delta: float) -> void:
	velocity = Iso.grid_vel_to_screen(_knock)
	_knock = _knock.move_toward(Vector2.ZERO, delta * 6.0)
	move_and_slide()
	if _state_t >= _stun_t:
		var p := _player()
		_enter_alert(p.global_position if p else global_position, awareness < ALERT_AT)


# ============================================================== being hit

## `force` scales the knockback (ripostes, backstabs and combo finishers hit harder).
func take_damage(dmg: int, from_screen_pos: Vector2, force := 1.0) -> void:
	if not is_hittable():
		return
	hp -= dmg
	Juice.flash(sprite, 0.07)
	_shake_t = 0.14
	life.squash(Vector2(0.84, 1.12) if force > 1.0 else Vector2(0.9, 1.07))
	var away := (grid_pos() - Iso.screen_to_grid(from_screen_pos)).normalized()
	if hp <= 0:
		knock_out(false, null)
		return
	_knock = away * 0.45 * force * 6.0
	if state == S.ALERT:
		_last_known = from_screen_pos
		if _phase == "":
			velocity = Iso.grid_vel_to_screen(_knock)
			move_and_slide()
	elif state != S.STUNNED and state != S.SHOVED:
		_enter_alert(from_screen_pos)


func on_blocked(player: Node) -> void:
	_turn_toward(player.grid_pos() - grid_pos(), 1.0, 10.0)
	_cooldown = 0.0
	if state != S.ALERT:
		_enter_alert(player.global_position)


func stun_by_torch(_by: Node) -> void:
	if not is_hittable():
		return
	_stun(type.thrust_stun)
	_knock = Vector2.ZERO
	_bark("Aaah!", Color(1.0, 0.7, 0.4))


## Pushed one tile along an eight-way grid direction.
func shoved(dir8: Vector2i, _by: Node) -> void:
	if not is_hittable() or state == S.SHOVED:
		return
	_release()
	var from_c := cell()
	var to_c := from_c + dir8
	_shove_from = global_position
	_shove_end = "stun"
	if room.is_hazard(to_c) or room.is_well(to_c):
		_shove_end = "fall"
	elif not room.is_walkable(to_c):
		to_c = from_c
	elif room.elevation_px(from_c) - room.elevation_px(to_c) >= 12.0:
		_shove_end = "fall"
	_shove_to = room.cell_center(to_c) if to_c != from_c else global_position
	_set_state(S.SHOVED)


func _shoved_step() -> void:
	var k := clampf(_state_t / 0.2, 0.0, 1.0)
	global_position = _shove_from.lerp(_shove_to, k)
	if k < 1.0:
		return
	if _shove_end == "fall":
		fall()
	else:
		_stun(0.6)


func fall() -> void:
	if state == S.FALLING or state == S.KO:
		return
	_release()
	_set_state(S.FALLING)
	life.shadow.visible = false
	_shape.set_deferred("disabled", true)
	Sfx.play("fall", global_position)
	var tw := create_tween()
	tw.tween_property(body_node, "position:y", body_node.position.y + 18.0, 0.5)
	tw.parallel().tween_property(body_node, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): knock_out(true, null))


## Down for good: drops obols (more for environmental takedowns) and sometimes a sword.
func knock_out(env: bool, _by: Node) -> void:
	if state == S.KO:
		return
	var fell := state == S.FALLING
	_release()
	_set_state(S.KO)
	awareness = 0.0
	collision_layer = 0
	collision_mask = 0
	_shape.set_deferred("disabled", true)
	lantern.enabled = false
	(body_node.get_node("Glow") as PointLight2D).enabled = false
	cone.visible = false
	mark.visible = false
	meter.visible = false
	daze.visible = false
	if not fell:
		# Topple: a beat of stagger, then down with a thud and a puff of dust.
		life.enabled = false
		body_node.scale = Vector2.ONE
		Juice.flash(sprite, 0.09)
		var tw := create_tween()
		tw.tween_property(sprite, "rotation", deg_to_rad(-12.0 if sprite.flip_h else 12.0), 0.08)
		tw.tween_property(sprite, "rotation", deg_to_rad(-84.0 if sprite.flip_h else 84.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(sprite, "position", Vector2(0, -4), 0.2)
		tw.tween_property(sprite, "rotation", deg_to_rad(-78.0 if sprite.flip_h else 78.0), 0.08)
		tw.tween_callback(func():
			Fx.dust(room.world, global_position, 8, 11.0)
			ShakeCamera.add_trauma(0.16))
		tw.parallel().tween_property(sprite, "modulate", Color(0.55, 0.55, 0.62), 0.4)
		Sfx.play("ko", global_position)
	var drop := randi_range(type.drop_min, type.drop_max)
	if env:
		drop = roundi(drop * 1.5)
	var at := _floor_pos if fell else global_position
	room.spawn_obols(at, drop)
	if type.id == &"watchman" and Game.weapon_id == "":
		room.spawn_sword(at)
	Game.stats.kos += 1
	if env:
		Game.stats.env_kos += 1


# ============================================================== visuals

func _update_visuals(delta: float) -> void:
	if state == S.KO:
		return
	var target_elev := room.elevation_px(cell())
	elev = move_toward(elev, target_elev, delta * 90.0)
	if state != S.FALLING:
		body_node.position.y = -roundf(elev)
	life.ground_y = elev
	# Stagger: a short horizontal shudder when hit or stunned.
	_shake_t = maxf(0.0, _shake_t - delta)
	sprite.position.x = roundf(sin(_shake_t * 110.0) * 1.4) if _shake_t > 0.0 else 0.0
	daze.visible = state == S.STUNNED and _stun_t > 0.5

	var sd := Iso.screen_dir(facing)
	var front := sd.y >= -0.01
	sprite.texture = Art.tex(type.sprite_se if front else type.sprite_ne)
	sprite.flip_h = sd.x < 0.0
	lantern_rot.rotation = atan2(sd.y * 2.0, sd.x)
	lantern.texture_scale = sight_range() * 22.6 / 64.0
	# Lights add up: where the lantern lands on Cedalion's torch pool the floor clips to white,
	# so the lantern and its glow ease off as he gets close.
	var near := 0.0
	var pl := _player()
	if pl:
		near = 1.0 - smoothstep(1.5, 5.0, Iso.screen_to_grid(pl.global_position).distance_to(Iso.screen_to_grid(global_position)))
	var moon: float = room.moonlight_at(global_position) if room else 0.0
	lantern.energy = (0.9 if state != S.STUNNED else 0.45) * (1.0 - 0.45 * maxf(near, moon))
	_glow.energy = 0.7 * (1.0 - 0.6 * near)
	# Red is the enemy: an alert guard's lantern burns red.
	var lc := type.lantern_color.lerp(Color(1.0, 0.28, 0.22), 0.6) if state == S.ALERT else type.lantern_color
	lantern.color = lantern.color.lerp(lc, clampf(delta * 6.0, 0.0, 1.0))

	var side := -1.0 if sprite.flip_h else 1.0
	glint.position = Vector2(8.0 * side, -22.0 + sin(_phase_t * 30.0))
	glint.scale = Vector2.ONE * (1.0 + 0.3 * clampf(_phase_t / maxf(0.01, _attack.windup if _attack else 1.0), 0.0, 1.0))

	match state:
		S.ALERT:
			mark.texture = Art.tex("mark_alert")
			mark.visible = true
		S.SUSPICIOUS, S.SEARCH:
			mark.texture = Art.tex("mark_question")
			mark.visible = true
		_:
			mark.visible = false
	meter.value = awareness / ALERT_AT
	meter.visible = awareness > 0.5 and state != S.ALERT
	meter.queue_redraw()
	_update_cone()


func _update_cone() -> void:
	if not is_instance_valid(cone):
		return
	cone.visible = state != S.FALLING and state != S.KO
	if not cone.visible:
		return
	var eye := global_position
	var g0 := grid_pos()
	var r := sight_range()
	var half := deg_to_rad(sight_half_angle())
	var pts := PackedVector2Array()
	pts.append(cone.get_parent().to_local(eye) + Vector2(0, -elev))
	var rays := 16
	for i in rays + 1:
		var a := lerpf(-half, half, float(i) / rays)
		var end_g := g0 + facing.rotated(a) * r
		var hit := room.ray_end(eye, Iso.grid_to_screen(end_g))
		var lift := room.elevation_px(Iso.cell_of_screen(hit))
		pts.append(cone.get_parent().to_local(hit) + Vector2(0, -lift))
	cone.polygon = pts
	var c := Color(1.0, 0.95, 0.75, 0.15)
	if state == S.ALERT:
		c = Color(1.0, 0.25, 0.2, 0.2)
	elif state == S.SUSPICIOUS or state == S.SEARCH or awareness >= SUSPICIOUS_AT:
		c = Color(1.0, 0.85, 0.2, 0.18)
	elif state == S.STUNNED:
		c.a = 0.06
	cone.color = c


## Three little stars circling a stunned guard's head.
class DazeStars extends Node2D:
	var _t := 0.0

	func _process(delta: float) -> void:
		if not visible:
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for i in 3:
			var a := _t * 5.0 + i * TAU / 3.0
			var p := Vector2(cos(a) * 6.0, sin(a) * 2.5).round()
			var c := Color(1.0, 0.85, 0.35) if sin(a) > 0.0 else Color(0.8, 0.6, 0.25)
			draw_rect(Rect2(p, Vector2(1, 1)), c)
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 1)), Color(c, 0.5))


## The thin bar under the mark that fills as a guard grows suspicious.
class AwarenessMeter extends Node2D:
	var value := 0.0

	func _draw() -> void:
		var w := 12.0
		draw_rect(Rect2(-w / 2.0, 0, w, 2), Color(0, 0, 0, 0.6))
		var c := Color(1.0, 0.85, 0.25) if value < 1.0 else Color(1.0, 0.3, 0.2)
		draw_rect(Rect2(-w / 2.0, 0, w * clampf(value, 0.0, 1.0), 2), c)
