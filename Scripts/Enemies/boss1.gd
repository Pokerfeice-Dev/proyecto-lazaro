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
var left_laser_line: Line2D
var right_laser_line: Line2D

# Attack states
var pattern_timer: Timer
var is_laser_active: bool = false
var laser_angle: float = PI / 2 # straight down (90 deg)
var laser_sweep_speed: float = 1.2
var laser_sweep_dir: float = 1.0
var laser_damage_cooldown: float = 0.0

var healthbar_instance: Node = null
var boss_health_bar_node: Range = null
var is_phase_two: bool = false
var is_transitioning_phase: bool = false
var phase_two_attack_step: int = 0
var pattern_execute_count: int = 0
var spawned_minions: Array[Node2D] = []
var roar_player: AudioStreamPlayer2D = null

func _ready() -> void:
	super._ready()
	damage = boss_damage
	move_speed = 0.0 # Stationary boss
	laser_sweep_speed = laser_sweep_base_speed
	
	_init_boss_phase_state()
	_setup_lasers()
	_setup_pattern_timer()
	_connect_to_hud.call_deferred()

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
	
	var title_container = _create_cinematic_title_container(cinema_layer)
	var camera = get_viewport().get_camera_2d()
	
	_animate_cinematic_entrance(title_container)
	_run_cinematic_timeline(cinema_layer, title_container, player, camera)

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

func _create_cinematic_title_container(parent: CanvasLayer) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(960 - 350, 540 - 65)
	container.custom_minimum_size = Vector2(700, 130)
	container.modulate.a = 0.0
	parent.add_child(container)
	
	var title_label = Label.new()
	title_label.text = "CENTINELA GÉNESIS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 12)
	container.add_child(title_label)
	
	var sub_label = Label.new()
	sub_label.text = "◆ FASE 2: MODO FURIA ◆\n[ REGENERACIÓN BIOLÓGICA +20% ]"
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	sub_label.add_theme_font_size_override("font_size", 20)
	sub_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	sub_label.add_theme_color_override("font_outline_color", Color.BLACK)
	sub_label.add_theme_constant_override("outline_size", 8)
	container.add_child(sub_label)
	return container

func _animate_cinematic_entrance(title: Control) -> void:
	var t = create_tween()
	t.tween_property(title, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _run_cinematic_timeline(cinema_layer: CanvasLayer, title: Control, player: Node, camera: Camera2D) -> void:
	var t_seq = create_tween()
	# 1s: Focused start with title fade in
	t_seq.tween_interval(1.0)
	
	# 1s: Camera zooms in to boss
	t_seq.tween_callback(func(): _zoom_camera_to_boss(camera, 1.0))
	t_seq.tween_interval(1.0)
	
	# 2s: Boss roars, heals +20% HP, healing particles spawn
	t_seq.tween_callback(func(): _trigger_healing_phase_effects(player))
	t_seq.tween_interval(2.0)
	
	# 1s: Camera zooms back out
	t_seq.tween_callback(func(): _zoom_camera_to_player(camera, 1.0))
	t_seq.tween_interval(1.0)
	
	# 1s: Title fades out
	t_seq.tween_callback(func(): _animate_cinematic_exit(title))
	t_seq.tween_interval(1.0)
	
	# Finish & start fight
	t_seq.tween_callback(func(): _finish_cinematic_and_start_fight(cinema_layer, player))

func _zoom_camera_to_boss(camera: Camera2D, duration: float) -> void:
	if not camera: return
	var target_offset = global_position - camera.get_parent().global_position
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", Vector2(1.35, 1.35), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(camera, "position", target_offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _zoom_camera_to_player(camera: Camera2D, duration: float) -> void:
	if not camera: return
	var t = create_tween().set_parallel(true)
	t.tween_property(camera, "zoom", Vector2(1.0, 1.0), duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(camera, "position", Vector2.ZERO, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

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

func _animate_cinematic_exit(title: Control) -> void:
	var t_out = create_tween()
	t_out.tween_property(title, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _finish_cinematic_and_start_fight(cinema_layer: CanvasLayer, player: Node) -> void:
	if cinema_layer and is_instance_valid(cinema_layer):
		cinema_layer.queue_free()
	_unfreeze_player_completely(player)
	set_physics_process(true)
	_apply_phase_two_buffs()

func _setup_lasers() -> void:
	# Left Laser setup
	left_raycast = RayCast2D.new()
	left_raycast.collision_mask = 1 | 4 # Player (1) and Walls (3)
	left_raycast.collide_with_areas = false
	left_raycast.collide_with_bodies = true
	add_child(left_raycast)
	
	left_laser_line = Line2D.new()
	left_laser_line.width = 12.0
	left_laser_line.default_color = Color(1.0, 0.1, 0.1, 0.8) # Red laser
	left_laser_line.visible = false
	add_child(left_laser_line)
	
	# Right Laser setup
	right_raycast = RayCast2D.new()
	right_raycast.collision_mask = 1 | 4
	right_raycast.collide_with_areas = false
	right_raycast.collide_with_bodies = true
	add_child(right_raycast)
	
	right_laser_line = Line2D.new()
	right_laser_line.width = 12.0
	right_laser_line.default_color = Color(1.0, 0.1, 0.1, 0.8)
	right_laser_line.visible = false
	add_child(right_laser_line)

func _setup_pattern_timer() -> void:
	pattern_timer = Timer.new()
	pattern_timer.wait_time = time_between_patterns
	pattern_timer.one_shot = false
	pattern_timer.autostart = true
	pattern_timer.timeout.connect(_on_pattern_timeout)
	add_child(pattern_timer)

func _connect_to_hud() -> void:
	var scene = _load_healthbar_scene()
	if not scene:
		printerr("Boss1: No se pudo encontrar la escena Boss_health_bar.tscn en ninguna de las rutas esperadas.")
		return
		
	healthbar_instance = scene.instantiate()
	if healthbar_instance is CanvasLayer:
		healthbar_instance.layer = 100
	get_tree().current_scene.add_child(healthbar_instance)
	
	boss_health_bar_node = _find_progress_bar(healthbar_instance)
	if boss_health_bar_node:
		boss_health_bar_node.max_value = max_health
		boss_health_bar_node.value = current_health
		
	var name_label = _find_label(healthbar_instance)
	if name_label:
		name_label.text = "Centinela Génesis"
		
	var anim_player = _find_animation_player(healthbar_instance)
	if anim_player:
		if anim_player.has_animation("Start_Fight"):
			anim_player.play("Start_Fight")
		elif anim_player.has_animation("start_fight"):
			anim_player.play("start_fight")
		elif anim_player.get_animation_list().size() > 0:
			anim_player.play(anim_player.get_animation_list()[0])

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
	if not is_laser_active:
		left_laser_line.visible = false
		right_laser_line.visible = false
		return
		
	left_laser_line.visible = true
	right_laser_line.visible = true
	
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

func _update_laser_beam(ray: RayCast2D, line: Line2D, muzzle_local_pos: Vector2, angle: float, delta: float) -> void:
	var dir = Vector2.from_angle(angle)
	ray.position = muzzle_local_pos
	ray.target_position = dir * 1000.0
	
	_perform_raycast_shifting(ray, muzzle_local_pos, dir)
	
	var local_col_point = muzzle_local_pos + dir * 1000.0
	if ray.is_colliding():
		var global_col = ray.get_collision_point()
		local_col_point = to_local(global_col)
		_check_laser_damage(ray.get_collider(), delta)
		
	# Restore raycast state
	ray.position = muzzle_local_pos
	ray.target_position = dir * 1000.0
	
	line.clear_points()
	line.add_point(muzzle_local_pos)
	line.add_point(local_col_point)

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

func _check_laser_damage(collider: Object, delta: float) -> void:
	if laser_damage_cooldown > 0.0:
		laser_damage_cooldown -= delta
		return
		
	if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
		var tick_damage = maxi(1, int(float(damage) / 3.0))
		collider.take_damage(tick_damage, "Mutante Génesis (Boss)")
		var base_cooldown = laser_damage_tick_rate
		laser_damage_cooldown = base_cooldown / 1.5 if is_phase_two else base_cooldown

func _on_pattern_timeout() -> void:
	if is_dying: return
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
		left_laser_line.visible = false
		right_laser_line.visible = false
	
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
	proj.source_name = "Mutante Génesis (Boss)"
	get_tree().current_scene.add_child(proj)
	proj.global_position = pos
	var base_dir = Vector2.from_angle(angle)
	proj.setup(base_dir, damage, "player")
	if is_phase_two and "speed" in proj:
		proj.speed = proj.speed * 1.25

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_transitioning_phase: return
	super.take_damage(amount, is_crit)
	_update_hud_health()
	_check_phase_transition()

func _check_phase_transition() -> void:
	if is_phase_two: return
	if is_dying: return
	if is_transitioning_phase: return
	
	var threshold = float(max_health) * 0.50
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
		left_laser_line.visible = false
		right_laser_line.visible = false
	
	GameData.boss_fight_phase = 2
	GameData.boss_persisted_max_health = max_health
	GameData.boss_persisted_health = current_health
	
	_play_rage_effects()
	_show_phase_two_message()
	
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

func _show_phase_two_message() -> void:
	var label = Label.new()
	label.text = "FASE 2: MODO FURIA"
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	
	var font_res = load("res://Art/Fonts/Dekatron-SemiBold.otf")
	if font_res:
		label.add_theme_font_override("font", font_res)
		
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	get_tree().current_scene.add_child(canvas_layer)
	canvas_layer.add_child(label)
	
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.position = Vector2(960 - 250, 540 - 40)
	
	var t = create_tween().set_parallel(true)
	t.tween_property(label, "scale", Vector2(1.2, 1.2), 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(label, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(canvas_layer.queue_free)

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
	super.die()
	GameData.reset_boss_state()
	_hide_hud_health()
	_stop_all_boss_sounds()
	if GameData.get_active_protocol() == "reciclaje_instantaneo":
		GameData.add_scrap(50)

func _hide_hud_health() -> void:
	if healthbar_instance:
		healthbar_instance.queue_free()
		healthbar_instance = null
		boss_health_bar_node = null

func _find_label(node: Node) -> Label:
	if node is Label:
		return node
	for i in range(node.get_child_count()):
		var found = _find_label(node.get_child(i))
		if found:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for i in range(node.get_child_count()):
		var found = _find_animation_player(node.get_child(i))
		if found:
			return found
	return null

func _find_progress_bar(node: Node) -> Range:
	if node is Range:
		return node
	for i in range(node.get_child_count()):
		var found = _find_progress_bar(node.get_child(i))
		if found:
			return found
	return null

func _load_healthbar_scene() -> PackedScene:
	var paths = [
		"res://Scenes/UI/boss_health_bar.tscn",
		"res://Scenes/UI/Boss_healtbar.tscn",
		"res://Scenes/UI/Boss_healthbar.tscn",
		"res://Scenes/Enemies/Boss_healtbar.tscn",
		"res://Scenes/Enemies/Boss_healthbar.tscn",
		"res://Boss_healtbar.tscn",
		"res://Boss_healthbar.tscn"
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null

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
		roar_player.volume_db = 4.0
		add_child(roar_player)
		roar_player.play()

func _update_laser_audio_state() -> void:
	if not laser_sound: return
	if is_laser_active:
		if not laser_sound.playing:
			laser_sound.play()
	else:
		if laser_sound.playing:
			laser_sound.stop()

func _stop_all_boss_sounds() -> void:
	if laser_sound and laser_sound.playing:
		laser_sound.stop()

func _play_death_sound() -> void:
	var ds = get_node_or_null("death_sound")
	if not ds: ds = get_node_or_null("Death_sound")
	if not ds: ds = get_node_or_null("DeathSound")
	if ds and ds.has_method("play"):
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
