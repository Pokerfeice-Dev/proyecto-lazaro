class_name EnemyDrop
extends Node

@export var loot_table: LootTable
@export var drop_chance: float = 0.5
@export var item_drop_scene: PackedScene

func roll_drop(spawn_position: Vector2) -> void:
	if not should_drop():
		return
	var item_to_drop: ItemData = loot_table.get_drop()
	process_drop(item_to_drop, spawn_position)

func should_drop() -> bool:
	return randf() <= drop_chance

func process_drop(item_data: ItemData, spawn_pos: Vector2) -> void:
	if item_data == null:
		return
	spawn_item(item_data, spawn_pos)

func spawn_item(item_data: ItemData, spawn_pos: Vector2) -> void:
	var drop_instance: Node = item_drop_scene.instantiate()
	drop_instance.item_data = item_data
	drop_instance.global_position = spawn_pos
	get_tree().current_scene.call_deferred("add_child", drop_instance)
