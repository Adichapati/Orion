class_name VaseBorder
extends RefCounted
## The meander band of a black-figure vase, drawn along the top and bottom of a 960x540 card.


static func draw_on(item: CanvasItem, col: Color) -> void:
	for y in [40.0, 492.0]:
		item.draw_rect(Rect2(60, y, 840, 4), col)
		for x in range(60, 900, 24):
			item.draw_rect(Rect2(x, y + 8, 16, 3), col)
			item.draw_rect(Rect2(x + 13, y + 8, 3, 9), col)
			item.draw_rect(Rect2(x + 4, y + 14, 12, 3), col)
		item.draw_rect(Rect2(60, y + 20, 840, 4), col)


const CLAY := Color(0.62, 0.31, 0.15)
const CLAY_DARK := Color(0.36, 0.17, 0.09)


## Terracotta, lighter where the vase swells: a few quantised bands with a checker of the next
## band at each edge, rather than a smooth gradient.
static func draw_ground(item: CanvasItem, centre_y := 250.0) -> void:
	item.draw_rect(Rect2(0, 0, 960, 540), CLAY_DARK)
	for y in range(0, 540, 2):
		var k := 1.0 - absf(y - centre_y) / 300.0
		var lv := clampf(k * 1.5, 0.0, 1.0) * 4.0
		var step := floorf(lv) + (1.0 if fmod(lv, 1.0) > 0.5 and (y / 2) % 2 == 0 else 0.0)
		item.draw_rect(Rect2(0, y, 960, 2), CLAY_DARK.lerp(CLAY, minf(step, 4.0) / 4.0))
