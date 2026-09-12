extends Area2D
class_name ElementalPuddle

# Charco elemental temporal (Fuego / Hielo) generado por la explosión de barriles.
# Fuego: Quema periódicamente a enemigos y al jugador mientras permanezcan dentro.
# Hielo: Ralentiza un 40% a quienes lo pisen, restaurando la velocidad al salir.

enum PuddleType { FIRE, ICE }

@export var puddle_type: PuddleType = PuddleType.FIRE
@export var duration: float = 5.0
@export var puddle_radius: float = 48.0
@export var burn_damage_enemy: int = 4
@export var burn_damage_player: int = 1
@export var slow_multiplier: float = 0.60 # 40% de reducción de velocidad

const BURN_TICK_INTERVAL: float = 0.5
const PUDDLE_OFFSETS: Array[Vector2] = [
	Vector2(0, 0),
	Vector2(-16, -6),
	Vector2(14, 6),
	Vector2(-8, 13),
	Vector2(11, -11),
	Vector2(20, -3),
	Vector2(-19, 8)
]

var _burn_tick_timer: float = 0.0
var _overlapping_bodies: Array[Node2D] = []
var _light_node: PointLight2D = null
var _particles: CPUParticles2D = null

func setup(type: PuddleType, at_position: Vector2) -> void:
	puddle_type = type
	global_position = at_position

func _ready() -> void:
	_setup_area_properties()
	_setup_collision_shape()
	_setup_particles()
	_setup_light()
	_start_lifecycle()

func _setup_area_properties() -> void:
	z_as_relative = false
	z_index = 1
	collision_layer = 0
	collision_mask = 7
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_collision_shape() -> void:
	var shape = CircleShape2D.new()
	shape.radius = puddle_radius
	var col = CollisionShape2D.new()
	col.shape = shape
	call_deferred("add_child", col)


func _setup_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.z_as_relative = false
	_particles.z_index = 3
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.emission_sphere_radius = 28.0
	_configure_particles_by_type(_particles)
	add_child(_particles)
	_particles.emitting = true

func _configure_particles_by_type(part: CPUParticles2D) -> void:
	if puddle_type == PuddleType.FIRE:
		_configure_fire_particles(part)
		return
	_configure_ice_particles(part)

func _configure_fire_particles(part: CPUParticles2D) -> void:
	part.amount = 16
	part.lifetime = 0.55
	part.gravity = Vector2(0, -35)
	part.initial_velocity_min = 8.0
	part.initial_velocity_max = 24.0
	part.scale_amount_min = 2.5
	part.scale_amount_max = 4.8
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.3, 0.9))
	grad.add_point(0.35, Color(1.0, 0.38, 0.05, 0.85))
	grad.add_point(0.75, Color(0.25, 0.1, 0.08, 0.35))
	grad.set_color(1, Color(0.1, 0.1, 0.1, 0.0))
	part.color_ramp = grad

func _configure_ice_particles(part: CPUParticles2D) -> void:
	part.amount = 12
	part.lifetime = 0.70
	part.gravity = Vector2(0, -8)
	part.initial_velocity_min = 4.0
	part.initial_velocity_max = 14.0
	part.scale_amount_min = 2.0
	part.scale_amount_max = 3.6
	
	var grad = Gradient.new()
	grad.set_color(0, Color(0.85, 0.98, 1.0, 0.7))
	grad.add_point(0.5, Color(0.4, 0.8, 1.0, 0.5))
	grad.set_color(1, Color(0.15, 0.45, 0.85, 0.0))
	part.color_ramp = grad

func _setup_light() -> void:
	_light_node = PointLight2D.new()
	var light_texture = load("res://Art/Lights/Yellow_Light.png")
	if light_texture:
		_light_node.texture = light_texture
	_configure_light_properties(_light_node)
	add_child(_light_node)

func _configure_light_properties(light: PointLight2D) -> void:
	if puddle_type == PuddleType.FIRE:
		light.color = Color(1.0, 0.45, 0.12)
		light.energy = 0.75
		light.texture_scale = 1.15
		return
	light.color = Color(0.35, 0.75, 1.2)
	light.energy = 0.60
	light.texture_scale = 1.05

func _start_lifecycle() -> void:
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duration - 0.85)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	if _light_node:
		tween.parallel().tween_property(_light_node, "energy", 0.0, 0.6)
	tween.chain().tween_callback(_on_lifecycle_finished)

func _on_lifecycle_finished() -> void:
	_clear_all_slow_effects()
	queue_free()

func _exit_tree() -> void:
	_clear_all_slow_effects()

func _physics_process(delta: float) -> void:
	if puddle_type != PuddleType.FIRE: return
	_burn_tick_timer -= delta
	if _burn_tick_timer > 0.0: return
	_burn_tick_timer = BURN_TICK_INTERVAL
	_process_burn_ticks()

func _process_burn_ticks() -> void:
	var valid_bodies: Array[Node2D] = []
	for body in _overlapping_bodies:
		_try_burn_and_retain_body(body, valid_bodies)
	_overlapping_bodies = valid_bodies

func _try_burn_and_retain_body(body: Node2D, valid_list: Array[Node2D]) -> void:
	if not is_instance_valid(body): return
	if not body.is_inside_tree(): return
	valid_list.append(body)
	_apply_burn_tick(body)

func _apply_burn_tick(body: Node2D) -> void:
	if body.is_in_group("player"):
		_burn_player(body)
		return
	if body.is_in_group("enemy"):
		_burn_enemy(body)

func _burn_player(player: Node2D) -> void:
	if player.has_method("take_damage"):
		player.take_damage(burn_damage_player, "Charco de Fuego", global_position)

func _burn_enemy(enemy: Node2D) -> void:
	if enemy.get("is_dying") == true: return
	if enemy.has_method("take_damage"):
		enemy.take_damage(burn_damage_enemy)

func _on_body_entered(body: Node2D) -> void:
	if not _is_affectable_body(body): return
	if _overlapping_bodies.has(body): return
	_overlapping_bodies.append(body)
	_apply_entry_effect(body)

func _on_body_exited(body: Node2D) -> void:
	_overlapping_bodies.erase(body)
	if puddle_type == PuddleType.ICE:
		_remove_ice_slow(body)

func _is_affectable_body(body: Node2D) -> bool:
	if not is_instance_valid(body): return false
	if body.is_in_group("player"): return true
	if body.is_in_group("enemy"): return true
	return false

func _apply_entry_effect(body: Node2D) -> void:
	if puddle_type == PuddleType.FIRE:
		_apply_burn_tick(body)
		return
	_apply_ice_slow(body)

func _apply_ice_slow(body: Node2D) -> void:
	if not is_instance_valid(body): return
	if body.has_method("set_speed_modifier"):
		body.set_speed_modifier("ice_puddle", slow_multiplier)

func _remove_ice_slow(body: Node2D) -> void:
	if not is_instance_valid(body): return
	if body.has_method("remove_speed_modifier"):
		body.remove_speed_modifier("ice_puddle")

func _clear_all_slow_effects() -> void:
	if puddle_type != PuddleType.ICE: return
	for body in _overlapping_bodies:
		_remove_ice_slow(body)
	_overlapping_bodies.clear()

# --- Dibujo Vectorial de los Charcos ---

func _draw() -> void:
	if puddle_type == PuddleType.FIRE:
		_draw_fire_puddle()
		return
	_draw_ice_puddle()

func _draw_fire_puddle() -> void:
	var scorch_color = Color(0.20, 0.07, 0.04, 0.65)
	var magma_color = Color(0.92, 0.32, 0.05, 0.75)
	var core_color = Color(1.0, 0.85, 0.20, 0.85)
	
	_draw_puddle_layer(PUDDLE_OFFSETS, 24.0, scorch_color)
	_draw_puddle_layer(PUDDLE_OFFSETS, 17.0, magma_color)
	_draw_puddle_layer([Vector2.ZERO, Vector2(-6, 3), Vector2(6, -3)], 9.0, core_color)

func _draw_ice_puddle() -> void:
	var rim_color = Color(0.18, 0.50, 0.80, 0.50)
	var sheet_color = Color(0.55, 0.88, 1.0, 0.70)
	var core_color = Color(0.92, 0.98, 1.0, 0.85)
	
	_draw_puddle_layer(PUDDLE_OFFSETS, 24.0, rim_color)
	_draw_puddle_layer(PUDDLE_OFFSETS, 17.0, sheet_color)
	_draw_puddle_layer([Vector2.ZERO, Vector2(-7, 4), Vector2(7, -4)], 9.0, core_color)
	_draw_ice_cracks()

func _draw_puddle_layer(offsets: Array, radius_base: float, color: Color) -> void:
	for offset in offsets:
		draw_circle(offset, radius_base, color)

func _draw_ice_cracks() -> void:
	var crack_color = Color(1.0, 1.0, 1.0, 0.75)
	draw_line(Vector2(-15, -8), Vector2(12, 10), crack_color, 1.2)
	draw_line(Vector2(-5, 12), Vector2(8, -14), crack_color, 1.0)
	draw_line(Vector2(0, 0), Vector2(-18, 5), crack_color, 1.0)
