extends Node2D
class_name FlickeringLight

static var is_globally_enabled: bool = true

@export var hum_speed: float = 3.6
@export var hum_amplitude: float = 0.06
@export var glitch_enabled: bool = true
@export var min_glitch_interval: float = 5.0
@export var max_glitch_interval: float = 11.0
@export var enable_sparks: bool = true

var lights: Array[PointLight2D] = []
var base_energies: Array[float] = []
var phase_offset: float = 0.0
var glitch_timer: float = 0.0
var is_glitching: bool = false
var glitch_progress: float = 0.0
var glitch_duration: float = 0.11
var spark_particles: CPUParticles2D = null

func _ready() -> void:
	add_to_group("flickering_lights")
	_initialize_phase_and_timer()
	_collect_point_lights()
	_setup_spark_particles()

func _initialize_phase_and_timer() -> void:
	phase_offset = randf_range(0.0, 100.0)
	glitch_timer = randf_range(min_glitch_interval, max_glitch_interval)

func _collect_point_lights() -> void:
	lights.clear()
	base_energies.clear()
	_find_lights_in_children()

func _find_lights_in_children() -> void:
	for child in get_children():
		_register_child_if_light(child)

func _register_child_if_light(node: Node) -> void:
	var light = node as PointLight2D
	if not light:
		return
	lights.append(light)
	base_energies.append(light.energy)

func _setup_spark_particles() -> void:
	if not enable_sparks:
		return
	spark_particles = CPUParticles2D.new()
	spark_particles.name = "SparkParticles"
	spark_particles.emitting = false
	spark_particles.one_shot = true
	spark_particles.amount = 3
	spark_particles.lifetime = 0.18
	spark_particles.explosiveness = 0.95
	spark_particles.direction = Vector2(0, 1)
	spark_particles.spread = 70.0
	spark_particles.initial_velocity_min = 25.0
	spark_particles.initial_velocity_max = 50.0
	spark_particles.gravity = Vector2(0, 120.0)
	spark_particles.scale_amount_min = 1.0
	spark_particles.scale_amount_max = 2.0
	spark_particles.color = Color(1.0, 0.82, 0.45, 0.9)
	spark_particles.z_index = 10
	add_child(spark_particles)
	_position_spark_particles()

func _position_spark_particles() -> void:
	if lights.is_empty():
		return
	spark_particles.position = lights[0].position

func _process(delta: float) -> void:
	if not is_globally_enabled:
		return
	if lights.is_empty():
		return
	_update_glitch_state(delta)
	_apply_light_modulation()

func _update_glitch_state(delta: float) -> void:
	if not glitch_enabled:
		return
	if is_glitching:
		_advance_glitch(delta)
		return
	_countdown_glitch(delta)

func _countdown_glitch(delta: float) -> void:
	glitch_timer -= delta
	if glitch_timer > 0.0:
		return
	_trigger_glitch()

func _trigger_glitch() -> void:
	is_glitching = true
	glitch_progress = 0.0
	glitch_duration = randf_range(0.09, 0.13)
	glitch_timer = randf_range(min_glitch_interval, max_glitch_interval)
	_emit_glitch_sparks()

func _emit_glitch_sparks() -> void:
	if not spark_particles:
		return
	if randf() > 0.5:
		return
	spark_particles.restart()

func _advance_glitch(delta: float) -> void:
	glitch_progress += delta
	if glitch_progress < glitch_duration:
		return
	is_glitching = false
	glitch_progress = 0.0

func _apply_light_modulation() -> void:
	var factor = _calculate_total_modulation_factor()
	for i in range(lights.size()):
		_update_single_light_energy(i, factor)

func _calculate_total_modulation_factor() -> float:
	var hum = _calculate_organic_hum()
	var dip = _calculate_glitch_dip()
	return clampf(1.0 + hum - dip, 0.2, 1.5)

func _calculate_organic_hum() -> float:
	var t = (Time.get_ticks_msec() / 1000.0) + phase_offset
	var wave1 = sin(t * hum_speed) * (hum_amplitude * 0.65)
	var wave2 = sin(t * (hum_speed * 1.83)) * (hum_amplitude * 0.35)
	return wave1 + wave2

func _calculate_glitch_dip() -> float:
	if not is_glitching:
		return 0.0
	var progress_ratio = glitch_progress / glitch_duration
	return sin(progress_ratio * PI) * 0.28

func _update_single_light_energy(index: int, factor: float) -> void:
	var light = lights[index]
	if not is_instance_valid(light):
		return
	var base = base_energies[index]
	light.energy = base * factor

static func toggle_global_flicker(tree: SceneTree) -> bool:
	is_globally_enabled = not is_globally_enabled
	_update_all_lights_in_tree(tree, is_globally_enabled)
	return is_globally_enabled

static func _update_all_lights_in_tree(tree: SceneTree, enabled: bool) -> void:
	if not tree:
		return
	var nodes = tree.get_nodes_in_group("flickering_lights")
	for node in nodes:
		_reset_flicker_node(node as FlickeringLight, enabled)

static func _reset_flicker_node(flicker: FlickeringLight, enabled: bool) -> void:
	if not flicker:
		return
	if enabled:
		return
	flicker._restore_base_energies()

func _restore_base_energies() -> void:
	for i in range(lights.size()):
		_restore_single_light(i)

func _restore_single_light(index: int) -> void:
	var light = lights[index]
	if not is_instance_valid(light):
		return
	light.energy = base_energies[index]
