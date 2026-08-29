# Flecha roja que aparece en el borde de la pantalla apuntando hacia el
# origen de un golpe recibido (útil para torretas, tiradores u otras
# amenazas que golpean desde fuera de cámara).
extends Node2D
class_name DamageDirectionIndicator

const EDGE_MARGIN: float = 48.0
const ARROW_COLOR: Color = Color(0.95, 0.15, 0.15, 0.9)
const LIFETIME: float = 0.6

func _ready() -> void:
	z_index = 4096
	modulate.a = 0.0
	_animate()

func _draw() -> void:
	# Triángulo apuntando hacia +X; la rotación del nodo lo orienta hacia el golpe.
	var points = PackedVector2Array([Vector2(18, 0), Vector2(-12, -11), Vector2(-12, 11)])
	draw_colored_polygon(points, ARROW_COLOR)

# ubica la flecha en el borde de la pantalla, en la dirección hacia la fuente del daño
func setup(dir: Vector2, viewport_size: Vector2) -> void:
	rotation = dir.angle()
	var half_extents = viewport_size / 2.0 - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	position = viewport_size / 2.0 + _get_edge_offset(dir, half_extents)

func _get_edge_offset(dir: Vector2, half_extents: Vector2) -> Vector2:
	var t_x = half_extents.x / absf(dir.x) if dir.x != 0.0 else INF
	var t_y = half_extents.y / absf(dir.y) if dir.y != 0.0 else INF
	return dir * min(t_x, t_y)

func _animate() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.08)
	tween.tween_interval(LIFETIME - 0.28)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
