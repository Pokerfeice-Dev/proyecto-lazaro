extends Marker2D
class_name BarrelSpawnPoint

## Nodo de punto de spawn probabilístico de barriles. Se coloca manualmente en
## cualquier punto de una sala; al cargarse la sala "tira la ruleta" y, con
## probabilidad spawn_chance, instancia un barril random de la lista
## possible_barrels en su posición. Para agregar mas tipos de barril en el
## futuro (electrico, veneno, etc.) solo hay que sumar su escena al array
## possible_barrels (desde este script como default, o por-instancia desde el
## inspector si una sala en particular quiere una lista distinta).

## Probabilidad (0.0 a 1.0) de que aparezca un barril en este punto.
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.5

## Barriles posibles que puede tirar la ruleta en este punto.
@export var possible_barrels: Array[PackedScene] = [
	preload("res://Scenes/Objects/FireBarrel.tscn"),
	preload("res://Scenes/Objects/IceBarrel.tscn"),
]

func _ready() -> void:
	_roll_for_barrel()

func _roll_for_barrel() -> void:
	if possible_barrels.is_empty():
		return
	if randf() > spawn_chance:
		return
	_spawn_random_barrel()

func _spawn_random_barrel() -> void:
	var barrel_scene: PackedScene = possible_barrels.pick_random()
	if not barrel_scene:
		return
	var barrel = barrel_scene.instantiate()
	barrel.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", barrel)
