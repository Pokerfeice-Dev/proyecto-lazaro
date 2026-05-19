class_name InventoryUI
extends Control

@export var inventory: Inventory
@export var equipment: Equipment

var ui_slots: Array[UISlot] = []
var inventory_slots: Array[UISlot] = []

func _process(_delta: float) -> void:
	check_toggle_input()

func check_toggle_input() -> void:
	if not Input.is_action_just_pressed("toggle_inventory"):
		return
	toggle_visibility()

func toggle_visibility() -> void:
	visible = !visible
	get_tree().paused = visible
	update_if_visible()

func update_if_visible() -> void:
	if not visible:
		return
	update_ui()

func update_ui() -> void:
	update_items_list()
	update_equipment_display()
	update_stats_display()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_auto_fetch_player_nodes()
	if not equipment or not inventory: return
	
	inventory.inventory_updated.connect(update_items_list)
	equipment.equipment_changed.connect(update_ui)
	var stats_lbl = $MarginContainer/HBoxContainer/StatsPanel/VBoxContainer/StatsLabel
	stats_lbl.bbcode_enabled = true
	_setup_slots()

func _auto_fetch_player_nodes() -> void:
	if inventory and equipment: return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0: return
	inventory = players[0].get_node_or_null("Inventory")
	equipment = players[0].get_node_or_null("Equipment")

func _setup_slots() -> void:
	var equip_container = $MarginContainer/HBoxContainer/EquipmentPanel/VBoxContainer/SlotsList
	for c in equip_container.get_children(): c.queue_free()
	
	var body_grid = GridContainer.new()
	body_grid.columns = 3
	body_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	equip_container.add_child(body_grid)
	
	# Row 1
	body_grid.add_child(Control.new())
	_create_equip_slot(ItemData.ItemSlot.TORSO, "Torso", body_grid)
	body_grid.add_child(Control.new())
	
	# Row 2
	body_grid.add_child(Control.new())
	_create_equip_slot(ItemData.ItemSlot.ARMS, "Brazos", body_grid)
	body_grid.add_child(Control.new())
	
	# Row 3
	body_grid.add_child(Control.new())
	_create_equip_slot(ItemData.ItemSlot.LEGS, "Piernas", body_grid)
	body_grid.add_child(Control.new())

	var sep = HSeparator.new()
	sep.custom_minimum_size.y = 16
	equip_container.add_child(sep)
	
	var wpns_grid = GridContainer.new()
	wpns_grid.columns = 3
	equip_container.add_child(wpns_grid)
	
	_create_equip_slot(ItemData.ItemSlot.MAIN_W1, "Arma 1", wpns_grid)
	_create_equip_slot(ItemData.ItemSlot.MAIN_W2, "Arma 2", wpns_grid)
	_create_equip_slot(ItemData.ItemSlot.MAIN_W3, "Arma 3", wpns_grid)
	
	_create_equip_slot(ItemData.ItemSlot.SEC_W1, "Sec 1", wpns_grid)
	_create_equip_slot(ItemData.ItemSlot.SEC_W2, "Sec 2", wpns_grid)
	_create_equip_slot(ItemData.ItemSlot.SEC_W3, "Sec 3", wpns_grid)
		
	var grid = $MarginContainer/HBoxContainer/InventoryPanel/VBoxContainer/InventoryGrid
	for i in range(25):
		var slot_ui = UISlot.new()
		slot_ui.is_inventory_slot = true
		slot_ui.item_dropped.connect(_on_item_dropped)
		slot_ui.slot_clicked.connect(_on_slot_clicked)
		grid.add_child(slot_ui)
		inventory_slots.append(slot_ui)

func _create_equip_slot(slot_key: ItemData.ItemSlot, empty_text: String, parent: Control) -> void:
	var slot_ui = UISlot.new()
	slot_ui.slot_type = slot_key
	slot_ui.empty_text = empty_text
	slot_ui.item_dropped.connect(_on_item_dropped)
	slot_ui.slot_clicked.connect(_on_slot_clicked)
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

func _on_slot_clicked(item: ItemData) -> void:
	var stats_lbl = $MarginContainer/HBoxContainer/StatsPanel/VBoxContainer/StatsLabel
	var txt = "[b]Stats de " + item.item_name + ":[/b]\n"
	if item.stats.is_empty():
		txt += "(Sin mejoras)\n"
	else:
		for k in item.stats.keys():
			txt += format_stat_string(k, item.stats[k]) + "\n"
	stats_lbl.text = txt

func format_stat_string(k: String, v: float) -> String:
	var stat_name = k.capitalize()
	var is_percent = false
	var is_negative_good = false
	
	match k:
		"max_health_percent": stat_name = "Vida Máxima"; is_percent = true
		"move_speed_percent": stat_name = "Vel. Movimiento"; is_percent = true
		"armor": stat_name = "Armadura"
		"damage": stat_name = "Daño"
		"projectile_speed": stat_name = "Vel. Proyectil"
		"bullet_count": stat_name = "Proyectiles"
		"cone_spread_angle": stat_name = "Dispersión"; is_negative_good = true
		"piercing": stat_name = "Perforación"
		"crit_chance": stat_name = "Prob. Crítico"; is_percent = true
		"crit_damage": stat_name = "Daño Crítico"
		"attack_speed": stat_name = "Vel. Ataque"; is_negative_good = true
		"damage_multiplier": stat_name = "Multiplicador de Daño"
		"knockback_force": stat_name = "Empuje"
		"lifetime": stat_name = "Alcance"
		"attack_range": stat_name = "Rango de Ataque"
		
	var prefix = "+" if v > 0 else ""
	var display_val = ""
	
	if is_percent:
		display_val = str(round(v * 100)) + "%"
	else:
		display_val = str(v)
		
	return "%s: [color=yellow]%s%s[/color]" % [stat_name, prefix, display_val]

func update_items_list() -> void:
	if inventory == null: return
	for i in range(inventory_slots.size()):
		if i < inventory.items.size():
			inventory_slots[i].update_slot(inventory.items[i])
		else:
			inventory_slots[i].update_slot(null)

func update_equipment_display() -> void:
	if equipment == null: return
	for slot_ui in ui_slots:
		slot_ui.update_slot(equipment.slots[slot_ui.slot_type])

func update_stats_display() -> void:
	if equipment == null: return
	var main_stats: Dictionary = equipment.get_main_weapon_stats()
	var sec_stats: Dictionary = equipment.get_secondary_weapon_stats()
	display_stats(main_stats, sec_stats)

func display_stats(_main_stats: Dictionary, _sec_stats: Dictionary) -> void:
	var lbl = $MarginContainer/HBoxContainer/StatsPanel/VBoxContainer/StatsLabel
	var txt = "[b]--- Estadísticas Globales ---[/b]\n"
	
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	var p_stats = p.stats
	
	var armor = p._get_equip_stat("armor", false)
	txt += "Vida Máxima: [color=yellow]" + str(p_stats.max_health) + "[/color]\n"
	txt += "Vel. Movimiento: [color=yellow]" + str(p_stats.move_speed) + "[/color]\n"
	txt += "Armadura: [color=yellow]" + str(armor) + "[/color]\n"
	
	txt += "\n[b]--- Arma Principal ---[/b]\n"
	var w_dmg = (GameData.weapon_damage + p._get_equip_stat("damage", true)) * (GameData.weapon_damage_multiplier + p._get_equip_stat("damage_multiplier", true))
	var w_spd = maxf(0.05, GameData.weapon_fire_rate - p._get_equip_stat("attack_speed", true))
	var w_proj = GameData.weapon_bullet_count + int(p._get_equip_stat("bullet_count", true))
	var w_crit_c = GameData.weapon_crit_chance + p._get_equip_stat("crit_chance", true)
	var w_crit_d = GameData.weapon_crit_damage + p._get_equip_stat("crit_damage", true)
	
	txt += "Daño Total: [color=yellow]" + str(w_dmg) + "[/color]\n"
	txt += "Velocidad de Ataque: [color=yellow]" + str(w_spd) + "[/color]s\n"
	txt += "Proyectiles: [color=yellow]" + str(w_proj) + "[/color]\n"
	txt += "Prob. Crítico: [color=yellow]" + str(w_crit_c * 100) + "%[/color]\n"
	txt += "Daño Crítico: [color=yellow]x" + str(w_crit_d) + "[/color]\n"
	
	txt += "\n[b]--- Cuerpo a Cuerpo ---[/b]\n"
	var m_dmg = GameData.melee_damage + p._get_equip_stat("damage", false)
	var m_spd = GameData.melee_speed + p._get_equip_stat("attack_speed", false)
	var m_knock = GameData.melee_knockback + p._get_equip_stat("knockback_force", false)
	
	txt += "Daño: [color=yellow]" + str(m_dmg) + "[/color]\n"
	txt += "Velocidad Ataque: [color=yellow]" + str(m_spd) + "[/color]\n"
	txt += "Empuje: [color=yellow]" + str(m_knock) + "[/color]\n"
	
	lbl.text = txt
