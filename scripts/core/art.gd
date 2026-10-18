class_name Art
extends RefCounted
## One place that maps art names to textures, so final art can replace the grey-box without
## touching code.
##
## Lookup order for a name such as "cedalion_se" or "column":
##   1. res://art/final/<name>.png      <- drop finished art here, same name, same pivot
##   2. res://art/placeholders/<name>.png  (the character placeholders)
##   3. res://art/greybox/<name>.png       (the generated grey-box tiles and props)

const SEARCH := ["res://art/final/", "res://art/placeholders/", "res://art/greybox/"]

static var _cache := {}


static func tex(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var t: Texture2D = null
	for dir in SEARCH:
		var path: String = dir + name + ".png"
		if ResourceLoader.exists(path):
			t = load(path)
			break
	if t == null:
		push_warning("Art: no texture named '%s'" % name)
	_cache[name] = t
	return t


## A Sprite2D whose bottom-centre pixel sits on the node's origin (characters and props).
static func feet_sprite(name: String, extra_y := 0) -> Sprite2D:
	var s := Sprite2D.new()
	var t := tex(name)
	s.texture = t
	s.centered = false
	if t:
		s.offset = Vector2(-floorf(t.get_width() / 2.0), -t.get_height() + extra_y)
	return s


## A Sprite2D for a block whose 32x16 ground diamond is centred on the node's origin.
static func block_sprite(name: String) -> Sprite2D:
	var s := Sprite2D.new()
	var t := tex(name)
	s.texture = t
	s.centered = false
	if t:
		var h := t.get_height() - 16
		s.offset = Vector2(-16, -(h + 8))
	return s


## A flat 32x16 tile centred on the node's origin.
static func tile_sprite(name: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(name)
	s.centered = true
	return s
