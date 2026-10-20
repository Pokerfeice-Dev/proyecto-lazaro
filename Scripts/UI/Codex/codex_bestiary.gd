extends HBoxContainer
class_name CodexBestiary

## Pestaña BESTIARIO del códice: a la izquierda los especímenes (cada uno con
## su idle animado en miniatura) y a la derecha una vitrina con el elegido en
## grande, su descripción y sus stats. Los jefes tienen marco dorado.
## Pasar el mouse o hacer clic en un espécimen lo muestra en la vitrina.

const CATEGORY := "enemies"
const BOSSES := ["boss", "boss2", "boss3"]
const ICON_BOSS := preload("res://Art/Ui/svg/icon_warning.svg")
const ICON_ENEMY := preload("res://Art/Ui/svg/icon_damage.svg")
const TILE_SIZE := Vector2(112, 112)
const COLUMNS := 3

var _detail: VBoxContainer
var _tiles: Dictionary = {}
var _selected: String = ""

func _ready() -> void:
	add_theme_constant_override("separation", 24)
	add_child(_build_grid())
	add_child(_build_detail_panel())
	_select(_first_id())

# --- Grilla de especímenes ---

func _build_grid() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	var ids = CodexData.DATA[CATEGORY].keys()
	box.add_child(CodexKit.section_header(ICON_ENEMY, "ESPECÍMENES", "%d / %d" % [_count_unlocked(ids), ids.size()]))
	var grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for id in ids:
		grid.add_child(_tile(id))
	box.add_child(grid)
	return box

func _tile(id: String) -> Control:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var btn = Button.new()
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = TILE_SIZE
	UIStyle.style_slot_button(btn, "equipped" if id in BOSSES and unlocked else ("normal" if unlocked else "disabled"))
	var m = UIStyle.padded(10)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)
	m.add_child(CodexAnim.create(CATEGORY, id, 84.0, unlocked, 2))
	if id in BOSSES:
		btn.add_child(_corner_badge())
	CodexKit.pad_select(btn, _select.bind(id))
	btn.pressed.connect(_select.bind(id))
	_tiles[id] = btn
	return btn

func _corner_badge() -> Control:
	var ic = UIStyle.icon(ICON_BOSS, 18)
	ic.modulate = UIStyle.COLOR_GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.position = Vector2(TILE_SIZE.x - 24, 6)
	return ic

# --- Vitrina ---

func _build_detail_panel() -> Control:
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(860, 470)
	var m = UIStyle.padded(22)
	panel.add_child(m)
	_detail = VBoxContainer.new()
	m.add_child(_detail)
	return panel

func _select(id: String) -> void:
	if id == _selected or id == "": return
	_selected = id
	for key in _tiles:
		_tiles[key].set_pressed_no_signal(key == id)
	for c in _detail.get_children():
		_detail.remove_child(c)
		c.queue_free()
	_detail.add_child(_detail_content(id))
	_detail.modulate.a = 0.0
	_detail.create_tween().tween_property(_detail, "modulate:a", 1.0, 0.15)

func _detail_content(id: String) -> Control:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	row.add_child(_tank(id, unlocked))
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 12)
	info.add_child(_kind_tag(id, unlocked))
	info.add_child(CodexKit.title(CATEGORY, id, unlocked, 30))
	info.add_child(UIStyle.divider())
	var e = CodexKit.entry(CATEGORY, id)
	if unlocked:
		info.add_child(CodexKit.lore(e.get("lore", ""), 15))
		info.add_child(CodexKit.stat_chips(e.get("stats", ""), 13))
	else:
		info.add_child(CodexKit.redacted(id, 4))
		info.add_child(CodexKit.tag(CodexKit.ICON_LOCK, "SIN REGISTRAR", CodexKit.LOCKED_TEXT))
	row.add_child(info)
	return row

func _kind_tag(id: String, unlocked: bool) -> Control:
	var number = "Nº %02d" % (CodexData.DATA[CATEGORY].keys().find(id) + 1)
	if id in BOSSES:
		return CodexKit.tag(ICON_BOSS, "JEFE · " + number, UIStyle.COLOR_GOLD if unlocked else CodexKit.LOCKED_TEXT)
	return CodexKit.tag(ICON_ENEMY, "ESPÉCIMEN · " + number, UIStyle.COLOR_TEAL if unlocked else CodexKit.LOCKED_TEXT)

# Vitrina de contención: brillo de fondo, base iluminada y el idle en grande.
func _tank(id: String, unlocked: bool) -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if id in BOSSES and unlocked else "normal"])
	frame.custom_minimum_size = Vector2(300, 400)
	var s = CodexKit.stack(Vector2(280, 380))
	frame.add_child(s)
	var glow_color = UIStyle.COLOR_GOLD if id in BOSSES else UIStyle.COLOR_TEAL
	s.add_child(CodexKit.glow_backdrop(glow_color if unlocked else CodexKit.LOCKED_TEXT))
	s.add_child(_tank_floor(glow_color if unlocked else CodexKit.LOCKED_TEXT))
	var m = UIStyle.padded(18)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(CodexAnim.create(CATEGORY, id, 240.0, unlocked, PixelIcon.FIT))
	s.add_child(m)
	if not unlocked:
		s.add_child(CodexKit.lock_overlay(40))
	return frame

func _tank_floor(color: Color) -> Control:
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line = ColorRect.new()
	line.color = Color(color, 0.55)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.anchor_left = 0.12
	line.anchor_right = 0.88
	line.anchor_top = 0.88
	line.anchor_bottom = 0.88
	line.offset_bottom = 3
	holder.add_child(line)
	return holder

# --- Detalles ---

func _first_id() -> String:
	var ids = CodexData.DATA[CATEGORY].keys()
	for id in ids:
		if CodexKit.is_unlocked(CATEGORY, id):
			return id
	return ids[0] if not ids.is_empty() else ""

func _count_unlocked(ids: Array) -> int:
	var n = 0
	for id in ids:
		if CodexKit.is_unlocked(CATEGORY, id): n += 1
	return n
