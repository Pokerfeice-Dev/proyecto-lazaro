extends Projectile

## Bola de nieve de la sinergia Snowman (escopeta): grande y lenta, atraviesa
## a los enemigos y congela a cada uno que toca. Se rompe contra las paredes
## o al terminar su vida, en una lluvia de escarcha.

const FROST_SOUND := "res://Audio/Sfx/Barril/frost.ogg"

@export var freeze_duration: float = 2.5
@export var spin_speed: float = 4.0

var _frost_particles: CPUParticles2D = null

func _ready() -> void:
	super._ready()
	_setup_frost_fx()

func _setup_frost_fx() -> void:
	_frost_particles = _create_frost_trail_particles()
	add_child(_frost_particles)

func _create_frost_trail_particles() -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.amount = 32
	p.lifetime = 0.5
	p.local_coords = false
	p.z_index = 49
	p.z_as_relative = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.spread = 180.0
	p.gravity = Vector2(0, 15)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 24.0
	p.damping_min = 10.0
	p.damping_max = 20.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.scale_amount_curve = _create_frost_scale_curve()
	p.color_ramp = _create_frost_color_gradient()
	p.material = _create_frost_material()
	p.emitting = true
	return p

func _create_frost_scale_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func _create_frost_color_gradient() -> Gradient:
	var g = Gradient.new()
	g.set_color(0, Color(0.95, 1.0, 1.0, 0.9))
	g.add_point(0.4, Color(0.55, 0.88, 1.0, 0.7))
	g.set_color(1, Color(0.3, 0.6, 1.0, 0.0))
	return g

func _create_frost_material() -> CanvasItemMaterial:
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return mat

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_destroyed: return
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.rotation += spin_speed * delta

func _process_body_hit(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		_handle_wall_collision()
		return
	body.take_damage(damage, is_crit)
	if body.has_method("freeze_enemy"):
		body.freeze_enemy(freeze_duration)
	_spawn_frost_burst(10, 0.35)

# Atraviesa a todos los enemigos; solo se rompe con paredes o por tiempo.
func _handle_piercing_or_destroy(_body: Node2D) -> void:
	pass

func _handle_wall_collision() -> void:
	_destroy_projectile()

func _destroy_projectile() -> void:
	if is_destroyed: return
	_stop_frost_particles()
	_spawn_frost_burst(36, 0.6)
	_play_frost_sound()
	super._destroy_projectile()

func _stop_frost_particles() -> void:
	if _frost_particles and is_instance_valid(_frost_particles):
		_frost_particles.emitting = false

func _spawn_frost_burst(amount: int, life: float) -> void:
	var p = CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = life
	p.spread = 180.0
	p.gravity = Vector2(0, 40)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 150.0
	p.damping_min = 80.0
	p.damping_max = 140.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	var g = Gradient.new()
	g.set_color(0, Color(0.95, 1.0, 1.0, 1.0))
	g.add_point(0.5, Color(0.55, 0.85, 1.0, 0.9))
	g.set_color(1, Color(0.2, 0.5, 0.9, 0.0))
	p.color_ramp = g
	p.z_as_relative = false
	p.z_index = 51
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.finished.connect(p.queue_free)

func _play_frost_sound() -> void:
	if not ResourceLoader.exists(FROST_SOUND): return
	var audio = AudioStreamPlayer2D.new()
	audio.stream = load(FROST_SOUND)
	audio.bus = "SFX"
	audio.volume_db = -6.0
	get_tree().current_scene.add_child(audio)
	audio.global_position = global_position
	audio.play()
	audio.finished.connect(audio.queue_free)
