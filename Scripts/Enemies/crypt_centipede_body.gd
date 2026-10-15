extends Node2D
class_name CryptCentipedeBody

## Cuerpo segmentado del ciempiés: los segmentos siguen el camino que va
## dejando la cabeza (ArtSprite), como una cadena, y las patas se mueven según
## lo que avanza. Se dibuja por código para no crear un nodo por segmento.
## Al morir, los segmentos se sueltan y se desvanecen.

## Hacia dónde mira el dibujo original de cada pieza (abajo a la izquierda).
const ART_FORWARD := 135.0
const BODY := preload("res://Art/Enemies/Crypt/Centipede/centipede_body.png")
const LINK := preload("res://Art/Enemies/Crypt/Centipede/centipede_link.png")
const TAIL := preload("res://Art/Enemies/Crypt/Centipede/centipede_tail.png")
const LEGS := [
	preload("res://Art/Enemies/Crypt/Centipede/centipede_legs_walk01.png"),
	preload("res://Art/Enemies/Crypt/Centipede/centipede_legs_front.png"),
	preload("res://Art/Enemies/Crypt/Centipede/centipede_legs_walk02.png"),
	preload("res://Art/Enemies/Crypt/Centipede/centipede_legs_back.png"),
]
## Piezas detrás de la cabeza: 0 cuerpo (con patas), 1 eslabón, 2 cola.
@export var pieces: PackedInt32Array = [0, 1, 0, 1, 0, 2]
## Distancia entre piezas, en píxeles del mundo.
@export var spacing := 14.0
## Cuánto hay que avanzar para cambiar el cuadro de las patas.
@export var leg_step := 6.0

var _head: Node2D
var _trail: PackedVector2Array = []
var _traveled := 0.0
var _scatter: Array[Vector2] = []
var _death_time := -1.0

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_head = get_parent().get_node_or_null("ArtSprite") as Node2D
	if _head == null: return
	# arranca enroscado detrás de la cabeza
	var start := _head.global_position
	for index in pieces.size() + 2:
		_trail.append(start + Vector2(spacing, -spacing * 0.6) * index)

func _process(delta: float) -> void:
	if _head == null or not is_instance_valid(_head): return
	if _death_time >= 0.0:
		_death_time += delta
		modulate.a = maxf(0.0, 1.0 - _death_time / 0.35)
		queue_redraw()
		return
	modulate = _head.modulate
	visible = get_parent().visible
	_follow(_head.global_position)
	queue_redraw()

# Guarda el recorrido de la cabeza; las piezas se ubican sobre ese camino.
func _follow(point: Vector2) -> void:
	var moved := point.distance_to(_trail[0])
	if moved < 1.0: return
	_traveled += moved
	_trail.insert(0, point)
	var needed := spacing * (pieces.size() + 2)
	var length := 0.0
	for index in range(1, _trail.size()):
		length += _trail[index].distance_to(_trail[index - 1])
		if length > needed:
			_trail.resize(index + 1)
			break

func _draw() -> void:
	if _trail.size() < 2: return
	var scale_factor := absf(_head.global_scale.x)
	var segments := _segments()
	# primero las patas, después las piezas, de la cola a la cabeza
	for index in range(segments.size() - 1, -1, -1):
		if pieces[index] != 0: continue
		var frame := (int(_traveled / leg_step) + index) % LEGS.size()
		_draw_piece(LEGS[frame], segments[index], scale_factor, index)
	for index in range(segments.size() - 1, -1, -1):
		var texture: Texture2D = [BODY, LINK, TAIL][pieces[index]]
		_draw_piece(texture, segments[index], scale_factor, index)

func _draw_piece(texture: Texture2D, placement: Array, scale_factor: float, index: int) -> void:
	var position_on_trail: Vector2 = placement[0]
	if _death_time >= 0.0 and index < _scatter.size():
		position_on_trail += _scatter[index] * _death_time
	var angle: float = placement[1] - deg_to_rad(ART_FORWARD)
	draw_set_transform(position_on_trail, angle, Vector2.ONE * scale_factor)
	draw_texture(texture, -texture.get_size() / 2.0)
	draw_set_transform(Vector2.ZERO)

# Posición y ángulo de cada pieza, medidos a lo largo del camino.
func _segments() -> Array:
	var result := []
	for index in pieces.size():
		result.append(_point_at(spacing * (index + 1)))
	return result

func _point_at(distance: float) -> Array:
	var walked := 0.0
	for index in range(1, _trail.size()):
		var a := _trail[index - 1]
		var b := _trail[index]
		var step := a.distance_to(b)
		if walked + step >= distance and step > 0.0:
			var point := a.lerp(b, (distance - walked) / step)
			return [point, b.direction_to(a).angle()]
		walked += step
	var last := _trail[_trail.size() - 1]
	return [last, last.direction_to(_trail[_trail.size() - 2]).angle()]

## Lo llama CryptEnemy al morir: las piezas salen despedidas y se desvanecen.
func crypt_death() -> void:
	_death_time = 0.0
	_scatter.clear()
	for index in pieces.size():
		_scatter.append(Vector2.from_angle(randf() * TAU) * randf_range(30.0, 70.0))
