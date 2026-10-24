extends Node

func _ready() -> void:
	var ui = preload("res://Scenes/UI/inventory_ui.tscn").instantiate()
	var inventory := Inventory.new()
	var equipment := Equipment.new()
	var old := ItemData.new()
	old.item_name = "Torso anterior"
	old.type = ItemData.ItemType.TORSO
	old.stats = {"armor": 3.0, "damage": 2.0}
	var candidate := ItemData.new()
	candidate.item_name = "Torso nuevo"
	candidate.type = ItemData.ItemType.TORSO
	candidate.stats = {"armor": 5.0}
	equipment.slots[ItemData.ItemSlot.TORSO] = old
	inventory.items.append(candidate)
	ui.inventory = inventory
	ui.equipment = equipment
	add_child(ui)
	ui.selected_item = candidate
	ui.update_ui()
	assert(not ui.detail_stats_label.text.contains("→"))
	ui.detail_compare_btn.pressed.emit()
	assert(ui.is_comparing)
	assert(ui.detail_compare_btn.text == "Ver valores")
	assert(ui.detail_desc_label.text.contains("Torso anterior"))
	assert(ui.detail_stats_label.text.contains("(+2)"))
	assert(ui.detail_stats_label.text.contains("(-2)"), "Debe mostrar el daño perdido")
	ui.detail_compare_btn.pressed.emit()
	assert(not ui.is_comparing)
	assert(not ui.detail_stats_label.text.contains("→"))
	equipment.slots.clear()
	ui.detail_compare_btn.pressed.emit()
	assert(ui.detail_desc_label.text.contains("casillero vacío"))
	assert(ui.detail_stats_label.text.contains("(+5)"))
	assert(inventory.items.has(candidate), "Comparar no debe equipar el objeto")
	ui.free()
	inventory.free()
	equipment.free()
	print("INVENTORY_COMPARE_OK")
	get_tree().quit()
