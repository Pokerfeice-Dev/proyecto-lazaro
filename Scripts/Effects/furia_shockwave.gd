extends Node2D
class_name FuriaShockwave

var radius: float = 0.0
var max_radius: float = 120.0
var speed: float = 400.0
var alpha: float = 1.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	radius += speed * delta
	alpha = 1.0 - (radius / max_radius)
	if radius >= max_radius:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var c_fill = Color(1.0, 0.2, 0.2, alpha * 0.3)
	var c_stroke = Color(1.0, 0.4, 0.4, alpha * 0.7)
	if has_meta("color_fill"):
		var meta_fill = get_meta("color_fill")
		c_fill = Color(meta_fill.r, meta_fill.g, meta_fill.b, alpha * meta_fill.a)
	if has_meta("color_stroke"):
		var meta_stroke = get_meta("color_stroke")
		c_stroke = Color(meta_stroke.r, meta_stroke.g, meta_stroke.b, alpha * meta_stroke.a)
		
	draw_circle(Vector2.ZERO, radius, c_fill)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, c_stroke, 2.0)
