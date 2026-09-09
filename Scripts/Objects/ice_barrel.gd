extends StaticBody2D
class_name IceBarrel

@export var freeze_radius: float = 135.0
@export var freeze_duration: float = 5.0

var is_exploding: bool = false

func _ready() -> void:
	add_to_group("destructible")
	add_to_group("barrel")

const ElementalPuddleScript = preload("res://Scripts/Objects/elemental_puddle.gd")

func take_damage(_amount: float = 1.0, _is_crit: bool = false) -> void:
	if is_exploding: return
	is_exploding = true
	_disable_barrel_collisions()
	_spawn_ice_explosion_fx()
	_play_ice_audio()
	_apply_ice_freeze_effect()
	_spawn_ice_puddle()
	_schedule_queue_free()

func _spawn_ice_puddle() -> void:
	var puddle = ElementalPuddleScript.new()
	puddle.setup(ElementalPuddle.PuddleType.ICE, global_position)
	get_parent().add_child(puddle)

func _disable_barrel_collisions() -> void:
	var col = get_node_or_null("CollisionShape2D")
	if col:
		col.set_deferred("disabled", true)
	hide()

func _spawn_ice_explosion_fx() -> void:
	var particles = CPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 18.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 90.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 12.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.85, 0.95, 1.0, 1.0))
	gradient.add_point(0.5, Color(0.2, 0.75, 1.0, 0.9))
	gradient.set_color(1, Color(0.05, 0.3, 0.7, 0.0))
	particles.color_ramp = gradient
	
	get_parent().add_child(particles)
	particles.global_position = global_position

func _play_ice_audio() -> void:
	var audio = AudioStreamPlayer2D.new()
	var stream = load("res://Audio/Sfx/Barril/frost.ogg")
	if stream:
		audio.stream = stream
		audio.pitch_scale = randf_range(0.95, 1.05)
		audio.volume_db = 2.0
		get_parent().add_child(audio)
		audio.global_position = global_position
		audio.play()
		audio.finished.connect(audio.queue_free)

func _apply_ice_freeze_effect() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		_try_freeze_exploded_enemy(enemy)

func _try_freeze_exploded_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy): return
	if enemy.get("is_dying") == true: return
	if global_position.distance_to(enemy.global_position) > freeze_radius: return
	_apply_freeze_to_target(enemy)

func _apply_freeze_to_target(enemy: Node) -> void:
	if enemy.has_method("freeze_enemy"):
		enemy.freeze_enemy(freeze_duration)
		return
	if enemy.has_method("apply_freeze"):
		enemy.apply_freeze(freeze_duration)

func _schedule_queue_free() -> void:
	var t = create_tween()
	t.tween_interval(0.65)
	t.tween_callback(queue_free)
