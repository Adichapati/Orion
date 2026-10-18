class_name Iso
extends RefCounted
## Isometric maths for ORION's 2:1 grid of 32x16 tiles.
##
## Three spaces are used:
## - grid: float tile coordinates. Cell (x, y) has its centre at Vector2(x, y). x grows east
##   (down-right on screen), y grows south (down-left on screen). Distances here are in tiles and
##   are the same in every direction, so all gameplay ranges and angles are measured in grid space.
## - screen: pixels in the 480x270 world viewport (before the camera).
## - cell: Vector2i of the tile a grid point falls in.

const TILE_W := 32.0
const TILE_H := 16.0
const HALF_W := 16.0
const HALF_H := 8.0
## Pixels of height per elevation level (raised floor 'h').
const LEVEL_PX := 16.0


static func grid_to_screen(g: Vector2) -> Vector2:
	return Vector2((g.x - g.y) * HALF_W, (g.x + g.y) * HALF_H)


static func screen_to_grid(s: Vector2) -> Vector2:
	return Vector2(s.x / TILE_W + s.y / TILE_H, s.y / TILE_H - s.x / TILE_W)


static func cell_to_screen(c: Vector2i) -> Vector2:
	return grid_to_screen(Vector2(c))


static func cell_of_grid(g: Vector2) -> Vector2i:
	return Vector2i(roundi(g.x), roundi(g.y))


static func cell_of_screen(s: Vector2) -> Vector2i:
	return cell_of_grid(screen_to_grid(s))


## Distance in tiles between two screen points.
static func tiles_between(a: Vector2, b: Vector2) -> float:
	return screen_to_grid(a).distance_to(screen_to_grid(b))


## Converts a screen-relative input vector (as read from the keyboard or stick) into a grid
## direction. "Up" on screen moves along grid -x-y, "up-right" moves along grid -y, and so on.
static func input_to_grid_dir(input: Vector2) -> Vector2:
	if input.length_squared() < 0.0001:
		return Vector2.ZERO
	var w := input.normalized()
	return screen_to_grid(Vector2(w.x, w.y * 0.5)).normalized()


## Screen-space velocity for a grid-space velocity (tiles per second).
static func grid_vel_to_screen(v: Vector2) -> Vector2:
	return grid_to_screen(v)


## The eight facings in grid space, in order starting east (screen down-right) and turning clockwise.
const DIRS8 := [
	Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1),
	Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
]


static func snap_dir8(d: Vector2) -> Vector2i:
	if d.length_squared() < 0.0001:
		return Vector2i(1, 0)
	var best := 0
	var best_dot := -INF
	for i in DIRS8.size():
		var dot: float = d.normalized().dot((DIRS8[i] as Vector2).normalized())
		if dot > best_dot:
			best_dot = dot
			best = i
	var v: Vector2 = DIRS8[best]
	return Vector2i(int(v.x), int(v.y))


## Screen direction of a grid direction, for picking sprites and flipping them.
static func screen_dir(grid_dir: Vector2) -> Vector2:
	return grid_to_screen(grid_dir)


## The four diamond corners of a cell, relative to its centre, scaled by s (1 = full tile).
static func diamond(s: float = 1.0) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -HALF_H * s), Vector2(HALF_W * s, 0), Vector2(0, HALF_H * s), Vector2(-HALF_W * s, 0),
	])
