extends Node
## ORION's headless test suite, loaded by tests/run_tests.gd once the autoloads exist.

signal finished(failed: int)

var _failed := 0
var _passed := 0
var _host: Node


func run() -> void:
	_host = self
	await get_tree().process_frame
	test_iso_round_trip()
	test_final_art_matches_placeholders()
	await test_rooms_build_and_connect()
	await test_rooms_are_sealed()
	await test_interactables_reachable()
	await test_cedalion_sword()
	await test_guard_animation()
	await test_guard_sees_player()
	await test_noise_makes_guard_suspicious()
	await test_statue_guard_wakes()
	await test_cracked_marble_collapses()
	await test_shove_into_pit()
	await test_duel_parry_and_hit()
	await test_shop_buy_and_equip()
	await test_playthrough()
	print("
%d passed, %d failed" % [_passed, _failed])
	finished.emit(_failed)


func check(ok: bool, what: String) -> void:
	if ok:
		_passed += 1
		print("  ok    ", what)
	else:
		_failed += 1
		printerr("  FAIL  ", what)


func _seconds(t: float) -> void:
	var end := Time.get_ticks_msec() + int(t * 1000.0)
	while Time.get_ticks_msec() < end:
		await get_tree().physics_frame


func _make_room(data: Dictionary) -> Room:
	var r := Room.new()
	_host.add_child(r)
	r.build(data)
	return r


func _free_room(r: Room) -> void:
	_host.remove_child(r)
	r.free()
	Game.clear_attack_token()


func _add_player(r: Room, c: Vector2i) -> Player:
	var p := Player.new()
	p.room = r
	r.player = p
	p.position = r.cell_center(c)
	r.world.add_child(p)
	return p


# ============================================================== tests

func test_iso_round_trip() -> void:
	print("Iso")
	var ok := true
	for g in [Vector2(0, 0), Vector2(3, 7), Vector2(-2.5, 4.25), Vector2(12, -1)]:
		var back := Iso.screen_to_grid(Iso.grid_to_screen(g))
		ok = ok and back.distance_to(g) < 0.0001
	check(ok, "grid → screen → grid round-trips")
	check(Iso.cell_of_screen(Iso.cell_to_screen(Vector2i(5, 9))) == Vector2i(5, 9), "cell → screen → cell round-trips")
	check(Iso.grid_to_screen(Vector2(1, 0)) == Vector2(16, 8), "cell (1, 0) sits 16 px right, 8 px down")


## Final art replaces a placeholder by name, so it must keep the placeholder's size (the pivot is
## the bottom-centre pixel, so the same size means the same pivot).
func test_final_art_matches_placeholders() -> void:
	print("Final art")
	var dir := DirAccess.open("res://art/final")
	if dir == null:
		check(true, "no art/final folder yet")
		return
	var count := 0
	for f in dir.get_files():
		if not f.ends_with(".png"):
			continue
		var ph := "res://art/placeholders/" + f
		if not ResourceLoader.exists(ph):
			continue
		var a: Texture2D = load("res://art/final/" + f)
		var b: Texture2D = load(ph)
		# A character with an animation sheet uses its sheet's cell size for the stills too.
		var base := f.get_basename().rsplit("_", true, 1)[0]
		if FileAccess.file_exists("res://art/final/%s_sheet.json" % base):
			var anim := SheetAnim.load_for(base)
			check(anim != null and a.get_size() == Vector2(anim.cell), "%s matches its animation sheet's cells" % f)
			count += 1
			continue
		check(a.get_size() == b.get_size(), "%s is %s like its placeholder" % [f, b.get_size()])
		count += 1
	check(count > 0, "art/final has character sprites")


func test_rooms_build_and_connect() -> void:
	print("Rooms")
	check(Game.rooms.size() == 6, "rooms.json has six rooms")
	for data in Game.rooms:
		var r := _make_room(data)
		await get_tree().physics_frame
		check(r.size.x > 0 and r.size.y > 0 and r.world.get_child_count() > 0, "%s builds" % r.id)
		check(r.is_walkable(r.player_spawn), "%s: spawn %s is walkable" % [r.id, r.player_spawn])
		for g in data.get("guards", []):
			var at := Vector2i(int(g.at[0]), int(g.at[1]))
			check(r.is_walkable(at), "%s: guard %s spawn %s is walkable" % [r.id, g.id, at])
			for p in g.get("path", []):
				var c := Vector2i(int(p[0]), int(p[1]))
				check(r.reachable(r.nearest_walkable(at), c), "%s: guard %s can reach waypoint %s" % [r.id, g.id, c])
		var exits := _exits(r)
		check(not exits.is_empty(), "%s has an exit door" % r.id)
		var seen := _flood_with_jumps(r, r.player_spawn)
		var reach := exits.any(func(e): return seen.has(e))
		check(reach, "%s: an exit is reachable from the spawn (walking and 2-tile jumps)" % r.id)
		r.spawn_guards()
		check(r.guards.size() == data.get("guards", []).size(), "%s spawns %d guards" % [r.id, r.guards.size()])
		check(r.get_node_or_null("Island") != null and r.get_node_or_null("Cliffs") != null,
				"%s stands on its floating island (drawn for its grid size)" % r.id)
		_free_room(r)


func _exits(r: Room) -> Array:
	var out: Array = []
	for y in r.size.y:
		for x in r.size.x:
			if r.ch(Vector2i(x, y)) == "D":
				out.append(Vector2i(x, y))
	return out


## Cells reachable by walking (as the guards' A* graph allows) plus the player's fixed jumps:
## two tiles along a grid axis over anything that isn't solid, landing on the same height.
func _flood_with_jumps(r: Room, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	var steps := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var next: Array[Vector2i] = []
		for d in steps:
			var n: Vector2i = c + d
			if r._can_step(c, n) and (d.x == 0 or d.y == 0 or (r._can_step(c, Vector2i(n.x, c.y)) and r._can_step(c, Vector2i(c.x, n.y)))):
				next.append(n)
			if d.x == 0 or d.y == 0:
				var mid: Vector2i = c + d
				var land: Vector2i = c + d * 2
				var mid_ok := r.is_walkable(mid) or r.is_hazard(mid)
				if mid_ok and r.is_walkable(land) and absf(r.elevation_px(land) - r.elevation_px(c)) < 12.0:
					next.append(land)
		for n in next:
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen


## The eight input directions (screen space), as pressed on the keyboard.
const PUSHES := [
	["move_right"], ["move_left"], ["move_up"], ["move_down"],
	["move_up", "move_right"], ["move_up", "move_left"], ["move_down", "move_right"], ["move_down", "move_left"],
]


var _escaped_to := ""


## Steps the player's own state machine synchronously and returns false if he ever stands outside
## the room (off the grid or inside a wall cell).
func _step_inside(r: Room, p: Player, frames: int) -> bool:
	for i in frames:
		p._physics_process(1.0 / 60.0)
		var c := p.cell()
		if c.x < 0 or c.y < 0 or c.x >= r.size.x or c.y >= r.size.y or r.ch(c) in Room.WALLS:
			_escaped_to = "%s in state %s" % [p.grid_pos().snapped(Vector2(0.01, 0.01)), Player.S.keys()[p.state]]
			return false
	return true


func _reset_player(r: Room, p: Player, c: Vector2i) -> void:
	p._set_state(Player.S.NORMAL)
	p._gvel = Vector2.ZERO
	p.velocity = Vector2.ZERO
	p.global_position = r.cell_center(c)
	for k in p._cool:
		p._cool[k] = 0.0


## Bug: Cedalion could walk out through a door on the grid's edge onto the sky. From every
## reachable cell next to a wall or the edge, push him in all eight directions by walking, then
## dodge and jump into whatever stopped him, and check he never leaves the room.
func test_rooms_are_sealed() -> void:
	print("Rooms are sealed")
	for data in Game.rooms:
		var r := _make_room(data)
		NoiseBus.noise.disconnect(r._show_noise)
		var p := _add_player(r, r.player_spawn)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var seen := _flood_with_jumps(r, r.player_spawn)
		var leaks: Array = []
		var tried := 0
		for c in seen:
			var edge: bool = r.ch(c) in "ED"
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				var n: Vector2i = c + d
				if n.x < 0 or n.y < 0 or n.x >= r.size.x or n.y >= r.size.y or r.ch(n) in Room.WALLS:
					edge = true
			if not edge:
				continue
			for push in PUSHES:
				tried += 1
				_reset_player(r, p, c)
				for a in push:
					Input.action_press(a)
				var dir := Iso.input_to_grid_dir(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
				var ok := _step_inside(r, p, 45)
				p._start_dodge(dir)
				ok = ok and _step_inside(r, p, 20)
				p._set_state(Player.S.NORMAL)
				ok = ok and _step_inside(r, p, 10)
				p.facing = dir
				p._start_jump()
				ok = ok and _step_inside(r, p, 30)
				for a in push:
					Input.action_release(a)
				# A standing jump from the middle of the cell, too.
				_reset_player(r, p, c)
				p.facing = dir
				p._start_jump()
				ok = ok and _step_inside(r, p, 30)
				if not ok:
					leaks.append("%s %s to %s" % [c, "+".join(push), _escaped_to])
		check(tried > 0 and leaks.is_empty(), "%s: Cedalion stays inside from %d pushes at the edges%s" % [
				r.id, tried, "" if leaks.is_empty() else " (leaks: %s)" % ", ".join(leaks.slice(0, 6))])
		_free_room(r)


## Bug: Phineus stood on a raised floor with no steps. Every important interactable must be usable
## (be the closest one in reach) from some cell reachable from the spawn by walking and jumping.
func test_interactables_reachable() -> void:
	print("Interactables are reachable")
	for data in Game.rooms:
		var r := _make_room(data)
		await get_tree().physics_frame
		var seen := _flood_with_jumps(r, r.player_spawn)
		var count := 0
		for it in r.interactables:
			if not (it.verb in ["Talk to Phineus", "Take the Belt Star", "Enter", "Open", "Take the sword", "Read the mark"]):
				continue
			count += 1
			var from := Vector2i(-1, -1)
			for c in seen:
				if r.closest_interactable(r.cell_center(c)) == it:
					from = c
					break
			var at := Iso.cell_of_screen(it.global_position)
			check(from != Vector2i(-1, -1), "%s: \"%s\" at %s can be used from a reachable cell%s" % [
					r.id, it.verb, at, "" if from == Vector2i(-1, -1) else " (%s)" % from])
		check(count > 0, "%s has interactables to check" % r.id)
		_free_room(r)


## Bug: Cedalion showed a sword before he had one, and it blinked in and out as he walked (two
## walk frames were drawn without it). The sword is now its own sprite on a hand point that
## every frame carries, hidden while he's unarmed, and swept through an arc when he attacks.
func test_cedalion_sword() -> void:
	print("Cedalion's sword")
	var anim := SheetAnim.load_for("cedalion")
	check(anim != null, "Cedalion has an animation sheet")
	if anim == null:
		return
	var missing: Array = []
	for name in anim.clips:
		var clip: SheetAnim.Clip = anim.clips[name]
		for i in clip.frames.size():
			if clip.hand[i] == null:
				missing.append("%s#%d" % [name, i])
	check(missing.is_empty(), "every frame of every clip has a sword hand%s" % ("" if missing.is_empty() else " (missing: %s)" % ", ".join(missing)))
	for wid in Game.weapons:
		check(ResourceLoader.exists("res://art/final/sword_%s.png" % wid), "the %s has a sword sprite" % wid)

	Game.reset_run()
	var r := _open_room([])
	var p := _add_player(r, Vector2i(4, 3))
	await _seconds(0.1)
	check(not p.sword.visible, "unarmed, Cedalion shows no sword")
	Game.give_weapon("xiphos")
	var shown := true
	for i in 40:
		Input.action_press("move_right")
		await get_tree().physics_frame
		shown = shown and p.sword.visible
	Input.action_release("move_right")
	check(shown, "armed, the sword shows on every frame of the walk")
	await _seconds(0.3)
	var frames := {}
	p._start_attack()
	while p.state == Player.S.ATTACK:
		frames[p.sword.frame] = true
		await get_tree().physics_frame
	check(frames.size() >= 5, "a swing sweeps the blade through %d angles" % frames.size())
	Game.reset_run()
	_free_room(r)


## The guards and Phineus had single stills. Each now has a sheet (built from the stills by
## tools/animate_stills.py until hand-made ones arrive): a walk that cycles while he moves, and
## wind-up and strike frames in step with his attack.
func test_guard_animation() -> void:
	print("Guard animation")
	for n in ["watchman", "spearman", "hoplite"]:
		var a := SheetAnim.load_for(n)
		var ok := a != null
		if ok:
			for clip in ["idle_se", "idle_ne", "walk_se", "walk_ne", "attack_se", "attack_ne", "hurt_se"]:
				ok = ok and a.clips.has(clip)
		check(ok, "%s has idle, walk, attack and hurt clips, front and back" % n)
	var ph := SheetAnim.load_for("phineus")
	check(ph != null and ph.clips.has("idle_se") and ph.clips.has("talk_se"), "Phineus has idle and talk clips")

	var r := _open_room([{"id": "g", "type": "watchman", "at": [2, 2], "face": [1, 0], "path": [[2, 2], [9, 2]]}])
	r.spawn_guards()
	var g: Guard = r.guards[0]
	var seen := {}
	for i in 60:
		await get_tree().physics_frame
		seen[g.sprite.texture] = true
	check(seen.size() >= 3, "a patrolling guard walks through %d frames in a second" % seen.size())
	_free_room(r)

	Game.reset_run()
	r = _open_room([{"id": "g", "type": "watchman", "at": [5, 2], "face": [-1, 0], "path": [[5, 2]]}])
	r.spawn_guards()
	var p := _add_player(r, Vector2i(4, 2))
	g = r.guards[0]
	var t := 0.0
	while t < 4.0 and g._phase != "windup":
		await get_tree().physics_frame
		t += 1.0 / 60.0
	await get_tree().physics_frame
	var clip: SheetAnim.Clip = g._anim.pick("attack", Iso.screen_dir(g.facing)).clip
	check(g._phase == "windup" and g.sprite.texture == clip.frames[0], "a winding-up guard shows his wind-up frame")
	while t < 6.0 and g._phase != "recover":
		await get_tree().physics_frame
		t += 1.0 / 60.0
	# Real time: the strike lands on Cedalion and the hit-stop freezes the game for a moment.
	await _seconds(0.16)
	check(g.sprite.texture == clip.frames[1] and g._lunge > 0.0, "...then lunges into his strike frame (frame %d, lunge %.1f px, %s %.2f s)" % [
			clip.frames.find(g.sprite.texture), g._lunge, g._phase, g._phase_t])
	p.queue_free()
	Game.reset_run()
	_free_room(r)


const OPEN_GRID := [
	"############",
	"#..........#",
	"#..........#",
	"#..........#",
	"#....xx....#",
	"#..........#",
	"#..........#",
	"############",
]


func _open_room(guards: Array) -> Room:
	return _make_room({"id": "test", "name": "Test", "grid": OPEN_GRID, "player": [1, 1], "guards": guards})


func test_guard_sees_player() -> void:
	print("Guard sight")
	var r := _open_room([{"id": "g", "type": "watchman", "at": [3, 2], "face": [1, 0], "path": [[3, 2]]}])
	r.spawn_guards()
	var p := _add_player(r, Vector2i(6, 2))
	var g: Guard = r.guards[0]
	await get_tree().physics_frame
	check(g.can_see_player(), "a Watchman facing the player at 3 tiles sees him")
	var t := 0.0
	while t < 4.0 and not g.is_alert():
		await get_tree().physics_frame
		t += 1.0 / 60.0
	check(g.is_alert(), "...and reaches Alert (after %.1f s)" % t)
	check(p.is_targetable(), "the player is still standing")
	_free_room(r)

	r = _open_room([{"id": "g", "type": "watchman", "at": [6, 2], "face": [1, 0], "path": [[6, 2]]}])
	r.spawn_guards()
	_add_player(r, Vector2i(3, 2))
	g = r.guards[0]
	await _seconds(0.5)
	check(not g.can_see_player() and g.state == Guard.S.PATROL, "a guard doesn't see a player standing behind him")
	_free_room(r)


func test_noise_makes_guard_suspicious() -> void:
	print("Guard hearing")
	var r := _open_room([{"id": "g", "type": "watchman", "at": [6, 3], "face": [1, 0], "path": [[6, 3]]}])
	r.spawn_guards()
	var g: Guard = r.guards[0]
	await get_tree().physics_frame
	NoiseBus.emit_noise(r.cell_center(Vector2i(3, 3)), 4.0, null)
	check(g.state == Guard.S.SUSPICIOUS, "a noise 3 tiles away (radius 4) makes an idle guard Suspicious")
	check(g.awareness >= 35.0, "...and raises awareness to at least 35")
	await _seconds(0.7)
	check(g.facing.dot(Vector2(-1, 0)) > 0.7, "...who turns toward the noise")
	_free_room(r)
	r = _open_room([{"id": "g", "type": "watchman", "at": [9, 3], "face": [1, 0], "path": [[9, 3]]}])
	r.spawn_guards()
	g = r.guards[0]
	await get_tree().physics_frame
	NoiseBus.emit_noise(r.cell_center(Vector2i(2, 3)), 4.0, null)
	await get_tree().physics_frame
	check(g.state == Guard.S.PATROL, "a noise beyond its radius goes unheard")
	_free_room(r)


func test_statue_guard_wakes() -> void:
	print("Statue guard")
	var r := _open_room([{"id": "h", "type": "hoplite", "statue": true, "at": [3, 2], "face": [1, 0], "path": [[3, 2]]}])
	r.spawn_guards()
	var p := _add_player(r, Vector2i(7, 2))
	var g: Guard = r.guards[0]
	await _seconds(1.5)
	check(g.dormant and g.awareness == 0.0, "a statue guard ignores Cedalion in plain view 4 tiles away")
	p.position = r.cell_center(Vector2i(5, 2))
	await _seconds(0.3)
	check(not g.dormant and g.is_alert(), "...and wakes, alert, when he comes within reach")
	_free_room(r)


func test_cracked_marble_collapses() -> void:
	print("Cracked marble")
	var r := _open_room([])
	var c := Vector2i(5, 4)
	check(r.is_cracked(c), "the test room has cracked marble at %s" % c)
	var hp_before := Game.hp
	_add_player(r, c)
	await _seconds(0.9)
	check(not r.is_hazard(c), "it holds for 0.9 s")
	await _seconds(0.6)
	check(r.is_hazard(c), "it collapses after 1.2 s of standing on it")
	await _seconds(0.8)
	check(Game.hp == hp_before - 1, "falling in costs a heart")
	Game.heal(10)
	_free_room(r)


func test_shove_into_pit() -> void:
	print("Shove")
	var grid := OPEN_GRID.duplicate()
	grid[3] = "#......_...#"
	var r := _make_room({"id": "test", "name": "Test", "grid": grid, "player": [1, 1],
			"guards": [{"id": "g", "type": "watchman", "at": [6, 3], "face": [0, 1], "path": [[6, 3]]}]})
	r.spawn_guards()
	var g: Guard = r.guards[0]
	var kos: int = Game.stats.kos
	var env: int = Game.stats.env_kos
	await get_tree().physics_frame
	g.shoved(Vector2i(1, 0), null)
	await _seconds(1.0)
	check(g.is_ko(), "a guard shoved into a pit is knocked out")
	check(Game.stats.kos == kos + 1 and Game.stats.env_kos == env + 1, "...and it counts as an environmental KO")
	check(r.pickups.get_child_count() > 0, "...and drops obols")
	_free_room(r)


func test_duel_parry_and_hit() -> void:
	print("Duel")
	Game.reset_run()
	Game.give_weapon("xiphos")
	var r := _open_room([{"id": "g", "type": "watchman", "at": [5, 2], "face": [-1, 0], "path": [[5, 2]]}])
	r.spawn_guards()
	var p := _add_player(r, Vector2i(4, 2))
	p.facing = Vector2(1, 0)
	var g: Guard = r.guards[0]
	await get_tree().physics_frame
	var t := 0.0
	while t < 4.0 and g._phase != "windup":
		await get_tree().physics_frame
		t += 1.0 / 60.0
	check(g._phase == "windup", "an alert Watchman at arm's length winds up an attack")
	check(g.glint.visible, "...showing a glint")
	var parryable: bool = g._attack.parryable
	await _seconds(maxf(0.0, g._attack.windup - g._phase_t - 0.06))
	p._start_parry()
	await _seconds(0.25)
	check(parryable and g.state == Guard.S.STUNNED, "a parry in the window stuns him")
	var hp: int = g.hp
	p._set_state(Player.S.NORMAL)
	p._start_attack()
	await _seconds(0.5)
	check(g.hp < hp, "Cedalion's riposte lands (%d → %d hp)" % [hp, g.hp])
	# Let him strike unparried.
	var stars := Game.hp
	t = 0.0
	while t < 6.0 and Game.hp == stars:
		await get_tree().physics_frame
		t += 1.0 / 60.0
	check(Game.hp < stars, "an unparried strike costs a heart")
	_free_room(r)
	Game.reset_run()
	await _test_parry_on_the_flash()


## A bot that waits for the glint's flash and parries after a human reaction time. Typical
## reactions (0.2-0.26 s) should land; a press right on the flash is too early (the window has
## closed before the blade arrives) and one long after it is too late.
func _test_parry_on_the_flash() -> void:
	for reaction in [0.05, 0.2, 0.23, 0.26, 0.45]:
		Game.reset_run()
		Game.give_weapon("xiphos")
		var r := _open_room([{"id": "g", "type": "watchman", "at": [5, 2], "face": [-1, 0], "path": [[5, 2]]}])
		r.spawn_guards()
		var p := _add_player(r, Vector2i(4, 2))
		p.facing = Vector2(1, 0)
		var g: Guard = r.guards[0]
		var t := 0.0
		while t < 4.0 and not (g._phase == "windup" and g._phase_t >= g._attack.windup - Guard.FLASH_LEAD):
			await get_tree().physics_frame
			t += 1.0 / 60.0
		await _seconds(reaction)
		p._start_parry()
		await _seconds(0.5)
		var ok := g.state == Guard.S.STUNNED
		var should: bool = reaction > 0.1 and reaction < 0.35
		check(ok == should, "a parry %.2f s after the flash %s" % [reaction, "lands" if should else "misses"])
		_free_room(r)
	Game.reset_run()


func test_shop_buy_and_equip() -> void:
	print("Shop")
	Game.reset_run()
	Game.add_obols(100)
	check(Game.buy("kopis") == "", "buying the kopis with 100 obols works")
	check(Game.weapon_id == "kopis" and Game.obols == 25, "...equips it and costs 75")
	check(Game.buy("cuirass") != "", "the cuirass (90) is refused with 25 obols left")
	check(Game.buy("pomegranate") == "" and Game.pomegranates == 1, "a pomegranate costs 15")
	Game.take_snapshot()
	Game.add_obols(-10)
	Game.restore_snapshot()
	check(Game.obols == 10 and Game.weapon_id == "kopis", "restoring the snapshot brings back obols and gear")
	Game.reset_run()


func _door(r: Room, verb: String) -> Interactable:
	for it in r.interactables:
		if is_instance_valid(it) and it.verb == verb:
			return it
	return null


## Drives the real main scene: walks every exit, the shop, the star-shrine escape and a death.
func test_playthrough() -> void:
	print("Play-through")
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	Game.reset_run()
	main.load_room(0)
	for i in Game.rooms.size():
		var r: Room = main.room
		check(r != null and r.id == Game.rooms[i].id and main.player != null, "room %d (%s) loads with the player" % [i, Game.rooms[i].id])
		await get_tree().physics_frame
		if r.id == "cistern":
			Game.add_obols(40)
			r.message.emit("shop")
			await get_tree().process_frame
			check(main._menu is ShopPanel and main.player.state == Player.S.LOCKED, "talking to Phineus opens the shop and locks the player")
			var err := Game.buy("linothorax")
			check(err == "" and Game.armour_id == "linothorax" and Game.max_hp() == 5, "buying the linothorax equips it (+1 heart)")
			main._menu.close()
			await get_tree().process_frame
			check(main._menu == null and main.player.state == Player.S.NORMAL, "leaving the shop unlocks the player")
		if r.id == "star-shrine":
			var door := _door(r, "Enter")
			door.use(main.player)
			await get_tree().process_frame
			check(main.room == r, "the shrine door stays sealed before the star is taken")
			_door(r, "Take the Belt Star").use(main.player)
			check(not r.exit_locked, "taking the Belt Star unseals the door")
			# The ring arms 2 s of game time after the star is taken; the star beat's freeze and slow
			# motion stretch that by about half a second of real time.
			await _seconds(3.2)
			check(r._collapsed.size() > 0, "...and the cracked ring starts to fall")
		var exit := _door(r, "Enter")
		check(exit != null, "%s has a usable exit" % r.id)
		exit.use(main.player)
		# The climb to the next island: the camera rises for about half a second first.
		await _seconds(0.9)
	check(main._screen is EndCard, "the last exit shows the Dawn Rank end card")
	check(Game.stats.end_msec > 0, "...and the run's clock stops")

	# Death: restart the room from the snapshot taken on entry.
	Game.reset_run()
	main.load_room(1)
	await get_tree().physics_frame
	var obols_at_entry := Game.obols
	Game.add_obols(12)
	Game.hp = 1
	var p: Player = main.player
	p.take_hit(1, p.global_position + Vector2(10, 0), 0.2)
	check(p.state == Player.S.DEAD, "losing the last heart kills Cedalion")
	await _seconds(4.5)
	check(main.room != null and main.room.id == "colonnade" and main.player != p, "death rebuilds the same room")
	check(Game.obols == obols_at_entry and Game.hp == Game.max_hp(), "...with the obols and hearts from the entry snapshot")
	main.queue_free()
	await get_tree().process_frame

