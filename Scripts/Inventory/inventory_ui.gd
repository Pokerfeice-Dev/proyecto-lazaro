class_name InventoryUI
extends Control

@export var inventory: Inventory
@export var equipment: Equipment

var ui_slots: Array[UISlot] = []
var inventory_slots: Array[UISlot] = []

@onready var stats_label: RichTextLabel = $MarginContainer/HBoxContainer/StatsPanel/MarginContainer/VBoxContainer/StatsLabel
@onready var equip_container: VBoxContainer = $MarginContainer/HBoxContainer/EquipmentPanel/MarginContainer/VBoxContainer/SlotsList
@onready var inventory_grid: GridContainer = $MarginContainer/HBoxContainer/InventoryPanel/MarginContainer/VBoxContainer/InventoryGrid

# Tab and layout variables
var current_tab: String = "INVENTORY" # "INVENTORY" or "CODEX"
var current_filter: String = "ALL" # "ALL", "WEAPON", "BODY"
var is_sorted_recent: bool = false
var _is_animating: bool = false
var _default_margin_pos_y: float = 80.0
var selected_codex_category: String = "enemies" # "enemies", "weapons", "items", "npcs", "levels"

# Codex Panel UI container
var codex_panel: ScrollContainer
var main_hbox: HBoxContainer
var codex_grid: GridContainer

# Tooltip UI components
var tooltip_panel: PanelContainer
var tooltip_name: Label
var tooltip_rarity: Label
var tooltip_type: Label
var tooltip_desc: RichTextLabel
var tooltip_stats: RichTextLabel
var tooltip_action: Label

# Process method removed to handle all inputs via _input function.

func toggle_visibility() -> void:
	if _is_animating:
		return
	_toggle_state()

func _toggle_state() -> void:
	if visible:
		_animate_close()
	else:
		_animate_open()

func _animate_open() -> void:
	_is_animating = true
	visible = true
	get_tree().paused = true
	update_ui()
	_start_open_tweens()

func _start_open_tweens() -> void:
	var start_y = get_viewport_rect().size.y
	$MarginContainer.position.y = start_y
	$Background.modulate.a = 0.0
	
	var slide_tween = create_tween()
	slide_tween.tween_property($MarginContainer, "position:y", _default_margin_pos_y, 0.4)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	var fade_tween = create_tween()
	fade_tween.tween_property($Background, "modulate:a", 1.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	slide_tween.tween_callback(_on_open_animation_finished)

func _on_open_animation_finished() -> void:
	_is_animating = false

func _animate_close() -> void:
	_is_animating = true
	_hide_tooltip()
	_start_close_tweens()

func _start_close_tweens() -> void:
	var target_y = get_viewport_rect().size.y
	
	var slide_tween = create_tween()
	slide_tween.tween_property($MarginContainer, "position:y", target_y, 0.45)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	
	var fade_tween = create_tween()
	fade_tween.tween_property($Background, "modulate:a", 0.0, 0.35)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	slide_tween.tween_callback(_on_close_animation_finished)

func _on_close_animation_finished() -> void:
	visible = false
	get_tree().paused = false
	_is_animating = false

func update_if_visible() -> void:
	if not visible:
		return
	update_ui()

func update_ui() -> void:
	update_items_list()
	update_equipment_display()
	update_stats_display()
	if current_tab == "CODEX":
		_refresh_codex_grid()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_auto_fetch_player_nodes()
	_init_default_margin_position()

func _init_default_margin_position() -> void:
	var margin_node = get_node_or_null("MarginContainer")
	if margin_node:
		_default_margin_pos_y = margin_node.position.y
	
	# Wrap UI in tabs hierarchy
	_build_tabs_hierarchy()
	_create_tooltip_panel()
	_setup_codex()
	
	if not equipment or not inventory: return
	
	inventory.inventory_updated.connect(update_items_list)
	equipment.equipment_changed.connect(update_ui)
	stats_label.bbcode_enabled = true
	_setup_slots()

func _input(event: InputEvent) -> void:
	_handle_toggle_input(event)
	_handle_menu_input(event)

func _handle_toggle_input(event: InputEvent) -> void:
	if not event.is_action_pressed("toggle_inventory"):
		return
	if not visible:
		var root = get_tree().root
		if root.has_node("WeaponSelectionMenu") or root.has_node("UpgradesMenu"):
			return
	toggle_visibility()
	get_viewport().set_input_as_handled()

func _handle_menu_input(event: InputEvent) -> void:
	if not visible:
		return
	_handle_cancel_input(event)
	_handle_key_input(event)

func _handle_cancel_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	toggle_visibility()
	get_viewport().set_input_as_handled()

func _handle_key_input(event: InputEvent) -> void:
	var key_event = event as InputEventKey
	if not key_event:
		return
	if not key_event.pressed:
		return
	_process_menu_key(key_event.keycode)

func _process_menu_key(keycode: int) -> void:
	if keycode == KEY_F:
		_toggle_sort_recent()
		get_viewport().set_input_as_handled()

func _toggle_sort_recent() -> void:
	is_sorted_recent = !is_sorted_recent
	update_items_list()

func _auto_fetch_player_nodes() -> void:
	if inventory and equipment: return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0: return
	inventory = players[0].get_node_or_null("Inventory")
	equipment = players[0].get_node_or_null("Equipment")

# ── Header & Tabs Re-wrapping ───────────────────────────────────────────────

func _build_tabs_hierarchy() -> void:
	main_hbox = $MarginContainer/HBoxContainer
	var margin_container = $MarginContainer
	margin_container.remove_child(main_hbox)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "MainVBox"
	main_vbox.add_theme_constant_override("separation", 20)
	margin_container.add_child(main_vbox)
	
	# Create top tab buttons bar
	var header_tabs = HBoxContainer.new()
	header_tabs.alignment = FlowContainer.ALIGNMENT_CENTER
	header_tabs.add_theme_constant_override("separation", 48)
	main_vbox.add_child(header_tabs)
	
	var btn_inventory = Button.new()
	btn_inventory.text = "INVENTARIO"
	btn_inventory.custom_minimum_size = Vector2(160, 40)
	btn_inventory.pressed.connect(_on_inventory_tab_pressed)
	header_tabs.add_child(btn_inventory)
	
	var btn_codex = Button.new()
	btn_codex.text = "CÓDICE"
	btn_codex.custom_minimum_size = Vector2(160, 40)
	btn_codex.pressed.connect(_on_codex_tab_pressed)
	header_tabs.add_child(btn_codex)
	
	main_vbox.add_child(main_hbox)
	
	# Add filter buttons to the inventory panel VBox dynamically
	var inv_vbox = $MarginContainer/MainVBox/HBoxContainer/InventoryPanel/MarginContainer/VBoxContainer
	var filter_hbox = HBoxContainer.new()
	filter_hbox.alignment = FlowContainer.ALIGNMENT_CENTER
	filter_hbox.add_theme_constant_override("separation", 12)
	inv_vbox.add_child(filter_hbox)
	inv_vbox.move_child(filter_hbox, inv_vbox.get_node("InventoryGrid").get_index())
	
	var btn_all = Button.new()
	btn_all.text = "TODOS"
	btn_all.pressed.connect(_on_filter_pressed.bind("ALL"))
	filter_hbox.add_child(btn_all)
	
	var btn_wpns = Button.new()
	btn_wpns.text = "ARMAS"
	btn_wpns.pressed.connect(_on_filter_pressed.bind("WEAPON"))
	filter_hbox.add_child(btn_wpns)
	
	var btn_body = Button.new()
	btn_body.text = "CUERPO"
	btn_body.pressed.connect(_on_filter_pressed.bind("BODY"))
	filter_hbox.add_child(btn_body)

func _on_inventory_tab_pressed() -> void:
	current_tab = "INVENTORY"
	main_hbox.visible = true
	codex_panel.visible = false
	_hide_tooltip()
	update_ui()

func _on_codex_tab_pressed() -> void:
	current_tab = "CODEX"
	main_hbox.visible = false
	codex_panel.visible = true
	_hide_tooltip()
	_refresh_codex_grid()

func _on_filter_pressed(filter_type: String) -> void:
	current_filter = filter_type
	update_items_list()

# ── Custom Hover Tooltip Panel ───────────────────────────────────────────────

func _create_tooltip_panel() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.custom_minimum_size = Vector2(280, 200)
	tooltip_panel.z_index = 100
	add_child(tooltip_panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.05, 0.05, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 1.0, 0.8, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	tooltip_panel.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	tooltip_name = Label.new()
	tooltip_name.add_theme_font_size_override("font_size", 16)
	tooltip_name.add_theme_color_override("font_color", Color(1, 1, 1))
	tooltip_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(tooltip_name)
	
	tooltip_rarity = Label.new()
	tooltip_rarity.add_theme_font_size_override("font_size", 12)
	header.add_child(tooltip_rarity)
	
	tooltip_type = Label.new()
	tooltip_type.add_theme_font_size_override("font_size", 12)
	tooltip_type.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(tooltip_type)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	tooltip_desc = RichTextLabel.new()
	tooltip_desc.fit_content = true
	tooltip_desc.bbcode_enabled = true
	tooltip_desc.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tooltip_desc)
	
	tooltip_stats = RichTextLabel.new()
	tooltip_stats.fit_content = true
	tooltip_stats.bbcode_enabled = true
	tooltip_stats.add_theme_font_size_override("font_size", 12)
	vbox.add_child(tooltip_stats)
	
	tooltip_action = Label.new()
	tooltip_action.text = "🖱 Clic para seleccionar"
	tooltip_action.add_theme_font_size_override("font_size", 11)
	tooltip_action.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 0.7))
	vbox.add_child(tooltip_action)

func _get_category_for_item_id(entry_id: String) -> String:
	return CodexData.get_category_for_id(entry_id)

func _show_tooltip(item_data: ItemData, slot_rect: Rect2) -> void:
	if not tooltip_panel: return
	
	var codex_cat = _get_category_for_item_id(item_data.id)
	if codex_cat != "":
		_show_codex_tooltip(item_data.id, codex_cat, slot_rect)
		return
		
	_show_inventory_tooltip(item_data, slot_rect)

func _show_codex_tooltip(entry_id: String, category: String, slot_rect: Rect2) -> void:
	var entry = CodexData.DATA[category][entry_id]
	var is_unlocked = GameData.is_codex_unlocked(category, entry_id)
	
	if not is_unlocked:
		tooltip_name.text = "???"
		tooltip_rarity.text = "BLOQUEADO"
		tooltip_rarity.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		
		var category_names = {
			"enemies": "BESTIARIO", "weapons": "ARMAMENTO", 
			"items": "OBJETO RECOGIDO", "npcs": "CONTACTO", "levels": "ZONA DE COMBATE"
		}
		tooltip_type.text = category_names.get(category, category.to_upper())
		tooltip_desc.text = "Información encriptada. Interactúa con este elemento en el juego para desbloquear sus detalles."
		tooltip_stats.text = ""
		tooltip_action.text = "🔒 Bloqueado"
		tooltip_action.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 0.7))
	else:
		tooltip_name.text = entry.name.to_upper()
		tooltip_rarity.text = "DESBLOQUEADO"
		tooltip_rarity.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
		
		var category_names = {
			"enemies": "BESTIARIO", "weapons": "ARMAMENTO", 
			"items": "OBJETO RECOGIDO", "npcs": "CONTACTO", "levels": "ZONA DE COMBATE"
		}
		tooltip_type.text = category_names.get(category, category.to_upper())
		tooltip_desc.text = entry.lore
		tooltip_stats.text = "[color=yellow]" + entry.stats + "[/color]"
		tooltip_action.text = "🔓 Registrado"
		tooltip_action.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 0.7))
		
	_display_tooltip_at_position(slot_rect)

func _show_inventory_tooltip(item_data: ItemData, slot_rect: Rect2) -> void:
	tooltip_name.text = item_data.item_name.to_upper()
	
	var rarity_text = "COMÚN"
	var rarity_color = Color(0.7, 0.7, 0.7)
	if item_data.stats.size() >= 3:
		rarity_text = "ÉPICO"
		rarity_color = Color(0.78, 0.2, 1.0)
	elif item_data.stats.size() >= 2:
		rarity_text = "RARO"
		rarity_color = Color(0.2, 0.6, 1.0)
	elif item_data.stats.size() >= 1:
		rarity_text = "MEJORADO"
		rarity_color = Color(0.2, 1.0, 0.4)
		
	tooltip_rarity.text = rarity_text
	tooltip_rarity.add_theme_color_override("font_color", rarity_color)
	
	var type_text = ""
	match item_data.type:
		ItemData.ItemType.WEAPON:
			type_text = "ARMA PRINCIPAL" if item_data.slot in [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3] else "ARMA SECUNDARIA"
		ItemData.ItemType.TORSO: type_text = "ARMADURA DE TORSO"
		ItemData.ItemType.ARMS: type_text = "ACCESORIO DE BRAZO"
		ItemData.ItemType.LEGS: type_text = "PIERNAS"
		
	if item_data.item_name.to_lower().contains("vara") or item_data.item_name.to_lower().contains("espada") or item_data.item_name.to_lower().contains("bastón"):
		type_text = "ARMA CUERPO A CUERPO"
		
	tooltip_type.text = type_text
	
	var desc_text = "Dispositivo de combate avanzado para el agente táctico."
	if item_data.id.contains("Arms") or item_data.id.contains("Arm"):
		desc_text = "Guantes reforzados que mejoran la velocidad del usuario."
	elif item_data.id.contains("Chest") or item_data.id.contains("Torso"):
		desc_text = "Coraza blindada ligera que disipa la energía del impacto."
	elif item_data.id.contains("Boots") or item_data.id.contains("Leg"):
		desc_text = "Botas servoasistidas para optimizar la movilidad en combate."
		
	tooltip_desc.text = desc_text
	
	var stats_text = ""
	for k in item_data.stats.keys():
		stats_text += _format_tooltip_stat(k, item_data.stats[k]) + "\n"
	tooltip_stats.text = stats_text
	
	tooltip_action.text = "🖱 Clic para seleccionar / Arrastrar para equipar"
	tooltip_action.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8, 0.7))
	
	_display_tooltip_at_position(slot_rect)

func _display_tooltip_at_position(slot_rect: Rect2) -> void:
	var tooltip_pos = Vector2(slot_rect.end.x + 12, slot_rect.position.y)
	if tooltip_pos.x + tooltip_panel.size.x > get_viewport_rect().size.x:
		tooltip_pos.x = slot_rect.position.x - tooltip_panel.size.x - 12
	tooltip_panel.global_position = tooltip_pos
	tooltip_panel.show()

func _format_tooltip_stat(k: String, v: float) -> String:
	var stat_name = k.capitalize()
	var is_percent = false
	match k:
		"max_health_percent": stat_name = "Vida Máxima"; is_percent = true
		"move_speed_percent": stat_name = "Vel. Movimiento"; is_percent = true
		"armor": stat_name = "Armadura"
		"damage": stat_name = "Daño"
		"projectile_speed": stat_name = "Vel. Proyectil"
		"bullet_count": stat_name = "Proyectiles"
		"cone_spread_angle": stat_name = "Dispersión"
		"piercing": stat_name = "Perforación"
		"crit_chance": stat_name = "Prob. Crítico"; is_percent = true
		"crit_damage": stat_name = "Daño Crítico"
		"attack_speed": stat_name = "Vel. Ataque"; is_percent = true
		"damage_multiplier": stat_name = "Multiplicador de Daño"; is_percent = true
		"knockback_force": stat_name = "Empuje"
		
	var sign_str = "+" if v > 0 else ""
	var val_str = str(round(v * 100)) + "%" if is_percent else str(v)
	return "%s: [color=yellow]%s%s[/color]" % [stat_name, sign_str, val_str]

func _hide_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.hide()

func _on_slot_hovered(item_data: ItemData, slot_rect: Rect2) -> void:
	_show_tooltip(item_data, slot_rect)

func _on_slot_unhovered() -> void:
	_hide_tooltip()

# ── Codex Panel Definition ──────────────────────────────────────────────────

func _setup_codex() -> void:
	var main_vbox = $MarginContainer/MainVBox
	
	codex_panel = ScrollContainer.new()
	codex_panel.name = "CodexPanel"
	codex_panel.visible = false
	codex_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(codex_panel)
	
	var codex_vbox = VBoxContainer.new()
	codex_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	codex_vbox.add_theme_constant_override("separation", 16)
	codex_panel.add_child(codex_vbox)
	
	var title = Label.new()
	title.text = "CÓDICE DE COMPONENTES E HISTORIAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	codex_vbox.add_child(title)
	
	# Codex sub-tabs bar
	var sub_tabs_hbox = HBoxContainer.new()
	sub_tabs_hbox.alignment = FlowContainer.ALIGNMENT_CENTER
	sub_tabs_hbox.add_theme_constant_override("separation", 16)
	codex_vbox.add_child(sub_tabs_hbox)
	
	var btn_bestiario = Button.new()
	btn_bestiario.text = "BESTIARIO"
	btn_bestiario.pressed.connect(_on_codex_category_pressed.bind("enemies"))
	sub_tabs_hbox.add_child(btn_bestiario)
	
	var btn_armamento = Button.new()
	btn_armamento.text = "ARMAMENTO"
	btn_armamento.pressed.connect(_on_codex_category_pressed.bind("weapons"))
	sub_tabs_hbox.add_child(btn_armamento)
	
	var btn_objetos = Button.new()
	btn_objetos.text = "ITEMS"
	btn_objetos.pressed.connect(_on_codex_category_pressed.bind("items"))
	sub_tabs_hbox.add_child(btn_objetos)
	
	var btn_npcs = Button.new()
	btn_npcs.text = "NPCs"
	btn_npcs.pressed.connect(_on_codex_category_pressed.bind("npcs"))
	sub_tabs_hbox.add_child(btn_npcs)
	
	var btn_zonas = Button.new()
	btn_zonas.text = "ZONAS"
	btn_zonas.pressed.connect(_on_codex_category_pressed.bind("levels"))
	sub_tabs_hbox.add_child(btn_zonas)
	
	var scroll_grid_container = CenterContainer.new()
	scroll_grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	codex_vbox.add_child(scroll_grid_container)
	
	codex_grid = GridContainer.new()
	codex_grid.columns = 6
	codex_grid.add_theme_constant_override("h_separation", 16)
	codex_grid.add_theme_constant_override("v_separation", 16)
	scroll_grid_container.add_child(codex_grid)
	
	_refresh_codex_grid()

func _on_codex_category_pressed(category: String) -> void:
	selected_codex_category = category
	_hide_tooltip()
	_refresh_codex_grid()

func _refresh_codex_grid() -> void:
	if not codex_grid: return
	for c in codex_grid.get_children(): c.queue_free()
	
	var category_data = CodexData.DATA.get(selected_codex_category, {})
	for entry_id in category_data.keys():
		var entry = category_data[entry_id]
		var is_unlocked = GameData.is_codex_unlocked(selected_codex_category, entry_id)
		
		var fake_item = ItemData.new()
		fake_item.id = entry_id
		
		if is_unlocked:
			fake_item.item_name = entry.name
			fake_item.icon = entry.icon
		else:
			fake_item.item_name = "???"
			fake_item.icon = load("res://Art/Ui/Cell.png")
			
		var slot = UISlot.new()
		slot.update_slot(fake_item)
		slot.slot_hovered.connect(_on_slot_hovered)
		slot.slot_unhovered.connect(_on_slot_unhovered)
		codex_grid.add_child(slot)

# ── Slot Setup and Centered Grids Layout ─────────────────────────────────────

func _setup_slots() -> void:
	# Clear old slots in Equipment Panel
	for c in equip_container.get_children(): c.queue_free()
	ui_slots.clear()
	
	var body_grid = _create_centered_grid(3)
	equip_container.add_child(body_grid)
	_add_body_grid_slots(body_grid)

	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 16
	equip_container.add_child(sep)
	
	var wpns_grid = _create_centered_grid(3)
	equip_container.add_child(wpns_grid)
	_add_weapon_grid_slots(wpns_grid)
	
	# Clear old children in Inventory Grid
	for c in inventory_grid.get_children(): c.queue_free()
	inventory_slots.clear()
	
	# Build Inventory Grid (24 slots)
	for i in range(24):
		var slot_ui = UISlot.new()
		slot_ui.is_inventory_slot = true
		slot_ui.item_dropped.connect(_on_item_dropped)
		slot_ui.slot_clicked.connect(_on_slot_clicked)
		slot_ui.slot_double_clicked.connect(_on_slot_double_clicked)
		slot_ui.slot_hovered.connect(_on_slot_hovered)
		slot_ui.slot_unhovered.connect(_on_slot_unhovered)
		inventory_grid.add_child(slot_ui)
		inventory_slots.append(slot_ui)

func _create_centered_grid(cols: int) -> GridContainer:
	var grid = GridContainer.new()
	grid.columns = cols
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	return grid

func _add_body_grid_slots(grid: GridContainer) -> void:
	# Row 1: Brazo Izq, Torso, Brazo Der
	_create_equip_slot(ItemData.ItemSlot.ARM_L, "Brazo I", grid)
	_create_equip_slot(ItemData.ItemSlot.TORSO, "Torso", grid)
	_create_equip_slot(ItemData.ItemSlot.ARM_R, "Brazo D", grid)
	
	# Row 2: Pierna Izq, Spacer, Pierna Der
	_create_equip_slot(ItemData.ItemSlot.LEG_L, "Pierna I", grid)
	grid.add_child(Control.new())
	_create_equip_slot(ItemData.ItemSlot.LEG_R, "Pierna D", grid)

func _add_weapon_grid_slots(grid: GridContainer) -> void:
	_create_equip_slot(ItemData.ItemSlot.MAIN_W1, "Arma 1", grid)
	_create_equip_slot(ItemData.ItemSlot.MAIN_W2, "Arma 2", grid)
	_create_equip_slot(ItemData.ItemSlot.MAIN_W3, "Arma 3", grid)
	
	_create_equip_slot(ItemData.ItemSlot.SEC_W1, "Sec 1", grid)
	_create_equip_slot(ItemData.ItemSlot.SEC_W2, "Sec 2", grid)
	_create_equip_slot(ItemData.ItemSlot.SEC_W3, "Sec 3", grid)

func _create_equip_slot(slot_key: ItemData.ItemSlot, empty_text: String, parent: Control) -> void:
	var slot_ui = UISlot.new()
	slot_ui.slot_type = slot_key
	slot_ui.empty_text = empty_text
	slot_ui.item_dropped.connect(_on_item_dropped)
	slot_ui.slot_clicked.connect(_on_slot_clicked)
	slot_ui.slot_double_clicked.connect(_on_slot_double_clicked)
	slot_ui.slot_hovered.connect(_on_slot_hovered)
	slot_ui.slot_unhovered.connect(_on_slot_unhovered)
	parent.add_child(slot_ui)
	ui_slots.append(slot_ui)

func _on_item_dropped(drag_item: ItemData, source_slot: UISlot, target_slot: UISlot) -> void:
	if source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		var old_item = equipment.slots.get(target_slot.slot_type)
		drag_item.slot = target_slot.slot_type
		inventory.remove_item(drag_item)
		if old_item:
			inventory.add_item(old_item)
		equipment.equip_item(drag_item)
		
	elif not source_slot.is_inventory_slot and target_slot.is_inventory_slot:
		equipment.slots[source_slot.slot_type] = null
		equipment.equipment_changed.emit()
		inventory.add_item(drag_item)
		
	elif not source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		var old_item = equipment.slots.get(target_slot.slot_type)
		equipment.slots[source_slot.slot_type] = old_item
		if old_item:
			old_item.slot = source_slot.slot_type
		drag_item.slot = target_slot.slot_type
		equipment.equip_item(drag_item)
	else:
		update_ui()
	_hide_tooltip()

func _on_slot_clicked(item: ItemData) -> void:
	var txt = "[b]Stats de " + item.item_name + ":[/b]\n"
	if item.stats.is_empty():
		txt += "(Sin mejoras)\n"
	else:
		for k in item.stats.keys():
			txt += format_stat_string(k, item.stats[k]) + "\n"
	stats_label.text = txt

func _on_slot_double_clicked(item: ItemData, slot_ui: UISlot) -> void:
	if slot_ui.is_inventory_slot:
		_auto_equip_item(item)
	else:
		_auto_unequip_item(item, slot_ui.slot_type)

func _auto_equip_item(item: ItemData) -> void:
	var target_slot_type = _get_available_slot_for_item(item)
	var old_item = equipment.slots.get(target_slot_type)
	
	item.slot = target_slot_type
	inventory.remove_item(item)
	
	if old_item:
		inventory.add_item(old_item)
		
	equipment.equip_item(item)
	update_ui()
	_hide_tooltip()

func _auto_unequip_item(item: ItemData, slot_type: ItemData.ItemSlot) -> void:
	equipment.slots[slot_type] = null
	equipment.equipment_changed.emit()
	inventory.add_item(item)
	update_ui()
	_hide_tooltip()

func _get_available_slot_for_item(item: ItemData) -> ItemData.ItemSlot:
	match item.type:
		ItemData.ItemType.TORSO:
			return ItemData.ItemSlot.TORSO
		ItemData.ItemType.ARMS:
			if equipment.slots.get(ItemData.ItemSlot.ARM_L) == null:
				return ItemData.ItemSlot.ARM_L
			if equipment.slots.get(ItemData.ItemSlot.ARM_R) == null:
				return ItemData.ItemSlot.ARM_R
			return ItemData.ItemSlot.ARM_L
		ItemData.ItemType.LEGS:
			if equipment.slots.get(ItemData.ItemSlot.LEG_L) == null:
				return ItemData.ItemSlot.LEG_L
			if equipment.slots.get(ItemData.ItemSlot.LEG_R) == null:
				return ItemData.ItemSlot.LEG_R
			return ItemData.ItemSlot.LEG_L
		ItemData.ItemType.WEAPON:
			var w_slots = [
				ItemData.ItemSlot.MAIN_W1,
				ItemData.ItemSlot.MAIN_W2,
				ItemData.ItemSlot.MAIN_W3,
				ItemData.ItemSlot.SEC_W1,
				ItemData.ItemSlot.SEC_W2,
				ItemData.ItemSlot.SEC_W3
			]
			for slot_key in w_slots:
				if equipment.slots.get(slot_key) == null:
					return slot_key
			return ItemData.ItemSlot.MAIN_W1
	return ItemData.ItemSlot.TORSO

func format_stat_string(k: String, v: float) -> String:
	var stat_name = k.capitalize()
	var is_percent = false
	match k:
		"max_health_percent": stat_name = "Vida Máxima"; is_percent = true
		"move_speed_percent": stat_name = "Vel. Movimiento"; is_percent = true
		"armor": stat_name = "Armadura"
		"damage": stat_name = "Daño"
		"projectile_speed": stat_name = "Vel. Proyectil"
		"bullet_count": stat_name = "Proyectiles"
		"cone_spread_angle": stat_name = "Dispersión"
		"piercing": stat_name = "Perforación"
		"crit_chance": stat_name = "Prob. Crítico"; is_percent = true
		"crit_damage": stat_name = "Daño Crítico"
		"attack_speed": stat_name = "Vel. Ataque"; is_percent = true
		"damage_multiplier": stat_name = "Multiplicador de Daño"
		"knockback_force": stat_name = "Empuje"
		
	var prefix = "+" if v > 0 else ""
	var display_val = str(round(v * 100)) + "%" if is_percent else str(v)
	return "%s: [color=yellow]%s%s[/color]" % [stat_name, prefix, display_val]

# ── Stacking, Sorting and Populating Lists ───────────────────────────────────

func update_items_list() -> void:
	if inventory == null: return
	
	# 1. Group / Stack identical items
	var grouped = []
	for item_data in inventory.items:
		var found = false
		for entry in grouped:
			if entry.item.id == item_data.id:
				entry.count += 1
				found = true
				break
		if not found:
			grouped.append({ "item": item_data, "count": 1 })
			
	if is_sorted_recent:
		grouped.reverse()
		
	# 2. Filter items
	var filtered = []
	for entry in grouped:
		if current_filter == "ALL":
			filtered.append(entry)
		elif current_filter == "WEAPON" and entry.item.type == ItemData.ItemType.WEAPON:
			filtered.append(entry)
		elif current_filter == "BODY" and entry.item.type in [ItemData.ItemType.TORSO, ItemData.ItemType.ARMS, ItemData.ItemType.LEGS]:
			filtered.append(entry)
			
	# 3. Populate slots
	for i in range(inventory_slots.size()):
		if i < filtered.size():
			var entry = filtered[i]
			inventory_slots[i].update_slot(entry.item, entry.count)
		else:
			inventory_slots[i].update_slot(null)

func update_equipment_display() -> void:
	if equipment == null: return
	for slot_ui in ui_slots:
		slot_ui.update_slot(equipment.slots[slot_ui.slot_type])

# ── Comparison Statistics Display (Green/Red Diffs) ─────────────────────────

func update_stats_display() -> void:
	if equipment == null: return
	var main_stats: Dictionary = equipment.get_main_weapon_stats()
	var sec_stats: Dictionary = equipment.get_secondary_weapon_stats()
	display_stats(main_stats, sec_stats)

func display_stats(_main_stats: Dictionary, _sec_stats: Dictionary) -> void:
	var txt = "[b]─ ESTADÍSTICAS GLOBALES ─[/b]\n"
	
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	var p_stats = p.stats
	
	# 1. Vida Máxima
	var base_hp = p_stats.base_max_health
	var current_hp = p_stats.max_health
	txt += format_stat_diff("Vida Máxima", base_hp, current_hp) + "\n"
	
	# 2. Vel. Movimiento
	var base_speed = p_stats.base_move_speed
	var current_speed = p_stats.move_speed
	txt += format_stat_diff("Vel. Movimiento", base_speed, current_speed) + "\n"
	
	# 3. Armadura
	var base_armor = 0.0
	var current_armor = p._get_equip_stat("armor", false)
	txt += format_stat_diff("Armadura", base_armor, current_armor) + "\n"
	
	txt += "\n[b]─ ARMA PRINCIPAL ─[/b]\n"
	var base_dmg_val = GameData.weapon_damage * GameData.weapon_damage_multiplier
	var base_aps = GameData.weapon_fire_rate
	var base_bullets = GameData.weapon_bullet_count
	var base_crit_c = GameData.weapon_crit_chance
	var base_crit_d = GameData.weapon_crit_damage
	
	if p.active_weapon:
		base_dmg_val = p._get_weapon_damage() * p._get_weapon_damage_multiplier()
		base_aps = p._get_weapon_attack_speed()
		base_bullets = p._get_weapon_bullets()
		base_crit_c = p._get_weapon_crit_chance()
		base_crit_d = p._get_weapon_crit_damage()
		
	var bonus_aps_pct = p._get_equip_stat("attack_speed")
	
	var current_dmg = ((p._get_weapon_damage() if p.active_weapon else GameData.weapon_damage) + p._get_equip_stat("damage", true)) * ((p._get_weapon_damage_multiplier() if p.active_weapon else GameData.weapon_damage_multiplier) + p._get_equip_stat("damage_multiplier", true))
	var current_aps = base_aps * (1.0 + bonus_aps_pct)
	var current_bullets = base_bullets + int(p._get_equip_stat("bullet_count", true))
	var current_crit_c = base_crit_c + p._get_equip_stat("crit_chance", true)
	var current_crit_d = base_crit_d + p._get_equip_stat("crit_damage", true)
	
	txt += format_stat_diff("Daño Total", base_dmg_val, current_dmg) + "\n"
	txt += format_stat_diff("Velocidad de Ataque", base_aps, current_aps) + "\n"
	txt += format_stat_diff("Proyectiles", base_bullets, current_bullets) + "\n"
	txt += format_stat_diff("Prob. Crítico", base_crit_c, current_crit_c, true) + "\n"
	txt += format_stat_diff("Daño Crítico", base_crit_d, current_crit_d, false, true) + "\n"
	
	txt += "\n[b]─ CUERPO A CUERPO ─[/b]\n"
	var base_m_dmg = GameData.melee_damage
	var base_m_spd = GameData.melee_speed
	var base_m_knock = GameData.melee_knockback
	
	var current_m_dmg = GameData.melee_damage + p._get_equip_stat("damage", false)
	var current_m_spd = GameData.melee_speed * (1.0 + p._get_equip_stat("attack_speed", false))
	var current_m_knock = GameData.melee_knockback + p._get_equip_stat("knockback_force", false)
	
	txt += format_stat_diff("Daño", base_m_dmg, current_m_dmg) + "\n"
	txt += format_stat_diff("Velocidad Ataque", base_m_spd, current_m_spd) + "\n"
	txt += format_stat_diff("Empuje", base_m_knock, current_m_knock) + "\n"
	
	stats_label.text = txt

func format_stat_diff(stat_name: String, base: float, current: float, is_percent: bool = false, is_multiplier: bool = false) -> String:
	var diff = current - base
	var base_str = ""
	var current_str = ""
	var diff_str = ""
	
	if is_percent:
		base_str = str(round(base * 100)) + "%"
		current_str = str(round(current * 100)) + "%"
		diff_str = "%+d%%" % round(diff * 100)
	elif is_multiplier:
		base_str = "x%.1f" % base
		current_str = "x%.1f" % current
		diff_str = "%+.1fx" % diff
	else:
		if base == int(base) and current == int(current):
			base_str = str(int(base))
			current_str = str(int(current))
			diff_str = "%+d" % int(diff)
		else:
			base_str = "%.2f" % base
			current_str = "%.2f" % current
			diff_str = "%+.2f" % diff
			
	if diff > 0.001:
		return "%s: %s > [color=#00ff80]%s (+%s)[/color]" % [stat_name, base_str, current_str, diff_str.replace("+", "")]
	elif diff < -0.001:
		return "%s: %s > [color=#ff4040]%s (%s)[/color]" % [stat_name, base_str, current_str, diff_str]
	else:
		return "%s: %s > %s [color=gray](-)[/color]" % [stat_name, base_str, current_str]
