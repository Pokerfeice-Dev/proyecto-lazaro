class_name Equipment
extends Node

signal equipment_changed

var slots: Dictionary = {}

func _ready() -> void:
	slots = GameData.equipment_slots

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
	for slot_key in [ItemData.ItemSlot.TORSO, ItemData.ItemSlot.ARMS, ItemData.ItemSlot.LEGS]:
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
