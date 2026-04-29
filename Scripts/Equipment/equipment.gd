class_name Equipment
extends Node

signal equipment_changed

var slots: Dictionary = {}

func _ready() -> void:
	initialize_slots()

func initialize_slots() -> void:
	slots[ItemData.ItemSlot.MAIN_W1] = null
	slots[ItemData.ItemSlot.MAIN_W2] = null
	slots[ItemData.ItemSlot.MAIN_W3] = null
	slots[ItemData.ItemSlot.SEC_W1] = null
	slots[ItemData.ItemSlot.SEC_W2] = null
	slots[ItemData.ItemSlot.SEC_W3] = null
	slots[ItemData.ItemSlot.LEG_L] = null
	slots[ItemData.ItemSlot.LEG_R] = null
	slots[ItemData.ItemSlot.ARM_L] = null
	slots[ItemData.ItemSlot.ARM_R] = null
	slots[ItemData.ItemSlot.TORSO] = null

func equip_item(item: ItemData) -> void:
	remove_old_item(item.slot)
	slots[item.slot] = item
	equipment_changed.emit()

func remove_old_item(slot: ItemData.ItemSlot) -> void:
	var old_item: ItemData = slots[slot]
	if old_item == null:
		return
	destroy_item(old_item)
	slots[slot] = null

func destroy_item(_item: ItemData) -> void:
	_item = null

func get_main_weapon_stats() -> Dictionary:
	return calculate_stats_for_type(ItemData.ItemType.MAIN_WEAPON)

func get_secondary_weapon_stats() -> Dictionary:
	return calculate_stats_for_type(ItemData.ItemType.SECONDARY_WEAPON)

func get_character_stats() -> Dictionary:
	return calculate_stats_for_type(ItemData.ItemType.CHARACTER)

func calculate_stats_for_type(type: ItemData.ItemType) -> Dictionary:
	var total_stats: Dictionary = {}
	for slot_key in slots.keys():
		process_slot_for_stats(slots[slot_key], type, total_stats)
	return total_stats

func process_slot_for_stats(item: ItemData, type: ItemData.ItemType, total_stats: Dictionary) -> void:
	if item == null:
		return
	if item.type != type:
		return
	add_item_stats(total_stats, item.stats)

func add_item_stats(total: Dictionary, item_stats: Dictionary) -> void:
	for stat_name in item_stats.keys():
		add_single_stat(total, stat_name, item_stats[stat_name])

func add_single_stat(total: Dictionary, stat_name: String, value: float) -> void:
	if total.has(stat_name):
		total[stat_name] += value
		return
	total[stat_name] = value
