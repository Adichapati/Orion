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
