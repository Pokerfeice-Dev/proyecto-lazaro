extends GridContainer
class_name CodexNpcs

## Pestaña NPCs del códice: un retrato grande por personaje, parado sobre un
## pedestal iluminado y con su idle animado. Al lado, el nombre, su rol y su
## historia. Los que todavía no conociste quedan en silueta.

const CATEGORY := "npcs"
const ICON_ROLE := preload("res://Art/Ui/svg/icon_info.svg")
const CARD_SIZE := Vector2(640, 300)

func _ready() -> void:
	columns = 2
	add_theme_constant_override("h_separation", 18)
	add_theme_constant_override("v_separation", 18)
	for id in CodexData.DATA[CATEGORY].keys():
		add_child(_card(id))

func _card(id: String) -> Control:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var card = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var m = UIStyle.padded(18)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(m)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	m.add_child(row)
	row.add_child(_portrait(id, unlocked))
	row.add_child(_info(id, unlocked))
	CodexKit.hover_pop(card)
	return card

# Retrato: brillo detrás, pedestal abajo y el personaje animado encima.
func _portrait(id: String, unlocked: bool) -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if unlocked else "disabled"])
	frame.custom_minimum_size = Vector2(210, 260)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s = CodexKit.stack(Vector2(190, 240))
	frame.add_child(s)
	var color = UIStyle.COLOR_GOLD if unlocked else CodexKit.LOCKED_TEXT
	s.add_child(CodexKit.glow_backdrop(color))
	s.add_child(_pedestal(color))
	var m = MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 34)
	m.add_child(CodexAnim.create(CATEGORY, id, 190.0, unlocked))
	s.add_child(m)
	if not unlocked:
		s.add_child(CodexKit.lock_overlay(40))
	return frame

func _pedestal(color: Color) -> Control:
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top = ColorRect.new()
	top.color = Color(color, 0.6)
	_place(top, 0.2, 0.8, 0.86, 3)
	holder.add_child(top)
	var base = ColorRect.new()
	base.color = Color(color, 0.18)
	_place(base, 0.16, 0.84, 0.875, 14)
	holder.add_child(base)
	return holder

func _place(r: ColorRect, left: float, right: float, top: float, height: float) -> void:
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.anchor_left = left
	r.anchor_right = right
	r.anchor_top = top
	r.anchor_bottom = top
	r.offset_bottom = height

func _info(id: String, unlocked: bool) -> Control:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	box.add_child(CodexKit.title(CATEGORY, id, unlocked, 26))
	var e = CodexKit.entry(CATEGORY, id)
	if unlocked:
		box.add_child(CodexKit.tag(ICON_ROLE, _role(e.get("stats", "")), UIStyle.COLOR_TEAL))
		box.add_child(UIStyle.divider())
		box.add_child(CodexKit.lore(e.get("lore", ""), 14))
	else:
		box.add_child(UIStyle.divider())
		box.add_child(CodexKit.redacted(id, 4))
		box.add_child(CodexKit.tag(CodexKit.ICON_LOCK, "SIN CONOCER", CodexKit.LOCKED_TEXT))
	return box

# "Rol: Comerciante / Proveedor" -> "COMERCIANTE / PROVEEDOR"
func _role(stats: String) -> String:
	var colon = stats.find(":")
	return (stats.substr(colon + 1) if colon >= 0 else stats).strip_edges().to_upper()
