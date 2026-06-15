extends EnemyBase
class_name Boss1

@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")

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
var pattern_execute_count: int = 0
var roar_player: AudioStreamPlayer2D = null

func _ready() -> void:
	super._ready()
	max_health = boss_max_health
	current_health = max_health
	damage = boss_damage
	move_speed = 0.0 # Stationary boss
	laser_sweep_speed = laser_sweep_base_speed
	
	_setup_lasers()
	_setup_pattern_timer()
	_connect_to_hud.call_deferred()

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
	get_tree().current_scene.add_child(healthbar_instance)
	
	boss_health_bar_node = _find_progress_bar(healthbar_instance)
	if boss_health_bar_node:
		boss_health_bar_node.max_value = max_health
		boss_health_bar_node.value = max_health
		
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
	ray.force_raycast_update()
	
	var local_col_point = muzzle_local_pos + dir * 1000.0
	if ray.is_colliding():
		var global_col = ray.get_collision_point()
		local_col_point = to_local(global_col)
		_check_laser_damage(ray.get_collider(), delta)
		
	line.clear_points()
	line.add_point(muzzle_local_pos)
	line.add_point(local_col_point)

func _check_laser_damage(collider: Object, delta: float) -> void:
	if laser_damage_cooldown > 0.0:
		laser_damage_cooldown -= delta
		return
		
	if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
		var tick_damage = maxi(1, int(float(damage) / 3.0))
		collider.take_damage(tick_damage)
		var base_cooldown = laser_damage_tick_rate
		laser_damage_cooldown = base_cooldown / 1.5 if is_phase_two else base_cooldown

func _on_pattern_timeout() -> void:
	if is_dying: return
	_toggle_attack_pattern()
	_update_spawn_counter()

func _toggle_attack_pattern() -> void:
	is_laser_active = not is_laser_active
	_update_laser_audio_state()
	if not is_laser_active:
		_fire_ring_pattern()

func _fire_ring_pattern() -> void:
	if bullet_sound:
		bullet_sound.play()
	var bullet_count = projectile_ring_count
	var angle_step = (2 * PI) / bullet_count
	for i in range(bullet_count):
		var spawn_angle = i * angle_step
		_spawn_projectile_at_angle(muzzle_center.global_position, spawn_angle)

func _spawn_projectile_at_angle(pos: Vector2, angle: float) -> void:
	if not projectile_scene: return
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = pos
	var base_dir = Vector2.from_angle(angle)
	proj.setup(base_dir, damage, "player")
	if is_phase_two and "speed" in proj:
		proj.speed = proj.speed * 1.25

func take_damage(amount: int, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)
	_update_hud_health()
	_check_phase_transition()

func _check_phase_transition() -> void:
	if is_phase_two: return
	if is_dying: return
	
	var threshold = float(max_health) * 0.25
	if float(current_health) <= threshold:
		_activate_phase_two()

func _activate_phase_two() -> void:
	is_phase_two = true
	_show_phase_two_message()
	_apply_phase_two_buffs()

func _show_phase_two_message() -> void:
	var label = Label.new()
	label.text = "FASE 2: FURIA"
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
	_hide_hud_health()
	_stop_all_boss_sounds()

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

func _spawn_minions() -> void:
	var spawn1 = _find_spawn_node("spawn1")
	var spawn2 = _find_spawn_node("spawn2")
	
	if spawn1:
		_spawn_mutation_at(spawn1.global_position)
	if spawn2:
		_spawn_mutation_at(spawn2.global_position)
		
	if not spawn1 and not spawn2:
		# Fallback: spawn relative to boss position if nodes aren't found on parent
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
		# Search recursively from parent
		var found = parent.find_child(name_var, true, false)
		if found and found is Node2D:
			return found
			
		# Search recursively from self
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
	get_parent().add_child(inst)
	inst.global_position = pos

func _play_spawn_roar() -> void:
	if roar_invoc:
		roar_invoc.play()
	elif roar_player:
		roar_player.play()
	else:
		# Fallback: create dynamic player if not present in scene
		roar_player = AudioStreamPlayer2D.new()
		var stream = load("res://Audio/Enemy_snd/Boss1/Retro Roar LoFi 08.wav")
		if stream:
			roar_player.stream = stream
		roar_player.volume_db = 0.0
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
