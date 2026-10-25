extends MeleeWeaponBase
## Motor de sierra: carga, avance de dirección fija, cuatro pulsos y frenada.
enum Phase { IDLE, START, CUT, BRAKE }
@export_category("Audio del motor")
## Modula respecto al volumen/tono del nodo Motor. Desactivar para ajustes fijos.
@export var dynamic_motor_audio := true
@export_category("Escalado por velocidad de ataque")
## Cadencia base de Speeddemon, antes de equipo y sinergias.
@export var scaling_reference_rate: float = 2.0
## Ganancias por cada +100% de cadencia respecto a la referencia.
@export var reach_per_attack_speed: float = 0.15
@export var drive_per_attack_speed: float = 0.20
@export var damage_per_attack_speed: float = 0.25
## Limita el crecimiento adicional para mantener legibles los impactos.
@export var max_attack_speed_scaling: float = 4.0
var phase := Phase.IDLE
var drive_direction := Vector2.RIGHT
var drive_multiplier := 1.0
var drive_speed_multiplier := 1.0
var _phase_time := 0.0
var _cycle := 0.6
var _pulse_time := 0.0
var _pulses := 0
var _pulse_damage := 1.0
var _contact_time := 0.0
var _boost_time := 0.0
var _sprite_position := Vector2.ZERO
var _clock := 0.0
var _pilot: Node2D
var _motor: AudioStreamPlayer2D
var _contact_audio: AudioStreamPlayer2D
var _fx: Node2D
var _motor_base_volume := 0.0
var _motor_base_pitch := 1.0

func _ready() -> void:
	super._ready()
	_sprite_position = melee_sprite.position
	_motor = $Sounds/Motor
	_contact_audio = $Sounds/Cut
	_motor_base_volume = _motor.volume_db
	_motor_base_pitch = _motor.pitch_scale
	_motor.finished.connect(_repeat_motor)
	_contact_audio.finished.connect(_repeat_contact)
	_fx = preload("res://Scripts/Effects/speed_demon_fx.gd").new()
	add_child(_fx)
	if melee_sprite is AnimatedSprite2D: melee_sprite.speed_scale = 0.3

func _init_audio_player() -> void:
	audio_player = $Sounds/Start
	scale = Vector2.ONE * attack_range

func _repeat_motor() -> void:
	if phase == Phase.CUT: _motor.play()

func _repeat_contact() -> void:
	if phase == Phase.CUT and _contact_time > 0: _contact_audio.play()

func attack() -> void:
	if _is_attacking: return
	_pilot = _find_equip_owner() as Node2D
	if not _pilot or not _pilot.has_method("begin_speed_demon_drive"): return
	if _pilot.get("is_cutscene_frozen") == true or _pilot.get("is_dashing") == true: return
	if is_instance_valid(_pilot.get("_speed_demon_driver")): return
	drive_direction = (_pilot.get_aim_position() - _pilot.global_position).normalized()
	if drive_direction == Vector2.ZERO: drive_direction = Vector2.RIGHT
	_pilot._speed_demon_driver = self
	_motor_base_volume = _motor.volume_db
	_motor_base_pitch = _motor.pitch_scale
	var rate := maxf(0.1, attack_speed * (1 + _pilot._get_equip_stat("attack_speed", false)))
	var speed_bonus := clampf(rate / maxf(0.1, scaling_reference_rate) - 1.0, 0, maxf(0, max_attack_speed_scaling))
	drive_speed_multiplier = maxf(0.1, 1 + speed_bonus * drive_per_attack_speed)
	_cycle = clampf(2.4 / rate, 0.42, 0.9)
	_pulse_damage = rate * _cycle / 4.0 * maxf(0.1, 1 + speed_bonus * damage_per_attack_speed)
	var reach := maxf(0.2, (attack_range + _pilot._get_equip_stat("attack_range", false)) * (1 + _pilot._get_equip_stat("attack_range_percent", false)))
	scale = Vector2.ONE * reach * maxf(0.1, 1 + speed_bonus * reach_per_attack_speed)
	_is_attacking = true
	phase = Phase.START
	_phase_time = _cycle * 0.22
	_pulses = 0
	_contact_time = 0
	_boost_time = 0
	rotation = 0
	_play_accent("start")

func _physics_process(delta: float) -> void:
	_clock += delta
	if phase == Phase.IDLE: return
	if not is_instance_valid(_pilot) or _pilot.get("is_cutscene_frozen") == true or _pilot.get("is_dashing") == true or not is_visible_in_tree():
		cancel_drive()
		return
	_contact_time = maxf(0, _contact_time - delta)
	_boost_time = maxf(0, _boost_time - delta)
	drive_multiplier = 1.15 if _boost_time > 0 else (0.65 if _contact_time > 0 else 1.0)
	_phase_time -= delta
	if phase == Phase.START and _phase_time <= 0:
		phase = Phase.CUT
		_phase_time = _cycle * 0.56
		_pulse_time = 0
		slash_attack.monitoring = true
		_motor.play()
		_pilot.begin_speed_demon_drive(self, drive_direction, _phase_time)
	elif phase == Phase.CUT:
		_pulse_time -= delta
		if _pulse_time <= 0 and _pulses < 4:
			_pulses += 1
			_pulse_time += _cycle * 0.56 / 4
			_cut_overlapping_bodies()
		if _phase_time <= 0: _brake(false)
	elif phase == Phase.BRAKE and _phase_time <= 0:
		cancel_drive()
		return
	_update_motor_visuals()

func _update_motor_visuals() -> void:
	var power := 1.0 if phase == Phase.CUT else (0.45 if phase == Phase.START else clampf(_phase_time / (_cycle * 0.22), 0, 1))
	melee_sprite.position = _sprite_position + Vector2(sin(_clock * 125), cos(_clock * 97)) * power * (1.5 if _contact_time > 0 else 0.7)
	melee_sprite.modulate = Color.WHITE.lerp(Color(1.35, 1.12, 0.75), power * 0.5)
	if melee_sprite is AnimatedSprite2D: melee_sprite.speed_scale = 0.3 + power * 2.3
	_fx.power = power
	_fx.cutting = phase == Phase.CUT
	_fx.contact = _contact_time > 0
	if dynamic_motor_audio:
		_motor.pitch_scale = _motor_base_pitch * lerpf(0.85, 1.25, power) * (0.85 if _contact_time > 0 else 1.0) * (1.12 if _boost_time > 0 else 1.0)
		_motor.volume_db = _motor_base_volume - (1 - power) * 18
	if _contact_time <= 0: _contact_audio.stop()

func _cut_overlapping_bodies() -> void:
	if not slash_attack.monitoring: return
	for body in slash_attack.get_overlapping_bodies():
		if not is_instance_valid(body) or body.is_queued_for_deletion(): continue
		if body.is_in_group("player") or not body.has_method("take_damage") or body.get("is_dying") == true: continue
		var alive: bool = body.get("is_dying") != true
		var blade_tip := to_global(Vector2(30, -4))
		var contact_point := blade_tip.move_toward(body.global_position, minf(10, blade_tip.distance_to(body.global_position)))
		preload("res://Scripts/Effects/saw_contact_fx.gd").spawn(body, contact_point, drive_direction)
		_apply_damage_to_enemy(body, _pulse_damage)
		_contact_time = 0.10
		_fx.hit(to_local(contact_point), false)
		if _pilot.has_method("apply_custom_camera_shake"): _pilot.apply_custom_camera_shake(0.8, 0.045)
		if not _contact_audio.playing: _contact_audio.play()
		if alive and (not is_instance_valid(body) or body.is_queued_for_deletion() or body.get("is_dying") == true):
			_boost_time = 0.14
			_fx.hit(Vector2(28, -4), true)
			if _pilot.has_method("apply_custom_camera_shake"): _pilot.apply_custom_camera_shake(2.5, 0.08)

func _on_body_entered(_body: Node2D) -> void:
	pass # El daño se aplica solo en los cuatro pulsos de contacto.

func _apply_knockback_to_enemy(body: Node2D, force: float) -> void:
	super._apply_knockback_to_enemy(body, force * 0.15)

func brake_on_wall() -> void:
	if phase != Phase.CUT: return
	_fx.hit(Vector2(30, -4), true)
	if _pilot.has_method("apply_custom_camera_shake"): _pilot.apply_custom_camera_shake(4, 0.12)
	_brake(true)

func _brake(wall: bool) -> void:
	phase = Phase.BRAKE
	_phase_time = maxf(0.12, _cycle * 0.22)
	_disable_slash_monitoring()
	_contact_audio.stop()
	if is_instance_valid(_pilot): _pilot.end_speed_demon_drive(self)
	_play_accent("wall" if wall else "stop")

func _play_accent(sound: String) -> void:
	for sound_node_name in ["Start", "Stop", "Wall"]:
		var audio := get_node("Sounds/" + sound_node_name) as AudioStreamPlayer2D
		audio.stop()
		if sound_node_name.to_lower() == sound: audio.play()

func cancel_drive() -> void:
	phase = Phase.IDLE
	_is_attacking = false
	_disable_slash_monitoring()
	_motor.stop()
	_contact_audio.stop()
	for sound_node_name in ["Start", "Stop", "Wall"]: get_node("Sounds/" + sound_node_name).stop()
	_motor.volume_db = _motor_base_volume
	_motor.pitch_scale = _motor_base_pitch
	_fx.power = 0
	_fx.cutting = false
	_fx.contact = false
	melee_sprite.position = _sprite_position
	melee_sprite.modulate = Color.WHITE
	if melee_sprite is AnimatedSprite2D: melee_sprite.speed_scale = 0.3
	if is_instance_valid(_pilot):
		_pilot.end_speed_demon_drive(self)
		if _pilot._speed_demon_driver == self: _pilot._speed_demon_driver = null

func _exit_tree() -> void:
	if is_instance_valid(_pilot):
		_pilot.end_speed_demon_drive(self)
		if _pilot._speed_demon_driver == self: _pilot._speed_demon_driver = null
