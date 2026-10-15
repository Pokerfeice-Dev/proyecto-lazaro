extends PanelContainer
class_name CodexSynergyCard

## Ficha grande de una sinergia en la pestaña SINERGIAS del códice.
## Descubierta (ya armada en una run): sprite, nombre, arma, receta y descripción.
## Receta comprada en O.M.N.I.A. pero sin descubrir: todo menos el sprite, que
## queda en silueta con una lupa.
## Bloqueada: solo se ve para qué arma es. El sprite queda como silueta con un
## candado que late, el nombre son caracteres cifrados que cambian solos, las
## piezas de la receta están tapadas, la descripción está tachada en bloques y
## un sello de rayas se desliza encima de toda la ficha.
## Uso: grid.add_child(CodexSynergyCard.create("snowman"))

const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
const SEAL_SHADER := preload("res://Art/Ui/shaders/sello_bloqueado.gdshader")
const ICON_LOCK := preload("res://Art/Ui/svg/icon_lock.svg")
const ICON_SEARCH := preload("res://Art/Ui/svg/icon_search.svg")
const CARD_SIZE := Vector2(420, 236)
const GLYPHS := "#%&@$*+=<>/?01"
const GLYPH_INTERVAL := 0.12
const LOCKED_TEXT := Color("#4E6B73")

var syn_id: String = ""
var _unlocked: bool = false # receta comprada
var _discovered: bool = false # armada en una run
var _name_label: Label
var _name_length: int = 8
var _glyph_timer: float = 0.0

static func create(id: String) -> CodexSynergyCard:
	var card = CodexSynergyCard.new()
	card.syn_id = id
	return card

func _ready() -> void:
	var def: Dictionary = SynergyManager.SYNERGIES.get(syn_id, {})
	_unlocked = GameData.is_synergy_unlocked(syn_id)
	_discovered = _unlocked and GameData.is_synergy_discovered(syn_id)
	_name_length = String(def.get("name", "????????")).length()
	custom_minimum_size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS
	var style = "equipped" if _discovered else ("normal" if _unlocked else "disabled")
	add_theme_stylebox_override("panel", UIStyle.nine_slice(UIStyle.TEX_SLOT[style]))

	var m = UIStyle.padded(16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(m)
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	m.add_child(row)
	row.add_child(_build_art())
	row.add_child(_build_info(def))
	if not _unlocked:
		_add_seal()
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))

func _process(delta: float) -> void:
	if _discovered: return
	_glyph_timer -= delta
	if _glyph_timer > 0.0: return
	_glyph_timer = GLYPH_INTERVAL
	_name_label.text = "Sinergia desconocida"

# --- Partes de la ficha ---

func _build_art() -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["normal" if _unlocked else "disabled"])
	frame.custom_minimum_size = Vector2(140, 140)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art = UIStyle.icon(OmniaCatalog.synergy_icon(syn_id) if _discovered else null, 112)
	art.self_modulate = OmniaCatalog.synergy_tint(syn_id)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	if not _discovered:
		var mat = ShaderMaterial.new()
		mat.shader = LOCKED_SHADER
		mat.set_shader_parameter("blur", 2.0 if not _unlocked else 1.0)
		mat.set_shader_parameter("phase", fmod(syn_id.hash() * 0.0001, 1.0))
		art.material = mat
		frame.add_child(_build_lock() if not _unlocked else _build_mark(ICON_SEARCH, UIStyle.COLOR_TEAL))
	return frame

# Candado al centro de la silueta que late despacio.
func _build_lock() -> Control:
	return _build_mark(ICON_LOCK, UIStyle.COLOR_GOLD)

# Ícono que late sobre la silueta: candado (bloqueada) o lupa (falta descubrirla).
func _build_mark(icon_tex: Texture2D, color: Color) -> Control:
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lock = UIStyle.icon(icon_tex, 34)
	lock.modulate = color
	lock.pivot_offset = Vector2(17, 17)
	center.add_child(lock)
	var t = lock.create_tween().set_loops()
	t.tween_property(lock, "modulate:a", 0.45, 0.9).set_trans(Tween.TRANS_SINE)
	t.tween_property(lock, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	return center

func _build_info(def: Dictionary) -> Control:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)

	_name_label = UIStyle.label(def.get("name", "") if _discovered else "Sinergia desconocida", 24, UIStyle.COLOR_GOLD if _discovered else LOCKED_TEXT)
	box.add_child(_name_label)
	if _discovered:
		box.add_child(_weapon_line(def))
	box.add_child(_recipe_row())
	if _unlocked:
		var desc = UIStyle.label(def.get("description", "") if _discovered else OmniaCatalog.RESEARCH.clues.get(syn_id, ""), 13, UIStyle.COLOR_MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.max_lines_visible = 3 if _discovered else 2
		desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		box.add_child(desc)
		if not _discovered:
			box.add_child(_undiscovered_tag())
	else:
		box.add_child(_redacted_lines())
	return box

# Lo único que se ve siempre: para qué arma es la sinergia.
func _weapon_line(def: Dictionary) -> Control:
	var line = HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	var weapon_id = def.get("required_weapon", "")
	var icon = _codex_icon("weapons", weapon_id)
	if icon:
		line.add_child(UIStyle.icon(icon, 22))
	var text = "SINERGIA · " + SynergyManager.get_weapon_display_name(weapon_id).to_upper()
	line.add_child(UIStyle.label(text, 14, UIStyle.COLOR_TEAL))
	return line

func _recipe_row() -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var parts = OmniaCatalog.synergy_ingredients(syn_id)
	for i in parts.size():
		row.add_child(_recipe_chip(parts[i], OmniaCatalog.is_ingredient_revealed(syn_id, i)))
	return row

func _recipe_chip(part: Dictionary, visible_part: bool) -> Control:
	var chip = UIStyle.panel(UIStyle.TEX_SLOT["normal" if visible_part else "disabled"])
	chip.custom_minimum_size = Vector2(44, 44)
	if visible_part:
		chip.tooltip_text = part.name
		chip.add_child(UIStyle.icon(part.icon, 30))
	else:
		var q = UIStyle.label("?", 20, LOCKED_TEXT)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chip.add_child(q)
	return chip

# Texto "tachado": bloques de distinto largo en vez de la descripción.
func _undiscovered_tag() -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var ic = UIStyle.icon(ICON_SEARCH, 16)
	ic.modulate = UIStyle.COLOR_TEAL
	row.add_child(ic)
	row.add_child(UIStyle.label("RECETA · ÁRMALA EN UNA RUN", 12, UIStyle.COLOR_TEAL))
	return row

func _redacted_lines() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var rng = RandomNumberGenerator.new()
	rng.seed = syn_id.hash()
	for i in 3:
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		var words = rng.randi_range(2, 4)
		for w in words:
			var block = ColorRect.new()
			block.color = Color("#1B3138")
			block.custom_minimum_size = Vector2(rng.randi_range(26, 70), 9)
			block.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.add_child(block)
		box.add_child(line)
	return box

func _add_seal() -> void:
	var seal = ColorRect.new()
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	mat.shader = SEAL_SHADER
	seal.material = mat
	add_child(seal)

# --- Detalles ---

func _on_hover(inside: bool) -> void:
	pivot_offset = size / 2.0
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2(1.03, 1.03) if inside else Vector2.ONE, 0.15).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "modulate", Color(1.15, 1.15, 1.15) if inside else Color.WHITE, 0.15)

func _cipher(length: int) -> String:
	var out = ""
	for i in length:
		out += GLYPHS[randi() % GLYPHS.length()]
	return out

func _codex_icon(category: String, id: String) -> Texture2D:
	return CodexData.DATA.get(category, {}).get(id, {}).get("icon", null)
