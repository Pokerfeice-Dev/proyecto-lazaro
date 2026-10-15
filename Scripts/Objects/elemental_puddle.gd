extends Area2D
class_name ElementalPuddle

# Charco elemental temporal (Fuego / Hielo) generado por la explosión de barriles.
# El arte (mancha pixel y partículas) está en PuddleVisuals.
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
## Cada cuánto sale una llamarada del charco de fuego (al azar entre estos valores).
const FLAME_BURST_EVERY := Vector2(0.45, 1.1)
const FLAME_BURST_TIME: float = 0.45

var _burn_tick_timer: float = 0.0
var _overlapping_bodies: Array[Node2D] = []
var _light_node: PointLight2D = null
var _sprite: Sprite2D = null
var _flame_timer: float = 0.4
var _time: float = 0.0

func setup(type: PuddleType, at_position: Vector2) -> void:
	puddle_type = type
	global_position = at_position

func _ready() -> void:
	_setup_area_properties()
	_setup_collision_shape()
	_setup_sprite()
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


# Mancha pixel art (ver PuddleVisuals); cada charco sale un poco distinto.
func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = PuddleVisuals.build_texture(puddle_type == PuddleType.FIRE, randi())
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(PuddleVisuals.PIXEL, PuddleVisuals.PIXEL)
	_sprite.z_as_relative = false
	_sprite.z_index = 1
	add_child(_sprite)

func _setup_particles() -> void:
	if puddle_type == PuddleType.FIRE:
		add_child(PuddleVisuals.fire_smoke())
		add_child(PuddleVisuals.fire_embers())
		return
	add_child(PuddleVisuals.ice_mist())
	add_child(PuddleVisuals.ice_glints())

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

func _process(delta: float) -> void:
	_time += delta
	if puddle_type == PuddleType.FIRE:
		_flicker()
		_update_flame_bursts(delta)
	else:
		_shimmer()

# El fuego titila: brillo y luz suben y bajan sin ritmo fijo.
func _flicker() -> void:
	var k = 0.5 + 0.25 * sin(_time * 9.0) + 0.25 * sin(_time * 23.0 + 1.3)
	_sprite.self_modulate = Color(1.0 + 0.1 * k, 1.0 + 0.04 * k, 1.0)
	if _light_node:
		_light_node.texture_scale = 1.1 + 0.1 * k

# El hielo brilla muy suave, como reflejo.
func _shimmer() -> void:
	var k = 0.5 + 0.5 * sin(_time * 2.2)
	_sprite.self_modulate = Color(1.0 + 0.08 * k, 1.0 + 0.08 * k, 1.0 + 0.1 * k)

# Cada tanto sale una llamarada corta (la del lanzallamas) desde un punto del charco.
func _update_flame_bursts(delta: float) -> void:
	_flame_timer -= delta
	if _flame_timer > 0.0: return
	_flame_timer = randf_range(FLAME_BURST_EVERY.x, FLAME_BURST_EVERY.y)
	# a veces salen dos juntas
	for i in (2 if randf() < 0.35 else 1):
		_spawn_flame_burst()

func _spawn_flame_burst() -> void:
	var flame = PuddleVisuals.flame_burst()
	var a = randf_range(0.0, TAU)
	flame.position = Vector2(cos(a) * 22.0, sin(a) * 14.0) * sqrt(randf())
	add_child(flame)
	flame.emitting = true
	var t = flame.create_tween()
	t.tween_interval(FLAME_BURST_TIME)
	t.tween_property(flame, "emitting", false, 0.0)
	t.tween_interval(flame.lifetime + 0.1)
	t.tween_callback(flame.queue_free)

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
