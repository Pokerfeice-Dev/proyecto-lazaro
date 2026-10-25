extends Node2D
class_name PrometeoFlameCone

const EnemyNavigation = preload("res://Scripts/World/enemy_navigation.gd")

## Llamarada del lanzallamas de Prometeo (boss 3): un cono de fuego que el boss
## va girando despacio hacia el jugador. Quema por ticks mientras el jugador
## esté adentro (el dash lo atraviesa, como cualquier daño).

@export var reach: float = 130.0
@export var half_angle_degrees: float = 22.0
@export var tick_interval: float = 0.18

var damage: int = 8
var source_name: String = "Prometeo"
var _active: bool = false
var _tick: float = 0.0
var _particles: FlameConeParticles

func _ready() -> void:
	_particles = _build_particles()
	add_child(_particles)

func start(p_damage: int, p_source: String) -> void:
	damage = p_damage
	source_name = p_source
	_active = true
	_tick = tick_interval
	_particles.emitting = true

func stop() -> void:
	_active = false
	if _particles:
		_particles.emitting = false

func is_active() -> bool:
	return _active

func _physics_process(delta: float) -> void:
	if not _active: return
	_tick -= delta
	if _tick > 0.0: return
	_tick = tick_interval
	_burn_targets()

func _burn_targets() -> void:
	for body in get_tree().get_nodes_in_group("player"):
		if _is_inside_cone(body.global_position) and body.has_method("take_damage") and _clear_path(body.global_position):
			body.take_damage(damage, source_name, global_position)

func _is_inside_cone(pos: Vector2) -> bool:
	var to_pos = pos - global_position
	if to_pos.length() > reach: return false
	return absf(wrapf(to_pos.angle() - global_rotation, -PI, PI)) <= deg_to_rad(half_angle_degrees)

func _build_particles() -> FlameConeParticles:
	var p = FlameConeParticles.new()
	p.set_cone(reach, half_angle_degrees)
	return p

func _clear_path(pos: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, pos, 5)
	query.exclude = EnemyNavigation.actor_exclusions(get_tree())
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()
