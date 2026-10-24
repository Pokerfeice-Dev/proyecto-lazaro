extends EnemyBase
class_name Boss1

@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")
@export var airstrike_scene: PackedScene = preload("res://Scenes/Enemies/BossAirstrike.tscn")

@export_group("Boss Base Stats")
@export var boss_max_health: int = 1000
@export var boss_damage: int = 15

@export_group("Boss Laser Settings")
@export var laser_sweep_base_speed: float = 1.2
@export var laser_damage_tick_rate: float = 0.15
## Aviso fijo antes del barrido; nunca causa daño durante la carga.
@export_range(0.35, 1.5, 0.05) var laser_charge_duration: float = 0.75
@export var laser_volume_db: float = -11.0

@export_group("Boss Pattern Settings")
@export var time_between_patterns: float = 4.0
@export var projectile_ring_count: int = 24

@onready var muzzle_left: Marker2D = $Muzzle_left
@onready var muzzle_right: Marker2D = $Muzzle_right
@onready var muzzle_center: Marker2D = $Muzzle_center
@onready var roar_invoc: AudioStreamPlayer2D = get_node_or_null("Roar_invoc")
@onready var bullet_sound: AudioStreamPlayer2D = get_node_or_null("Bullet_sound")
@onready var laser_sound: AudioStreamPlayer2D = get_node_or_null("Laser_sound")

# Laser nodes
var left_raycast: RayCast2D
var right_raycast: RayCast2D
var left_laser_line: BossLaserFX
var right_laser_line: BossLaserFX

# Attack states
var pattern_timer: Timer
var is_laser_active: bool = false
var laser_angle: float = PI / 2 # straight down (90 deg)
var laser_sweep_speed: float = 1.2
var laser_sweep_dir: float = 1.0
var laser_damage_cooldown: float = 0.0
var _laser_charge_left := 0.0
var _laser_firing := false
var _laser_charge_audio: AudioStreamPlayer2D
var _laser_accent_audio: AudioStreamPlayer2D
var _laser_audio_tween: Tween
var _laser_node_volume_db := 0.0

const BOSS_NAME := "Centinela Génesis"
const EMERGE_SHADER := preload("res://Art/Effects/emerge_clip.gdshader")
const EMERGE_TIME := 2.0
const PHASE_TWO_TITLE := "PROTOCOLO ÓMEGA"
const PHASE_TWO_SUBTITLE := "REPARACIÓN DE EMERGENCIA +20%"
const PHASE_TWO_RATIO := 0.5

var healthbar_instance: BossHealthBar = null
var boss_health_bar_node: Range = null
var is_phase_two: bool = false
var is_transitioning_phase: bool = false
var phase_two_attack_step: int = 0
var pattern_execute_count: int = 0
var spawned_minions: Array[Node2D] = []
var roar_player: AudioStreamPlayer2D = null

func _ready() -> void:
	super._ready()
	has_footstep_fx = false
	damage = boss_damage
	move_speed = 0.0 # Stationary boss
	laser_sweep_speed = laser_sweep_base_speed
	
	_init_boss_phase_state()
	_setup_lasers()
	_setup_pattern_timer()
	if not is_phase_two:
		add_to_group("boss_entrance") # el HUD no muestra el cartel de sala: lo hace el jefe
	_start_entrance.call_deferred()
	_assign_sfx_bus()

# manda todos los sonidos del boss al bus de efectos
func _assign_sfx_bus() -> void:
	if roar_invoc: roar_invoc.bus = "SFX"
	if bullet_sound: bullet_sound.bus = "SFX"
	if laser_sound: laser_sound.bus = "SFX"

func _init_boss_phase_state() -> void:
	if GameData.boss_fight_phase == 2:
		is_phase_two = true
		max_health = GameData.boss_persisted_max_health if GameData.boss_persisted_max_health > 0 else boss_max_health
		current_health = GameData.boss_persisted_health if GameData.boss_persisted_health > 0 else int(float(max_health) * 0.50)
		set_physics_process(false)
		_start_phase_two_cinematic.call_deferred()
	else:
		is_phase_two = false
		max_health = boss_max_health
		current_health = max_health

func _start_phase_two_cinematic() -> void:
	var player = get_tree().get_first_node_in_group("player")
	_freeze_player_completely(player)
	_ensure_boss_music_playing()
	
	var cinema_layer = CanvasLayer.new()
	cinema_layer.layer = 10
	get_tree().current_scene.add_child(cinema_layer)
	# cartel de fase animado (BossPhaseBanner), igual en los tres jefes
	BossPhaseBanner.show_phase(get_tree(), 2, PHASE_TWO_TITLE, PHASE_TWO_SUBTITLE)
	var camera = get_viewport().get_camera_2d()
	_run_cinematic_timeline(cinema_layer, player, camera)

func _freeze_player_completely(player: Node) -> void:
	if not player or not is_instance_valid(player): return
	if player.has_method("freeze_player"):
		player.freeze_player()
	else:
		player.set_physics_process(false)
		player.set_process(false)
		if "velocity" in player:
			player.velocity = Vector2.ZERO
		if "can_shoot" in player:
			player.can_shoot = false

func _unfreeze_player_completely(player: Node) -> void:
	if not player or not is_instance_valid(player): return
	if player.has_method("unfreeze_player"):
		player.unfreeze_player()
	else:
		player.set_physics_process(true)
		player.set_process(true)
		if "can_shoot" in player:
			player.can_shoot = true

func _ensure_boss_music_playing() -> void:
	var music = get_tree().current_scene.get_node_or_null("Boss_Fight_Music")
	if music and not music.playing:
		music.play()

func _run_cinematic_timeline(cinema_layer: CanvasLayer, player: Node, camera: Camera2D) -> void:
	var t_seq = create_tween()
	# 1s: entra el cartel de fase
	t_seq.tween_interval(1.0)
	
	# 1s: Camera zooms in to boss
	t_seq.tween_callback(_zoom_camera_to_boss.bind(camera, 1.0))
	t_seq.tween_interval(1.0)
	
	# 2s: Boss roars, heals +20% HP, healing particles spawn
	t_seq.tween_callback(_trigger_healing_phase_effects.bind(player))
	t_seq.tween_interval(2.0)
	
	# 1s: Camera zooms back out
	t_seq.tween_callback(_zoom_camera_to_player.bind(camera, 1.0))
	t_seq.tween_interval(1.0)
	
	# 1s: margen antes de devolver el control
	t_seq.tween_interval(1.0)
	
	# Finish & start fight
	t_seq.tween_callback(_finish_cinematic_and_start_fight.bind(cinema_layer, player))

# El zoom es relativo al de la pelea (la cámara del jugador no está en 1x), así
# no se aleja de más ni queda distinta al terminar la cinemática.
var _camera_rest_zoom: Vector2 = Vector2.ONE
var _camera_rest_offset: Vector2 = Vector2.ZERO

func _zoom_camera_to_boss(camera: Camera2D, duration: float) -> void:
	if not camera: return
	_camera_rest_zoom = camera.zoom
	_camera_rest_offset = camera.position
	var target_offset = global_position - camera.get_parent().global_position
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", _camera_rest_zoom * 1.25, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "position", target_offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _zoom_camera_to_player(camera: Camera2D, duration: float) -> void:
	if not camera: return
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", _camera_rest_zoom, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "position", _camera_rest_offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _trigger_healing_phase_effects(player: Node) -> void:
	_play_spawn_roar()
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(16.0, 2.0)
	_animate_boss_healing_visuals()
	var particles = _create_healing_particles()
	_animate_healthbar_healing(particles)

func _create_healing_particles() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 1.6
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 55.0
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.gravity = Vector2(0, -80)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.2, 1.0, 0.5, 0.9))
	gradient.set_color(1, Color(0.1, 0.8, 1.0, 0.0))
	particles.color_ramp = gradient
	
	add_child(particles)
	particles.position = Vector2.ZERO
	return particles

func _animate_boss_healing_visuals() -> void:
	var sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node: return
	var t = create_tween()
	t.tween_property(sprite_node, "modulate", Color(2.0, 0.3, 0.3), 0.3)
	t.tween_property(sprite_node, "modulate", Color(0.3, 1.8, 0.6), 0.9)
	t.tween_property(sprite_node, "modulate", Color(1.0, 1.0, 1.0), 0.8)

func _animate_healthbar_healing(particles: CPUParticles2D) -> void:
	var start_hp = current_health
	var target_hp = mini(max_health, current_health + int(float(max_health) * 0.20))
	
	var t_heal = create_tween()
	t_heal.tween_method(_update_healing_step, float(start_hp), float(target_hp), 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_heal.tween_interval(0.2)
	if particles:
		t_heal.tween_callback(particles.queue_free)

func _update_healing_step(val: float) -> void:
	current_health = int(val)
	if boss_health_bar_node:
		boss_health_bar_node.value = current_health

func _finish_cinematic_and_start_fight(cinema_layer: CanvasLayer, player: Node) -> void:
	if cinema_layer and is_instance_valid(cinema_layer):
		cinema_layer.queue_free()
	_unfreeze_player_completely(player)
	set_physics_process(true)
	_apply_phase_two_buffs()

func _setup_lasers() -> void:
	left_raycast = RayCast2D.new()
	right_raycast = RayCast2D.new()
	for ray in [left_raycast, right_raycast]:
		ray.collision_mask = 1 | 4 # Jugador y paredes.
		ray.collide_with_areas = false
		ray.collide_with_bodies = true
		add_child(ray)
	left_laser_line = BossLaserFX.new()
	right_laser_line = BossLaserFX.new()
	add_child(left_laser_line)
	add_child(right_laser_line)
	_setup_laser_audio()

func _setup_pattern_timer() -> void:
	pattern_timer = Timer.new()
	pattern_timer.wait_time = time_between_patterns
	pattern_timer.one_shot = false
	pattern_timer.autostart = true
	pattern_timer.timeout.connect(_on_pattern_timeout)
	add_child(pattern_timer)

# Entrada: cinemática (BossIntro) con el título que se convierte en la barra.
# En la fase 2 (otra sala, con su propia cinemática) la barra entra directo.
func _start_entrance() -> void:
	if is_phase_two:
		_connect_to_hud(false)
		return
	var intro = BossIntro.new()
	add_child(intro)
	intro.roared.connect(_connect_to_hud)
	await intro.play(self, 0.6)
	if not is_dying:
		_connect_to_hud()

# --- Aparición: el Centinela sale de la pared ---
# Se abre una grieta roja en la pared, el cuerpo baja recortado por esa línea
# (shader emerge_clip) entre polvo y chispas, y al final se le prenden los ojos.

var _emerge_sprite: Sprite2D
var _emerge_base_y := 0.0
var _emerge_material: Material
var _eye_energy: Dictionary = {}

func _intro_prepare() -> void:
	_emerge_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if not _emerge_sprite: return
	_emerge_base_y = _emerge_sprite.position.y
	_emerge_material = _emerge_sprite.material
	var mat = ShaderMaterial.new()
	mat.shader = EMERGE_SHADER
	_emerge_sprite.material = mat
	_set_emerge(_emerge_height())
	_set_emerge_shade(0.85)
	for light in [get_node_or_null("PointLight2D"), get_node_or_null("PointLight2D2")]:
		if light:
			_eye_energy[light] = light.energy
			light.energy = 0.0
	var shadow = get_node_or_null("DropShadow") as CanvasItem
	if shadow: shadow.self_modulate.a = 0.0

func _intro_appear() -> void:
	if not _emerge_sprite: return
	var wall_y = _emerge_base_y + _emerge_sprite.get_rect().position.y * _emerge_sprite.scale.y
	var width = _emerge_sprite.get_rect().size.x * _emerge_sprite.scale.x
	var crack = _make_wall_crack(wall_y, width)
	var dust = _make_wall_dust(wall_y, width)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(6.0, EMERGE_TIME + 0.4)
	SceneTransition.play_teleport_sound()
	var t = create_tween()
	t.tween_property(crack, "scale:x", 1.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(_set_particles_emitting.bind(dust, true))
	t.tween_method(_set_emerge, _emerge_height(), 0.0, EMERGE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_method(_set_emerge_shade, 0.85, 0.0, EMERGE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_finish_intro_emerge.bind(dust, wall_y, width))
	t.tween_property(crack, "modulate:a", 0.0, 0.4)
	await t.finished
	crack.queue_free()
	get_tree().create_timer(1.5, false).timeout.connect(dust.queue_free)
	_emerge_sprite.material = _emerge_material
	_light_up_eyes()

func _set_particles_emitting(particles: CPUParticles2D, enabled: bool) -> void:
	if is_instance_valid(particles):
		particles.emitting = enabled

func _finish_intro_emerge(particles: CPUParticles2D, wall_y: float, width: float) -> void:
	_set_particles_emitting(particles, false)
	_burst_wall_debris(wall_y, width)

# Sale como una silueta oscura que se va aclarando.
func _set_emerge_shade(value: float) -> void:
	var mat = _emerge_sprite.material as ShaderMaterial
	if mat: mat.set_shader_parameter("shade", value)

# Al terminar de salir, escombros que saltan de la pared.
func _burst_wall_debris(wall_y: float, width: float) -> void:
	var p = _make_wall_dust(wall_y, width)
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 40
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 200.0
	p.spread = 70.0
	p.emitting = true
	p.finished.connect(p.queue_free)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(14.0, 0.4)

func _emerge_height() -> float:
	return _emerge_sprite.get_rect().size.y * _emerge_sprite.scale.y

# rise = cuánto le falta salir (en píxeles de pantalla del mundo).
func _set_emerge(rise: float) -> void:
	_emerge_sprite.position.y = _emerge_base_y - rise
	var mat = _emerge_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("cutoff", _emerge_sprite.get_rect().position.y + rise / _emerge_sprite.scale.y)

func _make_wall_crack(wall_y: float, width: float) -> Line2D:
	var crack = Line2D.new()
	crack.points = PackedVector2Array([Vector2(-width / 2.0, 0), Vector2(width / 2.0, 0)])
	crack.width = 5.0
	crack.default_color = Color(1.0, 0.3, 0.2, 0.9)
	crack.position = Vector2(0, wall_y)
	crack.scale.x = 0.0
	crack.z_index = 1
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	crack.material = mat
	add_child(crack)
	return crack

func _make_wall_dust(wall_y: float, width: float) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.emitting = false
	p.amount = 46
	p.lifetime = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width / 2.0, 2.0)
	p.direction = Vector2(0, 1)
	p.spread = 35.0
	p.gravity = Vector2(0, 160)
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var g = Gradient.new()
	g.set_color(0, Color(0.75, 0.72, 0.7, 0.9))
	g.set_color(1, Color(0.4, 0.38, 0.36, 0.0))
	g.add_point(0.15, Color(1.0, 0.5, 0.3, 1.0))
	p.color_ramp = g
	p.position = Vector2(0, wall_y)
	p.z_index = 2
	add_child(p)
	return p

# Los ojos titilan y se prenden.
func _light_up_eyes() -> void:
	for light in _eye_energy:
		var e = _eye_energy[light]
		var t = create_tween()
		t.tween_property(light, "energy", e * 1.8, 0.08)
		t.tween_property(light, "energy", e * 0.2, 0.08)
		t.tween_property(light, "energy", e * 1.4, 0.1)
		t.tween_property(light, "energy", e, 0.3)
	var shadow = get_node_or_null("DropShadow") as CanvasItem
	if shadow: create_tween().tween_property(shadow, "self_modulate:a", 1.0, 0.4)

# Lo llama BossIntro cuando la cámara llega al jefe.
func _intro_roar() -> void:
	_play_spawn_roar()
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1.8, 0.6, 0.6), 0.15)
	t.tween_property(self, "modulate", Color.WHITE, 0.8)

func _connect_to_hud(with_intro: bool = true) -> void:
	if healthbar_instance and is_instance_valid(healthbar_instance): return
	var created = BossBarHelper.create(get_tree(), BOSS_NAME, max_health, current_health, {"intro": with_intro, "phase_marks": [PHASE_TWO_RATIO]})
	healthbar_instance = created.get("instance")
	boss_health_bar_node = created.get("bar")

func _setup_health_bar() -> void:
	pass # Overridden to prevent creating the small overhead health bar

func apply_knockback(_force: float, _direction: Vector2) -> void:
	pass # Stationary boss does not move

func process_movement(_delta: float) -> void:
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if is_dying: return
	_process_laser_logic(delta)

func _process_laser_logic(delta: float) -> void:
	laser_damage_cooldown = maxf(0.0, laser_damage_cooldown - delta)
	if not is_laser_active: return
	if _laser_charge_left > 0.0:
		_laser_charge_left = maxf(0.0, _laser_charge_left - delta)
		if _laser_charge_left <= 0.0:
			_ignite_lasers()
	elif _laser_firing:
		_update_laser_angle(delta)
	_update_laser_beam(left_raycast, left_laser_line, muzzle_left.position, laser_angle, delta)
	_update_laser_beam(right_raycast, right_laser_line, muzzle_right.position, laser_angle, delta)

func _update_laser_angle(delta: float) -> void:
	laser_angle += laser_sweep_speed * laser_sweep_dir * delta
	# Sweep between 45 and 135 degrees (PI/4 and 3*PI/4)
	if laser_angle >= 3 * PI / 4:
		laser_sweep_dir = -1.0
		laser_angle = 3 * PI / 4
	elif laser_angle <= PI / 4:
		laser_sweep_dir = 1.0
		laser_angle = PI / 4

func _update_laser_beam(ray: RayCast2D, line: BossLaserFX, muzzle_local_pos: Vector2, angle: float, delta: float) -> void:
	var dir = Vector2.from_angle(angle)
	ray.position = muzzle_local_pos
	ray.target_position = dir * 1000.0
	
	_perform_raycast_shifting(ray, muzzle_local_pos, dir)
	
	var local_col_point = muzzle_local_pos + dir * 1000.0
	if ray.is_colliding():
		var global_col = ray.get_collision_point()
		local_col_point = to_local(global_col)
		if _laser_firing:
			_check_laser_damage(ray.get_collider(), delta)
		
	# Restore raycast state
	ray.position = muzzle_local_pos
	ray.target_position = dir * 1000.0
	
	var normal: Vector2 = ray.get_collision_normal() if ray.is_colliding() else -dir
	line.update_beam(muzzle_local_pos, local_col_point, 1.0 - _laser_charge_left / maxf(laser_charge_duration, 0.01), _laser_firing, ray.is_colliding(), normal.rotated(-global_rotation))

func _perform_raycast_shifting(ray: RayCast2D, muzzle_local_pos: Vector2, dir: Vector2) -> void:
	var max_steps = 10
	var current_step = 0
	ray.force_raycast_update()
	while ray.is_colliding() and current_step < max_steps:
		var collider = ray.get_collider()
		if not collider or not collider.is_in_group("projectile_pass"):
			break
		
		# Shift start point past the collision point along direction
		var col_point = ray.get_collision_point()
		var local_col = to_local(col_point)
		ray.position = local_col + dir * 1.0
		ray.target_position = (muzzle_local_pos + dir * 1000.0) - ray.position
		ray.force_raycast_update()
		current_step += 1

func _check_laser_damage(collider: Object, _delta: float) -> void:
	if not _laser_firing or laser_damage_cooldown > 0.0: return
		
	if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
		var tick_damage = maxi(1, int(float(damage) / 3.0))
		collider.take_damage(tick_damage, BOSS_NAME, global_position)
		var base_cooldown = laser_damage_tick_rate
		laser_damage_cooldown = base_cooldown / 1.5 if is_phase_two else base_cooldown

func _on_pattern_timeout() -> void:
	if is_dying or is_transitioning_phase: return
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("is_cutscene_frozen") == true: return
	_toggle_attack_pattern()
	_update_spawn_counter()

func _toggle_attack_pattern() -> void:
	if is_phase_two:
		_execute_phase_two_pattern()
	else:
		_execute_phase_one_pattern()

func _execute_phase_one_pattern() -> void:
	is_laser_active = not is_laser_active
	_update_laser_audio_state()
	if not is_laser_active:
		_fire_ring_pattern()

func _execute_phase_two_pattern() -> void:
	phase_two_attack_step = (phase_two_attack_step + 1) % 3
	
	if is_laser_active and phase_two_attack_step != 0:
		is_laser_active = false
		_update_laser_audio_state()
		left_laser_line.stop()
		right_laser_line.stop()
	
	if phase_two_attack_step == 0:
		is_laser_active = true
		_update_laser_audio_state()
	elif phase_two_attack_step == 1:
		_fire_ring_pattern()
	elif phase_two_attack_step == 2:
		_fire_missile_barrage()

func _fire_ring_pattern() -> void:
	if bullet_sound:
		bullet_sound.play()
	var bullet_count = projectile_ring_count
	var angle_step = (2 * PI) / bullet_count
	for i in range(bullet_count):
		var spawn_angle = i * angle_step
		_spawn_projectile_at_angle(muzzle_center.global_position, spawn_angle)

func _fire_missile_barrage() -> void:
	if bullet_sound:
		bullet_sound.play()
	var missile_count = 3
	for i in range(missile_count):
		var delay = i * 0.35
		get_tree().create_timer(delay).timeout.connect(_spawn_single_missile_strike)

func _spawn_single_missile_strike() -> void:
	if is_dying: return
	if not airstrike_scene: return
	var player = get_tree().get_first_node_in_group("player")
	var target_pos = global_position + Vector2(randf_range(-200, 200), randf_range(100, 300))
	if player and is_instance_valid(player):
		target_pos = player.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
	var strike = airstrike_scene.instantiate()
	strike.global_position = target_pos
	strike.damage = int(float(damage) * 1.2)
	get_tree().current_scene.add_child(strike)

func _spawn_projectile_at_angle(pos: Vector2, angle: float) -> void:
	if not projectile_scene: return
	var proj = projectile_scene.instantiate()
	proj.source_name = BOSS_NAME
	get_tree().current_scene.add_child(proj)
	proj.global_position = pos
	var base_dir = Vector2.from_angle(angle)
	proj.setup(base_dir, damage, "player")
	if is_phase_two and "speed" in proj:
		proj.speed = proj.speed * 1.25
	if proj.has_method("enable_boss_comet"):
		proj.enable_boss_comet(is_phase_two)

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_transitioning_phase: return
	super.take_damage(amount, is_crit)
	_update_hud_health()
	_check_phase_transition()

func _check_phase_transition() -> void:
	if is_phase_two: return
	if is_dying: return
	if is_transitioning_phase: return
	
	var threshold = float(max_health) * PHASE_TWO_RATIO
	if float(current_health) <= threshold:
		_trigger_phase_two_teleport()

func _trigger_phase_two_teleport() -> void:
	is_transitioning_phase = true
	set_physics_process(false)
	if pattern_timer:
		pattern_timer.stop()
	if is_laser_active:
		is_laser_active = false
		_update_laser_audio_state()
		left_laser_line.stop()
		right_laser_line.stop()
	
	GameData.boss_fight_phase = 2
	GameData.boss_persisted_max_health = max_health
	GameData.boss_persisted_health = current_health
	
	_play_rage_effects()
	
	var t = create_tween()
	t.tween_interval(1.4)
	t.tween_callback(_change_to_phase_two_room)

func _play_rage_effects() -> void:
	_play_spawn_roar()
	SceneTransition.play_teleport_sound()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(20.0, 1.4)

func _change_to_phase_two_room() -> void:
	SceneTransition.change_scene("res://Scenes/Rooms/Level1_Room16-BossFight.tscn")

func _apply_phase_two_buffs() -> void:
	laser_sweep_speed = laser_sweep_base_speed * 1.5
	if pattern_timer:
		pattern_timer.wait_time = time_between_patterns / 1.5
		pattern_timer.start()

func _update_hud_health() -> void:
	if boss_health_bar_node:
		var t = create_tween()
		var target_val = maxi(0, current_health)
		t.tween_property(boss_health_bar_node, "value", float(target_val), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func die() -> void:
	if is_dying:
		return
	is_dying = true
	_disable_physics()
	if pattern_timer: pattern_timer.stop()
	is_laser_active = false
	if left_laser_line: left_laser_line.hide()
	if right_laser_line: right_laser_line.hide()
	_stop_all_boss_sounds()
	var body = _get_sprite()
	if body is AnimatedSprite2D: body.stop()
	var death_tween := create_tween()
	for i in 5:
		death_tween.tween_callback(_death_small_blast)
		if body:
			death_tween.tween_property(body, "modulate", Color(2.0, 0.7, 0.35), 0.07)
			death_tween.tween_property(body, "modulate", Color.WHITE, 0.16)
		else:
			death_tween.tween_interval(0.23)
	death_tween.tween_interval(0.25)
	death_tween.tween_callback(_finish_dramatic_death)

func _death_small_blast() -> void:
	_spawn_death_blast(Vector2(randf_range(-45, 45), randf_range(-60, 15)), 0.55)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(4.0, 0.18)

func _spawn_death_blast(offset: Vector2, power: float) -> void:
	var blast = preload("res://Scripts/Effects/boss_death_blast.gd").new()
	blast.position = global_position + offset
	blast.strength = power
	get_tree().current_scene.add_child(blast)

func _finish_dramatic_death() -> void:
	_spawn_death_blast(Vector2(0, -25), 1.8)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(16.0, 0.65)
	# La muerte base entrega recompensas y avisa a la sala recién al explotar.
	is_dying = false
	super.die()
	# Los efectos ya viven en la sala: el cuerpo no debe persistir esperando audio.
	hide()
	GameData.reset_boss_state()
	_hide_hud_health()
	_stop_all_boss_sounds()
	if GameData.is_event_build() or GameData.is_event_demo():
		GameData.finish_first_boss_demo.call_deferred()

func _hide_hud_health() -> void:
	if healthbar_instance and is_instance_valid(healthbar_instance):
		healthbar_instance.close()
		healthbar_instance = null
		boss_health_bar_node = null

func _update_spawn_counter() -> void:
	pattern_execute_count += 1
	if pattern_execute_count >= 3:
		pattern_execute_count = 0
		_spawn_minions()

func _has_living_minions() -> bool:
	_cleanup_dead_minions()
	return spawned_minions.size() > 0

func _cleanup_dead_minions() -> void:
	var alive: Array[Node2D] = []
	for minion in spawned_minions:
		if is_instance_valid(minion) and not _is_minion_dead(minion):
			alive.append(minion)
	spawned_minions = alive

func _is_minion_dead(minion: Node2D) -> bool:
	if "is_dying" in minion and minion.is_dying:
		return true
	if "current_health" in minion and minion.current_health <= 0:
		return true
	return false

func _spawn_minions() -> void:
	if _has_living_minions():
		return
		
	var spawn1 = _find_spawn_node("spawn1")
	var spawn2 = _find_spawn_node("spawn2")
	
	if spawn1:
		_spawn_mutation_at(spawn1.global_position)
	if spawn2:
		_spawn_mutation_at(spawn2.global_position)
		
	if not spawn1 and not spawn2:
		_spawn_mutation_at(global_position + Vector2(-150, 200))
		_spawn_mutation_at(global_position + Vector2(150, 200))
		
	_play_spawn_roar()

func _find_spawn_node(node_name: String) -> Node2D:
	var parent = get_parent()
	if not parent: return null
	
	var base_num = "1" if "1" in node_name else "2"
	var variations = [
		"Spawn" + base_num,
		"Spawn " + base_num,
		"Spawn_" + base_num,
		"spawn" + base_num,
		"spawn " + base_num,
		"spawn_" + base_num,
		"SPAWN" + base_num,
		"SPAWN " + base_num,
		"SPAWN_" + base_num
	]
	
	for name_var in variations:
		var found = parent.find_child(name_var, true, false)
		if found and found is Node2D:
			return found
			
		found = find_child(name_var, true, false)
		if found and found is Node2D:
			return found
			
	return null

func _spawn_mutation_at(pos: Vector2) -> void:
	var scene = load("res://Scenes/Enemies/EnemyFollower.tscn")
	if not scene:
		printerr("Boss1: No se pudo cargar EnemyFollower.tscn para spawneo.")
		return
	var inst = scene.instantiate()
	if is_phase_two and "is_elite" in inst:
		inst.is_elite = true
		inst.modulate = Color(1.3, 0.4, 0.4)
	get_parent().add_child(inst)
	inst.global_position = pos
	spawned_minions.append(inst)

func _play_spawn_roar() -> void:
	if roar_invoc:
		roar_invoc.pitch_scale = 0.85
		roar_invoc.volume_db = 4.0
		roar_invoc.play()
	elif roar_player:
		roar_player.pitch_scale = 0.85
		roar_player.volume_db = 4.0
		roar_player.play()
	else:
		roar_player = AudioStreamPlayer2D.new()
		var stream = load("res://Audio/Enemy_snd/Boss1/Retro Roar LoFi 08.wav")
		if stream:
			roar_player.stream = stream
		roar_player.pitch_scale = 0.85
		roar_player.volume_db = 0.0
		roar_player.bus = "SFX"
		add_child(roar_player)
		roar_player.play()

func _setup_laser_audio() -> void:
	if not laser_sound:
		laser_sound = AudioStreamPlayer2D.new()
		laser_sound.name = "Laser_sound"
		laser_sound.stream = load("res://Audio/Enemy_snd/Boss1/Laser.mp3")
		add_child(laser_sound)
	# Laser_sound conserva el stream, tono y espacialización de la escena.
	_laser_node_volume_db = laser_sound.volume_db
	laser_sound.bus = "SFX"
	if not laser_sound.finished.is_connected(_on_laser_sound_finished):
		laser_sound.finished.connect(_on_laser_sound_finished)
	_laser_charge_audio = AudioStreamPlayer2D.new()
	_laser_accent_audio = AudioStreamPlayer2D.new()
	add_child(_laser_charge_audio)
	add_child(_laser_accent_audio)
	for audio in [_laser_charge_audio, _laser_accent_audio]:
		audio.bus = "SFX"
		audio.max_distance = 1600
		audio.volume_db = laser_volume_db
	_laser_charge_audio.stream = load("res://Audio/Enemy_snd/Boss1/laser_charge.wav")

func _on_laser_sound_finished() -> void:
	if is_laser_active and _laser_firing and not is_dying:
		laser_sound.play()

func _update_laser_audio_state() -> void:
	if _laser_audio_tween and _laser_audio_tween.is_valid(): _laser_audio_tween.kill()
	if is_laser_active:
		_laser_firing = false
		_laser_charge_left = laser_charge_duration
		laser_damage_cooldown = 0.0
		if laser_sound: laser_sound.stop()
		if _laser_charge_audio:
			_laser_charge_audio.pitch_scale = 0.75 / maxf(laser_charge_duration, 0.01)
			_laser_charge_audio.play()
	else:
		_laser_charge_left = 0.0
		_laser_firing = false
		if _laser_charge_audio: _laser_charge_audio.stop()
		if left_laser_line: left_laser_line.stop()
		if right_laser_line: right_laser_line.stop()
		if laser_sound and laser_sound.playing:
			_play_laser_accent("release")
			_laser_audio_tween = create_tween()
			_laser_audio_tween.tween_property(laser_sound, "volume_db", -45.0, 0.18)
			_laser_audio_tween.tween_callback(laser_sound.stop)

func _ignite_lasers() -> void:
	if is_dying or not is_laser_active: return
	_laser_firing = true
	if _laser_charge_audio: _laser_charge_audio.stop()
	_play_laser_accent("ignite")
	if laser_sound:
		laser_sound.volume_db = _laser_node_volume_db
		laser_sound.play()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(3.5, 0.16)

func _play_laser_accent(kind: String) -> void:
	if not _laser_accent_audio: return
	_laser_accent_audio.stream = load("res://Audio/Enemy_snd/Boss1/laser_%s.wav" % kind)
	_laser_accent_audio.play()

func _stop_all_boss_sounds() -> void:
	is_laser_active = false
	_laser_firing = false
	_laser_charge_left = 0.0
	if _laser_audio_tween and _laser_audio_tween.is_valid(): _laser_audio_tween.kill()
	for audio in [laser_sound, _laser_charge_audio, _laser_accent_audio]:
		if is_instance_valid(audio): audio.stop()
	if left_laser_line: left_laser_line.stop(true)
	if right_laser_line: right_laser_line.stop(true)

func _play_death_sound() -> void:
	var ds = get_node_or_null("death_sound")
	if not ds: ds = get_node_or_null("Death_sound")
	if not ds: ds = get_node_or_null("DeathSound")
	if ds and ds.has_method("play"):
		ds.bus = "SFX"
		ds.play()
	else:
		super._play_death_sound()

func _play_death_fx() -> void:
	var anim_player = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player is AnimationPlayer and anim_player.has_animation("death"):
		anim_player.play("death")
		if not anim_player.animation_finished.is_connected(_on_custom_death_finished):
			anim_player.animation_finished.connect(_on_custom_death_finished)
		return
		
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite and sprite is AnimatedSprite2D and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		if not sprite.animation_finished.is_connected(_on_custom_sprite_death_finished):
			sprite.animation_finished.connect(_on_custom_sprite_death_finished)
		return
		
	super._play_death_fx()

func _on_custom_death_finished(_anim_name: StringName = &"") -> void:
	queue_free()

func _on_custom_sprite_death_finished() -> void:
	queue_free()
