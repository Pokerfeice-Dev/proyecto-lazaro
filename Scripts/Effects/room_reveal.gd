extends Node
class_name RoomReveal

## Utilidad genérica para hacer que los objetos de una sala "aparezcan" con
## rebote en vez de estar ahí de una, para darle un poco más de vida a la
## entrada a una sala. No depende de ninguna sala en particular: cualquier
## Node2D visual (props, barriles, cofres, etc.) se puede animar con
## reveal_node(); reveal_nodes() escalona una lista por orden/azar, y
## reveal_nodes_from_origin() la escalona como una ola que se expande desde
## un punto (por ejemplo el spawn del jugador) hacia el resto de la sala.

const DEFAULT_STAGGER: float = 0.08
const DEFAULT_POP_DURATION: float = 0.45
## Velocidad (px/seg) a la que se expande la "ola" de aparición cuando se usa
## reveal_nodes_from_origin() / delay_from_origin().
const DEFAULT_WAVE_SPEED: float = 500.0

## Anima un solo nodo: arranca en escala 0 (y opcionalmente transparente) y
## rebota hasta su escala original. "delay" es cuánto espera antes de arrancar
## (útil para escalonar varios objetos).
static func reveal_node(node: Node2D, delay: float = 0.0, duration: float = DEFAULT_POP_DURATION, trans_type: Tween.TransitionType = Tween.TRANS_BOUNCE, fade_in: bool = true) -> void:
	if not is_instance_valid(node): return
	var target_scale = node.scale
	node.scale = Vector2.ZERO
	var target_alpha = node.modulate.a
	if fade_in:
		node.modulate.a = 0.0

	var t = node.create_tween()
	if delay > 0.0:
		t.tween_interval(delay)
	t.set_parallel(true)
	t.tween_property(node, "scale", target_scale, duration).set_trans(trans_type).set_ease(Tween.EASE_OUT)
	if fade_in:
		t.tween_property(node, "modulate:a", target_alpha, minf(0.15, duration * 0.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## Anima una lista de nodos, escalonando el inicio de cada uno por orden (o
## desordenado al azar por default). Para una cascada que sigue la forma real
## de la sala, mejor usar reveal_nodes_from_origin().
static func reveal_nodes(nodes: Array, stagger: float = DEFAULT_STAGGER, base_delay: float = 0.0, randomize_order: bool = true, trans_type: Tween.TransitionType = Tween.TRANS_BOUNCE) -> void:
	var list: Array = nodes.duplicate()
	if randomize_order:
		list.shuffle()
	for i in range(list.size()):
		if list[i] is Node2D:
			reveal_node(list[i], base_delay + i * stagger, DEFAULT_POP_DURATION, trans_type)

## Cuánto debería tardar en aparecer algo ubicado en "pos" si la aparición se
## expande como una ola desde "origin" a wave_speed píxeles por segundo.
static func delay_from_origin(pos: Vector2, origin: Vector2, wave_speed: float = DEFAULT_WAVE_SPEED, base_delay: float = 0.0) -> float:
	return base_delay + (pos.distance_to(origin) / maxf(wave_speed, 1.0))

## Como reveal_nodes(), pero en vez de un orden fijo o al azar, hace que la
## aparición se expanda como una ola desde "origin" (por ejemplo el spawn del
## jugador) hasta el punto más lejano de la sala: lo más cerca del origen
## aparece primero, lo más lejos aparece último.
static func reveal_nodes_from_origin(nodes: Array, origin: Vector2, wave_speed: float = DEFAULT_WAVE_SPEED, base_delay: float = 0.0, trans_type: Tween.TransitionType = Tween.TRANS_BOUNCE) -> void:
	for n in nodes:
		if n is Node2D:
			var delay = delay_from_origin(n.global_position, origin, wave_speed, base_delay)
			reveal_node(n, delay, DEFAULT_POP_DURATION, trans_type)
