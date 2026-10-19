class_name Life
extends Node2D
## Procedural life for a character with only still facings: a walk bob and step squash, squash and
## stretch on demand, a soft breathing idle, and a blob shadow on the floor.
##
## Add one as a child of the actor, then call setup(). The actor keeps moving `body` for height;
## this node only touches body.scale and the sprite's y offset, and keeps itself (the shadow) on
## the ground at `ground_y`.

## Height of the ground under the actor, in pixels above its origin (the actor sets it).
var ground_y := 0.0
## 0 on the ground, 1 at the top of a jump: the shadow shrinks and fades.
var air := 0.0
var bob_px := 1.0
var enabled := true
## 0 = standing, 1 = crouched (sneaking): eased toward each frame.
var crouch := 0.0
var _crouch := 0.0

var body: Node2D
var sprite: Sprite2D
var shadow: Sprite2D
var _actor: CharacterBody2D
var _phase := 0.0
var _squash := Vector2.ONE
var _squash_v := Vector2.ZERO
var _breath := randf() * TAU

static var _shadow_tex := {}


func setup(p_body: Node2D, p_sprite: Sprite2D, width_px: int) -> Life:
	body = p_body
	sprite = p_sprite
	shadow = Sprite2D.new()
	shadow.texture = shadow_texture(width_px)
	shadow.z_as_relative = false
	shadow.z_index = -55
	add_child(shadow)
	return self


func _ready() -> void:
	_actor = get_parent() as CharacterBody2D


## A soft dark ellipse, generated once per width.
static func shadow_texture(w: int) -> Texture2D:
	if _shadow_tex.has(w):
		return _shadow_tex[w]
	var h := maxi(3, w / 2)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2(w / 2.0, h / 2.0)
	for y in h:
		for x in w:
			var d := Vector2((x + 0.5 - c.x) / c.x, (y + 0.5 - c.y) / c.y).length()
			if d <= 1.0:
				# Two steps of alpha, not a gradient: it stays pixel art.
				var a := 0.42 if d < 0.7 else 0.24
				img.set_pixel(x, y, Color(0.05, 0.04, 0.10, a))
	var t := ImageTexture.create_from_image(img)
	_shadow_tex[w] = t
	return t


## Squash (x > 1, y < 1) or stretch (x < 1, y > 1); springs back to 1.
func squash(s: Vector2) -> void:
	_squash = s


func _process(delta: float) -> void:
	if body == null or not enabled:
		return
	var speed := 0.0
	if _actor:
		speed = Iso.screen_to_grid(_actor.velocity).length()  # tiles per second
	# A damped spring back to scale 1 (keeps the squash snappy, with one small overshoot).
	var k := 260.0
	var damp := 18.0
	_squash_v += ((Vector2.ONE - _squash) * k - _squash_v * damp) * delta
	_squash += _squash_v * delta
	var sc := _squash
	_crouch = lerpf(_crouch, crouch, 1.0 - exp(-14.0 * delta))
	sc *= Vector2(1.0 + 0.06 * _crouch, 1.0 - 0.14 * _crouch)
	var bob := 0.0
	if speed > 0.3:
		# Two steps per cycle; the body is highest mid-stride and dips on each footfall.
		_phase += delta * (2.2 + speed * 1.3)
		var s := absf(sin(_phase * PI))
		bob = s * bob_px
		sc *= Vector2(1.0 + (1.0 - s) * 0.04, 1.0 - (1.0 - s) * 0.04)
	else:
		_phase = 0.0
		_breath += delta * 2.2
		sc *= Vector2(1.0, 1.0 + sin(_breath) * 0.018)
	body.scale = sc
	if sprite:
		sprite.position.y = -roundf(bob)
	position.y = -roundf(ground_y)
	var a := clampf(air, 0.0, 1.0)
	shadow.scale = Vector2.ONE * (1.0 - a * 0.35)
	shadow.modulate.a = 1.0 - a * 0.5

