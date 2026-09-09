extends Area2D
class_name Projectile

@export var speed: float = 600.0
@export var lifetime: float = 3.0
@export var piercing: int = 0
@export var enable_trail: bool = true
@export var trail_particle_amount: int = 22
@export var trail_particle_lifetime: float = 0.25

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var target_group: String = ""
var is_crit: bool = false

var fragmentation_chance: float = 0.0
var is_fragment: bool = false
var is_destroyed: bool = false
var trail_particles: CPUParticles2D = null

func setup(dir: Vector2, dmg: float, target: String, crit: bool = false):
	direction = dir.normalized()
	damage = dmg
	target_group = target
	is_crit = crit
	rotation = direction.angle()

func _ready() -> void:
	z_index = 50
	z_as_relative = false
	body_entered.connect(_on_body_entered)
	_setup_comet_tail()
	_start_lifetime_timer()

func _setup_comet_tail() -> void:
	if not enable_trail: return
	trail_particles = CPUParticles2D.new()
	_configure_trail_core()
	_configure_trail_emission()
	_configure_trail_dynamics()
	_configure_trail_curve()
	_configure_trail_gradient()
	_configure_trail_material()
	add_child(trail_particles)

func _configure_trail_core() -> void:
	trail_particles.amount = trail_particle_amount
	trail_particles.lifetime = trail_particle_lifetime
	trail_particles.local_coords = false
	trail_particles.z_index = 49
	trail_particles.z_as_relative = false
	trail_particles.emitting = true

func _configure_trail_emission() -> void:
	trail_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail_particles.emission_sphere_radius = 2.0
	trail_particles.spread = 180.0
	trail_particles.gravity = Vector2.ZERO

func _configure_trail_dynamics() -> void:
	trail_particles.initial_velocity_min = 2.0
	trail_particles.initial_velocity_max = 6.0
	trail_particles.damping_min = 4.0
	trail_particles.damping_max = 8.0
	trail_particles.scale_amount_min = 1.5
	trail_particles.scale_amount_max = 2.5

func _configure_trail_curve() -> void:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.4, 0.7))
	curve.add_point(Vector2(1.0, 0.0))
	trail_particles.scale_amount_curve = curve

func _configure_trail_gradient() -> void:
	var base_color = _get_trail_base_color()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(base_color.r, base_color.g, base_color.b, 0.6))
	gradient.add_point(0.45, Color(base_color.r, base_color.g, base_color.b, 0.3))
	gradient.set_color(1, Color(base_color.r * 0.7, base_color.g * 0.7, base_color.b * 0.7, 0.0))
	trail_particles.color_ramp = gradient

func _get_trail_base_color() -> Color:
	var light = get_node_or_null("PointLight2D")
	if not light:
		return Color(1.0, 0.7, 0.3)
	return light.color

func _configure_trail_material() -> void:
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	trail_particles.material = mat

func _start_lifetime_timer() -> void:
	await get_tree().physics_frame
	_create_and_start_timer()

func _create_and_start_timer() -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_destroy_projectile)
	add_child(timer)
	timer.start(lifetime)

func _physics_process(delta: float) -> void:
	if is_destroyed: return
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if is_destroyed: return
	if _should_ignore_body(body): return
	_process_body_hit(body)

func _should_ignore_body(body: Node2D) -> bool:
	return body.is_in_group("player") or body.is_in_group("projectile_pass")

func _process_body_hit(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		_handle_wall_collision()
		return
	body.take_damage(damage, is_crit)
	_handle_piercing_or_destroy(body)

func _handle_wall_collision() -> void:
	_spawn_wall_sparks()
	_destroy_projectile()

func _spawn_wall_sparks() -> void:
	var spark_dir = _get_impact_normal()
	var sparks = CPUParticles2D.new()
	_configure_sparks_core(sparks)
	_configure_sparks_motion(sparks, spark_dir)
	_configure_sparks_visuals(sparks)
	get_tree().current_scene.add_child(sparks)
	sparks.global_position = global_position
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)

func _get_impact_normal() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var from_pos = global_position - direction * 16.0
	var to_pos = global_position + direction * 16.0
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.exclude = [self.get_rid()]
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	if result.is_empty() or not result.has("normal"):
		return -direction
	return result.normal

func _configure_sparks_core(sparks: CPUParticles2D) -> void:
	sparks.amount = randi_range(4, 6)
	sparks.lifetime = 0.22
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.z_index = 60
	sparks.z_as_relative = false

func _configure_sparks_motion(sparks: CPUParticles2D, spark_dir: Vector2) -> void:
	sparks.direction = spark_dir
	sparks.spread = 45.0
	sparks.gravity = Vector2(0, 40)
	sparks.initial_velocity_min = 70.0
	sparks.initial_velocity_max = 140.0
	sparks.damping_min = 180.0
	sparks.damping_max = 260.0
	sparks.scale_amount_min = 1.2
	sparks.scale_amount_max = 2.4

func _configure_sparks_visuals(sparks: CPUParticles2D) -> void:
	_apply_sparks_curve(sparks)
	_apply_sparks_gradient(sparks)
	_apply_sparks_material(sparks)

func _apply_sparks_curve(sparks: CPUParticles2D) -> void:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.6, 0.7))
	curve.add_point(Vector2(1.0, 0.0))
	sparks.scale_amount_curve = curve

func _apply_sparks_gradient(sparks: CPUParticles2D) -> void:
	var base_col = _get_trail_base_color()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 0.85, 1.0))
	gradient.add_point(0.35, Color(base_col.r, base_col.g, base_col.b, 0.95))
	gradient.set_color(1, Color(base_col.r * 0.4, base_col.g * 0.2, base_col.b * 0.1, 0.0))
	sparks.color_ramp = gradient

func _apply_sparks_material(sparks: CPUParticles2D) -> void:
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = mat

func _handle_piercing_or_destroy(body: Node2D) -> void:
	if piercing > 0 and body.is_in_group("enemy"):
		piercing -= 1
		return
	_destroy_projectile()

func _destroy_projectile() -> void:
	if is_destroyed: return
	is_destroyed = true
	
	_stop_movement()
	_disable_projectile_collision()
	_hide_projectile_graphics()
	_stop_trail_emission()
	_check_and_trigger_fragmentation()
	_fade_out_light_and_trail()

func _stop_movement() -> void:
	speed = 0.0

func _disable_projectile_collision() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var col = get_node_or_null("CollisionShape2D")
	if not col: return
	col.set_deferred("disabled", true)

func _hide_projectile_graphics() -> void:
	_hide_static_sprite()
	_hide_animated_sprite()

func _hide_static_sprite() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	sprite.hide()

func _hide_animated_sprite() -> void:
	var anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite: return
	anim_sprite.hide()

func _stop_trail_emission() -> void:
	if not trail_particles: return
	trail_particles.emitting = false

func _fade_out_light_and_trail() -> void:
	var tween = create_tween().set_parallel(true)
	_tween_light_fade(tween)
	_tween_particles_fade(tween)
	tween.chain().tween_callback(_on_fade_out_complete)

func _tween_light_fade(tween: Tween) -> void:
	var light = get_node_or_null("PointLight2D")
	if not light: return
	var fade_time = 0.16
	tween.tween_property(light, "energy", 0.0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(light, "texture_scale", light.texture_scale * 0.6, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _tween_particles_fade(tween: Tween) -> void:
	if not trail_particles: return
	tween.tween_property(trail_particles, "modulate:a", 0.0, trail_particle_lifetime).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_fade_out_complete() -> void:
	queue_free()

func _check_and_trigger_fragmentation() -> void:
	if is_fragment: return
	if randf() > fragmentation_chance: return
	_spawn_fragments()

func _spawn_fragments() -> void:
	var path = _get_fragment_scene_path()
	var scene = load(path)
	if not scene: return
	_spawn_all_fragment_instances(scene)

func _get_fragment_scene_path() -> String:
	if scene_file_path == "":
		return "res://Scenes/Projectiles/Projectile.tscn"
	return scene_file_path

func _spawn_all_fragment_instances(scene: PackedScene) -> void:
	for i in range(4):
		_spawn_single_fragment(scene, i)

func _spawn_single_fragment(scene: PackedScene, idx: int) -> void:
	var frag = scene.instantiate()
	if not frag: return
	_configure_fragment_instance(frag, idx)
	get_parent().call_deferred("add_child", frag)

func _configure_fragment_instance(frag: Node2D, idx: int) -> void:
	var angle_offset = (idx * PI / 2.0) + (PI / 4.0)
	var frag_dir = direction.rotated(angle_offset)
	frag.global_position = global_position
	if frag.has_method("setup"):
		frag.setup(frag_dir, damage * 0.3, target_group, is_crit)
	frag.set("is_fragment", true)
	frag.set("fragmentation_chance", 0.0)
	frag.set("lifetime", 0.3)
	if "speed" in frag:
		frag.speed = speed
