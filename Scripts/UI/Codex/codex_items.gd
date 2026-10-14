extends HBoxContainer
class_name CodexItems

## Pestaña ITEMS del códice: grilla compacta de casilleros separada en
## prótesis (torso, piernas, brazos) y piezas de arma, con una ficha lateral
## que muestra el objeto que tengas bajo el mouse (o el último que elegiste).

const CATEGORY := "items"
const BODY_PREFIXES := ["torso_", "piernas_", "brazo_"]
const ICON_BODY := preload("res://Art/Ui/svg/icon_torso.svg")
const ICON_PARTS := preload("res://Art/Ui/svg/icon_damage.svg")
const TILE := Vector2(84, 84)
const COLUMNS := 9

var _card: VBoxContainer
var _tiles: Dictionary = {}
var _selected: String = ""

func _ready() -> void:
	add_theme_constant_override("separation", 22)
	var left = VBoxContainer.new()
	left.add_theme_constant_override("separation", 16)
	left.add_child(_section("PRÓTESIS", ICON_BODY, _ids(true)))
	left.add_child(_section("PIEZAS DE ARMA", ICON_PARTS, _ids(false)))
	add_child(left)
	add_child(_build_card_panel())
	_select(_first_id())

func _section(header: String, icon_tex: Texture2D, ids: Array) -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var unlocked = 0
	for id in ids:
		if CodexKit.is_unlocked(CATEGORY, id): unlocked += 1
	box.add_child(CodexKit.section_header(icon_tex, header, "%d / %d" % [unlocked, ids.size()]))
	var grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for id in ids:
		grid.add_child(_tile(id))
	box.add_child(grid)
	return box

func _tile(id: String) -> Control:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var btn = Button.new()
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = TILE
	UIStyle.style_slot_button(btn, "normal" if unlocked else "disabled")
	var m = UIStyle.padded(12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)
	m.add_child(CodexKit.art(CATEGORY, id, 56.0, unlocked))
	btn.mouse_entered.connect(_select.bind(id))
	btn.pressed.connect(_select.bind(id))
	_tiles[id] = btn
	return btn

# --- Ficha lateral ---

func _build_card_panel() -> Control:
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	panel.custom_minimum_size = Vector2(440, 440)
	var m = UIStyle.padded(20)
	panel.add_child(m)
	_card = VBoxContainer.new()
	_card.add_theme_constant_override("separation", 12)
	m.add_child(_card)
	return panel

func _select(id: String) -> void:
	if id == _selected or id == "": return
	_selected = id
	for key in _tiles:
		_tiles[key].set_pressed_no_signal(key == id)
	for c in _card.get_children():
		_card.remove_child(c)
		c.queue_free()
	_fill_card(id)

func _fill_card(id: String) -> void:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var center = CenterContainer.new()
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if unlocked else "disabled"])
	frame.custom_minimum_size = Vector2(150, 150)
	var s = CodexKit.stack(Vector2(132, 132))
	frame.add_child(s)
	s.add_child(CodexKit.glow_backdrop(UIStyle.COLOR_TEAL if unlocked else CodexKit.LOCKED_TEXT))
	var m = UIStyle.padded(16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(CodexKit.art(CATEGORY, id, 100.0, unlocked))
	s.add_child(m)
	if not unlocked:
		s.add_child(CodexKit.lock_overlay(34))
	center.add_child(frame)
	_card.add_child(center)

	var is_body = _is_body(id)
	_card.add_child(CodexKit.tag(ICON_BODY if is_body else ICON_PARTS, "PRÓTESIS" if is_body else "PIEZA DE ARMA", UIStyle.COLOR_TEAL if unlocked else CodexKit.LOCKED_TEXT))
	_card.add_child(CodexKit.title(CATEGORY, id, unlocked, 22))
	var e = CodexKit.entry(CATEGORY, id)
	if unlocked:
		_card.add_child(CodexKit.stat_chips(e.get("stats", ""), 13))
		_card.add_child(CodexKit.lore(e.get("lore", ""), 13))
	else:
		_card.add_child(CodexKit.redacted(id, 3))

# --- Detalles ---

func _ids(body: bool) -> Array:
	var out = []
	for id in CodexData.DATA[CATEGORY].keys():
		if _is_body(id) == body:
			out.append(id)
	return out

func _is_body(id: String) -> bool:
	for p in BODY_PREFIXES:
		if id.begins_with(p): return true
	return false

func _first_id() -> String:
	for id in CodexData.DATA[CATEGORY].keys():
		if CodexKit.is_unlocked(CATEGORY, id): return id
	return CodexData.DATA[CATEGORY].keys()[0]
