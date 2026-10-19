class_name Player
extends CharacterBody2D
## Cedalion. Moves in eight screen-relative directions, jumps fixed distances, sneaks, runs, and
## fights with a sword in the right hand and a torch in the left.

signal died

enum S { NORMAL, ATTACK, PARRY, DODGE, JUMP, HURT, SHOVE, THRUST, FALL, DEAD, LOCKED }

## Tiles per second.
const WALK := 2.6
const RUN := 4.2
const SNEAK := 1.5
const STEP_TIME := {"walk": 0.33, "run": 0.24, "sneak": 0.45}
const STEP_NOISE := {"walk": 2.0, "run": 5.0, "sneak": 0.0}
const TORCH_RADIUS := 96.0
const JUMP_TIME := 0.42
const DODGE_TIME := 0.28
const DODGE_TILES := 1.3
## Movement ramps (tiles/s²): quick enough to feel direct, slow enough to feel like a body.
const ACCEL := 26.0
const DECEL := 20.0
## A press this many seconds before an action is allowed still fires it (attack chains, a dodge
## pressed during a swing, a jump pressed while landing).
const BUFFER := 0.15
const BUFFERED := ["attack", "parry", "dodge", "jump", "shove", "thrust"]

var room: Room
var state := S.NORMAL
var facing := Vector2(1, 1).normalized()
var elev := 0.0
var gait := "walk"
var hold_progress := 0.0
var holding: Interactable = null
var focus: Interactable = null

var _state_t := 0.0
var _invuln := 0.0
var _cool := {"dodge": 0.0, "shove": 0.0, "thrust": 0.0, "toss": 0.0, "parry": 0.0, "attack": 0.0}
var _combo := 0
var _combo_window := 0.0
var _hit_done := false
var _parry_t := 0.0
var _riposte_t := 0.0
var _step_t := 0.0
var _jump_from := Vector2.ZERO
var _jump_to := Vector2.ZERO
var _dodge_dir := Vector2.ZERO
var _knock := Vector2.ZERO
var _told_unarmed := false
var _flicker := FastNoiseLite.new()
var _noise_t := 0.0
var _mouse_aim_t := 0.0
var _gvel := Vector2.ZERO
var _buf := {}
var _aiming := false
var _aim_t := 0.0
var _aim_preview: AimPreview

var body_node: Node2D
var sprite: Sprite2D
var torch: PointLight2D
var torch_embers: CPUParticles2D
var camera: ShakeCamera
var life: Life


func _ready() -> void:
	add_to_group("player")
	collision_layer = Room.ACTOR_LAYER
	collision_mask = Room.SOLID_LAYER | Room.HAZARD_LAYER | Room.LEDGE_LAYER | Room.ACTOR_LAYER
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	body_node = Node2D.new()
	add_child(body_node)
	sprite = Art.feet_sprite("cedalion_se")
	body_node.add_child(sprite)
	life = Life.new()
	add_child(life)
	life.setup(body_node, sprite, 12)
	torch = PointLight2D.new()
	torch.texture = Art.tex("light_radial")
	torch.texture_scale = TORCH_RADIUS / 64.0
	torch.color = Color(1.0, 0.72, 0.42)
	torch.energy = 1.05
	torch.scale = Vector2(1.0, 0.72)
	torch.position = Vector2(6, -16)
	body_node.add_child(torch)
	torch_embers = Atmosphere.embers(5, 1.0)
	body_node.add_child(torch_embers)
	_aim_preview = AimPreview.new()
	_aim_preview.z_index = 50
	_aim_preview.top_level = true
	_aim_preview.visible = false
	_aim_preview.material = Atmosphere.unshaded()
	add_child(_aim_preview)
	_flicker.frequency = 9.0
	_flicker.seed = 3

	camera = ShakeCamera.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.base_offset = Vector2(0, -12)
	camera.offset = camera.base_offset
	add_child(camera)


func set_camera_limits(r: Rect2) -> void:
	var view := Vector2(480, 270)
	if r.size.x < view.x:
		r = r.grow_individual((view.x - r.size.x) / 2.0, 0, (view.x - r.size.x) / 2.0, 0)
	if r.size.y < view.y:
		r = r.grow_individual(0, (view.y - r.size.y) / 2.0, 0, (view.y - r.size.y) / 2.0)
	camera.limit_left = int(r.position.x)
	camera.limit_top = int(r.position.y)
	camera.limit_right = int(r.end.x)
	camera.limit_bottom = int(r.end.y)
	camera.reset_smoothing()


func grid_pos() -> Vector2:
	return Iso.screen_to_grid(global_position)


func cell() -> Vector2i:
	return Iso.cell_of_screen(global_position)


func stands_on_floor() -> bool:
	return state != S.JUMP and state != S.FALL and state != S.DEAD


func is_heavy() -> bool:
	var a := Game.armour()
	return a != null and a.heavy


func is_targetable() -> bool:
	return state != S.DEAD and state != S.FALL and state != S.LOCKED


func is_sneaking() -> bool:
	return gait == "sneak"


func is_parrying() -> bool:
	return state == S.PARRY and _parry_t > 0.0


func lock(on: bool) -> void:
	if on:
		state = S.LOCKED
		velocity = Vector2.ZERO
	elif state == S.LOCKED:
		state = S.NORMAL


# ============================================================== frame

func _physics_process(delta: float) -> void:
	for k in _cool:
		_cool[k] = maxf(0.0, _cool[k] - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_riposte_t = maxf(0.0, _riposte_t - delta)
	_combo_window = maxf(0.0, _combo_window - delta)
	_parry_t = maxf(0.0, _parry_t - delta)
	_state_t += delta
	Sfx.listener_pos = global_position
	for a in BUFFERED:
		if Input.is_action_just_pressed(a):
			_buf[a] = BUFFER
		else:
			_buf[a] = maxf(0.0, _buf.get(a, 0.0) - delta)

	match state:
		S.NORMAL:
			_normal(delta)
		S.ATTACK:
			_attacking(delta)
		S.PARRY:
			_slide(0.0)
			if _state_t >= 0.32:
				_set_state(S.NORMAL)
		S.DODGE:
			_dodging(delta)
		S.JUMP:
			_jumping()
		S.HURT:
			velocity = Iso.grid_vel_to_screen(_knock)
			_knock = _knock.move_toward(Vector2.ZERO, delta * 8.0)
			move_and_slide()
			if _state_t >= 0.3:
				_set_state(S.NORMAL)
		S.SHOVE, S.THRUST:
			_slide(0.0)
			if _state_t >= 0.28:
				_set_state(S.NORMAL)
		S.FALL, S.DEAD, S.LOCKED:
			velocity = Vector2.ZERO
	_update_visuals(delta)


func _set_state(s: S) -> void:
	if s == S.NORMAL and state != S.NORMAL:
		# Carry some momentum out of a dodge or a knock instead of stopping dead.
		_gvel = Iso.screen_to_grid(velocity).limit_length(RUN) * 0.5
	state = s
	_state_t = 0.0
	if s != S.NORMAL:
		_aiming = false


## Consumes a buffered press of an action.
func _take(action: String) -> bool:
	if _buf.get(action, 0.0) > 0.0:
		_buf[action] = 0.0
		return true
	return false


func _slide(speed: float) -> void:
	velocity = Iso.grid_vel_to_screen(facing * speed)
	move_and_slide()


func _normal(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var dir := Iso.input_to_grid_dir(input)
	gait = "walk"
	var speed := WALK
	if Input.is_action_pressed("sneak"):
		gait = "sneak"
		speed = SNEAK
	elif Input.is_action_pressed("run"):
		gait = "run"
		speed = RUN
	var target := dir * speed
	var rate := ACCEL if dir != Vector2.ZERO else DECEL
	if dir != Vector2.ZERO and _gvel.dot(target) < 0.0:
		rate *= 1.8
	_gvel = _gvel.move_toward(target, rate * delta)
	velocity = Iso.grid_vel_to_screen(_gvel)
	move_and_slide()
	_gvel = Iso.screen_to_grid(velocity)
	if dir != Vector2.ZERO:
		facing = dir
		_step_t += delta
		if _step_t >= STEP_TIME[gait]:
			_step_t = 0.0
			_footstep()
	else:
		_step_t = STEP_TIME[gait] * 0.6

	_update_focus(delta)
	if _aiming:
		_aim_t += delta
		if not Input.is_action_pressed("toss"):
			_aiming = false
			_toss()
	if _buf.get("attack", 0.0) > 0.0 and _cool.attack <= 0.0:
		_take("attack")
		_start_attack()
	elif _cool.parry <= 0.0 and _take("parry"):
		_start_parry()
	elif _cool.dodge <= 0.0 and _take("dodge"):
		_start_dodge(dir)
	elif _take("jump"):
		_start_jump()
	elif _cool.shove <= 0.0 and _take("shove"):
		_start_shove()
	elif _cool.thrust <= 0.0 and _take("thrust"):
		_start_thrust()
	elif Input.is_action_just_pressed("toss") and _cool.toss <= 0.0:
		# Aim while held (the preview shows the arc and who will hear it); throw on release.
		_aiming = true
		_aim_t = 0.0
	elif Input.is_action_just_pressed("heal"):
		if not Game.eat_pomegranate():
			Game.toast.emit("No pomegranates." if Game.pomegranates == 0 else "You're already at full health.")


func _footstep() -> void:
	var c := cell()
	var radius: float = STEP_NOISE[gait]
	if gait != "sneak":
		var a := Game.armour()
		if a:
			radius += a.noise_bonus
	if room.ch(c) == "~":
		radius = maxf(radius, 3.0)
	if room.is_masked(global_position):
		radius = 0.0
	if radius > 0.0:
		NoiseBus.emit_noise(global_position, radius, self)
	if gait != "sneak":
		Sfx.play("step", null, -16.0 if gait == "walk" else -10.0, 0.15)
	if gait == "run" and room:
		Fx.dust(room.world, global_position + Vector2(0, -elev), 3, 5.0)


# ============================================================== interaction

func _update_focus(delta: float) -> void:
	focus = room.closest_interactable(global_position) if room else null
	if focus == null:
		holding = null
		hold_progress = 0.0
		return
	if focus.hold_time > 0.0:
		if Input.is_action_pressed("interact"):
			if holding != focus:
				holding = focus
				hold_progress = 0.0
			hold_progress += delta / focus.hold_time
			if hold_progress >= 1.0:
				holding = null
				hold_progress = 0.0
				focus.use(self)
		else:
			holding = null
			hold_progress = 0.0
	elif Input.is_action_just_pressed("interact"):
		focus.use(self)


# ============================================================== combat

func _guards_in_front(reach: float, half_deg: float) -> Array:
	var out: Array = []
	if room == null:
		return out
	var me := grid_pos()
	for g in room.guards:
		if not is_instance_valid(g) or not g.is_hittable():
			continue
		var to: Vector2 = g.grid_pos() - me
		var d := to.length()
		if d > reach + 0.35:
			continue
		if d > 0.35 and absf(rad_to_deg(facing.angle_to(to))) > half_deg:
			continue
		out.append(g)
	out.sort_custom(func(a, b): return a.grid_pos().distance_to(me) < b.grid_pos().distance_to(me))
	return out


func _start_attack() -> void:
	var w := Game.weapon()
	if w == null:
		if not _told_unarmed:
			_told_unarmed = true
			Game.toast.emit("You have no sword. Shove guards (F) into the well, or take a sword from the rack.")
		return
	if _cool.attack > 0.0:
		return
	_combo = (_combo + 1) % 3 if _combo_window > 0.0 else 0
	_hit_done = false
	_set_state(S.ATTACK)
	_aim_at_nearest(w.reach + 0.6)
	life.squash(Vector2(1.14, 0.9) if _combo < 2 else Vector2(1.22, 0.84))
	Sfx.play("swing", null, -6.0, 0.12)


func _aim_at_nearest(reach: float) -> void:
	var near := _guards_in_front(reach, 100.0)
	if near.size() > 0:
		facing = (near[0].grid_pos() - grid_pos()).normalized()


func _attacking(delta: float) -> void:
	var w := Game.weapon()
	var dur := w.swing_time if w else 0.4
	_slide(0.6 if _state_t < dur * 0.4 else 0.0)
	if not _hit_done and _state_t >= dur * 0.35:
		_hit_done = true
		_resolve_hit(w)
	if _hit_done and _state_t >= dur * 0.6 and _buf.get("attack", 0.0) > 0.0 and _combo < 2:
		# Chain the next swing of the combo straight from this one's follow-through.
		_buf["attack"] = 0.0
		_combo_window = 0.45
		_start_attack()
		return
	if _hit_done and _cool.dodge <= 0.0 and _take("dodge"):
		_start_dodge(Iso.input_to_grid_dir(Input.get_vector("move_left", "move_right", "move_up", "move_down")))
		return
	if _state_t >= dur:
		_combo_window = 0.45
		_set_state(S.NORMAL)


func _resolve_hit(w: WeaponData) -> void:
	Fx.swing(room.world, global_position + Vector2(0, -elev), facing, w.reach)
	var targets := _guards_in_front(w.reach, 70.0)
	var hit_any := false
	for g in targets.slice(0, 1):
		hit_any = true
		var to_me: Vector2 = (grid_pos() - g.grid_pos()).normalized()
		var behind: bool = g.facing.dot(to_me) < -0.25
		var unaware: bool = g.is_unaware()
		if g.blocks_attack_from(grid_pos()) and not w.breaks_shields:
			g.on_blocked(self)
			Fx.sparks(room.world, g.global_position + Vector2(0, -16))
			Sfx.play("shield", g.global_position)
			ShakeCamera.add_trauma(0.18)
			Juice.freeze(get_tree(), 0.04)
			NoiseBus.emit_noise(global_position, 8.0, self)
			continue
		var dmg := w.damage
		var heavy := false
		if _riposte_t > 0.0:
			dmg *= 2
			_riposte_t = 0.0
			heavy = true
		if unaware and behind:
			if w.backstab_ko:
				g.knock_out(false, self)
				Sfx.play("ko", g.global_position)
				Juice.freeze(get_tree(), 0.12)
				ShakeCamera.add_trauma(0.4)
				ShakeCamera.punch(0.04)
				continue
			dmg *= 2
			heavy = true
		g.take_damage(dmg, global_position, 1.8 if heavy or _combo == 2 else 1.0)
		Fx.sparks(room.world, g.global_position + Vector2(0, -14), 8 if heavy else 5, heavy)
		Sfx.play("hit", g.global_position)
		NoiseBus.emit_noise(global_position, 8.0, self)
		Juice.freeze(get_tree(), 0.1 if heavy else 0.065)
		ShakeCamera.add_trauma(0.38 if heavy else 0.22)
	# pots and jars
	var me := grid_pos()
	for b in get_tree().get_nodes_in_group("breakable"):
		var pos: Vector2 = b.get_parent().global_position
		var to := Iso.screen_to_grid(pos) - me
		if to.length() <= w.reach + 0.6 and (to.length() < 0.4 or absf(rad_to_deg(facing.angle_to(to))) <= 75.0):
			b.hit(global_position)
			hit_any = true
			break
	if not hit_any:
		NoiseBus.emit_noise(global_position, 1.0, self)


func _start_parry() -> void:
	var w := Game.weapon()
	if w == null:
		return
	_set_state(S.PARRY)
	_parry_t = w.parry_window
	_cool.parry = 0.45
	_aim_at_nearest(2.5)


## Called by a guard at the moment its attack lands. Returns true if Cedalion parried it.
func try_parry(attack: AttackData, guard: Node) -> bool:
	if not is_parrying() or not attack.parryable:
		return false
	_riposte_t = 1.0
	_parry_t = 0.0
	var clash: Vector2 = (global_position + guard.global_position) * 0.5 + Vector2(0, -14)
	Fx.sparks(room.world, clash, 12, true)
	Fx.ring(room.world, clash)
	Sfx.play("parry")
	NoiseBus.emit_noise(global_position, 8.0, self)
	# The perfect-parry beat: a frozen instant, then a short slow-motion breath to riposte in.
	Juice.flash(sprite, 0.06, Color(0.85, 0.92, 1.0))
	ShakeCamera.add_trauma(0.3)
	ShakeCamera.punch(0.07, 0.35)
	_parry_beat()
	return true


func _parry_beat() -> void:
	await Juice.freeze(get_tree(), 0.09)
	Juice.slowmo(get_tree(), 0.3, 0.35)


func _start_dodge(dir: Vector2) -> void:
	_dodge_dir = dir if dir != Vector2.ZERO else -facing
	_set_state(S.DODGE)
	_invuln = 0.25
	_cool.dodge = 0.55
	Sfx.play("dodge", null, -8.0)
	life.squash(Vector2(1.25, 0.82))
	if room:
		Fx.dust(room.world, global_position + Vector2(0, -elev), 5, 7.0)


func _dodging(_delta: float) -> void:
	velocity = Iso.grid_vel_to_screen(_dodge_dir * (DODGE_TILES / DODGE_TIME))
	move_and_slide()
	if _state_t >= DODGE_TIME:
		_set_state(S.NORMAL)


func _start_shove() -> void:
	var near := _guards_in_front(1.2, 80.0)
	_cool.shove = 0.8
	_set_state(S.SHOVE)
	Sfx.play("shove", null, -6.0)
	if near.is_empty():
		return
	var g = near[0]
	facing = (g.grid_pos() - grid_pos()).normalized()
	g.shoved(Iso.snap_dir8(facing), self)
	NoiseBus.emit_noise(global_position, 2.0, self)


func _start_thrust() -> void:
	_cool.thrust = 1.0
	_set_state(S.THRUST)
	var near := _guards_in_front(1.15, 70.0)
	Fx.sparks(room.world, global_position + Vector2(0, -14) + Iso.grid_to_screen(facing * 0.6), 4)
	Sfx.play("torch", null, -4.0)
	NoiseBus.emit_noise(global_position, 3.0, self)
	if near.size() > 0:
		near[0].stun_by_torch(self)


## Where a knucklebone thrown now would land: at the mouse if it moved lately, else 4 tiles ahead,
## never more than 6 tiles away.
func _toss_target() -> Vector2:
	var target: Vector2
	var mouse := get_global_mouse_position()
	var use_mouse := _mouse_aim_t > 0.0
	if use_mouse:
		target = mouse
	else:
		target = global_position + Iso.grid_to_screen(facing * 4.0)
	var g0 := grid_pos()
	var g1 := Iso.screen_to_grid(target)
	if g0.distance_to(g1) > 6.0:
		g1 = g0 + (g1 - g0).normalized() * 6.0
		target = Iso.grid_to_screen(g1)
	# It can't fly through a wall (it clears pots and columns): it drops just short.
	if room:
		var from := global_position + Vector2(0, -4)
		var hit := room.wall_ray_end(from, target + Vector2(0, -4))
		if hit.distance_to(target + Vector2(0, -4)) > 1.0:
			target = from + (hit - from).limit_length(maxf(0.0, from.distance_to(hit) - 6.0)) + Vector2(0, 4)
	return target


func _toss() -> void:
	_cool.toss = 0.6
	var target := _toss_target()
	var k := Knucklebone.new().setup(room, global_position, target)
	room.world.add_child(k)
	Sfx.play("toss", null, -10.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_aim_t = 3.0


func _process(delta: float) -> void:
	# A held toss shows its arc once it is clearly a hold, not a tap.
	_aim_preview.visible = _aiming and _aim_t > 0.1 and state == S.NORMAL
	if _aim_preview.visible:
		_aim_preview.start = global_position + Vector2(0, -elev)
		_aim_preview.target = _toss_target()
		_aim_preview.queue_redraw()
	_mouse_aim_t = maxf(0.0, _mouse_aim_t - delta)


## Hit by a guard. Returns true if the hit landed.
func take_hit(damage: int, from_pos: Vector2, knockback_tiles: float) -> bool:
	if _invuln > 0.0 or not is_targetable() or state == S.JUMP:
		return false
	Game.damage(damage)
	Sfx.play("hurt")
	_invuln = 0.8
	var away := (grid_pos() - Iso.screen_to_grid(from_pos)).normalized()
	_knock = away * knockback_tiles * 6.0
	_set_state(S.HURT)
	sprite.modulate = Color(1.0, 0.35, 0.35)
	Juice.flash(sprite, 0.08, Color(1.0, 0.35, 0.3))
	Juice.freeze(get_tree(), 0.08)
	ShakeCamera.add_trauma(0.5)
	life.squash(Vector2(1.25, 0.8))
	if Game.hp <= 0:
		_die()
	return true


# ============================================================== jumping and falling

func _start_jump() -> void:
	var d := Iso.snap_dir8(facing)
	var step := d * (2 if (d.x == 0 or d.y == 0) else 1)
	var from_c := cell()
	var to_c := from_c + step
	var mid := from_c + Vector2i(signi(step.x), signi(step.y))
	var ok := not _is_solid(mid) and not _is_solid(to_c) \
			and absf(room.elevation_px(to_c) - room.elevation_px(from_c)) < 12.0
	_jump_from = global_position
	_jump_to = room.cell_center(to_c) if ok else global_position
	_set_state(S.JUMP)
	life.squash(Vector2(0.78, 1.25))
	Sfx.play("jump", null, -6.0)


func _is_solid(c: Vector2i) -> bool:
	return not room.is_walkable(c) and not room.is_hazard(c)


func _jumping() -> void:
	var k := clampf(_state_t / JUMP_TIME, 0.0, 1.0)
	global_position = _jump_from.lerp(_jump_to, k)
	if k >= 1.0:
		_set_state(S.NORMAL)
		Sfx.play("land", null, -8.0)
		NoiseBus.emit_noise(global_position, 2.0, self)
		life.squash(Vector2(1.32, 0.74))
		Fx.dust(room.world, global_position + Vector2(0, -room.elevation_px(cell())), 6, 8.0)
		ShakeCamera.add_trauma(0.1)
		if room.is_hazard(cell()):
			fall()


func fall() -> void:
	if state == S.FALL or state == S.DEAD:
		return
	_set_state(S.FALL)
	life.shadow.visible = false
	Sfx.play("fall")
	var tw := create_tween()
	tw.tween_property(body_node, "position:y", body_node.position.y + 18.0, 0.5)
	tw.parallel().tween_property(body_node, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_after_fall)


func _after_fall() -> void:
	Game.damage(1)
	if Game.hp <= 0:
		_die()
		return
	room.on_player_fell()
	global_position = room.respawn_point()
	body_node.modulate.a = 1.0
	life.shadow.visible = true
	camera.reset_smoothing()
	_invuln = 1.2
	_set_state(S.NORMAL)
	Game.toast.emit("You fell, and lost a star.")


func _die() -> void:
	_set_state(S.DEAD)
	Sfx.play("death")
	var tw := create_tween()
	tw.tween_property(body_node, "modulate", Color(0.4, 0.2, 0.2, 0.0), 0.8)
	tw.tween_callback(func(): died.emit())


# ============================================================== visuals

func _update_visuals(delta: float) -> void:
	var target_elev := room.elevation_px(cell()) if room else 0.0
	if state == S.JUMP:
		var k := clampf(_state_t / JUMP_TIME, 0.0, 1.0)
		var e0 := room.elevation_px(Iso.cell_of_screen(_jump_from))
		elev = e0 + sin(k * PI) * 14.0
		life.ground_y = e0
		life.air = sin(k * PI)
	else:
		elev = move_toward(elev, target_elev, delta * 90.0)
		life.ground_y = elev
		life.air = 0.0
	if state != S.FALL:
		body_node.position.y = -roundf(elev)
	# Lean the view toward where he is heading.
	if camera:
		camera.look = Iso.grid_to_screen(_gvel) * 0.3 if state == S.NORMAL else camera.look * 0.92

	var sd := Iso.screen_dir(facing)
	var front := sd.y >= -0.01
	sprite.texture = Art.tex("cedalion_se" if front else "cedalion_ne")
	sprite.flip_h = sd.x < 0.0
	# The torch is in his right hand: screen left when he faces SE, screen right when he faces NE.
	var torch_x := -6.0 if front else 4.0
	torch.position = Vector2(-torch_x if sprite.flip_h else torch_x, -16)
	var flame := Vector2(-7, -23) if front else Vector2(3, -25)
	torch_embers.position = Vector2(-flame.x if sprite.flip_h else flame.x, flame.y)

	_noise_t += delta
	var n := _flicker.get_noise_1d(_noise_t * 60.0)
	# Lights add up and marble clips to white, so the torch eases off in a moonlight pool.
	var moon: float = room.moonlight_at(global_position) if room else 0.0
	torch.energy = (1.05 + n * 0.09) * (1.0 - 0.6 * moon)
	torch.texture_scale = TORCH_RADIUS / 64.0 * (1.0 + n * 0.04)

	if state != S.HURT and state != S.DEAD:
		sprite.modulate = Color.WHITE
	if _invuln > 0.0 and state != S.DODGE and state != S.FALL:
		sprite.visible = int(_invuln * 20.0) % 2 == 0
	else:
		sprite.visible = true
	if state == S.PARRY and _parry_t > 0.0:
		sprite.modulate = Color(1.4, 1.4, 1.6)
	elif state == S.DODGE:
		sprite.modulate = Color(1, 1, 1, 0.6)


## The aim of a held knucklebone: a dotted arc that marches toward the landing spot, and the
## 4-tile ring of everyone who will hear it land.
class AimPreview extends Node2D:
	var start := Vector2.ZERO
	var target := Vector2.ZERO

	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var dur := clampf(Iso.tiles_between(start, target) * 0.09, 0.25, 0.6)
		var lift := 22.0 * clampf(dur / 0.45, 0.6, 1.3)
		var n := 14
		for i in n:
			var k := (float(i) + fmod(t * 3.0, 1.0)) / n
			var p := start.lerp(target, k) + Vector2(0, -8.0 - sin(k * PI) * lift)
			draw_rect(Rect2(p.round() - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.86, 0.55, 0.75))
		# The hearing ring, as dashes on the floor.
		var g := Iso.screen_to_grid(target)
		var steps := 96
		for i in steps:
			if (i / 3) % 2 == 1:
				continue
			var a := TAU * i / steps + t * 0.3
			var p := Iso.grid_to_screen(g + Vector2(cos(a), sin(a)) * 4.0)
			draw_rect(Rect2(p.round(), Vector2(2, 1)), Color(1.0, 0.86, 0.55, 0.7))
		draw_rect(Rect2(target.round() - Vector2(3, 1), Vector2(6, 2)), Color(1.0, 0.86, 0.55, 0.9))
		draw_rect(Rect2(target.round() - Vector2(1, 2), Vector2(2, 4)), Color(1.0, 0.86, 0.55, 0.9))
