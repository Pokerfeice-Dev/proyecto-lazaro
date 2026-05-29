class_name Inventory
extends Node

signal inventory_updated

var items: Array[ItemData] = []

func _ready() -> void:
	items = GameData.inventory_items

func add_item(item: ItemData) -> void:
	items.append(item)
	if GameData.has_method("unlock_codex_entry") and item:
		GameData.unlock_codex_entry("items", item.id)
	inventory_updated.emit()

func remove_item(item: ItemData) -> void:
	items.erase(item)
	inventory_updated.emit()

func get_items() -> Array[ItemData]:
	return items
