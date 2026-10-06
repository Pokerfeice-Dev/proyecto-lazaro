extends CPUParticles2D
class_name FlameConeParticles

## Llamarada de partículas en cono, apuntando hacia +X del nodo. Es la del
## lanzallamas de Prometeo (boss 3) y también la usa la sinergia Lanzallamas del
## jugador, así las dos se ven igual. Con local_coords apagado, el fuego deja
## estela cuando el arma gira.

var reach: float = 130.0
var half_angle_degrees: float = 22.0

func _init() -> void:
	emitting = false
	amount = 80
	lifetime = 0.45
	local_coords = false
	z_as_relative = false
	z_index = 45
	direction = Vector2.RIGHT
	gravity = Vector2.ZERO
	scale_amount_min = 4.0
	scale_amount_max = 9.0
	color_ramp = _build_flame_gradient()
	material = _build_additive_material()
	set_cone(reach, half_angle_degrees)

## Ajusta el largo y la apertura de la llamarada (se puede llamar cada frame).
func set_cone(p_reach: float, p_half_angle_degrees: float) -> void:
	reach = p_reach
	half_angle_degrees = p_half_angle_degrees
	spread = half_angle_degrees * 0.85
	initial_velocity_min = reach / lifetime * 0.7
	initial_velocity_max = reach / lifetime

func _build_flame_gradient() -> Gradient:
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.5, 0.95))
	g.set_color(1, Color(0.6, 0.05, 0.05, 0.0))
	g.add_point(0.35, Color(1.0, 0.55, 0.1, 0.9))
	return g

func _build_additive_material() -> CanvasItemMaterial:
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat
