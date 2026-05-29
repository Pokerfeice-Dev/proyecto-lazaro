extends CanvasLayer
class_name HUD

@export var health_bar: TextureProgressBar
@export var scrap_label: Label
@export var flesh_label: Label
@export var dash_cd_bar: TextureProgressBar
@export var health_label: Label
@export var health_particles: CPUParticles2D

@export var primary_weapon_rect: TextureRect
@export var secondary_weapon_rect: TextureRect
var _dash_was_on_cooldown: bool = false
@export_group("Particles High Health (+70%)")
@export var particles_high_color: Color = Color(0.4, 0.9, 0.6, 0.7)
@export var particles_high_speed: float = 1.0
@export var particles_high_vel_min: float = 80.0
@export var particles_high_vel_max: float = 120.0
@export var particles_high_lifetime: float = 2.0

@export_group("Particles Mid Health (30%-70%)")
@export var particles_mid_color: Color = Color(0.7, 0.3, 0.9, 0.8)
@export var particles_mid_speed: float = 1.8
@export var particles_mid_vel_min: float = 140.0
@export var particles_mid_vel_max: float = 200.0
@export var particles_mid_lifetime: float = 1.2

@export_group("Particles Low Health (-30%)")
@export var particles_low_color: Color = Color(1.0, 0.2, 0.2, 0.9)
@export var particles_low_speed: float = 3.0
@export var particles_low_vel_min: float = 220.0
@export var particles_low_vel_max: float = 320.0
@export var particles_low_lifetime: float = 0.8

@export_group("Particles Fallback Setup")
@export var fallback_particles_amount: int = 40
@export_enum("Point", "Sphere", "Rectangle", "Points", "Directed Points") var fallback_particles_shape: int = 2
@export var fallback_particles_extents: Vector2 = Vector2(1, 20)
@export var fallback_particles_direction: Vector2 = Vector2(1, 0)
@export var fallback_particles_spread: float = 15.0
@export var fallback_particles_gravity: Vector2 = Vector2(0, 0)
@export var fallback_particles_position: Vector2 = Vector2(148, 98)

func _ready():
	add_to_group("hud")
	_setup_health_label()
	_setup_dash_cooldown()
	_setup_health_particles()
	_setup_weapon_hud()
	update_scrap(GameData.scrap)
	update_flesh(GameData.flesh)
	_initialize_health()

func _setup_weapon_hud() -> void:
	var circle_bg = _create_filled_circle_texture(Color(0.05, 0.05, 0.1, 0.7), Color(0.2, 0.8, 1.0, 0.8))
	var primary_panel = get_node_or_null("Control/WeaponHUD/PrimaryPanel")
	if primary_panel and primary_panel is TextureRect:
		primary_panel.texture = circle_bg
	var secondary_panel = get_node_or_null("Control/WeaponHUD/SecondaryPanel")
	if secondary_panel and secondary_panel is TextureRect:
		secondary_panel.texture = circle_bg

func _create_filled_circle_texture(bg_color: Color, border_color: Color) -> ImageTexture:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var center = Vector2(40, 40)
	for x in range(80):
		for y in range(80):
			var d = Vector2(x, y).distance_to(center)
			if d <= 38.0 and d >= 35.0:
				img.set_pixel(x, y, border_color)
			elif d < 35.0:
				img.set_pixel(x, y, bg_color)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)

func _setup_health_label() -> void:
	if health_label: return
	if _find_health_label_node(): return
	_create_health_label_fallback()

func _find_health_label_node() -> bool:
	if not health_bar: return false
	var found = health_bar.get_parent().get_node_or_null("HealthLabel")
	if found:
		health_label = found
		return true
	return false

func _create_health_label_fallback() -> void:
	if not health_bar: return
	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.add_theme_color_override("font_outline_color", Color.BLACK)
	health_label.add_theme_constant_override("outline_size", 4)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_bar.get_parent().add_child(health_label)
	health_label.size = Vector2(272, 40)
	health_label.position = health_bar.position + Vector2(192, 64)


func _initialize_health() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if "stats" in p and p.stats:
			update_health(p.stats.current_health, p.stats.max_health)

func _setup_dash_cooldown() -> void:
	if dash_cd_bar:
		_assign_fallback_textures(dash_cd_bar)
		return
	if _find_dash_bar_node():
		_assign_fallback_textures(dash_cd_bar)
		return
	_create_dash_bar_fallback()

func _assign_fallback_textures(bar: TextureProgressBar) -> void:
	if not bar.texture_under:
		bar.texture_under = _create_circle_texture(Color(0.2, 0.2, 0.2, 0.5))
	if not bar.texture_progress:
		bar.texture_progress = _create_circle_texture(Color(0.2, 0.8, 1.0, 1.0))

func _find_dash_bar_node() -> bool:
	var control = get_node_or_null("Control")
	if not control: return false
	var found = control.get_node_or_null("DashCDBar")
	if found:
		dash_cd_bar = found
		return true
	return false

func _create_dash_bar_fallback() -> void:
	var tex = _create_circle_texture(Color(0.2, 0.8, 1.0, 1.0))
	var tex_bg = _create_circle_texture(Color(0.2, 0.2, 0.2, 0.5))
	
	dash_cd_bar = TextureProgressBar.new()
	dash_cd_bar.texture_under = tex_bg
	dash_cd_bar.texture_progress = tex
	dash_cd_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	dash_cd_bar.max_value = 5.0
	dash_cd_bar.step = 0.01
	dash_cd_bar.value = 5.0
	dash_cd_bar.position = Vector2(64, 120)
	
	var lbl = _create_dash_label()
	dash_cd_bar.add_child(lbl)
	
	var control = get_node_or_null("Control")
	if control:
		control.add_child(dash_cd_bar)

func _create_circle_texture(color: Color) -> ImageTexture:
	var img = Image.create(72, 72, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(72):
		for y in range(72):
			var d = Vector2(x, y).distance_to(center)
			if d <= 30.0 and d >= 22.0:
				img.set_pixel(x, y, color)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)

func _create_dash_label() -> Label:
	var lbl = Label.new()
	lbl.text = "DASH"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	return lbl

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	if "dash_cd_timer" in p and p.dash_cd_timer:
		var time_left = 0.0 if p.dash_cd_timer.is_stopped() else p.dash_cd_timer.time_left
		update_dash_cooldown(time_left, 5.0)
	_update_weapons_hud(p)

func _update_weapons_hud(p: Node2D) -> void:
	if "active_weapon" in p and p.active_weapon:
		var tex = _get_weapon_texture(p.active_weapon)
		if primary_weapon_rect:
			primary_weapon_rect.texture = tex
			
	if "second_weapon" in p and p.second_weapon:
		var tex = _get_weapon_texture(p.second_weapon)
		if secondary_weapon_rect:
			secondary_weapon_rect.texture = tex

func _get_weapon_texture(weapon_container: Node) -> Texture2D:
	if not weapon_container: return null
	var cur = weapon_container.get("current_weapon")
	if not cur: return null
	
	var sprite = cur.get_node_or_null("Melee_sprite")
	if sprite and sprite is Sprite2D:
		return sprite.texture
		
	var anim_sprite = cur.get_node_or_null("Weapon_Sprites")
	if anim_sprite and anim_sprite is AnimatedSprite2D:
		var frames = anim_sprite.sprite_frames
		if frames and frames.has_animation(anim_sprite.animation):
			var frame_count = frames.get_frame_count(anim_sprite.animation)
			if frame_count > 0:
				return frames.get_frame_texture(anim_sprite.animation, 0)
				
	return null

func update_dash_cooldown(time_left: float, max_time: float) -> void:
	if not dash_cd_bar: return
	dash_cd_bar.max_value = max_time
	dash_cd_bar.value = max_time - time_left
	_check_dash_ready_trigger(time_left)

func _check_dash_ready_trigger(time_left: float) -> void:
	if time_left > 0.0:
		_dash_was_on_cooldown = true
		return
	if not _dash_was_on_cooldown:
		return
	_dash_was_on_cooldown = false
	_play_dash_ready_fx()

func _play_dash_ready_fx() -> void:
	if not dash_cd_bar:
		return
	_create_dash_ready_tween()

func _create_dash_ready_tween() -> void:
	var tween = create_tween()
	
	# Primera fase: Brillar intensamente en blanco
	tween.tween_property(dash_cd_bar, "self_modulate", Color(5.0, 5.0, 5.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Segunda fase: Restaurar el color original
	tween.tween_property(dash_cd_bar, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)




func update_health(new_health: int, max_health: int):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = new_health
		# Escalar la barra visualmente en base a la vida (100 = escala 1.0)
		var target_scale = float(max_health) / 100.0
		health_bar.scale.x = target_scale
		
	if health_label:
		health_label.text = "%d / %d" % [new_health, max_health]

		
	_update_health_particles(new_health, max_health)

func update_scrap(amount: int):
	if scrap_label:
		scrap_label.text = str(amount)

func update_flesh(amount: int):
	if flesh_label:
		flesh_label.text = str(amount)

func _setup_health_particles() -> void:
	if health_particles: return
	if _find_health_particles_node(): return
	_create_health_particles_fallback()

func _find_health_particles_node() -> bool:
	if not health_bar: return false
	var found = health_bar.get_parent().get_node_or_null("HealthParticles")
	if found:
		health_particles = found
		return true
	return false

func _create_health_particles_fallback() -> void:
	if not health_bar: return
	health_particles = CPUParticles2D.new()
	health_particles.name = "HealthParticles"
	health_particles.amount = fallback_particles_amount
	health_particles.emission_shape = fallback_particles_shape as CPUParticles2D.EmissionShape
	health_particles.emission_rect_extents = fallback_particles_extents
	health_particles.direction = fallback_particles_direction
	health_particles.spread = fallback_particles_spread
	health_particles.gravity = fallback_particles_gravity
	health_particles.position = fallback_particles_position
	health_bar.get_parent().add_child(health_particles)

func _update_health_particles(new_health: int, max_health: int) -> void:
	if not health_particles: return
	var pct = float(new_health) / float(max_health)
	if pct > 0.70:
		_set_particles_state(particles_high_color, particles_high_speed, particles_high_vel_min, particles_high_vel_max, particles_high_lifetime)
	elif pct >= 0.30:
		_set_particles_state(particles_mid_color, particles_mid_speed, particles_mid_vel_min, particles_mid_vel_max, particles_mid_lifetime)
	else:
		_set_particles_state(particles_low_color, particles_low_speed, particles_low_vel_min, particles_low_vel_max, particles_low_lifetime)

func _set_particles_state(color: Color, speed: float, vel_min: float, vel_max: float, lifetime: float) -> void:
	health_particles.color = color
	health_particles.speed_scale = speed
	health_particles.initial_velocity_min = vel_min
	health_particles.initial_velocity_max = vel_max
	health_particles.lifetime = lifetime
