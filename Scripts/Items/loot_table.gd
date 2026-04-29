class_name LootTable
extends Resource

@export var drops: Array[LootDrop]

func get_drop() -> ItemData:
	var total_weight: float = calculate_total_weight()
	return pick_random_item(total_weight)

func calculate_total_weight() -> float:
	var total: float = 0.0
	for drop in drops:
		total += drop.weight
	return total

func pick_random_item(total_weight: float) -> ItemData:
	var random_value: float = randf_range(0.0, total_weight)
	var current_weight: float = 0.0
	return evaluate_drops(random_value, current_weight)

func evaluate_drops(random_value: float, current_weight: float) -> ItemData:
	for drop in drops:
		current_weight += drop.weight
		var found_item: ItemData = check_weight_threshold(drop, current_weight, random_value)
		if found_item != null:
			return found_item
	return null

func check_weight_threshold(drop: LootDrop, current_weight: float, random_value: float) -> ItemData:
	if random_value <= current_weight:
		return drop.item
	return null
