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
	_create_equip_slot(ItemData.ItemSlot.ARM_L, "Brazo\nIzq", body_grid)
	body_grid.add_child(Control.new())
	_create_equip_slot(ItemData.ItemSlot.ARM_R, "Brazo\nDer", body_grid)
	
	# Row 3
	_create_equip_slot(ItemData.ItemSlot.LEG_L, "Pierna\nIzq", body_grid)
	body_grid.add_child(Control.new())
	_create_equip_slot(ItemData.ItemSlot.LEG_R, "Pierna\nDer", body_grid)

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
		drag_item.slot = target_slot.slot_type
		inventory.remove_item(drag_item)
		equipment.equip_item(drag_item)
	elif not source_slot.is_inventory_slot and target_slot.is_inventory_slot:
		equipment.slots[source_slot.slot_type] = null
		equipment.equipment_changed.emit()
		inventory.add_item(drag_item)
	elif not source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		equipment.slots[source_slot.slot_type] = null
		drag_item.slot = target_slot.slot_type
		equipment.equip_item(drag_item)
	else:
		update_ui()

func _on_slot_clicked(item: ItemData) -> void:
	var stats_lbl = $MarginContainer/HBoxContainer/StatsPanel/VBoxContainer/StatsLabel
	stats_lbl.text = "Stats de " + item.item_name + ":\n" + str(item.stats)

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
	var txt = "--- Stats Arma Principal ---\n"
	if _main_stats.is_empty(): txt += "(Sin stats)\n"
	for k in _main_stats.keys(): txt += str(k) + ": " + str(_main_stats[k]) + "\n"
	
	txt += "\n--- Stats Arma Secundaria ---\n"
	if _sec_stats.is_empty(): txt += "(Sin stats)\n"
	for k in _sec_stats.keys(): txt += str(k) + ": " + str(_sec_stats[k]) + "\n"
	
	var char_stats = equipment.get_character_stats()
	txt += "\n--- Stats de Personaje ---\n"
	if char_stats.is_empty(): txt += "(Sin stats)\n"
	for k in char_stats.keys(): txt += str(k) + ": " + str(char_stats[k]) + "\n"
	
	lbl.text = txt
