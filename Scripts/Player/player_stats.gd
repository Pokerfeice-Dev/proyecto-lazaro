extends Resource
class_name PlayerStats

@export var base_max_health: int = 100
@export var max_health: int = 100
@export var current_health: int = 100
@export var base_move_speed: float = 150
@export var move_speed: float = 150

# Scrap is stored in the GameData autoload so it persists through deaths.
var scrap_count: int:
	get: return GameData.scrap

signal health_changed(new_health: int, max_health: int)
signal stats_changed
signal player_died

func _init() -> void:
	pass

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = clampi(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		player_died.emit()
		
func update_max_health(new_max: int) -> void:
	max_health = new_max
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func add_scrap(amount: int) -> void:
	GameData.add_scrap(amount)

func heal(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)

func apply_upgrade(type: String, value: float) -> void:
	match type:
		"health":
			max_health += int(value)
			current_health += int(value)
			health_changed.emit(current_health, max_health)
		"speed":
			move_speed += value
	stats_changed.emit()

func restore_from_game_data() -> void:
	pass
