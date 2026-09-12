extends CPUParticles2D

## Chorro de particulas continuo en el cano del lanzallamas mientras se mantiene
## presionado el disparo. Se suma a los proyectiles individuales para lograr
## una sensacion de cono de fuego mas denso y continuo (como la referencia).

func _ready() -> void:
	emitting = false
	one_shot = false
	amount = 40
	lifetime = 0.3
	explosiveness = 0.0
	randomness = 0.3
	direction = Vector2.RIGHT
	spread = 20.0
	gravity = Vector2.ZERO
	initial_velocity_min = 180.0
	initial_velocity_max = 320.0
	damping_min = 200.0
	damping_max = 320.0
	scale_amount_min = 2.5
	scale_amount_max = 5.0

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = curve

	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.55, 0.15, 0.95))
	gradient.add_point(0.7, Color(0.9, 0.3, 0.1, 0.6))
	gradient.set_color(1, Color(0.5, 0.1, 0.05, 0.0))
	color_ramp = gradient

	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

func _process(_delta: float) -> void:
	emitting = is_visible_in_tree() and Input.is_action_pressed("shoot")
