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
	check(Game.hp == hp_before - 1, "falling in costs a star")
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
	check(Game.hp < stars, "an unparried strike costs a star")
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
			check(err == "" and Game.armour_id == "linothorax" and Game.max_hp() == 5, "buying the linothorax equips it (+1 star)")
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
			await _seconds(2.6)
			check(r._collapsed.size() > 0, "...and the cracked ring starts to fall")
		var exit := _door(r, "Enter")
		check(exit != null, "%s has a usable exit" % r.id)
		exit.use(main.player)
		await _seconds(0.6)
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
	check(p.state == Player.S.DEAD, "losing the last star kills Cedalion")
	await _seconds(3.5)
	check(main.room != null and main.room.id == "colonnade" and main.player != p, "death rebuilds the same room")
	check(Game.obols == obols_at_entry and Game.hp == Game.max_hp(), "...with the obols and stars from the entry snapshot")
	main.queue_free()
	await get_tree().process_frame

