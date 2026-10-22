class_name SheetAnim
extends RefCounted
## Frame animations from a sprite sheet and its JSON, in Aseprite's export format.
##
## Export from Aseprite with File > Export Sprite Sheet: JSON data on (array or hash), tags on.
## Name tags "<animation>_<facing>": idle_se, walk_ne, attack_se, and so on. A missing facing is
## filled by mirroring its partner (se <-> sw, ne <-> nw). Save the pair as
## art/final/<name>_sheet.png and art/final/<name>_sheet.json; with no sheet, the game uses the
## single stills as before.
##
## Optional extras the game reads if present: meta.pivot {x, y} (the feet pixel in every cell;
## default bottom-centre), a per-frame "torch" {x, y} (the flame, relative to the pivot) and a
## per-frame "hand" {x, y, angle} (the sword hand's grip relative to the pivot, and the resting
## blade's screen angle in degrees, clockwise from screen right), where the game draws the sword.

const SEARCH := ["res://art/final/", "res://art/placeholders/"]


class Clip:
	var frames: Array[Texture2D] = []
	var durations: PackedFloat32Array = PackedFloat32Array()
	var torch: Array = []
	## Vector3(x, y, angle) per frame, or null.
	var hand: Array = []
	var total := 0.0
	var pingpong := false

	## Frame index at time t (seconds). Looping clips wrap; others hold the last frame.
	func index_at(t: float, loop := true) -> int:
		var n := frames.size()
		if n <= 1 or total <= 0.0:
			return 0
		var span := total
		if pingpong and n > 2:
			span = total * 2.0 - durations[0] - durations[n - 1]
		var x := fmod(t, span) if loop else minf(t, total - 0.0001)
		for i in n:
			if x < durations[i]:
				return i
			x -= durations[i]
		if pingpong:
			for i in range(n - 2, 0, -1):
				if x < durations[i]:
					return i
				x -= durations[i]
		return n - 1

	## Frame index for a one-shot that should take `length` seconds in all.
	func index_for_progress(k: float) -> int:
		return clampi(int(clampf(k, 0.0, 0.9999) * frames.size()), 0, frames.size() - 1)


var clips := {}
var cell := Vector2i.ZERO
var pivot := Vector2.ZERO


static func load_for(name: String) -> SheetAnim:
	for dir in SEARCH:
		var json_path: String = dir + name + "_sheet.json"
		var png_path: String = dir + name + "_sheet.png"
		if FileAccess.file_exists(json_path) and ResourceLoader.exists(png_path):
			var a := SheetAnim.new()
			if a._parse(FileAccess.get_file_as_string(json_path), load(png_path)):
				return a
	return null


func _parse(text: String, tex: Texture2D) -> bool:
	var data: Variant = JSON.parse_string(text)
	if not (data is Dictionary) or tex == null:
		push_warning("SheetAnim: unreadable sheet data")
		return false
	var raw_frames: Variant = data.get("frames", [])
	var frames: Array = raw_frames.values() if raw_frames is Dictionary else raw_frames
	if frames.is_empty():
		return false
	var meta: Dictionary = data.get("meta", {})
	var f0: Dictionary = frames[0].get("frame", {})
	cell = Vector2i(int(f0.get("w", 0)), int(f0.get("h", 0)))
	var pv: Dictionary = meta.get("pivot", {})
	pivot = Vector2(float(pv.get("x", floorf(cell.x / 2.0))), float(pv.get("y", cell.y - 1)))

	var atlases: Array[Texture2D] = []
	var durs: Array[float] = []
	var torches: Array = []
	var hands: Array = []
	for f in frames:
		var r: Dictionary = f.get("frame", {})
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", cell.x)), float(r.get("h", cell.y)))
		atlases.append(at)
		durs.append(maxf(0.016, float(f.get("duration", 100)) / 1000.0))
		var t: Variant = f.get("torch", null)
		torches.append(Vector2(float(t.x), float(t.y)) if t is Dictionary else null)
		var h: Variant = f.get("hand", null)
		hands.append(Vector3(float(h.x), float(h.y), float(h.get("angle", 0.0))) if h is Dictionary else null)

	for tag in meta.get("frameTags", []):
		var clip := Clip.new()
		var a := int(tag.get("from", 0))
		var b := int(tag.get("to", a))
		var idx := range(a, b + 1)
		if String(tag.get("direction", "forward")) == "reverse":
			idx.reverse()
		clip.pingpong = String(tag.get("direction", "forward")).begins_with("pingpong")
		for i in idx:
			if i < 0 or i >= atlases.size():
				continue
			clip.frames.append(atlases[i])
			clip.durations.append(durs[i])
			clip.torch.append(torches[i])
			clip.hand.append(hands[i])
			clip.total += durs[i]
		if not clip.frames.is_empty():
			clips[String(tag.get("name", ""))] = clip
	return not clips.is_empty()


## True if any frame marks a sword hand: then a frame without one means the blade is hidden.
func has_hands() -> bool:
	for c in clips.values():
		for h in c.hand:
			if h != null:
				return true
	return false


func has(base: String) -> bool:
	for d in ["se", "sw", "ne", "nw"]:
		if clips.has(base + "_" + d):
			return true
	return false


## The clip for an animation facing a screen direction, and whether to mirror it.
## Returns {} if the sheet has no such animation.
func pick(base: String, screen_dir: Vector2) -> Dictionary:
	var front := screen_dir.y >= -0.01
	var right := screen_dir.x >= 0.0
	var rows := [front, not front]
	for is_front in rows:
		var want := ("se" if right else "sw") if is_front else ("ne" if right else "nw")
		var other := ("sw" if right else "se") if is_front else ("nw" if right else "ne")
		if clips.has(base + "_" + want):
			return {"clip": clips[base + "_" + want], "flip": false}
		if clips.has(base + "_" + other):
			return {"clip": clips[base + "_" + other], "flip": true}
	return {}


## Sprite offset that puts the pivot pixel's bottom edge on the node origin, like Art.feet_sprite.
func sprite_offset() -> Vector2:
	return -pivot - Vector2(0, 1)
