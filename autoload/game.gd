extends Node
## Global run state: rooms, gear, obols, health, the attack token and Dawn Rank stats.

signal obols_changed(value: int)
signal health_changed(hp: int, max_hp: int)
signal gear_changed
signal toast(text: String)
signal floating_text(world_pos: Vector2, text: String, color: Color)
signal debug_overlay_changed(on: bool)

const ROOMS_PATH := "res://art/maps/rooms.json"
const BASE_HP := 4
const POMEGRANATE_PRICE := 15
const POMEGRANATE_LIMIT := 2

const WEAPON_PATHS := [
	"res://data/weapons/xiphos.tres", "res://data/weapons/dagger.tres",
	"res://data/weapons/kopis.tres", "res://data/weapons/longsword.tres",
]
const ARMOUR_PATHS := [
	"res://data/armour/tunic.tres", "res://data/armour/linothorax.tres", "res://data/armour/cuirass.tres",
]
const GUARD_PATHS := [
	"res://data/guards/watchman.tres", "res://data/guards/spearman.tres", "res://data/guards/hoplite.tres",
]
## What Phineus sells in v1 (the doc's Must list: 2 swords, 2 armour sets, plus pomegranates).
const SHOP_STOCK := ["dagger", "kopis", "linothorax", "cuirass", "pomegranate"]

var rooms: Array = []
var guard_types := {}
var weapons := {}
var armours := {}

var room_index := 0
var obols := 0
var hp := BASE_HP
var weapon_id := ""
var armour_id := "tunic"
var owned := {}
var pomegranates := 0
var snapshot := {}
var stats := {}
var debug_overlay := false

var _token_holder: Node = null


func _ready() -> void:
	load_data()
	reset_run()


func load_data() -> void:
	var f := FileAccess.open(ROOMS_PATH, FileAccess.READ)
	if f == null:
		push_error("Can't open %s" % ROOMS_PATH)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		rooms = parsed.get("rooms", [])
	else:
		push_error("rooms.json didn't parse")
	for p in WEAPON_PATHS:
		var w: WeaponData = load(p)
		weapons[String(w.id)] = w
	for p in ARMOUR_PATHS:
		var a: ArmourData = load(p)
		armours[String(a.id)] = a
	for p in GUARD_PATHS:
		var g: GuardType = load(p)
		guard_types[String(g.id)] = g


func reset_run() -> void:
	room_index = 0
	obols = 0
	weapon_id = ""
	armour_id = "tunic"
	owned = {"tunic": true}
	pomegranates = 0
	hp = max_hp()
	stats = {
		"start_msec": Time.get_ticks_msec(),
		"end_msec": 0,
		"spotted": 0,
		"kos": 0,
		"env_kos": 0,
		"damage_taken": 0,
		"obols_found": 0,
		"guards_total": 0,
		"rooms_counted": {},
		"guards_alerted": {},
		"marks": 0,
		"falls": 0,
	}
	_token_holder = null
	take_snapshot()


# ------------------------------------------------------------------ gear and health

func weapon() -> WeaponData:
	return weapons.get(weapon_id)


func armour() -> ArmourData:
	return armours.get(armour_id)


func max_hp() -> int:
	var a := armour()
	return BASE_HP + (a.hp_bonus if a else 0)


func give_weapon(id: String) -> void:
	owned[id] = true
	weapon_id = id
	gear_changed.emit()


func equip(id: String) -> void:
	if not owned.has(id):
		return
	if weapons.has(id):
		weapon_id = id
	elif armours.has(id):
		armour_id = id
		hp = mini(hp, max_hp())
		health_changed.emit(hp, max_hp())
	gear_changed.emit()


func price_of(id: String) -> int:
	if id == "pomegranate":
		return POMEGRANATE_PRICE
	if weapons.has(id):
		return weapons[id].price
	if armours.has(id):
		return armours[id].price
	return 0


func display_name_of(id: String) -> String:
	if id == "pomegranate":
		return "Pomegranate"
	if weapons.has(id):
		return weapons[id].display_name
	if armours.has(id):
		return armours[id].display_name
	return id


func description_of(id: String) -> String:
	if id == "pomegranate":
		return "Persephone's fruit. Eat one at any time (H) to restore 2 stars. Carry up to 2."
	if weapons.has(id):
		return weapons[id].description
	if armours.has(id):
		return armours[id].description
	return ""


## Returns "" on success, or the reason the purchase failed.
func buy(id: String) -> String:
	var price := price_of(id)
	if id == "pomegranate":
		if pomegranates >= POMEGRANATE_LIMIT:
			return "You can't carry more."
	elif owned.has(id):
		equip(id)
		return ""
	if obols < price:
		return "Not enough obols."
	add_obols(-price)
	if id == "pomegranate":
		pomegranates += 1
		gear_changed.emit()
	else:
		owned[id] = true
		equip(id)
	Sfx.play("buy")
	return ""


func add_obols(n: int, world_pos: Variant = null) -> void:
	obols = maxi(0, obols + n)
	if n > 0:
		stats.obols_found += n
		if world_pos != null:
			floating_text.emit(world_pos, "+%d" % n, Color(1.0, 0.85, 0.35))
	obols_changed.emit(obols)


func damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	stats.damage_taken += amount
	health_changed.emit(hp, max_hp())


func heal(amount: int) -> void:
	hp = mini(max_hp(), hp + amount)
	health_changed.emit(hp, max_hp())


func eat_pomegranate() -> bool:
	if pomegranates <= 0 or hp >= max_hp():
		return false
	pomegranates -= 1
	heal(2)
	gear_changed.emit()
	Sfx.play("heal")
	return true


# ------------------------------------------------------------------ checkpoints

func take_snapshot() -> void:
	snapshot = {
		"obols": obols, "weapon_id": weapon_id, "armour_id": armour_id,
		"owned": owned.duplicate(), "pomegranates": pomegranates,
	}


func restore_snapshot() -> void:
	obols = snapshot.get("obols", 0)
	weapon_id = snapshot.get("weapon_id", "")
	armour_id = snapshot.get("armour_id", "tunic")
	owned = snapshot.get("owned", {"tunic": true}).duplicate()
	pomegranates = snapshot.get("pomegranates", 0)
	hp = max_hp()
	obols_changed.emit(obols)
	health_changed.emit(hp, max_hp())
	gear_changed.emit()


# ------------------------------------------------------------------ combat director

## Only one guard attacks at a time; the others circle. Returns true if this guard may attack.
func request_attack_token(guard: Node) -> bool:
	if _token_holder == guard:
		return true
	if _token_holder == null or not is_instance_valid(_token_holder) or not _token_holder.wants_token():
		_token_holder = guard
		return true
	return false


func release_attack_token(guard: Node) -> void:
	if _token_holder == guard:
		_token_holder = null


func clear_attack_token() -> void:
	_token_holder = null


# ------------------------------------------------------------------ stats and Dawn Rank

func record_alert(guard_id: String) -> void:
	if not stats.guards_alerted.has(guard_id):
		stats.guards_alerted[guard_id] = true
	stats.spotted += 1


func finish_run() -> void:
	stats.end_msec = Time.get_ticks_msec()


func elapsed_seconds() -> float:
	var end: int = stats.end_msec if stats.end_msec > 0 else Time.get_ticks_msec()
	return (end - int(stats.start_msec)) / 1000.0


## Returns {grade, score, lines}. Par time for the six-room slice is 12 minutes.
func dawn_rank() -> Dictionary:
	var secs := elapsed_seconds()
	var ghosted: int = maxi(0, int(stats.guards_total) - stats.guards_alerted.size() - int(stats.kos))
	var score := 100.0
	score -= clampf((secs - 720.0) / 12.0, 0.0, 25.0)
	score -= stats.spotted * 6.0
	score -= stats.damage_taken * 3.0
	score += ghosted * 2.0
	score += stats.env_kos * 3.0
	score += mini(stats.obols_found, 200) / 20.0
	score = clampf(score, 0.0, 120.0)
	var grade := "C"
	if score >= 95.0:
		grade = "S"
	elif score >= 80.0:
		grade = "A"
	elif score >= 60.0:
		grade = "B"
	if stats.spotted == 0 and stats.kos == 0 and secs <= 720.0:
		grade = "Orion"
	return {
		"grade": grade,
		"score": roundi(score),
		"time": "%d:%02d" % [int(secs) / 60, int(secs) % 60],
		"spotted": stats.spotted,
		"kos": stats.kos,
		"env_kos": stats.env_kos,
		"ghosted": ghosted,
		"obols": stats.obols_found,
		"damage": stats.damage_taken,
		"marks": stats.marks,
	}


func set_debug_overlay(on: bool) -> void:
	debug_overlay = on
	debug_overlay_changed.emit(on)
