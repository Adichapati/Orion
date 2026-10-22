class_name SheetSprite
extends Sprite2D
## A sprite that plays clips from a SheetAnim by itself, for characters without a state machine
## (Phineus). Set `clip` to switch animations; it falls back to "idle".

var anim: SheetAnim
var clip := "idle"
## Screen direction the figure faces (picks the SE / NE clip and the mirroring).
var screen_dir := Vector2(1, 1)
var _playing := ""
var _t := 0.0


## A SheetSprite for <name>_sheet if one exists, else the plain <name>_se still. Feet on the
## origin either way, lowered by extra_y pixels like Art.feet_sprite.
static func make(name: String, extra_y := 0) -> Sprite2D:
	var a := SheetAnim.load_for(name)
	if a == null:
		return Art.feet_sprite(name + "_se", extra_y)
	var s := SheetSprite.new()
	s.anim = a
	s.centered = false
	s.offset = a.sprite_offset() + Vector2(0, extra_y)
	s._show()
	return s


func _process(delta: float) -> void:
	if clip != _playing:
		_playing = clip
		_t = 0.0
	else:
		_t += delta
	_show()


func _show() -> void:
	var pick := anim.pick(clip, screen_dir)
	if pick.is_empty():
		pick = anim.pick("idle", screen_dir)
	if pick.is_empty():
		return
	var c: SheetAnim.Clip = pick.clip
	texture = c.frames[c.index_at(_t, true)]
	flip_h = pick.flip
