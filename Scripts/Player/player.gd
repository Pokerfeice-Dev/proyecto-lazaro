extends CharacterBody2D
class_name Player

@export var stats: PlayerStats = PlayerStats.new()
@export var acceleration: float = 2000.0
@export var friction: float = 1800.0
@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.2
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Projectile.tscn")
@export var weapon_scene: PackedScene = preload("res://Scenes/Weapon/main_weapon.tscn")
@export var second_weapon_scene: PackedScene = preload("res://Scenes/Weapon/second_weapon.tscn")

@export_category("Camera Feedback")
@export var shake_intensity: float = 6.0
@export var shake_duration: float = 0.1
var shake_tween: Tween

@export_category("Damage Effect")
@export var damage_border_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var damage_border_intensity: float = 0.9
var damage_canvas: CanvasLayer
var damage_rect: ColorRect

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var can_shoot: bool = true
var shoot_timer: Timer

var is_dashing: bool = false
var dash_timer: Timer
var dash_cd_timer: Timer
var dash_dir: Vector2 = Vector2.DOWN

var last_dir: String = "down"

var is_invulnerable: bool = false
var invuln_timer: Timer

var weapon_hide_timer: Timer

var active_weapon: Node2D
var second_weapon: Node2D

func _ready() -> void:
	_init_timers()
	setup_damage_effect()
	_init_stats()
	add_to_group("player")
	_init_weapon()
	_apply_game_data_upgrades()
	_update_hud_health(stats.current_health, stats.max_health)
	_update_hud_scrap(GameData.scrap)

func _init_timers() -> void:
	_create_shoot_timer()
	_create_dash_timer()
	_create_invuln_timer()
	_create_weapon_hide_timer()

func _create_shoot_timer() -> void:
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func _create_dash_timer() -> void:
	dash_timer = Timer.new()
	dash_timer.one_shot = true
	add_child(dash_timer)
	dash_timer.timeout.connect(_on_dash_timer_timeout)

	dash_cd_timer = Timer.new()
	dash_cd_timer.one_shot = true
	add_child(dash_cd_timer)

func _create_invuln_timer() -> void:
	invuln_timer = Timer.new()
	invuln_timer.one_shot = true
	add_child(invuln_timer)
	invuln_timer.timeout.connect(_on_invuln_timeout)

func _create_weapon_hide_timer() -> void:
	weapon_hide_timer = Timer.new()
	weapon_hide_timer.one_shot = true
	add_child(weapon_hide_timer)
	weapon_hide_timer.timeout.connect(_on_weapon_hide_timeout)
	weapon_hide_timer.start(2.0)

func _on_weapon_hide_timeout() -> void:
	if active_weapon: active_weapon.hide()
	if second_weapon: second_weapon.hide()

func _show_primary_weapon() -> void:
	if active_weapon: active_weapon.show()
	if second_weapon: second_weapon.hide()
	weapon_hide_timer.start(2.0)

func _show_secondary_weapon() -> void:
	if active_weapon: active_weapon.hide()
	if second_weapon: second_weapon.show()
	weapon_hide_timer.start(2.0)

func _init_stats() -> void:
	if not stats: stats = PlayerStats.new()
	stats.health_changed.connect(_on_health_changed)
	GameData.scrap_changed.connect(_on_scrap_changed)
	stats.player_died.connect(_on_died)

func _init_weapon() -> void:
	_init_primary_weapon()
	_init_secondary_weapon()

func _init_primary_weapon() -> void:
	if not weapon_scene: return
	active_weapon = weapon_scene.instantiate()
	add_child(active_weapon)

func _init_secondary_weapon() -> void:
	if not second_weapon_scene: return
	second_weapon = second_weapon_scene.instantiate()
	add_child(second_weapon)

func _apply_game_data_upgrades() -> void:
	GameData.apply_to_player_stats(stats)
	GameData.apply_to_weapon(active_weapon)
	GameData.apply_to_melee(second_weapon)

func _physics_process(delta: float) -> void:
	_check_dash_input()
	_process_movement(delta)
	_process_actions()
	move_and_slide()
	update_animation()
	update_glock()

func _check_dash_input() -> void:
	if not Input.is_action_just_pressed("dash"): return
	if is_dashing: return
	if not dash_cd_timer.is_stopped(): return
	_start_dash()

func _start_dash() -> void:
	is_dashing = true
	dash_timer.start(dash_duration)
	dash_cd_timer.start(5.0)
	_set_dash_direction()

func _set_dash_direction() -> void:
	if velocity == Vector2.ZERO:
		dash_dir = _get_dir_vector(last_dir)
		return
	dash_dir = velocity.normalized()

func _process_movement(delta: float) -> void:
	if is_dashing:
		velocity = dash_dir * dash_speed
		return
	handle_movement(delta)

func _process_actions() -> void:
	if is_dashing: return
	handle_shooting()
	handle_melee()

func handle_melee() -> void:
	if not Input.is_action_just_pressed("attack_melee"): return
	if not second_weapon: return
	if not second_weapon.has_method("attack"): return
	_show_secondary_weapon()
	second_weapon.attack()

func setup_damage_effect() -> void:
	damage_canvas = CanvasLayer.new()
	damage_canvas.layer = 99
	add_child(damage_canvas)
	damage_rect = ColorRect.new()
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_damage_material()

func _apply_damage_material() -> void:
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = _get_damage_shader_code()
	mat.shader = shader
	mat.set_shader_parameter("border_color", damage_border_color)
	mat.set_shader_parameter("intensity", 0.0)
	damage_rect.material = mat
	damage_canvas.add_child(damage_rect)

func _get_damage_shader_code() -> String:
	return """
shader_type canvas_item;
uniform vec4 border_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float intensity = 0.0;
void fragment() {
	vec2 uv = UV;
	float d = distance(uv, vec2(0.5, 0.5));
	float alpha = smoothstep(0.35, 0.75, d) * intensity;
	COLOR = border_color;
	COLOR.a *= alpha;
}
"""

func handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir == Vector2.ZERO:
		_apply_friction(delta)
		return
	_apply_acceleration(input_dir, delta)
	_update_last_dir(input_dir)

func _apply_friction(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func _apply_acceleration(input_dir: Vector2, delta: float) -> void:
	velocity = velocity.move_toward(input_dir * stats.move_speed, acceleration * delta)

func _update_last_dir(input_dir: Vector2) -> void:
	if abs(input_dir.x) > abs(input_dir.y):
		last_dir = "right" if input_dir.x > 0 else "left"
		return
	last_dir = "down" if input_dir.y > 0 else "up"

func handle_shooting() -> void:
	if not can_shoot: return
	if not Input.is_action_pressed("shoot"): return
	var shoot_dir = (get_global_mouse_position() - global_position).normalized()
	if shoot_dir == Vector2.ZERO: return
	fire_projectile(shoot_dir)

func _get_equipment_damage_bonus() -> float:
	var equip = get_node_or_null("Equipment")
	if not equip: return 0.0
	var char_stats = equip.get_character_stats()
	var weapon_stats = equip.get_main_weapon_stats()
	var bonus = 0.0
	if char_stats.has("damage"): bonus += char_stats["damage"]
	if weapon_stats.has("damage"): bonus += weapon_stats["damage"]
	return bonus

func fire_projectile(dir: Vector2) -> void:
	_show_primary_weapon()
	can_shoot = false
	shoot_timer.start(stats.fire_rate)
	var fire_point = global_position
	var p_scene = projectile_scene
	var dmg = 10.0 * stats.damage_multiplier + _get_equipment_damage_bonus()
	var p_speed = 600.0
	var bullets = 1
	var spread = 0.0
	var piercing = 0
	var crit_chance = 0.0

	if active_weapon:
		p_scene = _get_weapon_proj_scene(p_scene)
		dmg = (_get_weapon_damage() + _get_equipment_damage_bonus()) * stats.damage_multiplier
		p_speed = _get_weapon_proj_speed()
		bullets = _get_weapon_bullets()
		spread = _get_weapon_spread()
		piercing = _get_weapon_piercing()
		crit_chance = _get_weapon_crit_chance()
		_play_weapon_anim()
		_play_weapon_sound()
		fire_point = _get_weapon_mark(fire_point)

	if not p_scene: return
	_spawn_bullets(p_scene, bullets, spread, dir, dmg, p_speed, fire_point, piercing, crit_chance)
	apply_camera_shake()

func _get_weapon_proj_scene(fallback: PackedScene) -> PackedScene:
	if not active_weapon.has_method("get_projectile_scene"): return fallback
	var ws = active_weapon.get_projectile_scene()
	if not ws: return fallback
	return ws

func _get_weapon_damage() -> float:
	if not active_weapon.has_method("get_damage"): return 10.0
	return active_weapon.get_damage()

func _get_weapon_proj_speed() -> float:
	if not active_weapon.has_method("get_projectile_speed"): return 600.0
	return active_weapon.get_projectile_speed()

func _get_weapon_bullets() -> int:
	if not active_weapon.has_method("get_bullet_count"): return 1
	return active_weapon.get_bullet_count()

func _get_weapon_spread() -> float:
	if not active_weapon.has_method("get_spread_angle"): return 0.0
	return active_weapon.get_spread_angle()

func _get_weapon_piercing() -> int:
	if not active_weapon.has_method("get_piercing"): return 0
	return active_weapon.get_piercing()

func _get_weapon_crit_chance() -> float:
	if not active_weapon.has_method("get_crit_chance"): return 0.0
	return active_weapon.get_crit_chance()

func _play_weapon_anim() -> void:
	var weapon_anim = active_weapon.get_node_or_null("Weapon_Sprites")
	if not weapon_anim: return
	weapon_anim.stop()
	weapon_anim.play("shoot")

func _play_weapon_sound() -> void:
	var w_sound = active_weapon.get_node_or_null("Bullet_sound")
	if not w_sound: return
	if not w_sound.has_method("play"): return
	w_sound.play()

func _get_weapon_mark(fallback: Vector2) -> Vector2:
	var mark_node = active_weapon.get_node_or_null("Bullet_mark_right")
	if not mark_node: return fallback
	return mark_node.global_position

func _spawn_bullets(p_scene: PackedScene, count: int, spread: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float) -> void:
	var start_angle = _get_start_angle(dir, count, spread)
	var step_angle = _get_step_angle(count, spread)
	_instantiate_bullets(p_scene, count, start_angle, step_angle, dir, dmg, p_speed, spawn_pos, piercing, crit_chance)

func _get_start_angle(dir: Vector2, count: int, spread: float) -> float:
	var angle = dir.angle()
	if count <= 1: return angle
	return angle - (deg_to_rad(spread) / 2.0)

func _get_step_angle(count: int, spread: float) -> float:
	if count <= 1: return 0.0
	return deg_to_rad(spread) / float(count - 1)

func _instantiate_bullets(p_scene: PackedScene, count: int, start_angle: float, step_angle: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float) -> void:
	for i in range(count):
		_spawn_single_bullet(p_scene, i, count, start_angle, step_angle, dir, dmg, p_speed, spawn_pos, piercing, crit_chance)

func _spawn_single_bullet(p_scene: PackedScene, i: int, count: int, start_angle: float, step_angle: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float) -> void:
	var final_dir = dir
	if count > 1:
		final_dir = Vector2.RIGHT.rotated(start_angle + (step_angle * float(i)))
	var proj = p_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	
	var final_dmg = dmg
	var is_crit = false
	if randf() <= crit_chance:
		final_dmg *= 2.0
		is_crit = true
		
	proj.setup(final_dir, final_dmg, "enemy", is_crit)
	if "speed" in proj: proj.speed = p_speed
	if "piercing" in proj: proj.piercing = piercing

func apply_camera_shake() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	_reset_camera_shake(camera)
	_start_camera_shake(camera)

func _reset_camera_shake(camera: Camera2D) -> void:
	if not shake_tween: return
	if not shake_tween.is_valid(): return
	shake_tween.kill()
	camera.offset = Vector2.ZERO

func _start_camera_shake(camera: Camera2D) -> void:
	shake_tween = create_tween()
	var random_offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	shake_tween.tween_property(camera, "offset", random_offset, shake_duration / 2.0).set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, shake_duration / 2.0).set_trans(Tween.TRANS_SINE)

func update_glock() -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	var orbit_radius = 25.0
	_update_primary_weapon_pivot(mouse_pos, dir, orbit_radius)
	_update_secondary_weapon_pivot(mouse_pos, dir, orbit_radius)

func _update_primary_weapon_pivot(mouse_pos: Vector2, dir: Vector2, orbit_radius: float) -> void:
	if not active_weapon: return
	active_weapon.look_at(mouse_pos)
	active_weapon.position = dir * orbit_radius
	_flip_weapon(active_weapon, dir)

func _update_secondary_weapon_pivot(mouse_pos: Vector2, dir: Vector2, orbit_radius: float) -> void:
	if not second_weapon: return
	if second_weapon.has_method("is_attacking") and second_weapon.is_attacking():
		second_weapon.position = dir * orbit_radius
		return
	second_weapon.look_at(mouse_pos)
	second_weapon.position = dir * orbit_radius
	_flip_weapon(second_weapon, dir)

func _flip_weapon(weapon: Node2D, dir: Vector2) -> void:
	var base_scale = abs(weapon.scale.x)
	if dir.x < 0:
		weapon.scale.y = -base_scale
		return
	weapon.scale.y = base_scale

func update_animation() -> void:
	if not anim_sprite: return
	if is_dashing:
		anim_sprite.play("run_" + last_dir)
		return
	if velocity.length() > 50:
		anim_sprite.play("run_" + last_dir)
		return
	anim_sprite.play("idle_" + last_dir)

func _get_dir_vector(dir_str: String) -> Vector2:
	if dir_str == "up": return Vector2.UP
	if dir_str == "down": return Vector2.DOWN
	if dir_str == "right": return Vector2.RIGHT
	if dir_str == "left": return Vector2.LEFT
	return Vector2.DOWN

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func take_damage(amount: int) -> void:
	if is_invulnerable: return
	is_invulnerable = true
	invuln_timer.start(0.5)
	stats.take_damage(amount)
	_show_damage_text(amount)
	_play_hurt_sound()
	_animate_damage_vignette()
	_animate_damage_flash()

func _show_damage_text(amount: int) -> void:
	var label = Label.new()
	label.text = "-%d" % amount
	label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(100, 30)
	label.position = Vector2(-50, -15)
	
	var floating_node = Node2D.new()
	floating_node.global_position = global_position + Vector2(randf_range(-15.0, 15.0), -40.0)
	floating_node.add_child(label)
	
	get_tree().current_scene.call_deferred("add_child", floating_node)
	
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(0, -40), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(floating_node.queue_free)

func _play_hurt_sound() -> void:
	var hurt_sound = get_node_or_null("Hurt_sound")
	if not hurt_sound: hurt_sound = get_node_or_null("HurtSound")
	if not hurt_sound: return
	if not hurt_sound.has_method("play"): return
	hurt_sound.play()

func _animate_damage_vignette() -> void:
	if not damage_rect: return
	if not damage_rect.material: return
	var mat = damage_rect.material as ShaderMaterial
	mat.set_shader_parameter("border_color", damage_border_color)
	var t = create_tween()
	t.tween_method(_tween_damage_intensity.bind(mat), damage_border_intensity, 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _tween_damage_intensity(val: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("intensity", val)

func _animate_damage_flash() -> void:
	if not anim_sprite: return
	var original_modulate = anim_sprite.modulate
	anim_sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", original_modulate, 0.5)

func _on_invuln_timeout() -> void:
	is_invulnerable = false

func _on_health_changed(new_health: int, max_health: int) -> void:
	_update_hud_health(new_health, max_health)

func _update_hud_health(new_health: int, max_health: int) -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_health(new_health, max_health)

func _on_scrap_changed(amount: int) -> void:
	_update_hud_scrap(amount)

func _update_hud_scrap(amount: int) -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_scrap(amount)

func _on_died() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	_show_death_screen()

func _show_death_screen() -> void:
	var overlay = _build_death_overlay()
	get_tree().root.add_child(overlay)
	_animate_death_overlay(overlay)

func _build_death_overlay() -> CanvasLayer:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	var root = _build_death_root()
	canvas.add_child(root)
	root.add_child(_build_death_bg())
	root.add_child(_build_death_label())
	root.add_child(_build_death_sub_label())
	return canvas

func _build_death_root() -> Control:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return root

func _build_death_bg() -> ColorRect:
	var bg = ColorRect.new()
	bg.name = "BG"
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bg

func _build_death_label() -> Label:
	var lbl = Label.new()
	lbl.name = "DeathLabel"
	lbl.text = "MORISTE"
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	lbl.offset_left = -400.0
	lbl.offset_right = 400.0
	lbl.offset_top = -80.0
	lbl.offset_bottom = 80.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 96)
	lbl.add_theme_color_override("font_color", Color(1, 0.1, 0.1, 0))
	lbl.add_theme_color_override("font_outline_color", Color(0.6, 0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 6)
	return lbl

func _build_death_sub_label() -> Label:
	var sub = Label.new()
	sub.name = "SubLabel"
	sub.text = "Volviendo al laboratorio..."
	sub.set_anchors_preset(Control.PRESET_CENTER)
	sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sub.offset_left = -300.0
	sub.offset_right = 300.0
	sub.offset_top = 60.0
	sub.offset_bottom = 110.0
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 28)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	return sub

func _animate_death_overlay(canvas: CanvasLayer) -> void:
	var root: Control = canvas.get_child(0)
	var bg: ColorRect = root.get_node("BG")
	var lbl: Label = root.get_node("DeathLabel")
	var sub: Label = root.get_node("SubLabel")
	var t = canvas.create_tween().set_parallel(false)
	_setup_show_death_animation(t, bg, lbl, sub)
	_setup_pulse_death_animation(t, lbl)
	_setup_hide_death_animation(t, bg, lbl, sub)
	t.finished.connect(_on_death_animation_finished.bind(canvas))

func _setup_show_death_animation(t: Tween, bg: ColorRect, lbl: Label, _sub: Label) -> void:
	t.tween_property(bg, "color", Color(0, 0, 0, 0.85), 0.5)
	t.tween_property(lbl, "theme_override_colors/font_color", Color(1, 0.1, 0.1, 1), 0.3)
	t.parallel().tween_property(lbl, "theme_override_colors/font_outline_color", Color(0.6, 0, 0, 1), 0.3)

func _setup_pulse_death_animation(t: Tween, lbl: Label) -> void:
	t.tween_property(lbl, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_SINE)
	t.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)

func _setup_hide_death_animation(t: Tween, bg: ColorRect, lbl: Label, sub: Label) -> void:
	t.tween_property(sub, "theme_override_colors/font_color", Color(1, 1, 1, 0.8), 0.4)
	t.tween_interval(1.4)
	t.tween_property(bg, "color", Color(0, 0, 0, 0), 0.5)
	t.parallel().tween_property(lbl, "theme_override_colors/font_color", Color(1, 0.1, 0.1, 0), 0.5)
	t.parallel().tween_property(sub, "theme_override_colors/font_color", Color(1, 1, 1, 0), 0.5)

func _on_death_animation_finished(canvas: CanvasLayer) -> void:
	canvas.queue_free()
	SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
