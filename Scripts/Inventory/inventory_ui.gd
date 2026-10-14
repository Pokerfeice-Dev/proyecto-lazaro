class_name InventoryUI
extends Control

@export var inventory: Inventory
@export var equipment: Equipment
var player_sprite: AnimatedSprite2D

var ui_slots: Array[UISlot] = []
var inventory_slots: Array[UISlot] = []

# Referencias a slots corporales
var body_slots: Dictionary = {} # ItemData.ItemSlot -> UISlot
# Referencias a slots de armas
var main_weapon_slots: Array[UISlot] = []
var sec_weapon_slots: Array[UISlot] = []
var primary_weapon_slot_panel: PanelContainer
var primary_weapon_icon: TextureRect
var secondary_weapon_slot_panel: PanelContainer
var secondary_weapon_icon: TextureRect

# Estado de UI
var current_tab: String = "INVENTORY" # "INVENTORY" o "CODEX"
var current_filter: String = "ALL" # "ALL", "WEAPON", "BODY"
var sort_mode: String = "DEFAULT" # "DEFAULT", "TYPE", "NAME"
var _is_animating: bool = false
var _default_margin_pos_y: float = 40.0

# Item seleccionado en el inventario o equipamiento
var selected_item: ItemData = null
var selected_source_slot: UISlot = null
var is_comparing: bool = false

# Nodos principales
@onready var dark_backdrop: ColorRect = $DarkBackdrop
@onready var window_margin: MarginContainer = $WindowMargin
@onready var window_panel: PanelContainer = $WindowMargin/WindowPanel
@onready var top_bar: HBoxContainer = $WindowMargin/WindowPanel/WindowInnerMargin/WindowVBox/TopBar
@onready var content_area: Control = $WindowMargin/WindowPanel/WindowInnerMargin/WindowVBox/ContentArea
@onready var bottom_bar: PanelContainer = $WindowMargin/WindowPanel/WindowInnerMargin/WindowVBox/BottomBar

# Contenedores dinámicos
var main_three_columns: HBoxContainer
var codex_view: Control

# Pestañas superiores y monedas
var tab_inventory_btn: Button
var tab_codex_btn: Button
var coin_label: Label
var capacity_label: Label

# Columna 1: Inventario
var inventory_grid: GridContainer
var filter_all_btn: Button
var filter_weapons_btn: Button
var filter_body_btn: Button
var sort_option_btn: OptionButton

# Ficha de detalle inferior (columna 1)
var detail_panel: PanelContainer
var detail_empty_label: Label
var detail_content_box: VBoxContainer
var detail_icon_rect: TextureRect
var detail_name_label: Label
var detail_meta_label: Label
var detail_desc_label: Label
var detail_stats_label: RichTextLabel
var detail_equip_btn: Button
var detail_compare_btn: Button

# Columna 2: Equipamiento
var character_name_label: Label
var portrait_container: Control
var portrait_anim_sprite: AnimatedSprite2D

# Columna 3: Atributos
var stats_char_vbox: VBoxContainer
var stats_weapon_vbox: VBoxContainer
var stats_weapon_header_box: HBoxContainer
var stats_weapon_icon: TextureRect
var stats_weapon_name: Label
var stats_preview_badge: HBoxContainer
var stats_tab_primary_btn: Button
var stats_tab_secondary_btn: Button
var active_weapon_stats_tab: String = "PRIMARY"

# Tooltip flotante (para Códice y slots)
var tooltip_panel: PanelContainer
var tooltip_name: Label
var tooltip_rarity: Label
var tooltip_type: Label
var tooltip_desc: RichTextLabel
var tooltip_stats: RichTextLabel
var tooltip_action: Label

# Códice
var selected_codex_category: String = "enemies"
var codex_grid: GridContainer
var codex_category_buttons: Dictionary = {}
var codex_progress_label: Label

# Texturas SVG precargadas
static var tex_panel_main: Texture2D = preload("res://Art/Ui/svg/panel_main.svg")
static var tex_panel_inset: Texture2D = preload("res://Art/Ui/svg/panel_inset.svg")
static var tex_panel_footer: Texture2D = preload("res://Art/Ui/svg/panel_footer.svg")
static var tex_panel_tooltip: Texture2D = preload("res://Art/Ui/svg/panel_tooltip.svg")

static var tex_tab_normal: Texture2D = preload("res://Art/Ui/svg/tab_normal.svg")
static var tex_tab_hover: Texture2D = preload("res://Art/Ui/svg/tab_hover.svg")
static var tex_tab_active: Texture2D = preload("res://Art/Ui/svg/tab_active.svg")

static var tex_btn_primary_normal: Texture2D = preload("res://Art/Ui/svg/primary_normal.svg")
static var tex_btn_primary_hover: Texture2D = preload("res://Art/Ui/svg/primary_hover.svg")
static var tex_btn_primary_pressed: Texture2D = preload("res://Art/Ui/svg/primary_pressed.svg")
static var tex_btn_primary_disabled: Texture2D = preload("res://Art/Ui/svg/primary_disabled.svg")

static var tex_btn_secondary_normal: Texture2D = preload("res://Art/Ui/svg/secondary_normal.svg")
static var tex_btn_secondary_hover: Texture2D = preload("res://Art/Ui/svg/secondary_hover.svg")
static var tex_btn_secondary_pressed: Texture2D = preload("res://Art/Ui/svg/secondary_pressed.svg")
static var tex_btn_secondary_disabled: Texture2D = preload("res://Art/Ui/svg/secondary_disabled.svg")

static var tex_keycap: Texture2D = preload("res://Art/Ui/svg/keycap.svg")
static var tex_icon_coin: Texture2D = preload("res://Art/Ui/svg/icon_coin.svg")
static var tex_icon_close: Texture2D = preload("res://Art/Ui/svg/icon_close.svg")
static var tex_icon_check: Texture2D = preload("res://Art/Ui/svg/icon_check.svg")
static var tex_icon_info: Texture2D = preload("res://Art/Ui/svg/icon_info.svg")
static var tex_icon_warning: Texture2D = preload("res://Art/Ui/svg/icon_warning.svg")
static var tex_icon_sort: Texture2D = preload("res://Art/Ui/svg/icon_sort.svg")
static var tex_icon_mouse: Texture2D = preload("res://Art/Ui/svg/icon_mouse.svg")
static var tex_icon_compare: Texture2D = preload("res://Art/Ui/svg/icon_compare.svg")
static var tex_icon_damage: Texture2D = preload("res://Art/Ui/svg/icon_damage.svg")
static var tex_icon_health: Texture2D = preload("res://Art/Ui/svg/icon_health.svg")
static var tex_icon_energy: Texture2D = preload("res://Art/Ui/svg/icon_energy.svg")
static var tex_icon_armor: Texture2D = preload("res://Art/Ui/svg/icon_armor.svg")
static var tex_icon_fire_rate: Texture2D = preload("res://Art/Ui/svg/icon_fire_rate.svg")
static var tex_icon_projectiles: Texture2D = preload("res://Art/Ui/svg/icon_projectiles.svg")
static var tex_icon_critical: Texture2D = preload("res://Art/Ui/svg/icon_critical.svg")
static var tex_icon_range: Texture2D = preload("res://Art/Ui/svg/icon_range.svg")
static var tex_icon_ammo: Texture2D = preload("res://Art/Ui/svg/icon_ammo.svg")
static var tex_icon_pierce: Texture2D = preload("res://Art/Ui/svg/icon_pierce.svg")

# Diccionario de etiquetas legibles para atributos
const STAT_LABELS: Dictionary = {
	"max_health_percent": "Vida Máxima",
	"move_speed_percent": "Velocidad de Movimiento",
	"armor": "Armadura",
	"damage": "Daño",
	"projectile_speed": "Velocidad de Proyectil",
	"bullet_count": "Cantidad de Proyectiles",
	"cone_spread_angle": "Dispersión",
	"piercing": "Perforación",
	"crit_chance": "Prob. Crítica",
	"crit_damage": "Daño Crítico",
	"attack_speed": "Cadencia",
	"damage_multiplier": "Multiplicador Daño",
	"knockback_force": "Empuje",
	"stun_chance": "Prob. Aturdimiento",
	"burn_chance": "Prob. Quemadura",
	"slow_chance": "Prob. Ralentización",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_auto_fetch_player_nodes()
	_apply_window_panel_style()
	_build_top_bar()
	_build_content_area()
	_build_bottom_bar()
	_create_tooltip_panel()
	_build_codex_panel()

	if inventory:
		inventory.inventory_updated.connect(update_items_list)
	if equipment:
		equipment.equipment_changed.connect(update_ui)

	if window_margin:
		_default_margin_pos_y = window_margin.position.y

func _apply_window_panel_style() -> void:
	var style = _create_9slice_style(tex_panel_main, 8.0)
	window_panel.add_theme_stylebox_override("panel", style)

func _create_9slice_style(tex: Texture2D, margin: float) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	return style

# ── Construcción de la Franja Superior ─────────────────────────────────────────

func _build_top_bar() -> void:
	for c in top_bar.get_children():
		c.queue_free()

	var tabs_box = HBoxContainer.new()
	tabs_box.name = "TabsBox"
	tabs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs_box.add_theme_constant_override("separation", 8)
	top_bar.add_child(tabs_box)

	tab_inventory_btn = _create_tab_button("INVENTARIO", true)
	tab_inventory_btn.pressed.connect(_on_inventory_tab_pressed)
	tabs_box.add_child(tab_inventory_btn)

	tab_codex_btn = _create_tab_button("CÓDICE", false)
	tab_codex_btn.pressed.connect(_on_codex_tab_pressed)
	tabs_box.add_child(tab_codex_btn)

	var right_box = HBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_END
	right_box.add_theme_constant_override("separation", 24)
	top_bar.add_child(right_box)

	var coin_box = HBoxContainer.new()
	coin_box.add_theme_constant_override("separation", 8)
	right_box.add_child(coin_box)

	var coin_icon = TextureRect.new()
	coin_icon.texture = tex_icon_coin
	coin_icon.custom_minimum_size = Vector2(24, 24)
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_box.add_child(coin_icon)

	coin_label = Label.new()
	coin_label.text = _format_scrap_number(GameData.scrap)
	coin_label.add_theme_font_size_override("font_size", 22)
	coin_label.add_theme_color_override("font_color", Color("#F4C45E"))
	coin_box.add_child(coin_label)

	var close_box = HBoxContainer.new()
	close_box.add_theme_constant_override("separation", 6)
	right_box.add_child(close_box)

	var keycap = _create_keycap_box("Esc")
	close_box.add_child(keycap)

	var close_btn = Button.new()
	close_btn.text = "Cerrar"
	close_btn.icon = tex_icon_close
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color("#8DAAB4"))
	close_btn.add_theme_color_override("font_hover_color", Color("#E5EEF0"))
	close_btn.pressed.connect(toggle_visibility)
	close_box.add_child(close_btn)

func _create_tab_button(label_text: String, is_active: bool) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(170, 44)
	btn.add_theme_font_size_override("font_size", 22)
	_apply_tab_style(btn, is_active)
	return btn

func _apply_tab_style(btn: Button, is_active: bool) -> void:
	var tex = tex_tab_active if is_active else tex_tab_normal
	var hover_tex = tex_tab_active if is_active else tex_tab_hover
	var font_col = Color("#F4C45E") if is_active else Color("#8DAAB4")

	btn.add_theme_stylebox_override("normal", _create_9slice_style(tex, 8.0))
	btn.add_theme_stylebox_override("hover", _create_9slice_style(hover_tex, 8.0))
	btn.add_theme_stylebox_override("pressed", _create_9slice_style(tex_tab_active, 8.0))
	btn.add_theme_stylebox_override("focus", _create_9slice_style(hover_tex, 8.0))
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", Color("#E5EEF0"))

func _create_keycap_box(key_text: String) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(32, 32)
	panel.add_theme_stylebox_override("panel", _create_9slice_style(tex_keycap, 8.0))

	var lbl = Label.new()
	lbl.text = key_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#E5EEF0"))
	panel.add_child(lbl)
	return panel

# ── Construcción de las Tres Columnas (39% / 34% / 27%) ────────────────────────

func _build_content_area() -> void:
	for c in content_area.get_children():
		c.queue_free()

	main_three_columns = HBoxContainer.new()
	main_three_columns.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_three_columns.add_theme_constant_override("separation", 16)
	content_area.add_child(main_three_columns)

	# Columna Izquierda: 39%
	var col_left = PanelContainer.new()
	col_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_left.size_flags_stretch_ratio = 0.39
	col_left.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_inset, 8.0))
	main_three_columns.add_child(col_left)
	_build_inventory_column(col_left)

	_add_vertical_divider(main_three_columns)

	# Columna Centro: 34%
	var col_center = PanelContainer.new()
	col_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_center.size_flags_stretch_ratio = 0.34
	col_center.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_inset, 8.0))
	main_three_columns.add_child(col_center)
	_build_equipment_column(col_center)

	_add_vertical_divider(main_three_columns)

	# Columna Derecha: 27%
	var col_right = PanelContainer.new()
	col_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_right.size_flags_stretch_ratio = 0.27
	col_right.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_inset, 8.0))
	main_three_columns.add_child(col_right)
	_build_attributes_column(col_right)

func _add_vertical_divider(parent: Control) -> void:
	var div = TextureRect.new()
	div.texture = preload("res://Art/Ui/svg/divider_vertical.svg")
	div.custom_minimum_size = Vector2(2, 0)
	div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div.stretch_mode = TextureRect.STRETCH_TILE
	div.modulate = Color(1.0, 1.0, 1.0, 0.4)
	parent.add_child(div)

func _add_horizontal_divider(parent: Control) -> void:
	var div = TextureRect.new()
	div.texture = preload("res://Art/Ui/svg/divider_horizontal.svg")
	div.custom_minimum_size = Vector2(0, 2)
	div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div.stretch_mode = TextureRect.STRETCH_TILE
	div.modulate = Color(1.0, 1.0, 1.0, 0.4)
	parent.add_child(div)

# ── Columna 1: Inventario ──────────────────────────────────────────────────────

func _build_inventory_column(container: Control) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# Encabezado
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var title = Label.new()
	title.text = "INVENTARIO"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#E5EEF0"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	capacity_label = Label.new()
	capacity_label.text = "0 / 24"
	capacity_label.add_theme_font_size_override("font_size", 20)
	capacity_label.add_theme_color_override("font_color", Color("#8DAAB4"))
	header.add_child(capacity_label)

	# Filtros y selector de orden
	var filters_bar = HBoxContainer.new()
	filters_bar.add_theme_constant_override("separation", 8)
	vbox.add_child(filters_bar)

	filter_all_btn = _create_filter_button("Todos", "ALL")
	filter_weapons_btn = _create_filter_button("Armas", "WEAPON")
	filter_body_btn = _create_filter_button("Cuerpo", "BODY")
	filters_bar.add_child(filter_all_btn)
	filters_bar.add_child(filter_weapons_btn)
	filters_bar.add_child(filter_body_btn)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters_bar.add_child(spacer)

	sort_option_btn = OptionButton.new()
	sort_option_btn.add_item("Reciente", 0)
	sort_option_btn.add_item("Tipo", 1)
	sort_option_btn.add_item("Nombre", 2)
	sort_option_btn.custom_minimum_size = Vector2(130, 36)
	sort_option_btn.item_selected.connect(_on_sort_option_selected)
	filters_bar.add_child(sort_option_btn)

	# Grilla de 6 x 4 con scroll si excede capacidad
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	inventory_grid = GridContainer.new()
	inventory_grid.columns = 6
	inventory_grid.add_theme_constant_override("h_separation", 10)
	inventory_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(inventory_grid)

	inventory_slots.clear()
	for i in range(24):
		var slot_ui = UISlot.new()
		slot_ui.is_inventory_slot = true
		slot_ui.custom_minimum_size = Vector2(80, 80)
		slot_ui.empty_text = "+"
		slot_ui.item_dropped.connect(_on_item_dropped)
		slot_ui.slot_clicked.connect(_on_slot_clicked)
		slot_ui.slot_double_clicked.connect(_on_slot_double_clicked)
		slot_ui.slot_hovered.connect(_on_slot_hovered)
		slot_ui.slot_unhovered.connect(_on_slot_unhovered)
		slot_ui.drag_started.connect(_on_drag_started)
		inventory_grid.add_child(slot_ui)
		inventory_slots.append(slot_ui)

	_add_horizontal_divider(vbox)

	# Ficha fija del objeto seleccionado
	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(0, 220)
	detail_panel.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_footer, 8.0))
	vbox.add_child(detail_panel)

	_build_item_detail_panel(detail_panel)

func _create_filter_button(label_text: String, filter_type: String) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(76, 36)
	btn.add_theme_font_size_override("font_size", 16)
	_apply_secondary_button_style(btn)
	btn.pressed.connect(_on_filter_pressed.bind(filter_type))
	return btn

func _apply_secondary_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _create_9slice_style(tex_btn_secondary_normal, 8.0))
	btn.add_theme_stylebox_override("hover", _create_9slice_style(tex_btn_secondary_hover, 8.0))
	btn.add_theme_stylebox_override("pressed", _create_9slice_style(tex_btn_secondary_pressed, 8.0))
	btn.add_theme_stylebox_override("disabled", _create_9slice_style(tex_btn_secondary_disabled, 8.0))
	btn.add_theme_stylebox_override("focus", _create_9slice_style(tex_btn_secondary_hover, 8.0))
	btn.add_theme_color_override("font_color", Color("#E5EEF0"))

func _apply_primary_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _create_9slice_style(tex_btn_primary_normal, 8.0))
	btn.add_theme_stylebox_override("hover", _create_9slice_style(tex_btn_primary_hover, 8.0))
	btn.add_theme_stylebox_override("pressed", _create_9slice_style(tex_btn_primary_pressed, 8.0))
	btn.add_theme_stylebox_override("disabled", _create_9slice_style(tex_btn_primary_disabled, 8.0))
	btn.add_theme_stylebox_override("focus", _create_9slice_style(tex_btn_primary_hover, 8.0))
	btn.add_theme_color_override("font_color", Color("#171D22"))

func _build_item_detail_panel(parent: PanelContainer) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(margin)

	detail_empty_label = Label.new()
	detail_empty_label.text = "Seleccioná un objeto para ver sus detalles."
	detail_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_empty_label.add_theme_font_size_override("font_size", 18)
	detail_empty_label.add_theme_color_override("font_color", Color("#8DAAB4"))
	margin.add_child(detail_empty_label)

	detail_content_box = VBoxContainer.new()
	detail_content_box.visible = false
	detail_content_box.add_theme_constant_override("separation", 6)
	margin.add_child(detail_content_box)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	detail_content_box.add_child(top_hbox)

	detail_icon_rect = TextureRect.new()
	detail_icon_rect.custom_minimum_size = Vector2(56, 56)
	detail_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	top_hbox.add_child(detail_icon_rect)

	var meta_vbox = VBoxContainer.new()
	meta_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(meta_vbox)

	detail_name_label = Label.new()
	detail_name_label.text = "Nombre del Objeto"
	detail_name_label.add_theme_font_size_override("font_size", 24)
	detail_name_label.add_theme_color_override("font_color", Color("#E5EEF0"))
	meta_vbox.add_child(detail_name_label)

	detail_meta_label = Label.new()
	detail_meta_label.text = "Tipo • Rareza"
	detail_meta_label.add_theme_font_size_override("font_size", 18)
	detail_meta_label.add_theme_color_override("font_color", Color("#52D8C6"))
	meta_vbox.add_child(detail_meta_label)

	detail_desc_label = Label.new()
	detail_desc_label.text = "Descripción del objeto..."
	detail_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_desc_label.add_theme_font_size_override("font_size", 17)
	detail_desc_label.add_theme_color_override("font_color", Color("#8DAAB4"))
	detail_content_box.add_child(detail_desc_label)

	detail_stats_label = RichTextLabel.new()
	detail_stats_label.bbcode_enabled = true
	detail_stats_label.fit_content = true
	detail_stats_label.scroll_active = false
	detail_stats_label.add_theme_font_size_override("normal_font_size", 18)
	detail_content_box.add_child(detail_stats_label)

	var actions_hbox = HBoxContainer.new()
	actions_hbox.add_theme_constant_override("separation", 12)
	detail_content_box.add_child(actions_hbox)

	detail_equip_btn = Button.new()
	detail_equip_btn.text = "Equipar"
	detail_equip_btn.custom_minimum_size = Vector2(130, 38)
	detail_equip_btn.add_theme_font_size_override("font_size", 18)
	_apply_primary_button_style(detail_equip_btn)
	detail_equip_btn.pressed.connect(_on_detail_equip_pressed)
	actions_hbox.add_child(detail_equip_btn)

	detail_compare_btn = Button.new()
	detail_compare_btn.text = "Comparar"
	detail_compare_btn.custom_minimum_size = Vector2(120, 38)
	detail_compare_btn.add_theme_font_size_override("font_size", 18)
	_apply_secondary_button_style(detail_compare_btn)
	detail_compare_btn.pressed.connect(_toggle_compare_mode)
	actions_hbox.add_child(detail_compare_btn)

# ── Columna 2: Equipamiento ────────────────────────────────────────────────────

func _build_equipment_column(container: Control) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Encabezado
	var title = Label.new()
	title.text = "EQUIPAMIENTO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#E5EEF0"))
	vbox.add_child(title)

	character_name_label = Label.new()
	character_name_label.text = "LÁZARO"
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_name_label.add_theme_font_size_override("font_size", 20)
	character_name_label.add_theme_color_override("font_color", Color("#F4C45E"))
	vbox.add_child(character_name_label)

	# Paperdoll del personaje con los 5 slots distribuidos
	var paperdoll_area = Control.new()
	paperdoll_area.custom_minimum_size = Vector2(0, 350)
	paperdoll_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(paperdoll_area)

	_setup_character_paperdoll(paperdoll_area)

	_add_horizontal_divider(vbox)

	# Sección de Armas: Principal y Secundaria
	var weapons_box = VBoxContainer.new()
	weapons_box.add_theme_constant_override("separation", 10)
	vbox.add_child(weapons_box)

	var weapons_title = Label.new()
	weapons_title.text = "ARMAS"
	weapons_title.add_theme_font_size_override("font_size", 22)
	weapons_title.add_theme_color_override("font_color", Color("#E5EEF0"))
	weapons_box.add_child(weapons_title)

	_build_weapon_row(weapons_box, "Principal", true)
	_build_weapon_row(weapons_box, "Secundaria", false)

func _setup_character_paperdoll(parent: Control) -> void:
	# Sprite grande del personaje en el centro
	portrait_container = Control.new()
	portrait_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(portrait_container)

	portrait_anim_sprite = AnimatedSprite2D.new()
	portrait_anim_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	portrait_anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_anim_sprite.scale = Vector2(3.5, 3.5)
	portrait_container.add_child(portrait_anim_sprite)

	portrait_container.resized.connect(_center_portrait_sprite)

	# 5 slots corporales: Torso (arriba centro), Brazo I / D, Pierna I / D
	body_slots.clear()

	_create_paperdoll_slot(parent, ItemData.ItemSlot.TORSO, "Torso", "icon_torso", Vector2(0.5, 0.12), Vector2(0, 0))
	_create_paperdoll_slot(parent, ItemData.ItemSlot.ARM_L, "Brazo I", "icon_arm_left", Vector2(0.18, 0.28), Vector2(0, 0))
	_create_paperdoll_slot(parent, ItemData.ItemSlot.ARM_R, "Brazo D", "icon_arm_right", Vector2(0.82, 0.28), Vector2(0, 0))
	_create_paperdoll_slot(parent, ItemData.ItemSlot.LEG_L, "Pierna I", "icon_leg_left", Vector2(0.22, 0.72), Vector2(0, 0))
	_create_paperdoll_slot(parent, ItemData.ItemSlot.LEG_R, "Pierna D", "icon_leg_right", Vector2(0.78, 0.72), Vector2(0, 0))

func _create_paperdoll_slot(parent: Control, slot_type: ItemData.ItemSlot, label_text: String, icon_name: String, anchor: Vector2, offset: Vector2) -> void:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 3)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(container)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color("#8DAAB4"))
	container.add_child(lbl)

	var slot = UISlot.new()
	slot.slot_type = slot_type
	slot.is_equipped_slot = true
	slot.empty_icon_name = icon_name
	slot.custom_minimum_size = Vector2(78, 78)
	slot.item_dropped.connect(_on_item_dropped)
	slot.slot_clicked.connect(_on_slot_clicked)
	slot.slot_double_clicked.connect(_on_slot_double_clicked)
	slot.slot_hovered.connect(_on_slot_hovered)
	slot.slot_unhovered.connect(_on_slot_unhovered)
	slot.drag_started.connect(_on_drag_started)
	container.add_child(slot)

	# Posicionar centrado sobre el punto anchor
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var reposition_slot = func(): _position_paperdoll_node(container, anchor, offset)
	parent.resized.connect(reposition_slot)
	container.resized.connect(reposition_slot)
	reposition_slot.call_deferred()

	body_slots[slot_type] = slot
	ui_slots.append(slot)

func _position_paperdoll_node(container: Control, anchor: Vector2, offset: Vector2) -> void:
	var parent = container.get_parent() as Control
	if not parent: return
	var p_size = parent.size
	container.position = Vector2(p_size.x * anchor.x - (container.size.x * 0.5), p_size.y * anchor.y - (container.size.y * 0.5)) + offset

func _build_weapon_row(parent: Control, row_label: String, is_primary: bool) -> void:
	var row_box = HBoxContainer.new()
	row_box.add_theme_constant_override("separation", 10)
	parent.add_child(row_box)

	var lbl = Label.new()
	lbl.text = row_label
	lbl.custom_minimum_size = Vector2(95, 0)
	lbl.add_theme_font_size_override("font_size", 19)
	lbl.add_theme_color_override("font_color", Color("#8DAAB4"))
	row_box.add_child(lbl)

	var slot_keys = [
		ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3
	] if is_primary else [
		ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3
	]

	# Slot principal del arma (muestra el arma activa) + 3 slots de mejoras
	var weapon_badge = _create_weapon_badge_panel(is_primary)
	row_box.add_child(weapon_badge)

	for k in slot_keys:
		var slot = UISlot.new()
		slot.slot_type = k
		slot.is_equipped_slot = true
		slot.custom_minimum_size = Vector2(74, 74)
		slot.empty_text = "+"
		slot.item_dropped.connect(_on_item_dropped)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_double_clicked.connect(_on_slot_double_clicked)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		slot.drag_started.connect(_on_drag_started)
		row_box.add_child(slot)
		ui_slots.append(slot)
		if is_primary:
			main_weapon_slots.append(slot)
		else:
			sec_weapon_slots.append(slot)

func _create_weapon_badge_panel(is_main: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(74, 74)
	panel.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_inset, 8.0))

	var trect = TextureRect.new()
	trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(trect)

	panel.mouse_entered.connect(_on_weapon_badge_hovered.bind(is_main))
	panel.mouse_exited.connect(_on_weapon_badge_unhovered)

	if is_main:
		primary_weapon_slot_panel = panel
		primary_weapon_icon = trect
	else:
		secondary_weapon_slot_panel = panel
		secondary_weapon_icon = trect

	return panel

# ── Columna 3: Atributos ───────────────────────────────────────────────────────

func _build_attributes_column(container: Control) -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "ATRIBUTOS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#E5EEF0"))
	vbox.add_child(title)

	# Bloque 1: PERSONAJE
	var sec_char = Label.new()
	sec_char.text = "PERSONAJE"
	sec_char.add_theme_font_size_override("font_size", 18)
	sec_char.add_theme_color_override("font_color", Color("#F4C45E"))
	vbox.add_child(sec_char)

	stats_char_vbox = VBoxContainer.new()
	stats_char_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_char_vbox)

	_add_horizontal_divider(vbox)

	# Bloque 2: Pestañas de ARMA PRINCIPAL y ARMA SECUNDARIA
	var weapon_tabs_box = HBoxContainer.new()
	weapon_tabs_box.add_theme_constant_override("separation", 8)
	vbox.add_child(weapon_tabs_box)

	stats_tab_primary_btn = Button.new()
	stats_tab_primary_btn.text = "Principal"
	stats_tab_primary_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_tab_primary_btn.custom_minimum_size = Vector2(0, 36)
	stats_tab_primary_btn.add_theme_font_size_override("font_size", 16)
	stats_tab_primary_btn.pressed.connect(_on_stats_weapon_tab_pressed.bind("PRIMARY"))
	weapon_tabs_box.add_child(stats_tab_primary_btn)

	stats_tab_secondary_btn = Button.new()
	stats_tab_secondary_btn.text = "Secundaria"
	stats_tab_secondary_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_tab_secondary_btn.custom_minimum_size = Vector2(0, 36)
	stats_tab_secondary_btn.add_theme_font_size_override("font_size", 16)
	stats_tab_secondary_btn.pressed.connect(_on_stats_weapon_tab_pressed.bind("SECONDARY"))
	weapon_tabs_box.add_child(stats_tab_secondary_btn)

	_update_stats_weapon_tab_buttons()

	stats_weapon_header_box = HBoxContainer.new()
	stats_weapon_header_box.add_theme_constant_override("separation", 10)
	vbox.add_child(stats_weapon_header_box)

	var icon_panel = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(48, 48)
	icon_panel.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_inset, 8.0))
	stats_weapon_header_box.add_child(icon_panel)

	stats_weapon_icon = TextureRect.new()
	stats_weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stats_weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stats_weapon_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_panel.add_child(stats_weapon_icon)

	stats_weapon_name = Label.new()
	stats_weapon_name.text = "Pistola"
	stats_weapon_name.add_theme_font_size_override("font_size", 20)
	stats_weapon_name.add_theme_color_override("font_color", Color("#E5EEF0"))
	stats_weapon_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_weapon_header_box.add_child(stats_weapon_name)

	stats_weapon_vbox = VBoxContainer.new()
	stats_weapon_vbox.add_theme_constant_override("separation", 6)
	vbox.add_child(stats_weapon_vbox)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Indicador "Vista previa al equipar"
	stats_preview_badge = HBoxContainer.new()
	stats_preview_badge.add_theme_constant_override("separation", 6)
	stats_preview_badge.visible = false
	vbox.add_child(stats_preview_badge)

	var info_icon = TextureRect.new()
	info_icon.texture = tex_icon_info
	info_icon.custom_minimum_size = Vector2(20, 20)
	info_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	info_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stats_preview_badge.add_child(info_icon)

	var preview_text = Label.new()
	preview_text.text = "Vista previa al equipar"
	preview_text.add_theme_font_size_override("font_size", 16)
	preview_text.add_theme_color_override("font_color", Color("#52D8C6"))
	stats_preview_badge.add_child(preview_text)

# ── Construcción de la Franja Inferior (Atajos) ────────────────────────────────

func _build_bottom_bar() -> void:
	for c in bottom_bar.get_children():
		c.queue_free()

	bottom_bar.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_footer, 8.0))

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	bottom_bar.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 36)
	margin.add_child(hbox)

	_add_bottom_shortcut(hbox, "icon_mouse", "Clic", "Seleccionar")
	_add_bottom_shortcut(hbox, "keycap", "E", "Equipar")
	_add_bottom_shortcut(hbox, "keycap", "Shift", "Comparar")
	_add_bottom_shortcut(hbox, "keycap", "Esc", "Volver")

func _add_bottom_shortcut(parent: HBoxContainer, icon_type: String, key_text: String, action_text: String) -> void:
	var item_box = HBoxContainer.new()
	item_box.add_theme_constant_override("separation", 8)
	parent.add_child(item_box)

	if icon_type == "icon_mouse":
		var m_icon = TextureRect.new()
		m_icon.texture = tex_icon_mouse
		m_icon.custom_minimum_size = Vector2(24, 24)
		m_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		m_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_box.add_child(m_icon)
	else:
		var kcap = _create_keycap_box(key_text)
		item_box.add_child(kcap)

	var lbl = Label.new()
	lbl.text = action_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color("#8DAAB4"))
	item_box.add_child(lbl)

# ── Códice en Panel Overlay ───────────────────────────────────────────────────

func _build_codex_panel() -> void:
	codex_view = PanelContainer.new()
	codex_view.visible = false
	codex_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	codex_view.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_inset, 8.0))
	content_area.add_child(codex_view)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	codex_view.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "CÓDICE DE COMPONENTES E HISTORIAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#52D8C6"))
	vbox.add_child(title)

	var sub_tabs = HBoxContainer.new()
	sub_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_tabs.add_theme_constant_override("separation", 12)
	vbox.add_child(sub_tabs)

	codex_category_buttons.clear()
	_add_codex_cat_button(sub_tabs, "BESTIARIO", "enemies")
	_add_codex_cat_button(sub_tabs, "ARMAMENTO", "weapons")
	_add_codex_cat_button(sub_tabs, "ITEMS", "items")
	_add_codex_cat_button(sub_tabs, "NPCs", "npcs")
	_add_codex_cat_button(sub_tabs, "ZONAS", "levels")
	_add_codex_cat_button(sub_tabs, "SINERGIAS", "synergies")

	codex_progress_label = Label.new()
	codex_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	codex_progress_label.add_theme_font_size_override("font_size", 16)
	codex_progress_label.add_theme_color_override("font_color", Color("#8DAAB4"))
	vbox.add_child(codex_progress_label)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)

	codex_grid = GridContainer.new()
	codex_grid.columns = 6
	codex_grid.add_theme_constant_override("h_separation", 16)
	codex_grid.add_theme_constant_override("v_separation", 16)
	center.add_child(codex_grid)

func _add_codex_cat_button(parent: Control, text: String, cat_key: String) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(130, 38)
	btn.add_theme_font_size_override("font_size", 16)
	_apply_secondary_button_style(btn)
	btn.pressed.connect(_on_codex_category_pressed.bind(cat_key))
	parent.add_child(btn)
	codex_category_buttons[cat_key] = btn

# ── Lógica de Menú, Visibilidad y Animación ───────────────────────────────────

func toggle_visibility() -> void:
	if _is_animating: return
	if visible:
		_animate_close()
	else:
		_animate_open()

func _animate_open() -> void:
	_is_animating = true
	visible = true
	get_tree().paused = true
	SceneTransition.set_menu_muffle(true)
	update_ui()
	_start_open_tweens()

func _start_open_tweens() -> void:
	var start_y = get_viewport_rect().size.y
	window_margin.position.y = start_y
	dark_backdrop.modulate.a = 0.0

	var slide_tween = create_tween()
	slide_tween.tween_property(window_margin, "position:y", _default_margin_pos_y, 0.35)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	var fade_tween = create_tween()
	fade_tween.tween_property(dark_backdrop, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	slide_tween.tween_callback(func(): _is_animating = false)

func _animate_close() -> void:
	_is_animating = true
	_hide_tooltip()
	SceneTransition.set_menu_muffle(false)
	var target_y = get_viewport_rect().size.y

	var slide_tween = create_tween()
	slide_tween.tween_property(window_margin, "position:y", target_y, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	var fade_tween = create_tween()
	fade_tween.tween_property(dark_backdrop, "modulate:a", 0.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	slide_tween.tween_callback(_on_close_finished)

func _on_close_finished() -> void:
	visible = false
	get_tree().paused = false
	_is_animating = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if not visible:
			var root = get_tree().root
			if root.has_node("WeaponSelectionMenu") or root.has_node("UpgradesMenu"):
				return
		toggle_visibility()
		get_viewport().set_input_as_handled()
		return

	if not visible: return

	if event.is_action_pressed("ui_cancel"):
		_play_cancel_sound()
		toggle_visibility()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			_on_detail_equip_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SHIFT:
			_toggle_compare_mode()
			get_viewport().set_input_as_handled()

func _play_cancel_sound() -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://Audio/Sfx/UI_cancelar.wav")
	sfx_player.bus = "SFX"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _play_equip_sound() -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://Audio/Sfx/Equipar_items.wav")
	sfx_player.bus = "SFX"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

# ── Actualización General ──────────────────────────────────────────────────────

func update_if_visible() -> void:
	if not visible: return
	update_ui()

func update_ui() -> void:
	_update_header_data()
	_update_portrait()
	update_items_list()
	update_equipment_display()
	_update_weapon_displays()
	_update_attributes_display()
	_update_detail_panel()
	_update_slot_highlights_and_targets()

	if current_tab == "CODEX":
		_refresh_codex_grid()

func _update_header_data() -> void:
	if coin_label:
		coin_label.text = _format_scrap_number(GameData.scrap)
	if capacity_label and inventory:
		capacity_label.text = "%d / 24" % inventory.items.size()

func _format_scrap_number(n: int) -> String:
	var s = str(n)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "." + result
	return result

func _auto_fetch_player_nodes() -> void:
	if inventory and equipment and player_sprite: return
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	if not inventory:
		inventory = p.get_node_or_null("Inventory")
	if not equipment:
		equipment = p.get_node_or_null("Equipment")
	if not player_sprite:
		player_sprite = p.get_node_or_null("AnimatedSprite2D")

func _update_portrait() -> void:
	if not portrait_anim_sprite: return
	_auto_fetch_player_nodes()
	if not player_sprite or not player_sprite.sprite_frames: return
	if portrait_anim_sprite.sprite_frames != player_sprite.sprite_frames:
		portrait_anim_sprite.sprite_frames = player_sprite.sprite_frames
	var anim = &"idle_down"
	if portrait_anim_sprite.sprite_frames.has_animation(anim):
		portrait_anim_sprite.play(anim)
	_center_portrait_sprite()

func _center_portrait_sprite() -> void:
	if not portrait_container or not portrait_anim_sprite: return
	if portrait_container.size.x <= 0.0 or portrait_container.size.y <= 0.0: return
	portrait_anim_sprite.position = portrait_container.size * 0.5

# ── Manejo de Items y Filtrado ─────────────────────────────────────────────────

func update_items_list() -> void:
	if not inventory: return

	var grouped: Array = []
	for item_data in inventory.items:
		var found = false
		for entry in grouped:
			if entry.item.id == item_data.id:
				entry.count += 1
				found = true
				break
		if not found:
			grouped.append({"item": item_data, "count": 1})

	_sort_grouped_items(grouped)

	var filtered: Array = []
	for entry in grouped:
		if current_filter == "ALL":
			filtered.append(entry)
		elif current_filter == "WEAPON" and entry.item.type == ItemData.ItemType.WEAPON:
			filtered.append(entry)
		elif current_filter == "BODY" and entry.item.type in [ItemData.ItemType.TORSO, ItemData.ItemType.ARMS, ItemData.ItemType.LEGS]:
			filtered.append(entry)

	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if i < filtered.size():
			var entry = filtered[i]
			slot.update_slot(entry.item, entry.count)
			slot.set_selected(selected_item != null and selected_item.id == entry.item.id)
		else:
			slot.update_slot(null)
			slot.set_selected(false)

func _sort_grouped_items(list: Array) -> void:
	match sort_mode:
		"TYPE":
			list.sort_custom(func(a, b): return int(a.item.type) < int(b.item.type))
		"NAME":
			list.sort_custom(func(a, b): return a.item.item_name < b.item.item_name)
		_:
			pass

func update_equipment_display() -> void:
	if not equipment: return
	for slot_ui in ui_slots:
		var item_in_slot = equipment.slots.get(slot_ui.slot_type)
		slot_ui.update_slot(item_in_slot)
		slot_ui.set_selected(selected_item != null and item_in_slot != null and selected_item == item_in_slot)

func _update_weapon_displays() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	if primary_weapon_icon and "active_weapon" in p and p.active_weapon:
		primary_weapon_icon.texture = _get_weapon_texture(p.active_weapon)
	if secondary_weapon_icon and "second_weapon" in p and p.second_weapon:
		secondary_weapon_icon.texture = _get_weapon_texture(p.second_weapon)

func _get_weapon_texture(weapon_container: Node) -> Texture2D:
	if not weapon_container: return null
	var cur = weapon_container.get("current_weapon")
	if not cur:
		cur = weapon_container

	# 1. Sprite2D directo (Melee_sprite o Sprite2D)
	var melee_sprite = cur.get_node_or_null("Melee_sprite")
	if melee_sprite is Sprite2D and melee_sprite.texture:
		return melee_sprite.texture
	var sprite_node = cur.get_node_or_null("Sprite2D")
	if sprite_node is Sprite2D and sprite_node.texture:
		return sprite_node.texture

	# 2. AnimatedSprite2D (Weapon_Sprites o AnimatedSprite2D)
	var anim_sprite = cur.get_node_or_null("Weapon_Sprites")
	if not anim_sprite:
		anim_sprite = cur.get_node_or_null("AnimatedSprite2D")
	if anim_sprite is AnimatedSprite2D and anim_sprite.sprite_frames:
		var frames = anim_sprite.sprite_frames
		var anim = anim_sprite.animation
		if not frames.has_animation(anim):
			var anim_names = frames.get_animation_names()
			if anim_names.size() > 0:
				anim = anim_names[0]
		if frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
			return frames.get_frame_texture(anim, 0)

	# 3. Fallback en caso de nodos anidados
	for child in cur.get_children():
		if child is Sprite2D and child.texture:
			return child.texture
		if child is AnimatedSprite2D and child.sprite_frames:
			var anim_names = child.sprite_frames.get_animation_names()
			if anim_names.size() > 0 and child.sprite_frames.get_frame_count(anim_names[0]) > 0:
				return child.sprite_frames.get_frame_texture(anim_names[0], 0)

	# 4. Fallback si es el arma por defecto o elegida
	var chosen = GameData.chosen_primary_weapon if GameData else "pistol"
	match chosen:
		"pistol":
			return load("res://Art/Weapons/Distance/Pistol/Weapon_Pisotol.png")
		"shotgun":
			return load("res://Art/Weapons/Distance/Shotgun/Weapon_Shotgun.png")
		"uzi":
			return load("res://Art/Weapons/Distance/Uzi/Weapon_Uzi.png")
	return null

func _get_weapon_display_name_text(weapon_container: Node) -> String:
	if not weapon_container: return "Pistola"
	var cur = weapon_container.get("current_weapon")
	if not cur: cur = weapon_container
	if "id" in cur and str(cur.id) != "":
		return str(cur.id).capitalize()
	if "weapon_name" in cur and str(cur.weapon_name) != "":
		return str(cur.weapon_name)
	var scene_name = cur.name
	match scene_name.to_lower():
		"pistol": return "Pistola"
		"shotgun": return "Escopeta"
		"uzi": return "Uzi"
		"dagger": return "Daga"
		"axe": return "Hacha"
		"mace": return "Maza"
	return scene_name.capitalize()

# ── Interacción con Slots ──────────────────────────────────────────────────────

func _on_slot_clicked(item: ItemData) -> void:
	selected_item = item
	update_ui()

func _on_slot_double_clicked(item: ItemData, slot_ui: UISlot) -> void:
	if slot_ui.is_inventory_slot:
		_equip_item_direct(item)
	else:
		_unequip_item_direct(item, slot_ui.slot_type)

func _on_drag_started(drag_item: ItemData, source_slot: UISlot) -> void:
	selected_item = drag_item
	selected_source_slot = source_slot
	_highlight_slots_for_item(drag_item)

func _highlight_slots_for_item(item: ItemData) -> void:
	for slot in ui_slots:
		var is_valid = slot.is_valid_target_for(item)
		slot.set_drop_target_state(is_valid, not is_valid)
	for slot in inventory_slots:
		slot.set_drop_target_state(true, false)

func _update_slot_highlights_and_targets() -> void:
	if selected_item == null:
		for slot in ui_slots:
			slot.set_drop_target_state(false, false)
			slot.set_highlight(false)
		return

	# Resaltar destinos compatibles en equipamiento
	for slot in ui_slots:
		var is_valid = slot.is_valid_target_for(selected_item)
		slot.set_highlight(is_valid)

func _on_item_dropped(drag_item: ItemData, source_slot: UISlot, target_slot: UISlot) -> void:
	if source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		_equip_item_to_slot(drag_item, target_slot.slot_type)
	elif not source_slot.is_inventory_slot and target_slot.is_inventory_slot:
		_unequip_item_direct(drag_item, source_slot.slot_type)
	elif not source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		_swap_equipment_slots(source_slot.slot_type, target_slot.slot_type)

	selected_item = drag_item
	update_ui()
	_hide_tooltip()

func _equip_item_direct(item: ItemData) -> void:
	var target_slot_type = _get_available_slot_for_item(item)
	_equip_item_to_slot(item, target_slot_type)

func _equip_item_to_slot(item: ItemData, target_slot_type: ItemData.ItemSlot) -> void:
	var old_item = equipment.slots.get(target_slot_type)
	item.slot = target_slot_type
	inventory.remove_item(item)

	if old_item and not equipment.is_body_part(old_item):
		inventory.add_item(old_item)

	equipment.equip_item(item)
	_play_equip_sound()
	update_ui()

func _unequip_item_direct(item: ItemData, slot_type: ItemData.ItemSlot) -> void:
	equipment.slots[slot_type] = null
	equipment.equipment_changed.emit()
	inventory.add_item(item)
	update_ui()

func _swap_equipment_slots(slot_a: ItemData.ItemSlot, slot_b: ItemData.ItemSlot) -> void:
	var item_a = equipment.slots.get(slot_a)
	var item_b = equipment.slots.get(slot_b)
	equipment.slots[slot_a] = item_b
	equipment.slots[slot_b] = item_a
	if item_a: item_a.slot = slot_b
	if item_b: item_b.slot = slot_a
	equipment.equipment_changed.emit()
	_play_equip_sound()
	update_ui()

func _get_available_slot_for_item(item: ItemData) -> ItemData.ItemSlot:
	match item.type:
		ItemData.ItemType.TORSO:
			return ItemData.ItemSlot.TORSO
		ItemData.ItemType.ARMS:
			if equipment.slots.get(ItemData.ItemSlot.ARM_L) == null: return ItemData.ItemSlot.ARM_L
			if equipment.slots.get(ItemData.ItemSlot.ARM_R) == null: return ItemData.ItemSlot.ARM_R
			return ItemData.ItemSlot.ARM_L
		ItemData.ItemType.LEGS:
			if equipment.slots.get(ItemData.ItemSlot.LEG_L) == null: return ItemData.ItemSlot.LEG_L
			if equipment.slots.get(ItemData.ItemSlot.LEG_R) == null: return ItemData.ItemSlot.LEG_R
			return ItemData.ItemSlot.LEG_L
		ItemData.ItemType.WEAPON:
			var w_slots = [
				ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3,
				ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3
			]
			for s in w_slots:
				if equipment.slots.get(s) == null:
					return s
			return ItemData.ItemSlot.MAIN_W1
	return ItemData.ItemSlot.TORSO

# ── Ficha de Detalle y Comparación ─────────────────────────────────────────────

func _update_detail_panel() -> void:
	if selected_item == null:
		detail_empty_label.visible = true
		detail_content_box.visible = false
		return

	detail_empty_label.visible = false
	detail_content_box.visible = true

	detail_icon_rect.texture = selected_item.icon
	detail_name_label.text = selected_item.item_name

	var type_str = _get_item_type_string(selected_item)
	detail_meta_label.text = "%s • Raro" % type_str

	detail_desc_label.text = _get_item_description(selected_item)

	# Comparación de stats con el objeto actualmente equipado
	detail_stats_label.text = _format_item_comparison_stats(selected_item)

func _get_item_type_string(item: ItemData) -> String:
	match item.type:
		ItemData.ItemType.WEAPON: return "Arma"
		ItemData.ItemType.TORSO: return "Torso"
		ItemData.ItemType.ARMS: return "Brazos"
		ItemData.ItemType.LEGS: return "Piernas"
	return "Componente"

func _get_item_description(item: ItemData) -> String:
	if item.type == ItemData.ItemType.WEAPON:
		return "Módulo de combate para armamento táctico."
	if item.type == ItemData.ItemType.TORSO:
		return "Coraza blindada ligera que disipa la energía del impacto."
	if item.type == ItemData.ItemType.ARMS:
		return "Guantes servoasistidos que mejoran la velocidad y potencia."
	if item.type == ItemData.ItemType.LEGS:
		return "Botas cinéticas para optimizar la movilidad y el esquive."
	return "Dispositivo avanzado de combate."

func _format_item_comparison_stats(item: ItemData) -> String:
	if item.stats.is_empty():
		return "[color=#8DAAB4]Sin mejoras adicionales[/color]"

	var target_slot = _get_available_slot_for_item(item)
	var current_equipped = equipment.slots.get(target_slot)

	var lines: Array[String] = []
	for k in item.stats.keys():
		var new_val: float = item.stats[k]
		var old_val: float = current_equipped.stats.get(k, 0.0) if current_equipped else 0.0
		var line = _format_single_stat_diff_line(k, old_val, new_val)
		lines.append(line)

	return "\n".join(lines)

func _format_single_stat_diff_line(stat_key: String, old_val: float, new_val: float) -> String:
	var label = STAT_LABELS.get(stat_key, stat_key.capitalize())
	var diff = new_val - old_val
	var is_percent = stat_key in ["max_health_percent", "move_speed_percent", "crit_chance", "attack_speed", "stun_chance", "burn_chance", "slow_chance"]

	var old_str = ("%d%%" % round(old_val * 100)) if is_percent else str(old_val)
	var new_str = ("%d%%" % round(new_val * 100)) if is_percent else str(new_val)
	var diff_str = ("%+d%%" % round(diff * 100)) if is_percent else ("%+d" % int(diff) if diff == int(diff) else "%+.1f" % diff)

	var is_improvement = _is_stat_improvement(stat_key, diff)
	var col = "#52D8C6" if is_improvement else "#EDB35B"

	if abs(diff) < 0.001:
		return "%s: %s" % [label, new_str]
	return "%s: %s → [color=%s]%s (%s)[/color]" % [label, old_str, col, new_str, diff_str]

func _is_stat_improvement(stat_key: String, diff: float) -> bool:
	if stat_key == "cone_spread_angle":
		return diff < 0.0 # menor dispersión es mejora
	return diff > 0.0

func _on_detail_equip_pressed() -> void:
	if selected_item == null: return
	_equip_item_direct(selected_item)

func _toggle_compare_mode() -> void:
	is_comparing = !is_comparing
	update_ui()

func _on_stats_weapon_tab_pressed(tab_key: String) -> void:
	active_weapon_stats_tab = tab_key
	_update_stats_weapon_tab_buttons()
	_update_attributes_display()

func _update_stats_weapon_tab_buttons() -> void:
	if not stats_tab_primary_btn or not stats_tab_secondary_btn: return
	var is_primary = (active_weapon_stats_tab == "PRIMARY")
	_apply_subtab_button_style(stats_tab_primary_btn, is_primary)
	_apply_subtab_button_style(stats_tab_secondary_btn, not is_primary)

func _apply_subtab_button_style(btn: Button, is_active: bool) -> void:
	var tex = tex_tab_active if is_active else tex_tab_normal
	var hover_tex = tex_tab_active if is_active else tex_tab_hover
	var font_col = Color("#F4C45E") if is_active else Color("#8DAAB4")
	btn.add_theme_stylebox_override("normal", _create_9slice_style(tex, 8.0))
	btn.add_theme_stylebox_override("hover", _create_9slice_style(hover_tex, 8.0))
	btn.add_theme_stylebox_override("pressed", _create_9slice_style(tex_tab_active, 8.0))
	btn.add_theme_stylebox_override("focus", _create_9slice_style(hover_tex, 8.0))
	btn.add_theme_color_override("font_color", font_col)
	btn.add_theme_color_override("font_hover_color", Color("#E5EEF0"))

# ── Atributos del Personaje y Armas ──────────────────────────────────────────

func _update_attributes_display() -> void:
	for c in stats_char_vbox.get_children(): c.queue_free()
	for c in stats_weapon_vbox.get_children(): c.queue_free()

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]

	# Personaje
	var max_hp = p.stats.max_health
	var energy = int(p.trituradora_energy) if "trituradora_energy" in p else 100
	var armor = int(p._get_equip_stat("armor", false))
	_add_attribute_row(stats_char_vbox, tex_icon_health, "Vida máxima", str(max_hp))
	_add_attribute_row(stats_char_vbox, tex_icon_energy, "Energía", str(energy))
	_add_attribute_row(stats_char_vbox, tex_icon_armor, "Armadura", str(armor))

	if active_weapon_stats_tab == "PRIMARY":
		_render_primary_weapon_stats(p)
	else:
		_render_secondary_weapon_stats(p)

	stats_preview_badge.visible = (selected_item != null)

func _render_primary_weapon_stats(p: Node2D) -> void:
	if stats_weapon_icon and p.active_weapon:
		stats_weapon_icon.texture = _get_weapon_texture(p.active_weapon)
	if stats_weapon_name and p.active_weapon:
		stats_weapon_name.text = _get_weapon_display_name_text(p.active_weapon)

	var base_dmg = p._get_weapon_damage() * p._get_weapon_damage_multiplier() if p.active_weapon else 10.0
	var equip_dmg = p._get_equip_stat("damage", true)
	var total_dmg = int((base_dmg + equip_dmg) * (1.0 + p._get_equip_stat("damage_multiplier", true)))

	var aps = p._get_weapon_attack_speed() if p.active_weapon else 1.0
	var total_aps = aps * (1.0 + p._get_equip_stat("attack_speed", true))

	var bullets = (p._get_weapon_bullets() if p.active_weapon else 1) + int(p._get_equip_stat("bullet_count", true))
	var crit_c = (p._get_weapon_crit_chance() if p.active_weapon else 0.0) + p._get_equip_stat("crit_chance", true)
	var crit_d = (p._get_weapon_crit_damage() if p.active_weapon else 2.0) + p._get_equip_stat("crit_damage", true)
	var proj_speed = (p._get_weapon_proj_speed() if p.active_weapon else 600.0) + p._get_equip_stat("projectile_speed", true)
	var piercing = (p._get_weapon_piercing() if p.active_weapon else 0) + int(p._get_equip_stat("piercing", true))

	_add_attribute_row(stats_weapon_vbox, tex_icon_damage, "Daño", str(total_dmg), _get_preview_delta("damage"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_fire_rate, "Cadencia", "%.1f/s" % total_aps, _get_preview_delta("attack_speed"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_projectiles, "Proyectiles", str(bullets), _get_preview_delta("bullet_count"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_critical, "Prob. crítica", "%d%%" % int(crit_c * 100), _get_preview_delta("crit_chance"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_critical, "Daño crítico", "x%.1f" % crit_d, _get_preview_delta("crit_damage"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_range, "Vel. Proyectil", "%d" % int(proj_speed), _get_preview_delta("projectile_speed"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_pierce, "Perforación", str(piercing), _get_preview_delta("piercing"))

func _render_secondary_weapon_stats(p: Node2D) -> void:
	if stats_weapon_icon and p.second_weapon:
		stats_weapon_icon.texture = _get_weapon_texture(p.second_weapon)
	if stats_weapon_name and p.second_weapon:
		stats_weapon_name.text = _get_weapon_display_name_text(p.second_weapon)

	var base_dmg = float(p.second_weapon.damage) if p.second_weapon and "damage" in p.second_weapon else 15.0
	var equip_dmg = p._get_equip_stat("damage", false)
	var total_dmg = int((base_dmg + equip_dmg) * (1.0 + p._get_equip_stat("damage_multiplier", false)))

	var base_aps = float(p.second_weapon.attack_speed) if p.second_weapon and "attack_speed" in p.second_weapon else 1.0
	var total_aps = base_aps * (1.0 + p._get_equip_stat("attack_speed", false))

	var base_range = float(p.second_weapon.attack_range) if p.second_weapon and "attack_range" in p.second_weapon else 1.0
	var flat_range = p._get_equip_stat("attack_range", false)
	var pct_range = p._get_equip_stat("attack_range_percent", false)
	var total_range = (base_range + flat_range) * (1.0 + pct_range)

	var base_kb = float(p.second_weapon.knockback_force) if p.second_weapon and "knockback_force" in p.second_weapon else 150.0
	var total_kb = base_kb + p._get_equip_stat("knockback_force", false)

	_add_attribute_row(stats_weapon_vbox, tex_icon_damage, "Daño cuerpo a cuerpo", str(total_dmg), _get_preview_delta("damage"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_fire_rate, "Velocidad de ataque", "%.1f/s" % total_aps, _get_preview_delta("attack_speed"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_range, "Alcance de golpe", "x%.2f" % total_range, _get_preview_delta("attack_range"))
	_add_attribute_row(stats_weapon_vbox, tex_icon_armor, "Fuerza de empuje", "%d" % int(total_kb), _get_preview_delta("knockback_force"))

func _add_attribute_row(parent: Control, icon: Texture2D, label_text: String, value_text: String, delta_text: String = "") -> void:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)

	var icon_rect = TextureRect.new()
	icon_rect.texture = icon
	icon_rect.custom_minimum_size = Vector2(20, 20)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hbox.add_child(icon_rect)

	var name_lbl = Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color("#8DAAB4"))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)

	var val_lbl = Label.new()
	val_lbl.text = value_text
	val_lbl.add_theme_font_size_override("font_size", 20)
	val_lbl.add_theme_color_override("font_color", Color("#E5EEF0"))
	hbox.add_child(val_lbl)

	if not delta_text.is_empty():
		var delta_lbl = Label.new()
		delta_lbl.text = delta_text
		delta_lbl.add_theme_font_size_override("font_size", 18)
		delta_lbl.add_theme_color_override("font_color", Color("#52D8C6") if delta_text.begins_with("+") else Color("#EDB35B"))
		hbox.add_child(delta_lbl)

func _get_preview_delta(stat_name: String) -> String:
	if selected_item == null: return ""
	if not selected_item.stats.has(stat_name): return ""
	var val = selected_item.stats[stat_name]
	if stat_name in ["crit_chance", "attack_speed"]:
		return "%+d%%" % round(val * 100)
	if val == int(val):
		return "%+d" % int(val)
	return "%+.1f" % val

# ── Pestañas y Filtros ─────────────────────────────────────────────────────────

func _on_inventory_tab_pressed() -> void:
	current_tab = "INVENTORY"
	main_three_columns.visible = true
	codex_view.visible = false
	_apply_tab_style(tab_inventory_btn, true)
	_apply_tab_style(tab_codex_btn, false)
	_hide_tooltip()
	update_ui()

func _on_codex_tab_pressed() -> void:
	current_tab = "CODEX"
	main_three_columns.visible = false
	codex_view.visible = true
	_apply_tab_style(tab_inventory_btn, false)
	_apply_tab_style(tab_codex_btn, true)
	_hide_tooltip()
	_refresh_codex_grid()

func _on_filter_pressed(filter_type: String) -> void:
	current_filter = filter_type
	update_items_list()

func _on_sort_option_selected(index: int) -> void:
	match index:
		0: sort_mode = "DEFAULT"
		1: sort_mode = "TYPE"
		2: sort_mode = "NAME"
	update_items_list()

# ── Lógica de Códice ──────────────────────────────────────────────────────────

func _on_codex_category_pressed(cat: String) -> void:
	selected_codex_category = cat
	_hide_tooltip()
	_refresh_codex_grid()

func _refresh_codex_grid() -> void:
	if not codex_grid: return
	for c in codex_grid.get_children(): c.queue_free()

	for cat_key in codex_category_buttons.keys():
		var btn: Button = codex_category_buttons[cat_key]
		if cat_key == selected_codex_category:
			_apply_primary_button_style(btn)
		else:
			_apply_secondary_button_style(btn)

	if selected_codex_category == "synergies":
		_fill_codex_synergies()
		return
	codex_grid.columns = 6
	var cat_data = CodexData.DATA.get(selected_codex_category, {})
	var unlocked_count = 0
	for entry_id in cat_data.keys():
		var entry = cat_data[entry_id]
		var is_unlocked = GameData.is_codex_unlocked(selected_codex_category, entry_id)
		if is_unlocked: unlocked_count += 1

		var fake_item = ItemData.new()
		fake_item.id = entry_id
		if is_unlocked:
			fake_item.item_name = entry.name
			fake_item.icon = entry.icon
		else:
			fake_item.item_name = "???"

		var slot = UISlot.new()
		slot.custom_minimum_size = Vector2(72, 72)
		slot.update_slot(fake_item)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		codex_grid.add_child(slot)

	if codex_progress_label:
		codex_progress_label.text = "%d / %d registrados" % [unlocked_count, cat_data.size()]

# Pestaña SINERGIAS: fichas grandes (CodexSynergyCard) en vez de slots chicos.
# Las bloqueadas muestran solo para qué arma son; el resto queda tapado.
func _fill_codex_synergies() -> void:
	codex_grid.columns = 3
	var ids = OmniaCatalog.synergy_ids()
	var unlocked_count = 0
	for syn_id in ids:
		if GameData.is_synergy_unlocked(syn_id):
			unlocked_count += 1
		codex_grid.add_child(CodexSynergyCard.create(syn_id))
	if codex_progress_label:
		codex_progress_label.text = "%d / %d sinergias desbloqueadas" % [unlocked_count, ids.size()]

# ── Tooltip Flotante ──────────────────────────────────────────────────────────

func _create_tooltip_panel() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.custom_minimum_size = Vector2(300, 160)
	tooltip_panel.z_index = 100
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_theme_stylebox_override("panel", _create_9slice_style(tex_panel_tooltip, 8.0))
	add_child(tooltip_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	tooltip_panel.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)

	tooltip_name = Label.new()
	tooltip_name.add_theme_font_size_override("font_size", 18)
	tooltip_name.add_theme_color_override("font_color", Color("#E5EEF0"))
	tooltip_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(tooltip_name)

	tooltip_rarity = Label.new()
	tooltip_rarity.add_theme_font_size_override("font_size", 14)
	tooltip_rarity.add_theme_color_override("font_color", Color("#52D8C6"))
	header.add_child(tooltip_rarity)

	tooltip_type = Label.new()
	tooltip_type.add_theme_font_size_override("font_size", 14)
	tooltip_type.add_theme_color_override("font_color", Color("#8DAAB4"))
	vbox.add_child(tooltip_type)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	tooltip_desc = RichTextLabel.new()
	tooltip_desc.fit_content = true
	tooltip_desc.bbcode_enabled = true
	tooltip_desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(tooltip_desc)

	tooltip_stats = RichTextLabel.new()
	tooltip_stats.fit_content = true
	tooltip_stats.bbcode_enabled = true
	tooltip_stats.add_theme_font_size_override("font_size", 14)
	vbox.add_child(tooltip_stats)

	tooltip_action = Label.new()
	tooltip_action.add_theme_font_size_override("font_size", 12)
	tooltip_action.add_theme_color_override("font_color", Color("#F4C45E"))
	vbox.add_child(tooltip_action)

func _on_slot_hovered(item_data: ItemData, slot_rect: Rect2) -> void:
	if not tooltip_panel: return
	_show_slot_tooltip(item_data, slot_rect)

func _show_slot_tooltip(item_data: ItemData, slot_rect: Rect2) -> void:
	var codex_cat = CodexData.get_category_for_id(item_data.id)
	if codex_cat != "":
		var entry = CodexData.DATA[codex_cat].get(item_data.id, {})
		var is_unlocked = GameData.is_codex_unlocked(codex_cat, item_data.id)
		tooltip_name.text = entry.get("name", "???") if is_unlocked else "???"
		tooltip_rarity.text = "DESBLOQUEADO" if is_unlocked else "BLOQUEADO"
		tooltip_type.text = codex_cat.to_upper()
		tooltip_desc.text = entry.get("lore", "") if is_unlocked else "Información clasificada."
		tooltip_stats.text = entry.get("stats", "") if is_unlocked else ""
		tooltip_action.text = ""
	else:
		tooltip_name.text = item_data.item_name
		tooltip_rarity.text = "RARO"
		tooltip_type.text = _get_item_type_string(item_data)
		tooltip_desc.text = _get_item_description(item_data)
		tooltip_stats.text = _format_item_comparison_stats(item_data)
		tooltip_action.text = "Clic para seleccionar • Arrastrar para equipar"

	var tooltip_pos = Vector2(slot_rect.end.x + 12, slot_rect.position.y)
	if tooltip_pos.x + tooltip_panel.size.x > get_viewport_rect().size.x:
		tooltip_pos.x = slot_rect.position.x - tooltip_panel.size.x - 12
	tooltip_panel.global_position = tooltip_pos
	tooltip_panel.show()

func _on_slot_unhovered() -> void:
	_hide_tooltip()

func _hide_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.hide()

func _on_weapon_badge_hovered(is_main: bool) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var panel = primary_weapon_slot_panel if is_main else secondary_weapon_slot_panel
	if not panel: return
	tooltip_name.text = "ARMA " + ("PRINCIPAL" if is_main else "SECUNDARIA")
	tooltip_rarity.text = "EQUIPADA"
	tooltip_type.text = "ARMAMENTO ACTIVO"
	tooltip_desc.text = "Arma actualmente en tus manos. Los módulos contiguos aumentan sus características."
	tooltip_stats.text = ""
	tooltip_action.text = ""
	var rect = panel.get_global_rect()
	var pos = Vector2(rect.end.x + 12, rect.position.y)
	tooltip_panel.global_position = pos
	tooltip_panel.show()

func _on_weapon_badge_unhovered() -> void:
	_hide_tooltip()
