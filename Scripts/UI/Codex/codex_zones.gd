extends VBoxContainer
class_name CodexZones

## Pestaña ZONAS del códice: una franja ancha por zona, como un mapa de
## expedición. Número grande, arte de la zona, nombre, descripción, un medidor
## de peligro y las caras de sus amenazas y su jefe (en silueta las que aún no
## registraste en el bestiario).

const CATEGORY := "levels"
const ICON_DANGER := preload("res://Art/Ui/svg/icon_warning.svg")
const ICON_THREAT := preload("res://Art/Ui/svg/icon_damage.svg")
const BANNER_HEIGHT := 168
const DANGER_STEPS := 5
## zona -> {peligro (1-5), amenazas comunes, jefe}
const ZONE_INFO := {
	"distrito_1": {"danger": 2, "threats": ["follower", "shooter", "turret", "tank", "charger", "spawner"], "boss": "boss"},
	"distrito_2": {"danger": 4, "threats": ["follower", "tank", "spawner"], "boss": "boss2"},
	"distrito_3": {"danger": 5, "threats": [], "boss": "boss3"},
}

func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var ids = CodexData.DATA[CATEGORY].keys()
	for i in ids.size():
		add_child(_banner(ids[i], i + 1))

func _banner(id: String, number: int) -> Control:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var card = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	card.custom_minimum_size = Vector2(1300, BANNER_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var m = UIStyle.padded(14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(m)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	m.add_child(row)
	row.add_child(_number(number, unlocked))
	row.add_child(_zone_art(id, unlocked))
	row.add_child(_info(id, unlocked))
	row.add_child(_threats(id, unlocked))
	CodexKit.hover_pop(card)
	return card

func _number(number: int, unlocked: bool) -> Control:
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.custom_minimum_size = Vector2(90, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var zone = UIStyle.label("ZONA", 13, UIStyle.COLOR_MUTED)
	zone.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(zone)
	var n = UIStyle.label("%02d" % number, 56, UIStyle.COLOR_TEAL if unlocked else CodexKit.LOCKED_TEXT)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(n)
	return box

func _zone_art(id: String, unlocked: bool) -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["normal" if unlocked else "disabled"])
	frame.custom_minimum_size = Vector2(220, 138)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s = CodexKit.stack(Vector2(204, 122))
	frame.add_child(s)
	var art = CodexKit.art(CATEGORY, id, 110.0, unlocked)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	s.add_child(art)
	if not unlocked:
		s.add_child(CodexKit.lock_overlay(34))
	return frame

func _info(id: String, unlocked: bool) -> Control:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	var e = CodexKit.entry(CATEGORY, id)
	if unlocked:
		var name_lbl = UIStyle.label(_short_name(e.get("name", "")), 26, UIStyle.COLOR_GOLD)
		box.add_child(name_lbl)
		box.add_child(CodexKit.lore(e.get("lore", ""), 13, 2))
	else:
		box.add_child(CodexKit.title(CATEGORY, id, false, 26))
		box.add_child(CodexKit.redacted(id, 2))
	box.add_child(_danger_meter(ZONE_INFO.get(id, {}).get("danger", 0), unlocked))
	return box

# Medidor de peligro: barritas que se llenan de amarillo a rojo.
func _danger_meter(level: int, unlocked: bool) -> Control:
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	var ic = UIStyle.icon(ICON_DANGER, 18)
	ic.modulate = UIStyle.COLOR_WARNING if unlocked else CodexKit.LOCKED_TEXT
	row.add_child(ic)
	for i in DANGER_STEPS:
		var bar = ColorRect.new()
		bar.custom_minimum_size = Vector2(26, 10)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var lit = unlocked and i < level
		var heat = UIStyle.COLOR_WARNING.lerp(Color("#E2554B"), float(i) / (DANGER_STEPS - 1))
		bar.color = heat if lit else CodexKit.REDACTED
		row.add_child(bar)
	return row

# Caras de las amenazas comunes y, aparte y en dorado, el jefe de la zona.
func _threats(id: String, zone_unlocked: bool) -> Control:
	var info = ZONE_INFO.get(id, {})
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for enemy in info.get("threats", []):
		row.add_child(_face(enemy, zone_unlocked, false))
	if info.get("boss", "") != "":
		var gap = Control.new()
		gap.custom_minimum_size = Vector2(8, 0)
		row.add_child(gap)
		row.add_child(_face(info.boss, zone_unlocked, true))
	box.add_child(row)
	return box

func _face(enemy_id: String, zone_unlocked: bool, is_boss: bool) -> Control:
	var known = zone_unlocked and CodexKit.is_unlocked("enemies", enemy_id)
	var chip = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if is_boss and known else ("normal" if known else "disabled")])
	var face_size = 58.0 if is_boss else 46.0
	chip.custom_minimum_size = Vector2(face_size, face_size)
	chip.mouse_filter = Control.MOUSE_FILTER_PASS
	chip.tooltip_text = CodexKit.entry("enemies", enemy_id).get("name", "") if known else "???"
	chip.add_child(CodexKit.art("enemies", enemy_id, face_size - 12.0, known))
	return chip

# "Zona 1: Distrito Asphodel" -> "Distrito Asphodel" (el número ya va aparte).
func _short_name(full: String) -> String:
	var colon = full.find(":")
	return full.substr(colon + 1).strip_edges() if colon >= 0 else full
