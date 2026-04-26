extends Node
class_name UpgradeSystem

var available_upgrades: Array = [
	{"type": "health", "value": 20, "name": "Hearty Meal+", "description": "Increases Max HP by 20"},
	{"type": "speed", "value": 50.0, "name": "Running Shoes", "description": "Boosts movement speed"},
	{"type": "damage", "value": 0.5, "name": "Sharp Blade", "description": "Increases damage by 50%"},
	{"type": "fire_rate", "value": 0.1, "name": "Quick Trigger", "description": "Reduces fire delay by 0.1s"}
]

signal upgrades_presented(options: Array)
signal upgrade_selected(upgrade_data: Dictionary)

func present_upgrades(count: int = 3):
	var options = []
	var pool = available_upgrades.duplicate()
	pool.shuffle()
	
	for i in range(min(count, pool.size())):
		options.append(pool[i])
		
	upgrades_presented.emit(options)

func select_upgrade(upgrade_idx: int, presented_options: Array):
	if upgrade_idx >= 0 and upgrade_idx < presented_options.size():
		var chosen = presented_options[upgrade_idx]
		upgrade_selected.emit(chosen)
