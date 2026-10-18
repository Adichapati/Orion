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
	await test_rooms_build_and_connect()
	await test_guard_sees_player()
	await test_noise_makes_guard_suspicious()
	await test_cracked_marble_collapses()
	await test_shove_into_pit()
	await test_shop_buy_and_equip()
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
