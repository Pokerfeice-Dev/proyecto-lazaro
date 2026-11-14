class_name EnemyHollowTorso
extends Mecha
# Torso hueco (Área 3): tanque lento con el pecho abierto. Mientras el núcleo está
# expuesto recibe doble daño; se cierra cada tanto y entonces casi no lo lastiman.
# Sprite provisional (Mecha).

@export_category("Torso hueco")
@export var torso_speed: float = 55.0
@export var torso_health: int = 120
@export var open_time: float = 3.0
@export var closed_time: float = 2.0
@export var open_damage_multiplier: float = 2.0
@export var closed_damage_multiplier: float = 0.4
@export var core_radius: float = 8.0
@export var core_offset: Vector2 = Vector2(0, -6)
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

var _core_open: bool = true
var _core_time_left: float = 0.0
var _pulse: float = 0.0

func _ready() -> void:
	super._ready()
	charge_enabled = false
	move_speed = torso_speed
	max_health = torso_health
	current_health = max_health
	_core_time_left = open_time
	_default_modulate = body_tint
	var sprite := _get_sprite()
	if sprite: sprite.modulate = body_tint

func process_movement(delta: float) -> void:
	_pulse += delta
	_core_time_left -= delta
	if _core_time_left <= 0.0:
		_core_open = not _core_open
		_core_time_left = open_time if _core_open else closed_time
	super.process_movement(delta)
	queue_redraw()

func take_damage(amount: int, is_crit: bool = false) -> void:
	var multiplier := open_damage_multiplier if _core_open else closed_damage_multiplier
	super.take_damage(maxi(1, int(round(amount * multiplier))), is_crit)

func _draw() -> void:
	super._draw()
	if is_dying: return
	if _core_open:
		var glow := 0.75 + 0.25 * sin(_pulse * 8.0)
		draw_circle(core_offset, core_radius * 1.6, Color(1.0, 0.4, 0.1, 0.25 * glow))
		draw_circle(core_offset, core_radius, Color(1.0, 0.65, 0.2, 0.95 * glow))
	else:
		# Pecho cerrado: una placa tapa el hueco del sprite.
		draw_circle(core_offset, core_radius * 1.3, Color(0.42, 0.45, 0.55, 1.0))
		draw_arc(core_offset, core_radius * 1.3, 0.0, TAU, 20, Color(0.7, 0.75, 0.85, 1.0), 2.0)
		draw_line(core_offset + Vector2(-core_radius, 0.0), core_offset + Vector2(core_radius, 0.0), Color(0.2, 0.2, 0.28, 1.0), 1.5)

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()
