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

## Si está prendido, el barril aparece con un rebote (ver RoomReveal) en vez
## de estar ahí de una apenas se carga la sala. Si la sala tiene un nodo
## "player_spawn", el rebote sale como una ola desde ahí (mismo timing que
## usa CombatRoom para el resto de los props); si no lo encuentra, usa un
## delay random chico.
@export var reveal_with_bounce: bool = true

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
	if reveal_with_bounce:
		barrel.ready.connect(_on_barrel_ready.bind(barrel), CONNECT_ONE_SHOT)
	get_tree().current_scene.call_deferred("add_child", barrel)

func _on_barrel_ready(barrel: Node2D) -> void:
	var delay = randf_range(0.0, 0.25)
	var origin_node = get_tree().current_scene.get_node_or_null("player_spawn")
	if origin_node:
		delay = RoomReveal.delay_from_origin(barrel.global_position, origin_node.global_position)
	RoomReveal.reveal_node(barrel, delay)
