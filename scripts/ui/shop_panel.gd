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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.backdrop(0.55))
	var c := UiKit.center()
	add_child(c)
	var p := UiKit.panel()
	p.custom_minimum_size = Vector2(620, 0)
	c.add_child(p)
	var v := UiKit.vbox(8)
	p.add_child(v)
	var head := UiKit.hbox(12)
	v.add_child(head)
	head.add_child(UiKit.icon("phineus_se", 2))
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

	_obols = UiKit.label("", 15, UiKit.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	v.add_child(_obols)
	_rows = UiKit.vbox(4)
	v.add_child(_rows)
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
	_obols.text = "Obols: %d" % Game.obols
	for id in _items():
		var row := UiKit.hbox(10)
		_rows.add_child(row)
		var info := UiKit.vbox(0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(UiKit.label(Game.display_name_of(id), 15))
		var d := UiKit.label(Game.description_of(id), 12, UiKit.DIM)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(380, 0)
		info.add_child(d)
		var b := UiKit.button(_action_text(id), 14)
		b.custom_minimum_size = Vector2(130, 0)
		b.disabled = _is_equipped(id)
		b.pressed.connect(_on_item.bind(id))
		row.add_child(b)
		if _first == null and not b.disabled:
			_first = b


func _is_equipped(id: String) -> bool:
	return id == Game.weapon_id or id == Game.armour_id


func _action_text(id: String) -> String:
	if id == "pomegranate":
		return "Buy · %d" % Game.price_of(id)
	if _is_equipped(id):
		return "Equipped"
	if Game.owned.has(id):
		return "Equip"
	return "Buy · %d" % Game.price_of(id)


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
