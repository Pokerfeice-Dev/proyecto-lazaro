extends "res://Scripts/Projectiles/enemy_shooter_projectile.gd"
class_name PrometeoProjectile

## Bala de Prometeo (boss 3). Es la bala del enemigo disparador, pero con
## velocidad, color y persecución configurables para imitar cada arma del
## jugador (pistola, escopeta, uzi, minigun, colmena...).

var _energy_tail := PackedVector2Array()
var _tail_clock := 0.0

var homing_turn_rate: float = 0.0
var _homing_left: float = 0.0
var _homing_target: Node2D = null

## Se llama antes de agregarla a la escena (el lifetime se usa en _ready).
func configure(p_speed: float, tint: Color, p_lifetime: float = 4.0, turn_rate: float = 0.0, homing_time: float = 0.0) -> void:
	speed = p_speed
	lifetime = p_lifetime
	modulate = tint
	homing_turn_rate = turn_rate
	_homing_left = homing_time

func _ready() -> void:
	add_to_group("prometeo_bullet")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	super._ready()

func _physics_process(delta: float) -> void:
	_steer_towards_target(delta)
	super._physics_process(delta)
	_tail_clock -= delta
	if _tail_clock <= 0.0:
		_tail_clock = 0.025
		_energy_tail.append(global_position)
		if _energy_tail.size() > 7: _energy_tail.remove_at(0)
	queue_redraw()

# Las abejas de la colmena doblan un rato hacia el jugador y después siguen derecho.
func _steer_towards_target(delta: float) -> void:
	if _homing_left <= 0.0 or homing_turn_rate <= 0.0: return
	_homing_left -= delta
	if not _homing_target or not is_instance_valid(_homing_target):
		_homing_target = get_tree().get_first_node_in_group(target_group) as Node2D
		if not _homing_target: return
	var desired = (_homing_target.global_position - global_position).angle()
	var diff = wrapf(desired - direction.angle(), -PI, PI)
	var step = clampf(diff, -homing_turn_rate * delta, homing_turn_rate * delta)
	direction = direction.rotated(step)
	rotation = direction.angle()

## Se apaga sin explotar ni hacer daño (cambio de fase, muerte del boss).
func dissolve() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)

func _draw() -> void:
	if _exploding or _energy_tail.size() < 2: return
	for i in range(1, _energy_tail.size()):
		var strength := float(i) / float(_energy_tail.size())
		var a := to_local(_energy_tail[i - 1])
		var b := to_local(_energy_tail[i])
		draw_line(a, b, Color(1, 0.12, 0.25, strength * 0.65), 2.0 + strength * 4.0)
		draw_line(a, b, Color(0.06, 0.01, 0.04, strength), 1.0 + strength * 2.0)
