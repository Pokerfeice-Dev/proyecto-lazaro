extends CanvasLayer
class_name OmniaMenu

## Ventana de O.M.N.I.A. (terminal de mejoras permanentes del Lab), con la
## misma línea visual que el inventario (ver UIStyle). Qué se vende y cómo se
## compra está en OmniaCatalog; acá solo se muestra.
##   Arriba: una pestaña por categoría, chatarra y "Esc / Cerrar".
##   Izquierda: las entradas de la categoría (filas, o fichas con sprite para
##   armas y sinergias). Lo que todavía no se desbloqueó se ve como silueta.
##   Derecha: el detalle de la entrada elegida y el botón para comprarla.
## Se usa así: var menu = OmniaMenu.new(); get_tree().root.add_child(menu)
## (el nodo se llama "UpgradesMenu" para que la pausa y el inventario lo respeten).

signal closed

const RESEARCH_SCENE = preload("res://Scenes/UI/synergy_recipe_research.tscn")

const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
const ICON_COIN := preload("res://Art/Scrap/Scrap_icon.png")
const ICON_CLOSE := preload("res://Art/Ui/svg/icon_close.svg")
const ICON_MOUSE := preload("res://Art/Ui/svg/icon_mouse.svg")
const ICON_LOCK := preload("res://Art/Ui/svg/icon_lock.svg")
const ICON_CHECK := preload("res://Art/Ui/svg/icon_check.svg")
const ICON_WARNING := preload("res://Art/Ui/svg/icon_warning.svg")
const ICON_SEARCH := preload("res://Art/Ui/svg/icon_search.svg")
const BUY_SOUND := "res://Audio/Sfx/Equipar_items.wav"
const CANCEL_SOUND := "res://Audio/Sfx/UI_cancelar.wav"
const TILE_SIZE := Vector2(196, 176)
const TILE_KINDS := ["weapon", "synergy"]
const KIND_NAMES := {"upgrade": "MEJORA", "weapon": "ARMA", "synergy": "SINERGIA", "protocol": "PROTOCOLO"}
const STATE_NAMES := {"disponible": "DISPONIBLE", "comprado": "DESBLOQUEADA", "bloqueado": "BLOQUEADA", "maximo": "NIVEL MÁXIMO", "activo": "ACTIVO"}

var _category: String = "ESTRUCTURA"
var _entries: Array = []
var _selected_id: String = ""
var _is_animating: bool = false
var _was_paused: bool = false

var _backdrop: ColorRect
var _window: MarginContainer
var _tabs: Dictionary = {}
var _scrap_label: Label
var _list_title: Label
var _list_info: Label
var _list_progress: Label
var _scroll: ScrollContainer
var _cards: Dictionary = {} # id -> Button
var _detail_box: VBoxContainer
var _active_protocol_label: Label

func _init() -> void:
	name = "UpgradesMenu"
	layer = 220
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	SceneTransition.set_menu_muffle(true)
	_build_ui()
	PadFocus.push_modal(self) # con joystick el foco no se va a lo de atrás
	_show_category(_category)
	_animate_in()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var recipe = _detail_box.get_node_or_null("ResearchRecipe") if is_instance_valid(_detail_box) else null
		if recipe and recipe.dismiss_confirmation():
			get_viewport().set_input_as_handled()
			return
		get_viewport().set_input_as_handled()
		_play_sound(CANCEL_SOUND)
		close()
	elif event.is_action_pressed("ui_tab_prev") or event.is_action_pressed("ui_tab_next"):
		get_viewport().set_input_as_handled()
		_cycle_category(-1 if event.is_action_pressed("ui_tab_prev") else 1)

# LB / RB del joystick: categoría anterior o siguiente.
func _cycle_category(step: int) -> void:
	var cats = OmniaCatalog.CATEGORIES
	var i = wrapi(cats.find(_category) + step, 0, cats.size())
	_selected_id = ""
	_show_category(cats[i])

# --- Construcción ---

func _build_ui() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)

	_backdrop = ColorRect.new()
	_backdrop.color = UIStyle.COLOR_BACKDROP
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_backdrop)

	_window = MarginContainer.new()
	_window.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		_window.add_theme_constant_override("margin_" + side, 40)
	root.add_child(_window)

	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	_window.add_child(panel)
	var inner = MarginContainer.new()
	inner.add_theme_constant_override("margin_left", 24)
	inner.add_theme_constant_override("margin_right", 24)
	inner.add_theme_constant_override("margin_top", 20)
	inner.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(inner)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	inner.add_child(vbox)
	_build_top_bar(vbox)
	_build_columns(vbox)
	_build_bottom_bar(vbox)

func _build_top_bar(parent: Control) -> void:
	var bar = HBoxContainer.new()
	parent.add_child(bar)

	var tabs = HBoxContainer.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("separation", 8)
	bar.add_child(tabs)
	for cat in OmniaCatalog.CATEGORIES:
		var tab = Button.new()
		tab.text = cat
		tab.custom_minimum_size = Vector2(170, 44)
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_size_override("font_size", 20)
		tab.pressed.connect(_on_tab_pressed.bind(cat))
		tabs.add_child(tab)
		_tabs[cat] = tab
	KeycapSwitch.add_tab_hints(tabs, 36.0)

	var right = HBoxContainer.new()
	right.add_theme_constant_override("separation", 24)
	bar.add_child(right)
	var coin_box = HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 8)
	coin_box.add_child(UIStyle.icon(ICON_COIN, 24))
	_scrap_label = UIStyle.label("0", 22, UIStyle.COLOR_GOLD)
	coin_box.add_child(_scrap_label)
	right.add_child(coin_box)

	var close_box = HBoxContainer.new()
	close_box.add_theme_constant_override("separation", 6)
	close_box.add_child(UIStyle.keycap("Esc"))
	var close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.icon = ICON_CLOSE
	close_btn.flat = true
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", UIStyle.COLOR_MUTED)
	close_btn.add_theme_color_override("font_hover_color", UIStyle.COLOR_TEXT)
	close_btn.pressed.connect(close)
	close_box.add_child(close_btn)
	right.add_child(close_box)

func _build_columns(parent: Control) -> void:
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	parent.add_child(columns)

	var left = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.63
	columns.add_child(left)
	_build_list_column(left)

	var right = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.37
	columns.add_child(right)
	_build_detail_column(right)

func _build_list_column(container: Control) -> void:
	var m = UIStyle.padded(20)
	container.add_child(m)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	m.add_child(box)

	var head = HBoxContainer.new()
	box.add_child(head)
	_list_title = UIStyle.label("", 24, UIStyle.COLOR_TEXT)
	_list_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_list_title)
	_list_progress = UIStyle.label("", 16, UIStyle.COLOR_MUTED)
	head.add_child(_list_progress)
	_list_info = UIStyle.label("", 15, UIStyle.COLOR_GOLD)
	box.add_child(_list_info)
	box.add_child(UIStyle.divider())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UIStyle.style_scroll(_scroll)
	box.add_child(_scroll)

func _build_detail_column(container: Control) -> void:
	var m = UIStyle.padded(20)
	container.add_child(m)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	m.add_child(box)

	box.add_child(UIStyle.label("DETALLE", 24, UIStyle.COLOR_TEXT))
	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 10)
	box.add_child(_detail_box)

	box.add_child(UIStyle.divider())
	var proto_row = HBoxContainer.new()
	var proto_title = UIStyle.label("Protocolo activo", 16, UIStyle.COLOR_MUTED)
	proto_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	proto_row.add_child(proto_title)
	_active_protocol_label = UIStyle.label("", 16, UIStyle.COLOR_TEAL)
	proto_row.add_child(_active_protocol_label)
	box.add_child(proto_row)

func _build_bottom_bar(parent: Control) -> void:
	var bar = UIStyle.panel(UIStyle.TEX_PANEL_FOOTER)
	parent.add_child(bar)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 36)
	bar.add_child(hbox)
	var select = _add_shortcut(hbox, UIStyle.icon(ICON_MOUSE, 24), "Seleccionar")
	KeycapSwitch.swap_icon(select, "DPAD")
	var buy = _add_shortcut(hbox, UIStyle.icon(ICON_MOUSE, 24), "Doble clic: comprar")
	KeycapSwitch.swap_icon(buy, "A")
	var buy_text = buy.get_parent().get_child(buy.get_parent().get_child_count() - 1) as Label
	var pad_text = UIStyle.label("Comprar", 18, UIStyle.COLOR_MUTED)
	buy_text.add_sibling(pad_text)
	KeycapSwitch.swap(buy_text, pad_text)
	_add_shortcut(hbox, UIStyle.keycap("Esc"), "Volver")

func _add_shortcut(parent: Control, key: Control, text: String) -> Control:
	var item = HBoxContainer.new()
	item.add_theme_constant_override("separation", 8)
	item.add_child(key)
	item.add_child(UIStyle.label(text, 18, UIStyle.COLOR_MUTED))
	parent.add_child(item)
	return key

# --- Categorías y lista ---

func _on_tab_pressed(cat: String) -> void:
	if cat == _category: return
	_selected_id = ""
	_show_category(cat)

func _show_category(cat: String) -> void:
	_category = cat
	for key in _tabs:
		_style_tab(_tabs[key], key == cat)
	_entries = OmniaCatalog.entries(cat)
	if _find_entry(_selected_id).is_empty() and _entries.size() > 0:
		_selected_id = _entries[0].id
	_list_title.text = cat
	_list_info.text = OmniaCatalog.CATEGORY_INFO.get(cat, "")
	_list_progress.text = _progress_text(cat)
	_scrap_label.text = str(GameData.scrap)
	_active_protocol_label.text = _active_protocol_name()
	_build_list()
	_refresh_detail()

func _style_tab(tab: Button, active: bool) -> void:
	var tex = UIStyle.TEX_TAB_ACTIVE if active else preload("res://Art/Ui/svg/tab_normal.svg")
	var hover = UIStyle.TEX_TAB_ACTIVE if active else preload("res://Art/Ui/svg/tab_hover.svg")
	tab.add_theme_stylebox_override("normal", UIStyle.nine_slice(tex))
	tab.add_theme_stylebox_override("hover", UIStyle.nine_slice(hover))
	tab.add_theme_stylebox_override("pressed", UIStyle.nine_slice(UIStyle.TEX_TAB_ACTIVE))
	tab.add_theme_color_override("font_color", UIStyle.COLOR_GOLD if active else UIStyle.COLOR_MUTED)
	tab.add_theme_color_override("font_hover_color", UIStyle.COLOR_TEXT)

func _progress_text(cat: String) -> String:
	var p = OmniaCatalog.progress(cat)
	var unit = "niveles" if cat in ["ESTRUCTURA", "RECURSOS"] else "desbloqueadas"
	return "%d / %d %s" % [p.x, p.y, unit]

func _active_protocol_name() -> String:
	return OmniaCatalog.protocol_name(GameData.active_protocol)

func _build_list() -> void:
	for child in _scroll.get_children():
		child.queue_free()
	_cards.clear()
	var use_tiles = _entries.size() > 0 and _entries[0].kind in TILE_KINDS
	var container: Container
	if use_tiles:
		var grid = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		container = grid
	else:
		var list = VBoxContainer.new()
		list.add_theme_constant_override("separation", 10)
		container = list
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(container)
	for i in _entries.size():
		var entry = _entries[i]
		var card = _make_tile(entry, i) if use_tiles else _make_row(entry)
		for child in card.get_children():
			if child is Control:
				_ignore_mouse(child)
		card.pressed.connect(_select.bind(entry.id))
		card.gui_input.connect(_on_card_input.bind(entry.id))
		card.focus_entered.connect(_select.bind(entry.id)) # joystick: moverse ya selecciona
		PadFocusable.attach(card)
		container.add_child(card)
		_cards[entry.id] = card
	_update_card_styles()
	if InputMode.is_gamepad() and _cards.has(_selected_id):
		_cards[_selected_id].grab_focus.call_deferred()

# Ficha con el sprite grande (armas y sinergias).
func _make_tile(entry: Dictionary, index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = TILE_SIZE
	btn.focus_mode = Control.FOCUS_NONE
	var box = _card_content(VBoxContainer.new(), btn)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)

	var art = _entry_icon(entry, 84.0, index)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(art)
	var name_lbl = UIStyle.label(entry.name, 16, UIStyle.COLOR_TEXT if _is_owned(entry) else UIStyle.COLOR_MUTED)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_lbl)
	box.add_child(_price_tag(entry, true))
	return btn

# Fila con ícono chico (mejoras y protocolos).
func _make_row(entry: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 76)
	btn.focus_mode = Control.FOCUS_NONE
	var row = _card_content(HBoxContainer.new(), btn)
	row.add_theme_constant_override("separation", 14)

	var frame = UIStyle.panel(UIStyle.TEX_SLOT["normal"])
	frame.custom_minimum_size = Vector2(76, 76)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art = PixelIcon.icon(entry.icon, 68.0, 2) if not str(entry.icon.resource_path if entry.icon else "").ends_with(".svg") else UIStyle.icon(entry.icon, 30)
	art.modulate = UIStyle.COLOR_GOLD if entry.state in ["activo", "maximo"] else Color.WHITE
	frame.add_child(art)
	row.add_child(frame)

	var texts = VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_child(UIStyle.label(entry.name, 18, UIStyle.COLOR_TEXT))
	if entry.kind == "upgrade":
		texts.add_child(_level_pips(entry.level, entry.max, 8.0))
	else:
		var sub = UIStyle.label(entry.desc, 14, UIStyle.COLOR_MUTED)
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		texts.add_child(sub)
	row.add_child(texts)
	var tag = _price_tag(entry, false)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tag)
	return btn

# Contenedor interno de una ficha: ocupa todo el botón y no le roba los clics.
func _card_content(content: BoxContainer, btn: Button) -> BoxContainer:
	var m = UIStyle.padded(12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(content)
	return content

# Precio (moneda + número), tilde si ya está, candado si no se puede todavía.
func _price_tag(entry: Dictionary, centered: bool) -> HBoxContainer:
	var tag = HBoxContainer.new()
	tag.add_theme_constant_override("separation", 6)
	if centered:
		tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var cost = OmniaCatalog.shown_cost(entry)
	if cost > 0:
		tag.add_child(UIStyle.icon(ICON_COIN, 18))
		var enough = GameData.scrap >= cost
		tag.add_child(UIStyle.label(str(cost), 17, UIStyle.COLOR_GOLD if enough else UIStyle.COLOR_WARNING))
	elif entry.state == "bloqueado":
		var lock = UIStyle.icon(ICON_LOCK, 18)
		lock.modulate = UIStyle.COLOR_WARNING
		tag.add_child(lock)
	else:
		var check = UIStyle.icon(ICON_CHECK, 18)
		check.modulate = UIStyle.COLOR_TEAL
		tag.add_child(check)
		tag.add_child(UIStyle.label(_state_name(entry), 14, UIStyle.COLOR_TEAL))
	_ignore_mouse(tag)
	return tag

func _level_pips(level: int, max_level: int, width: float) -> HBoxContainer:
	var pips = HBoxContainer.new()
	pips.add_theme_constant_override("separation", 3)
	for i in max_level:
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(width, 8)
		pip.color = UIStyle.COLOR_TEAL if i < level else Color("#23434D")
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pips.add_child(pip)
	return pips

## Ícono de la entrada. Si es un arma o sinergia sin desbloquear, va como silueta.
## Una sinergia comprada sigue en silueta hasta descubrirla en una run.
func _entry_icon(entry: Dictionary, size: float, index: int) -> TextureRect:
	# grilla: todos x2 para que se vean parejos; ficha grande: lo más grande que entre
	var art = PixelIcon.icon(entry.icon, size, PixelIcon.FIT if size > 100.0 else 2)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.self_modulate = entry.get("tint", Color.WHITE)
	if entry.kind in ["weapon", "synergy"] and not _is_revealed(entry):
		var mat = ShaderMaterial.new()
		mat.shader = LOCKED_SHADER
		mat.set_shader_parameter("phase", fmod(index * 0.137, 1.0))
		art.material = mat
	if entry.kind == "synergy" and not _is_revealed(entry):
		_add_small_lock(art, size)
	return art

# Candado chico en la esquina de la silueta: se sabe que falta descubrirla.
func _add_small_lock(art: Control, size: float) -> void:
	var lock = UIStyle.icon(ICON_LOCK, maxf(16.0, size * 0.22))
	lock.modulate = UIStyle.COLOR_GOLD
	lock.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	lock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	lock.grow_vertical = Control.GROW_DIRECTION_BEGIN
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(lock)

func _is_owned(entry: Dictionary) -> bool:
	return entry.state in ["comprado", "activo", "maximo"]

# ¿Se ve el sprite? Al tener desbloqueada la sinergia o el objeto/arma.
func _is_revealed(entry: Dictionary) -> bool:
	return GameData.is_synergy_discovered(entry.id) if entry.kind == "synergy" else _is_owned(entry)

# Sinergia comprada pero sin descubrir
func _is_recipe_only(entry: Dictionary) -> bool:
	return entry.kind == "synergy" and _is_owned(entry) and not _is_revealed(entry)

func _state_name(entry: Dictionary) -> String:
	if entry.kind == "synergy" and _is_owned(entry):
		return "DESBLOQUEADA"
	return STATE_NAMES.get(entry.state, "")

func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_mouse(child)

# --- Selección y detalle ---

func _select(id: String) -> void:
	if id == _selected_id: return
	_selected_id = id
	_update_card_styles()
	_refresh_detail()

func _on_card_input(event: InputEvent, id: String) -> void:
	var double_click = event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT
	var pad_accept = event is InputEventJoypadButton and event.is_action_pressed("ui_accept")
	if double_click or pad_accept:
		_selected_id = id
		if pad_accept:
			_cards[id].accept_event()
		_on_action_pressed()

func _update_card_styles() -> void:
	for id in _cards:
		var entry = _find_entry(id)
		var base = "selected" if id == _selected_id else ("equipped" if entry.state == "activo" else "normal")
		UIStyle.style_slot_button(_cards[id], base)

func _find_entry(id: String) -> Dictionary:
	for e in _entries:
		if e.id == id:
			return e
	return {}

func _refresh_detail() -> void:
	for child in _detail_box.get_children():
		_detail_box.remove_child(child)
		child.queue_free()
	var entry = _find_entry(_selected_id)
	if entry.is_empty(): return

	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped" if _is_owned(entry) else "normal"])
	frame.name = "DetailIcon"
	frame.custom_minimum_size = Vector2(150, 150)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art = _entry_icon(entry, 110.0, 0)
	frame.add_child(art)
	_detail_box.add_child(frame)

	var title = UIStyle.label(entry.name, 26, UIStyle.COLOR_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_box.add_child(title)
	var status = UIStyle.label("%s · %s" % [KIND_NAMES.get(entry.kind, ""), _state_name(entry)], 15, _state_color(entry))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_box.add_child(status)

	var desc = UIStyle.label(entry.desc, 16, UIStyle.COLOR_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_box.add_child(desc)
	_add_kind_details(entry)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_box.add_child(spacer)
	_add_action_row(entry)

func _state_color(entry: Dictionary) -> Color:
	match entry.state:
		"bloqueado": return UIStyle.COLOR_WARNING
		"disponible": return UIStyle.COLOR_GOLD
	return UIStyle.COLOR_TEAL

func _add_kind_details(entry: Dictionary) -> void:
	match entry.kind:
		"upgrade":
			_detail_box.add_child(UIStyle.label("Nivel %d / %d" % [entry.level, entry.max], 17, UIStyle.COLOR_TEXT))
			_detail_box.add_child(_level_pips(entry.level, entry.max, 12.0 if entry.max <= 10 else 6.0))
			_detail_box.add_child(UIStyle.label("Bono actual: " + entry.bonus, 16, UIStyle.COLOR_TEAL if entry.level > 0 else UIStyle.COLOR_MUTED))
		"synergy":
			_add_base_weapon(entry)
			_add_recipe(entry)
			if entry.requirement != "":
				_add_warning(entry.requirement)
		"protocol":
			_add_hint("Desbloqueo permanente. Puedes cambiar de protocolo gratis en O.M.N.I.A.; solo uno puede estar equipado.")

# Arma base de la sinergia: junto con los 3 componentes, es la pista principal.
func _add_base_weapon(entry: Dictionary) -> void:
	var weapon_id: String = entry.get("weapon", "")
	if weapon_id == "": return
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var data: Dictionary = CodexData.DATA.get("weapons", {}).get(weapon_id, {})
	if data.get("icon"):
		row.add_child(PixelIcon.icon(data.icon, 40.0, PixelIcon.SLOT))
	row.add_child(UIStyle.label("Arma base: " + SynergyManager.get_weapon_display_name(weapon_id), 17, UIStyle.COLOR_TEXT))
	_detail_box.add_child(row)

# Componentes y confirmación editables en escenas de Godot.
func _add_recipe(entry: Dictionary) -> void:
	var recipe = RESEARCH_SCENE.instantiate()
	_detail_box.add_child(recipe)
	recipe.configure(entry.id)
	recipe.hint_purchased.connect(func():
		_play_sound(BUY_SOUND)
		_show_category(_category)
	)

func _add_warning(text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UIStyle.icon(ICON_WARNING, 20))
	var lbl = UIStyle.label(text, 15, UIStyle.COLOR_WARNING)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	_detail_box.add_child(row)

func _add_hint(text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var ic = UIStyle.icon(ICON_SEARCH, 20)
	ic.modulate = UIStyle.COLOR_TEAL
	row.add_child(ic)
	var lbl = UIStyle.label(text, 15, UIStyle.COLOR_TEAL)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	_detail_box.add_child(row)

func _add_action_row(entry: Dictionary) -> void:
	var cost = OmniaCatalog.shown_cost(entry)
	if cost > 0 and GameData.scrap < cost:
		_add_warning("Te faltan %d de chatarra." % (cost - GameData.scrap))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_detail_box.add_child(row)
	if cost > 0:
		row.add_child(UIStyle.icon(ICON_COIN, 24))
		row.add_child(UIStyle.label(str(cost), 24, UIStyle.COLOR_GOLD))
	var btn = UIStyle.button(entry.action, OmniaCatalog.can_act(entry), Vector2(0, 52), 16 if entry.kind == "protocol" else 20)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = not OmniaCatalog.can_act(entry)
	btn.pressed.connect(_on_action_pressed)
	row.add_child(btn)

# --- Compra ---

func _on_action_pressed() -> void:
	var entry = _find_entry(_selected_id)
	if entry.is_empty() or not OmniaCatalog.can_act(entry):
		_play_sound(CANCEL_SOUND)
		return
	var was_locked = (entry.kind in TILE_KINDS) and not _is_owned(entry)
	var bought_synergy = entry.kind == "synergy" and not _is_owned(entry)
	if not OmniaCatalog.purchase(entry):
		_play_sound(CANCEL_SOUND)
		return
	_play_sound(BUY_SOUND)
	_show_category(_category)
	_celebrate(was_locked and entry.kind != "synergy")
	if bought_synergy:
		_cascade_chips()
		OmniaRevealPopup.research_unlocked(entry.id, entry.name)

# Efecto de compra: la ficha y el ícono del detalle saltan con un destello; si
# era una silueta, se revela con el shader en vez de aparecer de golpe.
func _celebrate(reveal: bool) -> void:
	var targets: Array[Control] = []
	if _cards.has(_selected_id):
		targets.append(_cards[_selected_id])
	var detail = _detail_box.get_node_or_null("DetailIcon")
	if detail:
		targets.append(detail)
	for t in targets:
		_pop(t)
		if reveal:
			_reveal_icons_in(t)

# --- Animación al comprar una receta ---
# Las piezas "?" se dan vuelta una por una, un escaneo recorre la silueta y cae
# un sello dorado de "RECETA OBTENIDA" sobre el sprite (que sigue en silueta).
func _celebrate_recipe() -> void:
	await get_tree().process_frame # que el detalle nuevo ya tenga tamaño
	if _cards.has(_selected_id):
		_pop(_cards[_selected_id])
	var detail = _detail_box.get_node_or_null("DetailIcon")
	if detail:
		_pop(detail)
		_scan_sweep(detail)
		_stamp(detail)
	_cascade_chips()

func _cascade_chips() -> void:
	var chips = _detail_box.get_node_or_null("ResearchRecipe/RecipeChips")
	if not chips: return
	var i = 0
	for chip in chips.get_children():
		chip.pivot_offset = chip.size / 2.0
		chip.scale = Vector2(0.2, 0.2)
		chip.modulate = Color(2.2, 2.2, 2.2, 0.0)
		var t = chip.create_tween()
		t.tween_interval(0.25 + i * 0.13)
		t.tween_property(chip, "modulate:a", 1.0, 0.05)
		t.parallel().tween_property(chip, "scale", Vector2(1.18, 1.18), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(chip, "scale", Vector2.ONE, 0.14)
		t.parallel().tween_property(chip, "modulate", Color.WHITE, 0.3)
		i += 1

func _scan_sweep(frame: Control) -> void:
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = true
	frame.add_child(holder)
	var line = ColorRect.new()
	line.color = Color(UIStyle.COLOR_TEAL, 0.85)
	line.size = Vector2(frame.size.x, 3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(line)
	var glow = ColorRect.new()
	glow.color = Color(UIStyle.COLOR_TEAL, 0.18)
	glow.size = Vector2(frame.size.x, 18)
	glow.position.y = -18
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(glow)
	var t = holder.create_tween()
	t.tween_property(line, "position:y", frame.size.y, 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_callback(holder.queue_free)

func _stamp(frame: Control) -> void:
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(center)
	var stamp = PanelContainer.new()
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.02, 0.85)
	box.border_color = UIStyle.COLOR_GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	stamp.add_theme_stylebox_override("panel", box)
	var lbl = UIStyle.label("RECETA\nOBTENIDA", 16, UIStyle.COLOR_GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.add_child(lbl)
	center.add_child(stamp)
	await get_tree().process_frame
	if not is_instance_valid(stamp): return
	stamp.pivot_offset = stamp.size / 2.0
	stamp.rotation = -0.22
	stamp.scale = Vector2(2.4, 2.4)
	stamp.modulate.a = 0.0
	var t = stamp.create_tween()
	t.tween_interval(0.45)
	t.tween_property(stamp, "modulate:a", 1.0, 0.08)
	t.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_pop.bind(frame))
	t.tween_property(stamp, "rotation", -0.12, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.1)
	t.tween_property(stamp, "modulate:a", 0.0, 0.35)
	t.tween_callback(center.queue_free)

func _pop(target: Control) -> void:
	target.pivot_offset = target.size / 2.0
	target.scale = Vector2(1.12, 1.12)
	target.modulate = Color(1.8, 1.8, 1.8)
	var t = target.create_tween().set_parallel(true)
	t.tween_property(target, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(target, "modulate", Color.WHITE, 0.45)

func _reveal_icons_in(target: Node) -> void:
	for child in target.find_children("*", "TextureRect", true, false):
		var art = child as TextureRect
		if art.custom_minimum_size.x < 60.0: continue # solo el sprite grande
		var mat = ShaderMaterial.new()
		mat.shader = LOCKED_SHADER
		art.material = mat
		# el tween va atado al ícono: si se cambia de pestaña en el medio, muere con él
		var t = art.create_tween()
		t.tween_method(func(v: float): mat.set_shader_parameter("reveal", v), 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_callback(_clear_icon_material.bind(art))

func _clear_icon_material(art: TextureRect) -> void:
	if is_instance_valid(art):
		art.material = null

func _play_sound(path: String) -> void:
	if not ResourceLoader.exists(path): return
	var p = AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = "SFX"
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

# --- Abrir y cerrar (entra desde abajo, como el inventario) ---

func _animate_in() -> void:
	_is_animating = true
	var h = get_viewport().get_visible_rect().size.y
	_window.position.y = h
	_backdrop.modulate.a = 0.0
	create_tween().tween_property(_backdrop, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	var slide = create_tween()
	slide.tween_property(_window, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_callback(_finish_open_animation)

func _finish_open_animation() -> void:
	_is_animating = false

func close() -> void:
	if _is_animating or is_queued_for_deletion(): return
	_is_animating = true
	SceneTransition.set_menu_muffle(false)
	var h = get_viewport().get_visible_rect().size.y
	create_tween().tween_property(_backdrop, "modulate:a", 0.0, 0.25)
	var slide = create_tween()
	slide.tween_property(_window, "position:y", h, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	slide.tween_callback(_finish_close)

func _finish_close() -> void:
	if not _was_paused:
		get_tree().paused = false
	closed.emit()
	queue_free()
