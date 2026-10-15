extends CanvasLayer
class_name WeaponSelectionMenu

## Ventana de selección de arma primaria y secundaria, con el estilo de la UI
## nueva (inventario/pausa). La usan la puerta de inicio de run y el terminal
## de la sala de entrenamiento; cada uno pasa su título, el texto del botón de
## confirmar y qué hacer al confirmar/cancelar.
##
## Prioriza íconos: cada arma es una ficha con su sprite, nombre, una línea
## corta y los íconos de sus sinergias (en color si ya las desbloqueaste, en
## silueta si no). Las armas bloqueadas quedan en silueta con un candado.
## ESC cancela y Enter confirma.

const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
const ICON_LOCK := preload("res://Art/Ui/svg/icon_lock.svg")
const ICON_CHECK := preload("res://Art/Ui/svg/icon_check.svg")
const ICON_RANGED := preload("res://Art/Ui/svg/icon_projectiles.svg")
const ICON_MELEE := preload("res://Art/Ui/svg/icon_damage.svg")
const CARD_SIZE := Vector2(360, 104)

const PRIMARY_WEAPONS := [
	{"id": "pistol", "name": "Pistola", "desc": "Precisión y cadencia estable"},
	{"id": "uzi", "name": "Uzi", "desc": "Fuego rápido a corta distancia"},
	{"id": "shotgun", "name": "Escopeta", "desc": "Gran dispersión a quemarropa"},
]
const MELEE_WEAPONS := [
	{"id": "daga", "name": "Daga", "desc": "Cortes veloces de corto alcance"},
	{"id": "hacha", "name": "Hacha de Mano", "desc": "Golpes potentes de rango medio"},
	{"id": "maze", "name": "Maza Pesada", "desc": "Lenta, con mucho empuje"},
]

var title_text: String = ""
var subtitle_text: String = ""
var confirm_text: String = ""
var on_confirm: Callable
var on_cancel: Callable
var selections: Dictionary = {}
var _window: Control

## Muestra la ventana. "caller" es cualquier Node del árbol (solo se usa para
## llegar a get_tree()). "on_confirm" recibe {"primary": id, "melee": id} ya
## guardado en GameData; "on_cancel" se llama si el jugador cancela.
static func show_popup(caller: Node, title: String, subtitle: String, confirm: String, confirm_cb: Callable = Callable(), cancel_cb: Callable = Callable()) -> void:
	var menu = WeaponSelectionMenu.new()
	menu.title_text = title
	menu.subtitle_text = subtitle
	menu.confirm_text = confirm
	menu.on_confirm = confirm_cb
	menu.on_cancel = cancel_cb
	caller.get_tree().root.add_child(menu)

func _ready() -> void:
	name = "WeaponSelectionMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 250
	get_tree().paused = true
	selections = {"primary": GameData.chosen_primary_weapon, "melee": GameData.chosen_melee_weapon}
	_build()
	_animate_in()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()
	elif event.is_action_pressed("ui_accept") and event is InputEventKey:
		get_viewport().set_input_as_handled()
		_confirm()

# --- Armado ---

func _build() -> void:
	var bg = ColorRect.new()
	bg.color = UIStyle.COLOR_BACKDROP
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_window = VBoxContainer.new()
	_window.add_theme_constant_override("separation", 0)
	center.add_child(_window)
	var tab = UIStyle.title_tab(title_text)
	tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_window.add_child(tab)

	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	_window.add_child(panel)
	var m = UIStyle.padded(24)
	panel.add_child(m)
	var body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	m.add_child(body)

	if subtitle_text != "":
		body.add_child(UIStyle.label(subtitle_text, 15, UIStyle.COLOR_MUTED))
	var cols = HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	body.add_child(cols)
	cols.add_child(_build_column("primary", "DISTANCIA", ICON_RANGED, PRIMARY_WEAPONS))
	cols.add_child(_vertical_divider())
	cols.add_child(_build_column("melee", "CUERPO A CUERPO", ICON_MELEE, MELEE_WEAPONS))
	body.add_child(UIStyle.divider())
	body.add_child(_build_footer())

func _build_column(slot: String, header: String, header_icon: Texture2D, weapons: Array) -> Control:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var ic = UIStyle.icon(header_icon, 22)
	ic.modulate = UIStyle.COLOR_TEAL
	head.add_child(ic)
	head.add_child(UIStyle.label(header, 16, UIStyle.COLOR_TEAL))
	col.add_child(head)
	var group = ButtonGroup.new()
	for w in weapons:
		col.add_child(_weapon_card(slot, w, group))
	return col

func _vertical_divider() -> Control:
	var line = ColorRect.new()
	line.color = Color(UIStyle.COLOR_MUTED, 0.25)
	line.custom_minimum_size = Vector2(2, 0)
	return line

func _build_footer() -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UIStyle.keycap("ESC"))
	var cancel = UIStyle.button("CANCELAR", false, Vector2(160, 48), 18)
	cancel.pressed.connect(_cancel)
	row.add_child(cancel)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var confirm = UIStyle.button(confirm_text, true, Vector2(240, 48), 20)
	confirm.pressed.connect(_confirm)
	row.add_child(confirm)
	row.add_child(UIStyle.keycap("ENTER"))
	return row

# --- Ficha de un arma ---

func _weapon_card(slot: String, w: Dictionary, group: ButtonGroup) -> Control:
	var unlocked = GameData.is_codex_unlocked("weapons", w.id)
	var btn = Button.new()
	btn.toggle_mode = true
	btn.button_group = group
	btn.custom_minimum_size = CARD_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not unlocked
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	btn.tooltip_text = "" if unlocked else "Se desbloquea en el terminal de chatarra"
	UIStyle.style_slot_button(btn, "normal" if unlocked else "disabled")

	var m = UIStyle.padded(12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	m.add_child(row)
	row.add_child(_weapon_art(w.id, unlocked))
	row.add_child(_weapon_info(w, unlocked))
	var check = _ignore(UIStyle.icon(ICON_CHECK, 26))
	check.modulate = UIStyle.COLOR_GOLD
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(check)

	check.visible = unlocked and selections[slot] == w.id
	if unlocked:
		btn.button_pressed = selections[slot] == w.id
		btn.toggled.connect(_on_card_toggled.bind(slot, w.id, check, btn))
	return btn

func _weapon_art(id: String, unlocked: bool) -> Control:
	var frame = _ignore(UIStyle.panel(UIStyle.TEX_SLOT["normal" if unlocked else "disabled"]))
	frame.custom_minimum_size = Vector2(76, 76)
	var art = _ignore(UIStyle.icon(UIStyle.trimmed(_codex_icon(id)), 60))
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(art)
	if not unlocked:
		var mat = ShaderMaterial.new()
		mat.shader = LOCKED_SHADER
		mat.set_shader_parameter("blur", 1.5)
		art.material = mat
		var center = _ignore(CenterContainer.new())
		var lock = _ignore(UIStyle.icon(ICON_LOCK, 26))
		lock.modulate = UIStyle.COLOR_GOLD
		center.add_child(lock)
		frame.add_child(center)
	return frame

func _weapon_info(w: Dictionary, unlocked: bool) -> Control:
	var box = _ignore(VBoxContainer.new())
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	box.add_child(_ignore(UIStyle.label(w.name, 18, UIStyle.COLOR_TEXT if unlocked else UIStyle.COLOR_MUTED.darkened(0.3))))
	if unlocked:
		box.add_child(_ignore(UIStyle.label(w.desc, 12, UIStyle.COLOR_MUTED)))
	box.add_child(_synergy_row(w.id, unlocked))
	return box

# Íconos de las sinergias del arma: en color las desbloqueadas, en silueta el resto.
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
		chip.custom_minimum_size = Vector2(28, 28)
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.tooltip_text = SynergyManager.SYNERGIES[syn_id].get("name", "") if known else "Sinergia sin descubrir"
		var ic = _ignore(UIStyle.icon(UIStyle.trimmed(OmniaCatalog.synergy_icon(syn_id)) if known else preload("res://Art/Ui/svg/icon_lock.svg"), 22))
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.self_modulate = OmniaCatalog.synergy_tint(syn_id)
		if not known:
			var mat = ShaderMaterial.new()
			mat.shader = LOCKED_SHADER
			mat.set_shader_parameter("blur", 1.0)
			ic.material = mat
		chip.add_child(ic)
		row.add_child(chip)
	return row

# --- Acciones ---

func _on_card_toggled(on: bool, slot: String, id: String, check: Control, btn: Control) -> void:
	check.visible = on
	if not on: return
	selections[slot] = id
	btn.pivot_offset = btn.size / 2.0
	btn.scale = Vector2(0.97, 0.97)
	btn.create_tween().tween_property(btn, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _confirm() -> void:
	GameData.chosen_primary_weapon = selections.primary
	GameData.chosen_melee_weapon = selections.melee
	GameData.save_game()
	_close()
	if on_confirm.is_valid():
		on_confirm.call(selections)

func _cancel() -> void:
	_close()
	if on_cancel.is_valid():
		on_cancel.call()

func _close() -> void:
	get_tree().paused = false
	queue_free()

func _animate_in() -> void:
	_window.modulate.a = 0.0
	await get_tree().process_frame
	_window.pivot_offset = _window.size / 2.0
	_window.scale = Vector2(0.94, 0.94)
	var t = _window.create_tween().set_parallel(true)
	t.tween_property(_window, "modulate:a", 1.0, 0.18)
	t.tween_property(_window, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Detalles ---

func _ignore(c: Control) -> Control:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _codex_icon(id: String) -> Texture2D:
	return CodexData.DATA.get("weapons", {}).get(id, {}).get("icon", null)
