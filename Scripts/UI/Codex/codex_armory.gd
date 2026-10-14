extends VBoxContainer
class_name CodexArmory

## Pestaña ARMAMENTO del códice: un estante por tipo (distancia y cuerpo a
## cuerpo) con fichas anchas. Cada ficha tiene el arma en grande, su
## descripción, los stats en chips y los íconos de sus sinergias (en color las
## que ya descubriste, en silueta las que faltan).

const CATEGORY := "weapons"
const RANGED := ["pistol", "uzi", "shotgun"]
const MELEE := ["daga", "hacha", "maze"]
const ICON_RANGED := preload("res://Art/Ui/svg/icon_projectiles.svg")
const ICON_MELEE := preload("res://Art/Ui/svg/icon_damage.svg")
const CARD_SIZE := Vector2(660, 170)

func _ready() -> void:
	add_theme_constant_override("separation", 18)
	add_child(_shelf("DISTANCIA", ICON_RANGED, RANGED))
	add_child(_shelf("CUERPO A CUERPO", ICON_MELEE, MELEE))

func _shelf(header: String, icon_tex: Texture2D, ids: Array) -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	var unlocked = 0
	for id in ids:
		if CodexKit.is_unlocked(CATEGORY, id): unlocked += 1
	box.add_child(CodexKit.section_header(icon_tex, header, "%d / %d" % [unlocked, ids.size()]))
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for id in ids:
		grid.add_child(_card(id, icon_tex))
	box.add_child(grid)
	return box

func _card(id: String, type_icon: Texture2D) -> Control:
	var unlocked = CodexKit.is_unlocked(CATEGORY, id)
	var card = UIStyle.panel(UIStyle.TEX_SLOT["normal" if unlocked else "disabled"])
	card.custom_minimum_size = CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var m = UIStyle.padded(14)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(m)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	m.add_child(row)
	row.add_child(_weapon_frame(id, unlocked))
	row.add_child(_info(id, unlocked, type_icon))
	CodexKit.hover_pop(card)
	return card

# Arma sobre un brillo, girada un poco como si estuviera colgada en el estante.
func _weapon_frame(id: String, unlocked: bool) -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if unlocked else "disabled"])
	frame.custom_minimum_size = Vector2(138, 138)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s = CodexKit.stack(Vector2(120, 120))
	frame.add_child(s)
	s.add_child(CodexKit.glow_backdrop(UIStyle.COLOR_TEAL if unlocked else CodexKit.LOCKED_TEXT))
	var m = UIStyle.padded(10)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(CodexKit.art(CATEGORY, id, 100.0, unlocked))
	s.add_child(m)
	if not unlocked:
		s.add_child(CodexKit.lock_overlay(30))
	return frame

func _info(id: String, unlocked: bool, type_icon: Texture2D) -> Control:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	var head = HBoxContainer.new()
	head.add_child(CodexKit.title(CATEGORY, id, unlocked, 22))
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(_synergy_row(id, unlocked))
	box.add_child(head)
	var e = CodexKit.entry(CATEGORY, id)
	if unlocked:
		box.add_child(CodexKit.lore(e.get("lore", ""), 13, 2))
		box.add_child(CodexKit.stat_chips(e.get("stats", "")))
	else:
		box.add_child(CodexKit.redacted(id, 2))
		box.add_child(CodexKit.tag(type_icon, "SIN REGISTRAR", CodexKit.LOCKED_TEXT))
	return box

# Íconos de las sinergias del arma; el tooltip dice el nombre si ya la tienes.
func _synergy_row(weapon_id: String, weapon_unlocked: bool) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for syn_id in OmniaCatalog.synergy_ids():
		if SynergyManager.SYNERGIES.get(syn_id, {}).get("required_weapon", "") != weapon_id:
			continue
		# el nombre se conoce al comprar la receta; el sprite, al armarla en una run
		var has_recipe = weapon_unlocked and GameData.is_synergy_unlocked(syn_id)
		var known = has_recipe and GameData.is_synergy_discovered(syn_id)
		var chip = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if known else ("normal" if has_recipe else "disabled")])
		chip.custom_minimum_size = Vector2(34, 34)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.tooltip_text = SynergyManager.SYNERGIES[syn_id].get("name", "") if has_recipe else "Sinergia sin descubrir"
		var ic = UIStyle.icon(UIStyle.trimmed(OmniaCatalog.synergy_icon(syn_id)), 26)
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.self_modulate = OmniaCatalog.synergy_tint(syn_id)
		if not known:
			ic.material = CodexKit.silhouette(syn_id)
		chip.add_child(ic)
		row.add_child(chip)
	return row
