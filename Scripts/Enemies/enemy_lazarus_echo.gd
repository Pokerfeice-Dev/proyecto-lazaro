class_name EnemyLazarusEcho
extends Carpenter
# Eco de Lázaro (Área 3): sigue el rastro de donde estabas hace 1 s y dispara a
# esa posición vieja y, un instante después, dispara otra bala adelantada a hacia dónde te mueves.
# Sprite: las hojas de Lázaro con paleta espectral (Art/Enemies/Redesign/lazaro_echo_*.png).

@export_category("Eco de Lázaro")
@export var echo_delay: float = 1.0
@export var echo_health: int = 28
## El arte ya es espectral: el tinte solo lo vuelve un poco translúcido.
@export var ghost_tint: Color = Color(1.0, 1.0, 1.0, 0.85)

var _clock: float = 0.0
# Cada entrada es [tiempo, posición del jugador].
var _history: Array = []

func _ready() -> void:
	super._ready()
	fan_count = 1
	max_health = echo_health
	current_health = max_health
	_default_modulate = ghost_tint
	if anim_sprite: anim_sprite.modulate = ghost_tint

func process_movement(delta: float) -> void:
	_clock += delta
	_record_player_position()
	super.process_movement(delta)
	_follow_old_position()

func _record_player_position() -> void:
	if not is_instance_valid(target): return
	_history.append([_clock, target.global_position])
	# Se descarta lo que ya quedó más viejo que la ventana de retraso.
	while _history.size() > 2 and _history[1][0] <= _clock - echo_delay:
		_history.pop_front()

# Posición del jugador de hace `echo_delay` segundos.
func _delayed_player_position() -> Vector2:
	if _history.is_empty():
		return target.global_position if is_instance_valid(target) else global_position
	return _history[0][1]

# Al perseguir, va hacia donde estaba el jugador y no hacia donde está.
func _follow_old_position() -> void:
	if is_dying or current_state != State.CHASE or not has_detected_player: return
	var old_position := _delayed_player_position()
	if global_position.distance_to(old_position) < 24.0:
		velocity = Vector2.ZERO
		return
	var dir := global_position.direction_to(old_position)
	if _can_walk_segment(global_position, global_position + dir * 32.0):
		velocity = dir * move_speed

# Apunta a donde estabas hace 1 s.
func _aim_direction() -> Vector2:
	if not is_instance_valid(target): return Vector2.RIGHT
	return global_position.direction_to(_delayed_player_position())

# Primero la bala al lugar viejo y poco después otra adelantada a hacia dónde te mueves ahora:
# quedarse quieto o seguir en línea recta no alcanza, hay que cortar con el dash.
func _spawn_projectile(dir: Vector2) -> void:
	super._spawn_projectile(dir)
	get_tree().create_timer(0.35).timeout.connect(_spawn_lead_bullet, CONNECT_ONE_SHOT)

func _spawn_lead_bullet() -> void:
	if is_dying or not is_instance_valid(target): return
	_spawn_fan_bullet(lead_direction(global_position, shot_speed), false)
