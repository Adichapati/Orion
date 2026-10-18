class_name UiKit
extends RefCounted
## Shared look for ORION's menus and HUD: night-blue panels with a gold meander-style border,
## warm parchment text. Every UI script builds its controls through these helpers so the style
## can be changed in one place (or swapped for a Theme resource later).

const INK := Color(0.05, 0.04, 0.1, 0.92)
const BLUE := Color(0.12, 0.18, 0.38, 0.96)
const GOLD := Color(0.86, 0.68, 0.32)
const TEXT := Color(0.96, 0.91, 0.8)
const DIM := Color(0.7, 0.66, 0.6)
const RED := Color(0.9, 0.32, 0.25)


static func label(text: String, size := 16, color := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4 if size >= 14 else 3)
	return l


static func panel_style(bg := BLUE, border := GOLD) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_content_margin_all(14)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 4
	return s


static func panel(bg := BLUE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg))
	return p


static func button(text: String, size := 16) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	var normal := panel_style(Color(0.08, 0.1, 0.22, 0.95), Color(0.45, 0.38, 0.22))
	normal.set_content_margin_all(6)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = GOLD
	hover.bg_color = Color(0.16, 0.2, 0.4, 0.98)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.focus_entered.connect(func(): Sfx.play("ui_move", null, -10.0, 0.0))
	b.pressed.connect(func(): Sfx.play("ui_select", null, -6.0, 0.0))
	return b


## A full-screen dark backdrop for cards and menus.
static func backdrop(alpha := 0.8) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.03, 0.02, 0.07, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


## A Control filling its parent, centring one child.
static func center() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c


static func vbox(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hbox(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


## A texture shown at an integer pixel scale.
static func icon(name: String, scale := 2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Art.tex(name)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if t.texture:
		t.custom_minimum_size = Vector2(t.texture.get_width(), t.texture.get_height()) * scale
	return t
