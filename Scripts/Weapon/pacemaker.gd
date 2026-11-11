extends MeleeWeaponBase
## El reloj comparte el tiempo de combate: pausa y cámara lenta mantienen el ritmo.
@export_category("Marcapasos · Ritmo")
@export var beat_period := 0.95
@export var timing_window := 0.18
@export var empowered_damage := 1.65
@export var contraction_damage := 2.2
@export var pressure_radius := 115.0
@export var contraction_radius := 180.0
@export var pulse_volume_db := -12.0
var chain := 0
var remaining := 0.0
var period := 0.95
var window := 0.18
var armed := false
var _cue_played := false
var _hit_multiplier := 1.0
var _finisher := false
var _feedback: Node2D
var _sound: AudioStreamPlayer2D
var _pilot: Node2D
var _swing: Tween
static var _sounds: Dictionary = {}

func _ready() -> void:
	super._ready()
	_pilot = _find_equip_owner() as Node2D
	_feedback = preload("res://Scripts/Effects/pacemaker_fx.gd").new()
	add_child(_feedback)
	_feedback.top_level = true
	_sound = AudioStreamPlayer2D.new()
	_sound.bus = "SFX"
	_sound.volume_db = pulse_volume_db
	add_child(_sound)
	for kind in ["beat", "good", "finish", "miss"]:
		if not _sounds.has(kind): _sounds[kind] = _synthesize(kind)

func _process(delta: float) -> void:
	if not is_instance_valid(_pilot): return
	if _pilot.get("is_dying") == true or _pilot.get("is_dead") == true:
		armed = false
		_feedback.hide()
		_sound.stop()
		return
	_feedback.global_position = _pilot.global_position
	if armed:
		remaining -= delta
		if remaining <= window and not _cue_played:
			_cue_played = true
			_play("beat")
		if remaining < -window:
			armed = false
			chain = 0
			_feedback.message("SIN PULSO", false)
			_play("miss")
	_feedback.set_rhythm(armed, remaining / period, window / period, chain)
	if melee_sprite:
		var pulse := 1.0 - clampf(absf(remaining) / window, 0.0, 1.0) if armed else 0.0
		melee_sprite.modulate = Color.WHITE.lerp(Color(1.5, 1.2, 0.65), pulse * 0.75)
		_feedback.head_position = melee_sprite.global_position

func attack() -> void:
	if _is_attacking: return
	var on_beat := armed and absf(remaining) <= window
	chain = chain + 1 if on_beat else 0
	_finisher = chain == 3
	_hit_multiplier = contraction_damage if _finisher else (empowered_damage if on_beat else 1.0)
	if _finisher: chain = 0
	var speed := attack_speed
	var reach := attack_range
	if is_instance_valid(_pilot):
		speed *= 1.0 + float(_pilot._get_equip_stat("attack_speed", false))
		reach = (reach + float(_pilot._get_equip_stat("attack_range", false))) * (1.0 + float(_pilot._get_equip_stat("attack_range_percent", false)))
	period = clampf(beat_period * 0.6 / maxf(speed, 0.1), 0.42, 1.6)
	window = minf(timing_window, period * 0.23)
	remaining = period
	armed = true
	_cue_played = false
	_is_attacking = true
	hit_enemies.clear()
	scale = Vector2.ONE * reach
	_play("finish" if _finisher else ("good" if on_beat else "beat"))
	_feedback.message("CONTRACCIÓN" if _finisher else ("SINCRONÍA %d/3" % chain if on_beat else "SEGUÍ EL PULSO"), on_beat)
	# Anticipación corta, golpe rápido y recuperación antes de abrir la ventana.
	var rest := deg_to_rad(sprite_rotation_offset)
	_swing = create_tween()
	_swing.tween_property(self, "rotation", rest + deg_to_rad(-45), period * 0.10)
	_swing.tween_callback(_impact.bind(on_beat))
	_swing.tween_property(self, "rotation", rest + deg_to_rad(110), period * 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_swing.tween_callback(_disable_slash_monitoring)
	_swing.tween_property(self, "rotation", rest, period * 0.25).set_trans(Tween.TRANS_SINE)
	_swing.tween_callback(_on_attack_finished)

func _impact(on_beat: bool) -> void:
	if slash_attack: slash_attack.monitoring = true
	_play_attack_fx()
	if not on_beat or not is_instance_valid(_pilot): return
	var direction := Vector2.RIGHT.rotated(get_parent().global_rotation)
	var center := _pilot.global_position + direction * 65.0
	var radius := contraction_radius if _finisher else pressure_radius
	_feedback.burst(center, radius, _finisher)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node2D: continue
		if enemy.get("is_dying") == true or not enemy.has_method("take_damage"): continue
		if center.distance_to(enemy.global_position) > radius: continue
		# La onda no atraviesa las paredes del escenario (capa 1).
		var query := PhysicsRayQueryParameters2D.create(_pilot.global_position, enemy.global_position, 1)
		if _pilot is CollisionObject2D: query.exclude = [_pilot.get_rid()]
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty(): continue
		hit_enemies.append(enemy)
		# Un único impacto por enemigo: evita sumar onda y colisión de la maza.
		super._apply_damage_to_enemy(enemy, _hit_multiplier)
		if _finisher and enemy.has_method("apply_knockback"):
			var pull: Vector2 = center - enemy.global_position
			enemy.apply_knockback(minf(420.0, pull.length() * 4.0), pull.normalized())
	if _pilot.has_method("apply_custom_camera_shake"):
		_pilot.apply_custom_camera_shake(2.5 if _finisher else 1.0, 0.10)

func _apply_damage_to_enemy(body: Node2D, damage_scale: float = 1.0) -> void:
	super._apply_damage_to_enemy(body, damage_scale * _hit_multiplier)

func _play(kind: String) -> void:
	_sound.stream = _sounds[kind]
	_sound.play()

static func _synthesize(kind: String) -> AudioStreamWAV:
	# PCM original: doble latido grave + telemetría; sin clips externos ni loops.
	var duration := 0.48 if kind == "finish" else 0.23
	var rate := 22050
	var data := PackedByteArray()
	data.resize(int(duration * rate) * 2)
	for i in range(int(duration * rate)):
		var t := float(i) / rate
		var envelope := exp(-t * 20.0) * minf(t * 800.0, 1.0)
		var value := sin(TAU * (68.0 * t + 2.0 * (1.0 - exp(-t * 25.0)))) * envelope * 0.55
		if t > 0.09:
			var second := t - 0.09
			value += sin(TAU * 92.0 * second) * exp(-second * 35.0) * minf(second * 800.0, 1.0) * 0.24
		var frequency := 880.0 if kind == "good" else (1320.0 if kind == "finish" else (220.0 if kind == "miss" else 660.0))
		value += sin(TAU * frequency * t) * envelope * 0.12
		if kind == "finish": value += sin(TAU * 43.0 * t) * exp(-t * 9.0) * minf(t * 500.0, 1.0) * 0.35
		data.encode_s16(i * 2, int(clampf(value, -0.95, 0.95) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
