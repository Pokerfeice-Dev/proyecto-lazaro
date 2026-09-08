extends Node2D
class_name LandingShadowMarker

## Marca de sombra que avisa dónde va a caer un ataque telegrafiado (por
## ejemplo el salto del boss del área 2). Crece al aparecer y se puede pedir
## que se desvanezca cuando el ataque conecta. Pensado para reutilizarse en
## cualquier ataque futuro que necesite avisar una zona antes de golpear.

@export var target_radius: float = 40.0
@export var grow_time: float = 0.35

var current_radius: float = 0.0

func _ready() -> void:
	scale = Vector2(1.0, 0.45)
	var t = create_tween()
	t.tween_method(_set_radius, 0.0, target_radius, grow_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_radius(r: float) -> void:
	current_radius = r
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, current_radius, Color(0, 0, 0, 0.35))

func fade_and_free() -> void:
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)
