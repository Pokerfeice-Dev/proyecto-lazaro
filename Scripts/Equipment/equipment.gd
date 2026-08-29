class_name Equipment
extends Node

signal equipment_changed
signal body_part_equipped(item: ItemData) # se instaló una pieza de cuerpo nueva (torso/brazo/pierna)

const BODY_PART_TYPES: Array = [ItemData.ItemType.TORSO, ItemData.ItemType.ARMS, ItemData.ItemType.LEGS]

var slots: Dictionary = {}

func _ready() -> void:
	slots = GameData.equipment_slots

func is_body_part(item: ItemData) -> bool:
	return item != null and item.type in BODY_PART_TYPES

# is_new_equip = false cuando es solo un reacomodo entre slots ya equipados (no cuenta como "pieza nueva")
func equip_item(item: ItemData, is_new_equip: bool = true) -> void:
	remove_old_item(item.slot)
	slots[item.slot] = item
	equipment_changed.emit()
	if is_new_equip and is_body_part(item):
		body_part_equipped.emit(item)

func remove_old_item(slot: ItemData.ItemSlot) -> void:
	var old_item: ItemData = slots[slot]
	if old_item == null:
		return
	destroy_item(old_item)
	slots[slot] = null

func destroy_item(_item: ItemData) -> void:
	_item = null

func get_main_weapon_stats() -> Dictionary:
	var total_stats: Dictionary = {}
	for slot_key in [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3]:
		if slots.has(slot_key) and slots[slot_key]:
			add_item_stats(total_stats, slots[slot_key].stats)
	return total_stats

func get_secondary_weapon_stats() -> Dictionary:
	var total_stats: Dictionary = {}
	for slot_key in [ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]:
		if slots.has(slot_key) and slots[slot_key]:
			add_item_stats(total_stats, slots[slot_key].stats)
	return total_stats

func get_character_stats() -> Dictionary:
	var total_stats: Dictionary = {}
	var slot_keys = [
		ItemData.ItemSlot.TORSO,
		ItemData.ItemSlot.ARM_L,
		ItemData.ItemSlot.ARM_R,
		ItemData.ItemSlot.LEG_L,
		ItemData.ItemSlot.LEG_R
	]
	for slot_key in slot_keys:
		if slots.has(slot_key) and slots[slot_key]:
			add_item_stats(total_stats, slots[slot_key].stats)
	return total_stats

func add_item_stats(total: Dictionary, item_stats: Dictionary) -> void:
	for stat_name in item_stats.keys():
		add_single_stat(total, stat_name, item_stats[stat_name])

func add_single_stat(total: Dictionary, stat_name: String, value: float) -> void:
	if total.has(stat_name):
		total[stat_name] += value
		return
	total[stat_name] = value
