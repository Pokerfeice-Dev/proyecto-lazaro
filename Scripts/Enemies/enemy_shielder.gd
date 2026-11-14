class_name EnemyShielder
extends EnemyFollower
# Escudero: no ataca. Avanza lento con un escudo al frente que bloquea el daño
# mientras el jugador esté de ese lado. El escudo gira despacio: hay que rodearlo.

@export_category("Escudero")
@export var shielder_speed: float = 70.0
@export var shielder_health: int = 72
@export var shield_arc_degrees: float = 140.0
## Qué tan rápido gira el escudo hacia el jugador (rad/s).
@export var shield_turn_rate: float = 1.4
@export var shield_radius: float = 24.0
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

var _shield_dir: Vector2 = Vector2.RIGHT
var _shield_flash: float = 0.0

func _ready() -> void:
	super._ready()
	lunge_enabled = false
	move_speed = shielder_speed
	max_health = shielder_health
	current_health = max_health
	_default_modulate = body_tint
	if anim_sprite: anim_sprite.modulate = body_tint

# No ataca: su función es bloquear el paso y los disparos.
func _on_attack_timer_timeout() -> void:
	pass

func process_movement(delta: float) -> void:
	_shield_flash = maxf(0.0, _shield_flash - delta)
	if is_instance_valid(target) and not is_dying:
		var wanted := global_position.direction_to(target.global_position).angle()
		var diff := wrapf(wanted - _shield_dir.angle(), -PI, PI)
		var step := clampf(diff, -shield_turn_rate * delta, shield_turn_rate * delta)
		_shield_dir = _shield_dir.rotated(step)
	super.process_movement(delta)
	queue_redraw()

func take_damage(amount: int, is_crit: bool = false) -> void:
	if _is_shielded_from_target():
		_shield_flash = 0.15
		return
	super.take_damage(amount, is_crit)

# El jugador cuenta como atacante: si está dentro del arco del escudo, no hay daño.
func _is_shielded_from_target() -> bool:
	if is_dying or not is_instance_valid(target): return false
	var to_player := global_position.direction_to(target.global_position)
	return _shield_dir.dot(to_player) >= cos(deg_to_rad(shield_arc_degrees * 0.5))

func _draw() -> void:
	if is_dying: return
	var half_arc := deg_to_rad(shield_arc_degrees * 0.5)
	var color := Color(1.0, 1.0, 1.0, 1.0) if _shield_flash > 0.0 else Color(0.55, 0.85, 1.0, 0.9)
	var angle := _shield_dir.angle()
	draw_arc(Vector2.ZERO, shield_radius, angle - half_arc, angle + half_arc, 20, color, 3.0)

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()
