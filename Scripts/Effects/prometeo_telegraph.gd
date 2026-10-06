extends Node2D
class_name PrometeoTelegraph

## Avisos de los ataques de Prometeo (boss 3): línea de mira, abanico de corte
## y círculo de impacto. Se dibujan por código, se van llenando mientras dura
## el aviso y se borran solos al terminar. Naranja = disparo, rojo = cuerpo a
## cuerpo / impacto.

enum Shape { LINE, ARC, CIRCLE }

const COLOR_RANGED := Color(1.0, 0.55, 0.15)
const COLOR_MELEE := Color(1.0, 0.12, 0.2)
const COLOR_SLASH := Color(1.0, 0.85, 0.85)

var shape: Shape = Shape.LINE
var color: Color = COLOR_RANGED
var duration: float = 0.5
var length: float = 200.0
var width: float = 3.0
var radius: float = 80.0
var half_angle: float = 0.6
var _elapsed: float = 0.0

static func line(parent: Node, origin: Vector2, angle: float, p_length: float, p_duration: float, p_color: Color = COLOR_RANGED) -> PrometeoTelegraph:
	var t := PrometeoTelegraph.new()
	t.shape = Shape.LINE
	t.length = p_length
	t.color = p_color
	return t._place(parent, origin, angle, p_duration)

static func arc(parent: Node, center: Vector2, angle: float, p_radius: float, p_half_angle: float, p_duration: float, p_color: Color = COLOR_MELEE) -> PrometeoTelegraph:
	var t := PrometeoTelegraph.new()
	t.shape = Shape.ARC
	t.radius = p_radius
	t.half_angle = p_half_angle
	t.color = p_color
	return t._place(parent, center, angle, p_duration)

static func circle(parent: Node, center: Vector2, p_radius: float, p_duration: float, p_color: Color = COLOR_MELEE) -> PrometeoTelegraph:
	var t := PrometeoTelegraph.new()
	t.shape = Shape.CIRCLE
	t.radius = p_radius
	t.color = p_color
	return t._place(parent, center, 0.0, p_duration)

func _place(parent: Node, pos: Vector2, angle: float, p_duration: float) -> PrometeoTelegraph:
	duration = maxf(p_duration, 0.01)
	z_as_relative = false
	z_index = 40
	add_to_group("prometeo_telegraph")
	parent.add_child(self)
	global_position = pos
	rotation = angle
	return self

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k = clampf(_elapsed / duration, 0.0, 1.0)
	match shape:
		Shape.LINE:
			_draw_line_shape(k)
		Shape.ARC:
			_draw_arc_shape(k)
		Shape.CIRCLE:
			_draw_circle_shape(k)

func _draw_line_shape(k: float) -> void:
	draw_line(Vector2.ZERO, Vector2(length, 0), Color(color, 0.22), width)
	draw_line(Vector2.ZERO, Vector2(length * k, 0), Color(color, 0.9), width * 0.6)

func _draw_arc_shape(k: float) -> void:
	draw_colored_polygon(_wedge_points(radius), Color(color, 0.12 + 0.15 * k))
	if radius * k > 4.0:
		draw_colored_polygon(_wedge_points(radius * k), Color(color, 0.3))
	draw_arc(Vector2.ZERO, radius, -half_angle, half_angle, 24, Color(color, 0.9), 2.0)

func _draw_circle_shape(k: float) -> void:
	draw_circle(Vector2.ZERO, radius, Color(color, 0.14))
	if radius * k > 2.0:
		draw_circle(Vector2.ZERO, radius * k, Color(color, 0.25))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.9), 2.0)

func _wedge_points(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2.ZERO])
	var steps := 16
	for i in range(steps + 1):
		var a = lerpf(-half_angle, half_angle, float(i) / float(steps))
		pts.append(Vector2(r, 0).rotated(a))
	return pts
