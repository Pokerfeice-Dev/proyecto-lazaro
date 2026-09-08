extends Node2D
class_name Boss2PlaceholderVisual

## Cuerpo placeholder del boss del área 2, dibujado por código (sin sprite
## final todavía). Da un aspecto de "blob" simple con ojos, y expone
## funciones de squash/stretch que usa boss2.gd para vender los saltos y
## aplastones. Cuando llegue el arte de turco, basta con ocultar/borrar este
## nodo y poner un AnimatedSprite2D en su lugar (las llamadas a squash/stretch
## se pueden mantener igual si el nuevo nodo también es un Node2D).

@export var body_radius: float = 34.0
@export var body_color: Color = Color(0.55, 0.15, 0.55)
@export var body_color_dark: Color = Color(0.32, 0.08, 0.32)

func _ready() -> void:
	scale = Vector2.ONE

func _draw() -> void:
	draw_circle(Vector2(0, 6), body_radius * 0.92, body_color_dark)
	draw_circle(Vector2.ZERO, body_radius, body_color)
	_draw_eyes()

func _draw_eyes() -> void:
	var eye_offset = body_radius * 0.35
	var eye_y = -body_radius * 0.2
	var eye_r = body_radius * 0.16
	var pupil_r = body_radius * 0.07
	draw_circle(Vector2(-eye_offset, eye_y), eye_r, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(eye_offset, eye_y), eye_r, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(-eye_offset, eye_y), pupil_r, Color.BLACK)
	draw_circle(Vector2(eye_offset, eye_y), pupil_r, Color.BLACK)

func set_squash(target_scale: Vector2, duration: float = 0.15) -> void:
	var t = create_tween()
	t.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func play_squash_down() -> void:
	set_squash(Vector2(1.25, 0.7), 0.12)

func play_stretch_up() -> void:
	set_squash(Vector2(0.75, 1.3), 0.18)

func play_landing_impact() -> void:
	set_squash(Vector2(1.35, 0.6), 0.05)
	var t = create_tween()
	t.tween_interval(0.05)
	t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func reset_squash() -> void:
	scale = Vector2.ONE
