class_name ShopPanel
extends Control
## Phineus's stall: buy or equip swords and armour, buy pomegranates, hear one prophecy about the
## next room, and save (take a checkpoint snapshot).

signal closed

const GREETING := "I lost my eyes long ago, little prince. I can still count obols."
## One prophecy per visit, keyed by the id of the room that comes next.
const PROPHECIES := {
	"statue-court": "Three keep the court of stone. Where the water sings, your feet fall silent. One of the stone men breathes.",
	"star-shrine": "The star sleeps on marble that cannot bear a heavy man. Take it, and run before the floor remembers.",
}
const DEFAULT_PROPHECY := "The dark is kinder to the small. Stay small."

var _rows: VBoxContainer
var _status: Label
var _obols: Label
var _first: Button = null
## The obol glyph at 2x for the price buttons (Button icons draw at texture size).
var _coin: Texture2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.backdrop(0.55))
	var img := Art.tex("hud_obol").get_image()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	_coin = ImageTexture.create_from_image(img)
	var c := UiKit.center()
	add_child(c)
	var p := UiKit.panel()
	p.custom_minimum_size = Vector2(660, 0)
	c.add_child(p)
	var v := UiKit.vbox(8)
	p.add_child(v)
	var head := UiKit.hbox(12)
	v.add_child(head)
	var frame := PanelContainer.new()
	var fs := UiKit.panel_style(Color(0.05, 0.05, 0.12), Color(0.45, 0.38, 0.22))
	fs.set_content_margin_all(4)
	fs.shadow_size = 0
	frame.add_theme_stylebox_override("panel", fs)
	frame.add_child(UiKit.icon("phineus_se", 3))
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head.add_child(frame)
	var words := UiKit.vbox(4)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(words)
	words.add_child(UiKit.label("Phineus, the blind seer", 20, UiKit.GOLD))
	var g := UiKit.label("“%s”" % GREETING, 14, UiKit.TEXT)
	g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(g)
	var next_id := ""
	if Game.room_index + 1 < Game.rooms.size():
		next_id = Game.rooms[Game.room_index + 1].get("id", "")
	var pr := UiKit.label("“%s”" % PROPHECIES.get(next_id, DEFAULT_PROPHECY), 14, Color(0.75, 0.82, 1.0))
	pr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_child(pr)

	var purse := UiKit.hbox(6)
	purse.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(purse)
	purse.add_child(UiKit.label("Your purse", 12, UiKit.DIM))
	purse.add_child(UiKit.icon("hud_obol", 2))
	_obols = UiKit.label("", 16, UiKit.GOLD)
	purse.add_child(_obols)
	_rows = UiKit.vbox(4)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The goods scroll (following the focused button) so the full stock fits on screen.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.add_child(_rows)
	v.add_child(scroll)
	_status = UiKit.label("", 14, UiKit.DIM, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_status)
	var buttons := UiKit.hbox(12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(buttons)
	var save := UiKit.button("Save here")
	save.pressed.connect(func():
		Game.take_snapshot()
		_status.text = "Saved. If you fall, you wake here with what you carry now.")
	buttons.add_child(save)
	var leave := UiKit.button("Leave")
	leave.pressed.connect(close)
	buttons.add_child(leave)
	_build_rows()
	if _first:
		_first.grab_focus()


func _items() -> Array:
	var out: Array = []
	for id in Game.weapons.keys() + Game.armours.keys():
		if Game.SHOP_STOCK.has(id) or Game.owned.has(id):
			out.append(id)
	out.append("pomegranate")
	return out


func _build_rows() -> void:
	for c in _rows.get_children():
		c.queue_free()
	_first = null
	_obols.text = str(Game.obols)
	var section := ""
	for id in _items():
		var kind := "Weapons" if Game.weapons.has(id) else ("Armour" if Game.armours.has(id) else "Supplies")
		if kind != section:
			section = kind
			_rows.add_child(_section(kind))
		var row := UiKit.hbox(10)
		_rows.add_child(row)
		var slot := PanelContainer.new()
		var ss := UiKit.panel_style(Color(0.05, 0.05, 0.12, 0.9), Color(0.86, 0.68, 0.32) if _is_equipped(id) else Color(0.25, 0.27, 0.42))
		ss.set_content_margin_all(2)
		ss.shadow_size = 0
		slot.add_theme_stylebox_override("panel", ss)
		slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var ic := UiKit.icon(_icon_of(id), 2)
		slot.add_child(ic)
		row.add_child(slot)
		var info := UiKit.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var owned: bool = Game.owned.has(id) and id != "pomegranate"
		info.add_child(UiKit.label(Game.display_name_of(id), 15, UiKit.GOLD if owned else UiKit.TEXT))
		var d := UiKit.label(Game.description_of(id), 12, UiKit.DIM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(380, 0)
		info.add_child(d)
		var b := UiKit.button(_action_text(id), 16 if _action_text(id).is_valid_int() else 14)
		b.custom_minimum_size = Vector2(104, 0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = _is_equipped(id)
		if _action_text(id).is_valid_int():
			b.icon = _coin
			b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
			if Game.price_of(id) > Game.obols:
				b.add_theme_color_override("font_color", Color(0.75, 0.45, 0.4))
		b.pressed.connect(_on_item.bind(id))
		row.add_child(b)
		if _first == null and not b.disabled:
			_first = b


## A small caps heading with a gold rule, between groups of goods.
func _section(t: String) -> Control:
	var h := UiKit.hbox(8)
	var l := UiKit.label(t.to_upper(), 12, UiKit.GOLD)
	h.add_child(l)
	var rule := ColorRect.new()
	rule.color = Color(0.86, 0.68, 0.32, 0.35)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(rule)
	return h


func _icon_of(id: String) -> String:
	var name := "item_" + id
	for dir in Art.SEARCH:
		if ResourceLoader.exists(dir + name + ".png"):
			return name
	return "item_xiphos"


func _is_equipped(id: String) -> bool:
	return id == Game.weapon_id or id == Game.armour_id


func _action_text(id: String) -> String:
	if id == "pomegranate":
		return str(Game.price_of(id))
	if _is_equipped(id):
		return "Worn" if Game.armours.has(id) else "In hand"
	if Game.owned.has(id):
		return "Equip"
	return str(Game.price_of(id))


func _on_item(id: String) -> void:
	var was_owned := Game.owned.has(id)
	var err := Game.buy(id)
	if err != "":
		_status.text = err
		Sfx.play("deny")
	elif id == "pomegranate":
		_status.text = "A pomegranate. You carry %d." % Game.pomegranates
	else:
		_status.text = ("You equip the %s." if was_owned else "You buy the %s.") % Game.display_name_of(id)
	_build_rows()
	await get_tree().process_frame
	if _first:
		_first.grab_focus()


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
