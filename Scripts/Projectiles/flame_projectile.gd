extends Projectile

## Proyectil del Lanzallamas: no deja fuego en el piso, solo aplica
## una quemadura (dano en el tiempo) sobre el enemigo impactado.

@export var burn_damage_per_tick: int = 2
@export var burn_tick_interval: float = 0.4
@export var burn_duration: float = 1.6

func _process_body_hit(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		_handle_wall_collision()
		return
	body.take_damage(damage, is_crit)
	IgniteEffect.apply_ignite(body, burn_damage_per_tick, burn_tick_interval, burn_duration)
	_spawn_impact_flame()
	_handle_piercing_or_destroy(body)

func _spawn_impact_flame() -> void:
	var flame := CPUParticles2D.new()
	flame.amount = 14
	flame.lifetime = 0.35
	flame.one_shot = true
	flame.explosiveness = 0.85
	flame.direction = Vector2(0, -1)
	flame.spread = 50.0
	flame.gravity = Vector2(0, -30)
	flame.initial_velocity_min = 40.0
	flame.initial_velocity_max = 90.0
	flame.damping_min = 60.0
	flame.damping_max = 100.0
	flame.scale_amount_min = 2.0
	flame.scale_amount_max = 4.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.9, 0.4, 1.0))
	gradient.add_point(0.4, Color(1.0, 0.45, 0.1, 0.9))
	gradient.set_color(1, Color(0.5, 0.1, 0.05, 0.0))
	flame.color_ramp = gradient
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	flame.material = mat
	get_tree().current_scene.add_child(flame)
	flame.global_position = global_position
	flame.emitting = true
	flame.finished.connect(flame.queue_free)
