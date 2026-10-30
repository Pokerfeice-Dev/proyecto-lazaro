extends CharacterBody2D
class_name Player

@export var stats: PlayerStats = PlayerStats.new()
@export var acceleration: float = 2000.0
@export var friction: float = 650
@export var dash_speed: float = 500
@export var dash_duration: float = 0.3
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Projectile.tscn")
@export var weapon_scene: PackedScene = preload("res://Scenes/Weapon/main_weapon.tscn")
@export var second_weapon_scene: PackedScene = preload("res://Scenes/Weapon/second_weapon.tscn")
## Variantes de materialización para comparar desde el Inspector.
@export_enum("Muerte inversa", "Convergencia radial", "Desde el suelo") var arrival_pixel_style: int = 0

@export_category("Weapon Animation Offsets")
@export var animation_frame_offsets: Dictionary = {
	"idle_default": [
		Vector2(0, 0),
		Vector2(0, 1),
		Vector2(0, 2),
		Vector2(0, 1),
		Vector2(0, 0),
		Vector2(0, -1),
		Vector2(0, -2),
		Vector2(0, -1)
	]
}

@export_category("Camera Feedback")
@export var shake_intensity: float = 6.0
@export var shake_duration: float = 0.1
var shake_tween: Tween

@export_category("Damage Effect")
@export var damage_border_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var damage_border_intensity: float = 0.9
@export var low_health_threshold: float = 0.3 # % de vida a partir del cual empieza a latir la pantalla
@export var low_health_pulse_interval: float = 1.0 # segundos entre cada latido
@export var body_part_heal_ratio: float = 0.03 # % de vida máxima que regenera al instalar una pieza de cuerpo nueva
var damage_canvas: CanvasLayer
var damage_rect: ColorRect
var damage_indicator_layer: CanvasLayer # capa para las flechas de daño direccional
var low_health_rect: ColorRect # vignette propio para el latido de vida baja, separado del de golpe recibido
var low_health_sound: AudioStreamPlayer
var low_health_pulse_timer: Timer
var is_low_health: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var can_shoot: bool = true
var minigun_hold_time: float = 0.0
var cerberus_hold_time: float = 0.0
var flame_stream_instance: Area2D = null
var shoot_timer: Timer
var cheat_op_weapon_mode: bool = false

var is_dashing: bool = false
var dash_timer: Timer
var dash_cd_timer: Timer
var dash_dir: Vector2 = Vector2.DOWN
var dash_ghost_timer: float = 0.0
const DASH_GHOST_INTERVAL: float = 0.075

# sonido de pasos al caminar
const FOOTSTEP_INTERVAL: float = 0.35
var footstep_timer: Timer

var last_dir: String = "down"

var is_invulnerable: bool = false
var invuln_timer: Timer

# parpadeo del sprite mientras dura la invulnerabilidad tras recibir daño
var _invuln_blink_timer: Timer

var weapon_hide_timer: Timer

var active_weapon
var second_weapon
var left_melee_weapon
var is_furia_active: bool = false
var furia_timer: Timer
var trituradora_energy: float = 0.0
const TRITURADORA_MAX_ENERGY: float = 600.0
var trituradora_shockwave_ready: bool = false
var _last_active_synergy_state: String = ""
var _werewolf_marked_enemy: Node2D = null
var _werewolf_mark_visual: Node2D = null
# Sinergia Speed Demon: cada golpe de la daga tira al jugador un poco hacia adelante.
const SPEED_DEMON_PUSH_SPEED: float = 420.0
var _speed_demon_push_time: float = 0.0
var _speed_demon_push_dir: Vector2 = Vector2.ZERO
var _speed_demon_driver: Node2D
const WEAPON_SHEET_FPS: float = 9.0 # hojas de varios cuadros de las armas (Holy Fire, etc.)
var _holy_fire_tongue: HolyFireTongue = null
const ALTO_OCTANAJE_RATIO := 1.5 # daño de la explosión respecto del hachazo
const ALTO_OCTANAJE_MIN := 15
const ALTO_OCTANAJE_MAX := 40

var protocols: ProtocolRuntime
var dash_start_pos: Vector2 = Vector2.ZERO

var _default_modulate: Color = Color.WHITE
var _flash_tween: Tween = null
var drop_shadow: DropShadow = null
var _arrogancia_shield: Node2D
var _last_enemy_hit_msec: int = 0
var _arrival_scene_id: int = 0

func _ready() -> void:
	_last_enemy_hit_msec = Time.get_ticks_msec()
	_init_timers()
	setup_damage_effect()
	_init_stats()
	add_to_group("player")
	set_collision_mask_value(5, true) # vacíos de la zona 3: frenan al jugador, no a las balas
	GameData.register_player(self)
	_initialize_protocols()
	_init_weapon()
	_apply_game_data_upgrades()
	_update_hud_health(stats.current_health, stats.max_health)
	_update_hud_scrap(GameData.scrap)
	z_index = 5
	_setup_player_shadow()
	_setup_cinematic_vignette()
	_arrogancia_shield = preload("res://Scripts/Effects/arrogancia_shield.gd").new()
	add_child(_arrogancia_shield)
	
	if anim_sprite:
		_default_modulate = anim_sprite.modulate
		_default_modulate.a = 1.0
		
	var equip = get_node_or_null("Equipment")
	if equip:
		equip.equipment_changed.connect(_on_equipment_changed)
		equip.body_part_equipped.connect(_on_body_part_equipped)
	_update_player_stats()
	get_tree().scene_changed.connect(_queue_arrival_fx)
	hide() # Evita ver el cuerpo completo antes de reunir los píxeles.
	_queue_arrival_fx.call_deferred()

func _queue_arrival_fx() -> void:
	# Espera el posicionamiento de la sala y el final del fade/portal para
	# que los 0,36 segundos del efecto no se consuman detrás de la transición.
	if not is_inside_tree(): return
	await get_tree().process_frame
	if not is_inside_tree(): return
	var scene := get_tree().current_scene
	if not is_instance_valid(scene): return
	var scene_id := scene.get_instance_id()
	if _arrival_scene_id == scene_id: return
	_arrival_scene_id = scene_id
	hide()
	while SceneTransition.is_transitioning:
		await get_tree().process_frame
		if not is_inside_tree(): return
		if not is_instance_valid(scene) or get_tree().current_scene != scene: return
	if is_inside_tree() and stats and stats.current_health > 0:
		preload("res://Scripts/Effects/player_arrival_fx.gd").spawn(self)

func _setup_player_shadow() -> void:
	drop_shadow = DropShadow.attach_to(self, Vector2(26.0, 12.0), Vector2(0.0, 15.0), 0.38)
	add_child(PlayerMarker.new()) # anillo celeste para no perder a Lázaro de vista

func _setup_cinematic_vignette() -> void:
	var vignette = CinematicVignette.new()
	add_child(vignette)

func _on_equipment_changed() -> void:
	_update_player_stats()

# regeneración de vida al instalar una pieza de cuerpo nueva (torso/brazo/pierna)
func _on_body_part_equipped(_item: ItemData) -> void:
	var heal_amount = int(round(stats.max_health * body_part_heal_ratio))
	if heal_amount <= 0: return
	stats.heal(heal_amount)
	_show_heal_text(heal_amount)
	_animate_heal_flash()

func _update_player_stats() -> void:
	var bonus_hp_percent = _get_equip_stat("max_health_percent", false)
	var integrity_lvl = GameData.core_upgrades.get("integridad_estructural", 0)
	var extra_hp = integrity_lvl * 2
	var new_max_hp = int(stats.base_max_health * (1.0 + bonus_hp_percent)) + extra_hp
	if new_max_hp != stats.max_health:
		stats.update_max_health(new_max_hp)
		
	var bonus_speed_percent = _get_equip_stat("move_speed_percent", false)
	var flat_speed = _get_equip_stat("move_speed", false)
	var servo_lvl = GameData.core_upgrades.get("servomotores", 0)
	var perm_speed_mult = 1.0 + (servo_lvl * 0.01)
	stats.move_speed = (stats.base_move_speed + flat_speed) * (1.0 + bonus_speed_percent) * perm_speed_mult
	
	_apply_synergy_weapon_override()
	
	if _is_bestia_de_caza_active():
		if not left_melee_weapon:
			_init_left_melee_weapon()
		if active_weapon:
			active_weapon.hide()
		if second_weapon:
			second_weapon.show()
		if left_melee_weapon:
			left_melee_weapon.show()
	else:
		if left_melee_weapon:
			left_melee_weapon.queue_free()
			left_melee_weapon = null
		if active_weapon:
			active_weapon.show()
			
	sync_weapon_visibility_for_room()
	if not _is_trituradora_active():
		trituradora_shockwave_ready = false
		trituradora_energy = 0.0
		if not is_furia_active:
			self.modulate = Color(1, 1, 1)
			
	_check_and_trigger_first_time_synergies()

var _observed_synergies: Array[String] = []
var _synergy_state_initialized: bool = false

func _check_and_trigger_first_time_synergies() -> void:
	var equip = get_node_or_null("Equipment")
	if not equip: return
	var active: Array[String] = SynergyManager.get_active_synergies(equip, get_active_ranged_weapon_id(), true)
	for id in SynergyManager.get_active_synergies(equip, get_active_melee_weapon_id(), false):
		if not active.has(id): active.append(id)
	# Restoring equipment when entering a room is not a new activation.
	if not _synergy_state_initialized:
		_observed_synergies = active
		_synergy_state_initialized = true
		return
	var newly_active: Array[String] = []
	for id in active:
		if not _observed_synergies.has(id): newly_active.append(id)
	_observed_synergies = active
	for id in newly_active:
		var first_discovery = not GameData.activated_synergies.has(id)
		if first_discovery:
			GameData.activated_synergies.append(id)
			GameData.save_game()
		SynergyManager.present_activation(id, first_discovery)

func _apply_synergy_weapon_override() -> void:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return
	_apply_ranged_synergy_override(equip)
	_apply_melee_synergy_override(equip)

func _apply_ranged_synergy_override(equip: Object) -> void:
	if not active_weapon:
		return
	if not active_weapon.has_method("apply_synergy_weapon_override"):
		return
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	var override_path = SynergyManager.get_synergies_weapon_override(active_syns)
	_print_synergy_debug_status(active_syns, override_path)
	active_weapon.apply_synergy_weapon_override(override_path)

func _apply_melee_synergy_override(equip: Object) -> void:
	if not second_weapon:
		return
	if not second_weapon.has_method("apply_synergy_weapon_override"):
		return
	var active_melee_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_melee_id, false)
	var override_path = SynergyManager.get_synergies_weapon_override(active_syns)
	second_weapon.apply_synergy_weapon_override(override_path)

func _print_synergy_debug_status(active_syns: Array[String], override_path: String) -> void:
	var state_str = ",".join(active_syns) + ":" + override_path
	if _last_active_synergy_state == state_str:
		return
	_last_active_synergy_state = state_str
	
	if active_syns.is_empty():
		print("[SYNERGY DEBUG] No active synergies. Reverting to base weapon.")
		return
	print("[SYNERGY DEBUG] Active Synergies: ", active_syns, " | Weapon Override: ", override_path)

func _init_timers() -> void:
	_create_shoot_timer()
	_create_dash_timer()
	_create_invuln_timer()
	_create_weapon_hide_timer()
	_create_furia_timer()
	_create_footstep_timer()
	_create_low_health_timer()

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
	_create_invuln_blink_timer()

# timer que va togueleando la visibilidad del sprite durante la invulnerabilidad
func _create_invuln_blink_timer() -> void:
	_invuln_blink_timer = Timer.new()
	_invuln_blink_timer.wait_time = 0.06
	add_child(_invuln_blink_timer)
	_invuln_blink_timer.timeout.connect(_toggle_invuln_blink)

func _toggle_invuln_blink() -> void:
	if not anim_sprite: return
	anim_sprite.visible = not anim_sprite.visible

# timer de cooldown para no repetir el sonido de pasos en cada frame
func _create_footstep_timer() -> void:
	footstep_timer = Timer.new()
	footstep_timer.one_shot = true
	add_child(footstep_timer)

# timer que repite el latido (visual + sonido) mientras la vida está baja
func _create_low_health_timer() -> void:
	low_health_pulse_timer = Timer.new()
	low_health_pulse_timer.wait_time = low_health_pulse_interval
	low_health_pulse_timer.one_shot = false
	add_child(low_health_pulse_timer)
	low_health_pulse_timer.timeout.connect(_on_low_health_pulse)

func _create_weapon_hide_timer() -> void:
	weapon_hide_timer = Timer.new()
	weapon_hide_timer.one_shot = true
	add_child(weapon_hide_timer)

func _on_weapon_hide_timeout() -> void:
	pass

func _show_primary_weapon() -> void:
	if _is_bestia_de_caza_active():
		if active_weapon: active_weapon.hide()
		if second_weapon: second_weapon.show()
		if left_melee_weapon: left_melee_weapon.show()
		return
	if active_weapon: active_weapon.show()
	if second_weapon: second_weapon.hide()

func _show_secondary_weapon() -> void:
	if _is_bestia_de_caza_active():
		if active_weapon: active_weapon.hide()
		if second_weapon: second_weapon.show()
		if left_melee_weapon: left_melee_weapon.show()
		return
	if active_weapon: active_weapon.hide()
	if second_weapon: second_weapon.show()

func _init_stats() -> void:
	if not stats: stats = PlayerStats.new()
	stats.health_changed.connect(_on_health_changed)
	GameData.scrap_changed.connect(_on_scrap_changed)
	GameData.flesh_changed.connect(_on_flesh_changed)
	stats.player_died.connect(_on_died)

func _init_weapon() -> void:
	_init_primary_weapon()
	_init_secondary_weapon()
	sync_weapon_visibility_for_room()

## Muestra u oculta las armas según la sala actual (en el laboratorio no
## aparecemos armados). Se llama al inicializar el arma y también cada vez
## que el jugador (que persiste entre salas) vuelve al laboratorio, para no
## dejar visible un arma que quedó mostrada durante la run anterior.
func sync_weapon_visibility_for_room() -> void:
	if _is_in_lab_room():
		_hide_all_weapons()
	else:
		_show_primary_weapon()
	if not _is_in_training_room():
		stats.min_health_floor = 0

func _is_in_lab_room() -> bool:
	var scene = get_tree().current_scene
	return scene != null and scene.name == "Lab_room"

# en la tienda de Ygor no se dispara (se compra)
func _is_in_shop_room() -> bool:
	var ygor = get_tree().get_first_node_in_group("ygor")
	return ygor != null and ygor.is_inside_tree()

func _is_in_training_room() -> bool:
	var scene = get_tree().current_scene
	return scene != null and scene.name in ["Training_Room", "Tutorial_Room"]

func _hide_all_weapons() -> void:
	if active_weapon: active_weapon.hide()
	if second_weapon: second_weapon.hide()
	if left_melee_weapon: left_melee_weapon.hide()

func _init_primary_weapon() -> void:
	if not weapon_scene: return
	active_weapon = weapon_scene.instantiate()
	add_child(active_weapon)

func _init_secondary_weapon() -> void:
	if not second_weapon_scene: return
	second_weapon = second_weapon_scene.instantiate()
	add_child(second_weapon)
	# "second_weapon" no es un arma real (mismo ícono que la daga): daga/maza/hacha ya se unlockean solas en second_weapon_container.gd según cuál esté equipada.
 

func _apply_game_data_upgrades() -> void:
	if active_weapon and active_weapon.has_method("get_damage"):
		GameData.apply_to_weapon(active_weapon)
	GameData.apply_to_melee(second_weapon)

var is_cutscene_frozen: bool = false

func freeze_player() -> void:
	if is_instance_valid(_arrogancia_shield):
		_arrogancia_shield.set_active(false)
	is_cutscene_frozen = true
	velocity = Vector2.ZERO
	can_shoot = false
	set_physics_process(false)
	set_process(false)

func unfreeze_player() -> void:
	is_cutscene_frozen = false
	can_shoot = true
	set_physics_process(true)
	set_process(true)

func _physics_process(delta: float) -> void:
	if is_cutscene_frozen:
		velocity = Vector2.ZERO
		return
	_update_minigun_hold_time(delta)
	_update_cerberus_hold_time(delta)
	_update_melee_synergy_visual(delta)
	_ensure_werewolf_mark()
	_update_ranged_synergy_visual(delta)
	_check_dash_input()
	_process_movement(delta)
	update_glock()
	_update_camera_drift(delta)
	_process_actions()
	_arrogancia_shield.set_active(_is_arrogancia_reflect_active())
	move_and_slide()
	update_animation()

func record_enemy_hit(_enemy: Node2D = null) -> void:
	_last_enemy_hit_msec = Time.get_ticks_msec()
	if protocols: protocols.note_target(_enemy)

func get_seconds_since_enemy_hit() -> float:
	return float(Time.get_ticks_msec() - _last_enemy_hit_msec) / 1000.0

func _check_dash_input() -> void:
	if not Input.is_action_just_pressed("dash"): return
	if is_dashing: return
	if not dash_cd_timer.is_stopped(): return
	_start_dash()

func _start_dash() -> void:
	is_dashing = true
	RunLog.note("dashes")
	dash_start_pos = global_position
	set_collision_mask_value(2, false)
	dash_timer.start(dash_duration)
	var bonus_cd_pct = _get_equip_stat("dash_cooldown_percent", false)
	var final_cd = maxf(1.0, 5.0 * (1.0 + bonus_cd_pct))
	dash_cd_timer.start(final_cd)
	_set_dash_direction()
	_play_dash_sound()
	_spawn_dash_dust()
	_trigger_initial_dash_ghost()
	_trigger_dash_synergies()

func _trigger_initial_dash_ghost() -> void:
	dash_ghost_timer = DASH_GHOST_INTERVAL
	_spawn_dash_ghost()

func _trigger_dash_synergies() -> void:
	if _is_bestia_de_caza_active():
		_start_furia()
	if _is_trituradora_active() and trituradora_shockwave_ready:
		_trigger_trituradora_shockwave()

func _set_dash_direction() -> void:
	if velocity == Vector2.ZERO:
		dash_dir = _get_dir_vector(last_dir)
		return
	dash_dir = velocity.normalized()

func _spawn_dash_dust() -> void:
	var dust = CPUParticles2D.new()
	dust.z_as_relative = false
	dust.z_index = 100
	dust.global_position = global_position + Vector2(0, 10)
	dust.emitting = false
	dust.one_shot = true
	dust.explosiveness = 0.9
	dust.lifetime = 0.45
	dust.amount = 14
	dust.direction = -dash_dir
	dust.spread = 50.0
	dust.gravity = Vector2(0, -20)
	dust.initial_velocity_min = 80.0
	dust.initial_velocity_max = 160.0
	dust.damping_min = 100.0
	dust.damping_max = 140.0
	dust.scale_amount_min = 5.0
	dust.scale_amount_max = 9.0
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.92, 0.88, 0.82, 0.95))
	gradient.set_color(1, Color(0.85, 0.82, 0.78, 0.0))
	dust.color_ramp = gradient
	
	get_tree().current_scene.add_child(dust)
	dust.emitting = true
	dust.finished.connect(dust.queue_free)

func _process_movement(delta: float) -> void:
	if is_dashing:
		_apply_dash_movement()
		_process_dash_ghosts(delta)
		return
	if _speed_demon_push_time > 0.0:
		_apply_speed_demon_push(delta)
		return
	handle_movement(delta)
	_accumulate_trituradora_energy(delta)

func _apply_dash_movement() -> void:
	var bonus_dash_speed_pct = _get_equip_stat("dash_speed_percent", false)
	var final_dash_speed = dash_speed * (1.0 + bonus_dash_speed_pct)
	velocity = dash_dir * final_dash_speed

func _process_dash_ghosts(delta: float) -> void:
	dash_ghost_timer -= delta
	if dash_ghost_timer > 0.0: return
	dash_ghost_timer = DASH_GHOST_INTERVAL
	_spawn_dash_ghost()

func _spawn_dash_ghost() -> void:
	if not anim_sprite or not is_instance_valid(anim_sprite): return
	if not anim_sprite.sprite_frames: return
	var texture = anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
	if not texture: return
	
	var ghost = Sprite2D.new()
	_configure_ghost_transform(ghost, texture)
	_configure_ghost_visuals(ghost)
	_animate_and_cleanup_ghost(ghost)

func _configure_ghost_transform(ghost: Sprite2D, texture: Texture2D) -> void:
	ghost.texture = texture
	ghost.global_position = anim_sprite.global_position
	ghost.scale = anim_sprite.scale
	ghost.flip_h = anim_sprite.flip_h
	ghost.rotation = anim_sprite.rotation
	ghost.offset = anim_sprite.offset

func _configure_ghost_visuals(ghost: Sprite2D) -> void:
	ghost.z_as_relative = false
	ghost.z_index = maxi(1, z_index - 1)
	ghost.modulate = _get_dash_ghost_color()
	
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ghost.material = mat
	
	get_tree().current_scene.add_child(ghost)

func _get_dash_ghost_color() -> Color:
	if is_furia_active:
		return Color(1.3, 0.35, 0.35, 0.65)
	return Color(0.35, 0.75, 1.25, 0.65)

func _animate_and_cleanup_ghost(ghost: Sprite2D) -> void:
	var tween = ghost.create_tween().set_parallel(true)
	var fade_duration = 0.28
	tween.tween_property(ghost, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", ghost.scale * 1.08, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(ghost.queue_free)

func _process_actions() -> void:
	if is_dashing: return
	if _is_in_lab_room() or _is_in_shop_room(): return
	handle_shooting()
	handle_melee()

func handle_melee() -> void:
	# Mantener el ataque encadena ciclos completos de motor de Speed Demon.
	var speed_demon = _is_speed_demon_active()
	var pressed = Input.is_action_pressed("attack_melee") if speed_demon else Input.is_action_just_pressed("attack_melee")
	if not pressed: return
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
	# capa aparte para las flechas de daño direccional
	damage_indicator_layer = CanvasLayer.new()
	damage_indicator_layer.layer = 100
	add_child(damage_indicator_layer)
	_setup_low_health_effect()
	_setup_enemy_compass()

func _setup_enemy_compass() -> void:
	var compass_script = load("res://Scripts/UI/enemy_compass.gd")
	if not compass_script: return
	var compass = compass_script.new()
	damage_indicator_layer.add_child(compass)

func _apply_damage_material() -> void:
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = _get_damage_shader_code()
	mat.shader = shader
	mat.set_shader_parameter("border_color", damage_border_color)
	mat.set_shader_parameter("intensity", 0.0)
	damage_rect.material = mat
	damage_canvas.add_child(damage_rect)

# vignette propio para el latido de vida baja, con su propio material para no
# pisar la animación del golpe recibido, más el sonido del latido
func _setup_low_health_effect() -> void:
	low_health_rect = ColorRect.new()
	low_health_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	low_health_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = _get_damage_shader_code()
	mat.shader = shader
	mat.set_shader_parameter("border_color", damage_border_color)
	mat.set_shader_parameter("intensity", 0.0)
	low_health_rect.material = mat
	damage_canvas.add_child(low_health_rect)

	low_health_sound = AudioStreamPlayer.new()
	var heartbeat_path = "res://Audio/Sfx/Low_health_heartbeat.wav"
	if ResourceLoader.exists(heartbeat_path):
		low_health_sound.stream = load(heartbeat_path)
	low_health_sound.bus = "SFX"
	add_child(low_health_sound)

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
	_play_footstep_sound()

var _footstep_side: int = 1

# sonido y efectos de pasos, con cooldown para que no suene en cada frame
func _play_footstep_sound() -> void:
	if not footstep_timer.is_stopped(): return
	footstep_timer.start(FOOTSTEP_INTERVAL)
	_play_footstep_sfx()
	_spawn_player_footstep_fx()

func _play_footstep_sfx() -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://Audio/Sfx/Pasos.wav")
	sfx_player.bus = "SFX"
	sfx_player.volume_db = -8.0
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

const FootstepFXScript = preload("res://Scripts/Effects/footstep_fx.gd")

func _spawn_player_footstep_fx() -> void:
	var move_dir = velocity.normalized()
	if move_dir == Vector2.ZERO:
		move_dir = _get_dir_vector(last_dir)
	var foot_pos = global_position + Vector2(0, 10)
	_footstep_side = -_footstep_side
	FootstepFXScript.spawn_footstep(get_tree(), foot_pos, move_dir, false, _footstep_side)


var _speed_modifiers: Dictionary = {}

func set_speed_modifier(source_id: String, multiplier: float) -> void:
	_speed_modifiers[source_id] = multiplier
	_update_speed_modifier_visuals()

func remove_speed_modifier(source_id: String) -> void:
	_speed_modifiers.erase(source_id)
	_update_speed_modifier_visuals()

func _get_external_speed_multiplier() -> float:
	var mult = 1.0
	for m in _speed_modifiers.values():
		mult *= m
	return mult

func _update_speed_modifier_visuals() -> void:
	if not anim_sprite: return
	if _speed_modifiers.has("ice_puddle"):
		anim_sprite.modulate = Color(0.65, 0.85, 1.3, 1.0)
		return
	anim_sprite.modulate = _default_modulate

func _apply_friction(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func _apply_acceleration(input_dir: Vector2, delta: float) -> void:
	var final_speed = stats.move_speed * _get_external_speed_multiplier()
	if _is_minigun_active() and Input.is_action_pressed("shoot") and can_shoot:
		final_speed = _apply_minigun_speed_penalty(final_speed)
	velocity = velocity.move_toward(input_dir * final_speed, acceleration * delta)

func _apply_minigun_speed_penalty(base_val: float) -> float:
	var level = _get_minigun_level()
	if level == 1:
		return base_val * 0.97
	if level == 2:
		return base_val * 0.94
	if level == 3:
		return base_val * 0.91
	if level == 4:
		return base_val * 0.88
	if level == 5:
		return base_val * 0.85
	return base_val

func _update_last_dir(input_dir: Vector2) -> void:
	last_dir = _get_8_dir_string(input_dir)

func _get_8_dir_string(dir: Vector2) -> String:
	var angle = dir.angle()
	if angle < 0:
		angle += 2 * PI
	var sector = int(round(angle / (PI / 4.0))) % 8
	match sector:
		0: return "right"
		1: return "down_right"
		2: return "down"
		3: return "down_left"
		4: return "left"
		5: return "up_left"
		6: return "up"
		7: return "up_right"
	return "down"


func handle_shooting() -> void:
	if _is_bestia_de_caza_active():
		if Input.is_action_just_pressed("shoot"):
			_attack_left_melee()
		return
	if _is_cerberus_active():
		_handle_cerberus_stream()
		return
	if is_instance_valid(flame_stream_instance):
		_force_stop_flame_stream()
	if not can_shoot: return
	if not Input.is_action_pressed("shoot"): return
	var shoot_dir = (get_aim_position() - global_position).normalized()
	if shoot_dir == Vector2.ZERO: return
	fire_projectile(shoot_dir)

func _get_equip_stat(stat_name: String, is_main: bool = true) -> float:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return 0.0
	var bonus = 0.0
	var char_stats = equip.get_character_stats()
	if char_stats.has(stat_name):
		bonus += float(char_stats[stat_name])
	
	if is_main:
		var w_stats = equip.get_main_weapon_stats()
		if w_stats.has(stat_name):
			bonus += float(w_stats[stat_name])
	else:
		var w_stats = equip.get_secondary_weapon_stats()
		if w_stats.has(stat_name):
			bonus += float(w_stats[stat_name])
			
	var active_weapon_id = get_active_ranged_weapon_id() if is_main else get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, is_main)
	bonus += SynergyManager.get_synergies_stat_modifier(active_syns, stat_name)
	
	if stat_name == "attack_speed":
		if is_furia_active:
			bonus += 0.50
		if protocols and protocols.is_fury_active():
			bonus += 0.35
		
	if is_main:
		bonus += _get_minigun_stat_bonus(stat_name)
		bonus += _get_cerberus_range_bonus(stat_name)
	else:
		bonus += _get_daga_del_odio_bonus(stat_name)
		
	return bonus

func get_active_ranged_weapon_id() -> String:
	if not active_weapon:
		return ""
	if active_weapon.has_method("get_base_weapon_id"):
		return active_weapon.get_base_weapon_id()
	var cur = active_weapon.get("current_weapon")
	if not cur:
		return active_weapon.get("id") if "id" in active_weapon else ""
	return cur.get("id") if "id" in cur else ""

func get_active_melee_weapon_id() -> String:
	if not second_weapon:
		return ""
	# el arma base (hacha, maza, daga), no la escena que la reemplaza con la
	# sinergia: si no, al cambiar al arma de la sinergia esta se desactivaba sola
	if second_weapon.has_method("get_base_weapon_id"):
		var base_id: String = second_weapon.get_base_weapon_id()
		if base_id != "":
			return base_id
	var cur = second_weapon.get("current_weapon")
	if not cur:
		return ""
	return cur.get("id") if "id" in cur else ""

func fire_projectile(dir: Vector2) -> void:
	_show_primary_weapon()
	can_shoot = false
	var base_aps = 1.0
	var bonus_aps_pct = _get_equip_stat("attack_speed")
	var final_aps = base_aps * (1.0 + bonus_aps_pct)
	var final_fire_rate = 1.0 / maxf(0.1, final_aps)
	var fire_point = global_position
	var p_scene = projectile_scene
	var dmg = (10.0 + _get_equip_stat("damage")) * (1.0 + _get_equip_stat("damage_multiplier"))
	var p_speed = 600.0 + _get_equip_stat("projectile_speed")
	var bullets = 1 + int(_get_equip_stat("bullet_count"))
	var spread = 0.0 + _get_equip_stat("cone_spread_angle")
	var piercing = 0 + int(_get_equip_stat("piercing"))
	var crit_chance = 0.0 + _get_equip_stat("crit_chance")
	var crit_damage = 2.0 + _get_equip_stat("crit_damage")
	var lifetime = 3.0 + _get_equip_stat("lifetime")

	if active_weapon:
		var w_base_aps = _get_weapon_attack_speed()
		var w_final_aps = w_base_aps * (1.0 + bonus_aps_pct)
		final_fire_rate = 1.0 / maxf(0.1, w_final_aps)
		p_scene = _get_weapon_proj_scene(p_scene)
		dmg = (_get_weapon_damage() + _get_equip_stat("damage")) * (_get_weapon_damage_multiplier() + _get_equip_stat("damage_multiplier"))
		p_speed = _get_weapon_proj_speed() + _get_equip_stat("projectile_speed")
		bullets = _get_weapon_bullets() + int(_get_equip_stat("bullet_count"))
		spread = maxf(0.0, _get_weapon_spread() + _get_equip_stat("cone_spread_angle"))
		piercing = _get_weapon_piercing() + int(_get_equip_stat("piercing"))
		crit_chance = _get_weapon_crit_chance() + _get_equip_stat("crit_chance")
		crit_damage = _get_weapon_crit_damage() + _get_equip_stat("crit_damage")
		lifetime = _get_weapon_lifetime() + _get_equip_stat("lifetime")
		_play_weapon_effects()
		fire_point = _get_weapon_mark(fire_point)

	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	var override_scene = SynergyManager.get_synergies_projectile_override(active_syns)
	if override_scene:
		p_scene = override_scene

	if not p_scene:
		return
	if cheat_op_weapon_mode:
		dmg = 50.0
		final_fire_rate = 0.05
	bullets = _calculate_final_bullet_count(bullets, p_scene, active_weapon_id)
	spread = _calculate_final_spread(spread, p_scene, active_weapon_id)
	shoot_timer.start(final_fire_rate)
	_spawn_bullets(p_scene, bullets, spread, dir, dmg, p_speed, fire_point, piercing, crit_chance, crit_damage, lifetime)
	apply_camera_shake()

func _get_weapon_proj_scene(fallback: PackedScene) -> PackedScene:
	if not active_weapon.has_method("get_projectile_scene"): return fallback
	var ws = active_weapon.get_projectile_scene()
	if not ws: return fallback
	return ws

func _get_weapon_attack_speed() -> float:
	if not active_weapon.has_method("get_attack_speed"): return 0.5
	return active_weapon.get_attack_speed()

func _get_weapon_damage_multiplier() -> float:
	if not active_weapon.has_method("get_damage_multiplier"): return 1.0
	return active_weapon.get_damage_multiplier()

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

func _get_weapon_crit_damage() -> float:
	if not active_weapon.has_method("get_crit_damage"): return 2.0
	return active_weapon.get_crit_damage()

func _get_weapon_lifetime() -> float:
	if not active_weapon.has_method("get_lifetime"): return 3.0
	return active_weapon.get_lifetime()

func _play_weapon_effects() -> void:
	if active_weapon and active_weapon.has_method("play_shoot_effects"):
		active_weapon.play_shoot_effects()
	
	# Fallback para armas viejas que no usan el nuevo sistema
	var weapon_anim = active_weapon.get_node_or_null("Weapon_Sprites")
	if weapon_anim:
		weapon_anim.stop()
		weapon_anim.play("shoot")
		
	var w_sound = active_weapon.get_node_or_null("Bullet_sound")
	if w_sound and w_sound.has_method("play"):
		w_sound.bus = "SFX"
		w_sound.play()

func _get_weapon_mark(fallback: Vector2) -> Vector2:
	if active_weapon and active_weapon.has_method("get_bullet_spawn_pos"):
		var pos = active_weapon.get_bullet_spawn_pos(fallback)
		if pos != fallback: return pos
		
	var mark_node = active_weapon.get_node_or_null("Bullet_mark_right")
	if not mark_node: return fallback
	return mark_node.global_position

func _spawn_bullets(p_scene: PackedScene, count: int, spread: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float, crit_damage: float, lifetime: float) -> void:
	var start_angle = _get_start_angle(dir, count, spread)
	var step_angle = _get_step_angle(count, spread)
	_instantiate_bullets(p_scene, count, start_angle, step_angle, dir, dmg, p_speed, spawn_pos, piercing, crit_chance, crit_damage, lifetime)

func _get_start_angle(dir: Vector2, count: int, spread: float) -> float:
	var angle = dir.angle()
	if count <= 1: return angle
	return angle - (deg_to_rad(spread) / 2.0)

func _get_step_angle(count: int, spread: float) -> float:
	if count <= 1: return 0.0
	return deg_to_rad(spread) / float(count - 1)

func _instantiate_bullets(p_scene: PackedScene, count: int, start_angle: float, step_angle: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float, crit_damage: float, lifetime: float) -> void:
	for i in range(count):
		_spawn_single_bullet(p_scene, i, count, start_angle, step_angle, dir, dmg, p_speed, spawn_pos, piercing, crit_chance, crit_damage, lifetime)

func _spawn_single_bullet(p_scene: PackedScene, i: int, count: int, start_angle: float, step_angle: float, dir: Vector2, dmg: float, p_speed: float, spawn_pos: Vector2, piercing: int, crit_chance: float, crit_damage: float, lifetime: float) -> Node2D:
	var final_dir = dir
	if count > 1:
		final_dir = Vector2.RIGHT.rotated(start_angle + (step_angle * float(i)))
	var proj = p_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	
	var final_dmg = dmg * protocol_damage_multiplier()
	if protocol_damage_multiplier() > 1.0:
		proj.set_meta("protocol_metric", "overload_damage")
		proj.set_meta("protocol_bonus_ratio", 1.0 - 1.0 / protocol_damage_multiplier())
	var is_crit = false
	if randf() <= crit_chance:
		final_dmg *= crit_damage
		is_crit = true
		
	proj.setup(final_dir, final_dmg, "enemy", is_crit)
	if "speed" in proj: proj.speed = p_speed
	if "piercing" in proj: proj.piercing = piercing
	if "lifetime" in proj: proj.lifetime = lifetime
	if "fragmentation_chance" in proj:
		proj.fragmentation_chance = _get_fragmentation_chance()
	_apply_bullet_proc_status_if_supported(proj)
	_configure_bee_swarm_if_supported(proj, i, count, final_dir)
	_assign_homing_target_if_supported(proj, i)
	return proj

func _apply_bullet_proc_status_if_supported(proj: Node2D) -> void:
	if not proj.has_method("set_status_effect"): return
	var effect = _roll_bullet_status_effect()
	if effect.is_empty(): return
	proj.set_status_effect(effect)

func _roll_bullet_status_effect(is_main: bool = true) -> String:
	var active_effects: Array[String] = []
	if _should_proc_status("stun_chance", is_main): active_effects.append("stun")
	if _should_proc_status("burn_chance", is_main): active_effects.append("burn")
	if _should_proc_status("slow_chance", is_main): active_effects.append("slow")
	if active_effects.is_empty(): return ""
	return active_effects.pick_random()

func _should_proc_status(stat_name: String, is_main: bool = true) -> bool:
	var chance = clampf(_get_equip_stat(stat_name, is_main), 0.0, 1.0)
	if chance <= 0.0: return false
	return randf() <= chance

func _calculate_final_bullet_count(current_bullets: int, p_scene: PackedScene, active_weapon_id: String) -> int:
	if active_weapon_id == "hivemind_pistol":
		return 3
	if _is_snowball(p_scene):
		return 1 # Snowman: una sola bola grande, aunque las piezas sumen proyectiles
	if p_scene and "beeprojectile" in p_scene.resource_path.to_lower():
		return 3
	return current_bullets

func _calculate_final_spread(current_spread: float, p_scene: PackedScene, active_weapon_id: String) -> float:
	if active_weapon_id == "hivemind_pistol":
		return maxf(50.0, current_spread)
	if _is_snowball(p_scene):
		return 0.0
	if p_scene and "beeprojectile" in p_scene.resource_path.to_lower():
		return maxf(50.0, current_spread)
	return current_spread

func _is_snowball(p_scene: PackedScene) -> bool:
	return p_scene != null and "snowball" in p_scene.resource_path.to_lower()

func _configure_bee_swarm_if_supported(proj: Node2D, index: int, total: int, initial_dir: Vector2) -> void:
	if not proj.has_method("setup_bee_swarm"):
		return
	proj.setup_bee_swarm(index, total, initial_dir)

func _assign_homing_target_if_supported(proj: Node2D, index: int = 0) -> void:
	if not proj.has_method("set_homing_target"):
		return
	var target = _get_cone_target_enemy_for_index(index)
	if not target:
		return
	proj.set_homing_target(target)

func _get_cone_target_enemy_for_index(index: int) -> Node2D:
	var enemies = _get_cone_enemies_list()
	if enemies.is_empty():
		return null
	if enemies.size() == 1:
		return enemies[0] as Node2D
	var target_index = index % enemies.size()
	return enemies[target_index] as Node2D

func _get_cone_enemies_list() -> Array:
	if not active_weapon:
		return []
	var cur = active_weapon.get("current_weapon")
	if not cur:
		return []
	var cone_aim = _get_cone_aim_node(cur)
	if not cone_aim:
		return []
	cone_aim.monitoring = true
	cone_aim.collision_mask = 2
	var bodies = cone_aim.get_overlapping_bodies()
	var enemies: Array = []
	for b in bodies:
		if not b.is_in_group("enemy"):
			continue
		enemies.append(b)
	return enemies

func _get_cone_target_enemy() -> Node2D:
	var enemies = _get_cone_enemies_list()
	if enemies.is_empty():
		return null
	return _find_closest_enemy_in_list(enemies)

func _get_cone_aim_node(cur: Node) -> Area2D:
	var node = cur.get_node_or_null("Cone_Aim")
	if not node:
		node = cur.get_node_or_null("cone_aim")
	return node as Area2D

func _find_closest_enemy_in_list(bodies: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist = INF
	for body in bodies:
		if not body.is_in_group("enemy"):
			continue
		var dist = global_position.distance_to(body.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = body
	return closest

func apply_camera_shake() -> void:
	if not FxSettings.on("sacudida_camara"): return
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	_reset_camera_shake(camera)
	_start_camera_shake(camera)

func apply_custom_camera_shake(intensity: float = 16.0, duration: float = 1.0) -> void:
	if not FxSettings.on("sacudida_camara"): return
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	_reset_camera_shake(camera)
	_start_custom_camera_shake(camera, intensity, duration)

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

func _start_custom_camera_shake(camera: Camera2D, intensity: float, duration: float) -> void:
	shake_tween = create_tween()
	var steps = int(duration / 0.05)
	for i in range(steps):
		var decay = 1.0 - (float(i) / float(steps))
		var current_intensity = intensity * decay
		var random_offset = Vector2(randf_range(-current_intensity, current_intensity), randf_range(-current_intensity, current_intensity))
		shake_tween.tween_property(camera, "offset", random_offset, 0.05).set_trans(Tween.TRANS_SINE)
	shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.05).set_trans(Tween.TRANS_SINE)

func _update_camera_drift(delta: float) -> void:
	var camera = get_node_or_null("Camera2D")
	if not camera: return
	
	var mouse_offset = get_aim_position() - global_position
	var weight = 0.18
	var target_local_pos = mouse_offset * weight
	var max_offset = 120.0
	
	if target_local_pos.length() > max_offset:
		target_local_pos = target_local_pos.normalized() * max_offset
		
	camera.position = camera.position.lerp(target_local_pos, 1.0 - exp(-7.0 * delta))

## Punto al que apunta el jugador: el mouse con teclado, el analógico derecho
## con joystick (ver InputMode). Lo usan las armas, la cámara y los enemigos.
func get_aim_position() -> Vector2:
	if InputMode.is_gamepad():
		return InputMode.aim_point(global_position, velocity)
	return get_global_mouse_position()

func update_glock() -> void:
	var mouse_pos = get_aim_position()
	var dir = (mouse_pos - global_position).normalized()
	var orbit_radius = 25.0
	_update_primary_weapon_pivot(mouse_pos, dir, orbit_radius)
	_update_secondary_weapon_pivot(mouse_pos, dir, orbit_radius)

func _update_primary_weapon_pivot(mouse_pos: Vector2, dir: Vector2, _orbit_radius: float) -> void:
	if not active_weapon:
		return
	var base_pos = _get_weapon_base_position(dir)
	active_weapon.look_at(mouse_pos)
	active_weapon.position = base_pos
	_flip_weapon(active_weapon, dir)
	active_weapon.show_behind_parent = dir.y < 0

func _update_secondary_weapon_pivot(mouse_pos: Vector2, dir: Vector2, _orbit_radius: float) -> void:
	if is_instance_valid(_speed_demon_driver) and _speed_demon_driver.is_attacking():
		dir = _speed_demon_driver.drive_direction
		mouse_pos = global_position + dir * 1000.0
	var base_pos = _get_weapon_base_position(dir)
	if second_weapon:
		second_weapon.look_at(mouse_pos)
		second_weapon.position = base_pos
		_flip_weapon(second_weapon, dir)
		second_weapon.show_behind_parent = dir.y < 0
	if left_melee_weapon:
		left_melee_weapon.look_at(mouse_pos)
		left_melee_weapon.position = base_pos
		_flip_weapon(left_melee_weapon, dir)
		left_melee_weapon.show_behind_parent = dir.y < 0

func _get_weapon_base_position(dir: Vector2) -> Vector2:
	var base_pos = _get_static_weapon_mark_position(dir)
	var anim_offset = _get_animation_offset()
	var final_offset = _apply_flip_to_offset(anim_offset, dir.x < 0)
	return base_pos + final_offset

func _get_static_weapon_mark_position(dir: Vector2) -> Vector2:
	var mark_node = get_node_or_null("Weapon_mark")
	if not mark_node:
		return Vector2.ZERO
	return _apply_flip_to_offset(mark_node.position, dir.x < 0)

func _get_animation_offset() -> Vector2:
	if not anim_sprite:
		return Vector2.ZERO
	return _calculate_frame_offset(anim_sprite.animation, anim_sprite.frame)

func _calculate_frame_offset(anim_name: String, frame_idx: int) -> Vector2:
	var offsets = _get_offsets_for_animation(anim_name)
	if offsets.is_empty():
		return Vector2.ZERO
	if frame_idx < 0 or frame_idx >= offsets.size():
		return Vector2.ZERO
	return offsets[frame_idx]

func _get_offsets_for_animation(anim_name: String) -> Array:
	if animation_frame_offsets.has(anim_name):
		return animation_frame_offsets[anim_name]
	if anim_name.begins_with("idle") and animation_frame_offsets.has("idle_default"):
		return animation_frame_offsets["idle_default"]
	return []

func _apply_flip_to_offset(offset: Vector2, should_flip: bool) -> Vector2:
	if should_flip:
		return Vector2(-offset.x, offset.y)
	return offset


func _flip_weapon(weapon: Node2D, dir: Vector2) -> void:
	var base_scale = abs(weapon.scale.x)
	if dir.x < 0:
		weapon.scale.y = -base_scale
		return
	weapon.scale.y = base_scale

func update_animation() -> void:
	_update_facing_direction()
	if not anim_sprite:
		return
	_play_player_sprite_animation()

func _update_facing_direction() -> void:
	var mouse_dir = (get_aim_position() - global_position).normalized()
	if mouse_dir != Vector2.ZERO:
		last_dir = _get_8_dir_string(mouse_dir)


func _play_player_sprite_animation() -> void:
	if is_dashing:
		_play_dash_animation()
		return
	if velocity.length() > 50:
		_play_run_animation()
		return
	_play_idle_animation()

func _play_dash_animation() -> void:
	var suffix = _get_dash_dir_suffix(last_dir)
	anim_sprite.play("Dash_" + suffix)

func _get_dash_dir_suffix(dir_str: String) -> String:
	if dir_str == "down_left":
		return "left_down"
	if dir_str == "up_left":
		return "left_up"
	if dir_str == "down_right":
		return "right_down"
	if dir_str == "up_right":
		return "right_up"
	return dir_str

func _play_run_animation() -> void:
	if _is_diagonal(last_dir):
		anim_sprite.play("run_diagonal_" + last_dir)
		return
	anim_sprite.play("run_" + last_dir)

func _play_idle_animation() -> void:
	if _is_diagonal(last_dir):
		anim_sprite.play("idle_diagonal_" + last_dir)
		return
	anim_sprite.play("idle_" + last_dir)

func _is_diagonal(dir_str: String) -> bool:
	return dir_str in ["up_left", "up_right", "down_left", "down_right"]


func _get_dir_vector(dir_str: String) -> Vector2:
	if dir_str == "up": return Vector2.UP
	if dir_str == "down": return Vector2.DOWN
	if dir_str == "right": return Vector2.RIGHT
	if dir_str == "left": return Vector2.LEFT
	if dir_str == "up_right": return Vector2(1, -1).normalized()
	if dir_str == "up_left": return Vector2(-1, -1).normalized()
	if dir_str == "down_right": return Vector2(1, 1).normalized()
	if dir_str == "down_left": return Vector2(-1, 1).normalized()
	return Vector2.DOWN


func _on_furia_timeout() -> void:
	is_furia_active = false
	if trituradora_shockwave_ready:
		self.modulate = Color(0.2, 0.8, 1.0)
	else:
		self.modulate = Color(1, 1, 1)
	set_collision_mask_value(2, true)

func _accumulate_trituradora_energy(delta: float) -> void:
	if not _is_trituradora_active():
		return
	if trituradora_shockwave_ready:
		return
	var moved_dist = velocity.length() * delta
	if moved_dist > 0.01:
		trituradora_energy += moved_dist
		if trituradora_energy >= TRITURADORA_MAX_ENERGY:
			trituradora_energy = TRITURADORA_MAX_ENERGY
			trituradora_shockwave_ready = true
			_play_shockwave_ready_effect()

func _play_shockwave_ready_effect() -> void:
	if not is_furia_active:
		self.modulate = Color(0.2, 0.8, 1.0)

func _is_trituradora_active() -> bool:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return false
	var active_syns = SynergyManager.get_active_synergies(equip, "")
	return "trituradora_biomecanica" in active_syns

func _trigger_trituradora_shockwave() -> void:
	trituradora_shockwave_ready = false
	trituradora_energy = 0.0
	self.modulate = Color(1, 1, 1)
	
	# Invulnerability for 0.5s
	is_invulnerable = true
	invuln_timer.start(0.5)
	_invuln_blink_timer.start()
	var original_modulate = self.modulate
	self.modulate = Color(0.2, 0.8, 1.0, 0.6)
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.5)
	
	# Damage and knockback area attack
	var base_dmg = 50.0
	var dmg_radius = 150.0
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < dmg_radius:
			enemy.take_damage(int(base_dmg))
			record_enemy_hit(enemy)
			if enemy.has_method("apply_knockback"):
				var dir = (enemy.global_position - global_position).normalized()
				if dir == Vector2.ZERO: dir = Vector2.UP
				enemy.apply_knockback(250.0, dir)
				
	# Spawn shockwave visual effect
	var wave = load("res://Scripts/Effects/furia_shockwave.gd").new()
	wave.global_position = global_position
	wave.max_radius = dmg_radius
	wave.set_meta("color_fill", Color(0.2, 0.8, 1.0, 0.3))
	wave.set_meta("color_stroke", Color(0.4, 0.9, 1.0, 0.7))
	get_tree().current_scene.add_child(wave)

func _start_furia() -> void:
	is_furia_active = true
	if furia_timer:
		furia_timer.start(3.0)
	self.modulate = Color(1.0, 0.2, 0.2)
	set_collision_mask_value(2, false)

func _apply_thorns_knockback(force: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("apply_knockback"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 80.0:
			var dir = (enemy.global_position - global_position).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.UP
			enemy.apply_knockback(force, dir)

func _on_flesh_collected() -> void:
	var heal_amt = int(_get_equip_stat("heal_on_flesh", false))
	if heal_amt > 0:
		stats.heal(heal_amt)

func _is_bestia_de_caza_active() -> bool:
	var equip = get_node_or_null("Equipment")
	if not equip:
		return false
	var active_syns = SynergyManager.get_active_synergies(equip, "")
	return "bestia_de_caza" in active_syns

func _attack_left_melee() -> void:
	if not left_melee_weapon:
		return
	if not left_melee_weapon.has_method("attack"):
		return
	_show_secondary_weapon()
	left_melee_weapon.attack()

func _init_left_melee_weapon() -> void:
	if not second_weapon_scene: return
	left_melee_weapon = second_weapon_scene.instantiate()
	add_child(left_melee_weapon)
	GameData.apply_to_melee(left_melee_weapon)
	if second_weapon and second_weapon.get("active_scene"):
		left_melee_weapon.switch_weapon(second_weapon.active_scene)

func _create_furia_timer() -> void:
	furia_timer = Timer.new()
	furia_timer.one_shot = true
	add_child(furia_timer)
	furia_timer.timeout.connect(_on_furia_timeout)

func _on_shoot_timer_timeout() -> void:
	can_shoot = true

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	if not is_furia_active:
		set_collision_mask_value(2, true)
	if GameData.get_active_protocol() == "reflejo_sintetico":
		_spawn_dash_hologram(dash_start_pos)

func take_damage(amount: int, source_name: String = "Infección Lázaro", source_position: Vector2 = Vector2.INF) -> void:
	if GameData.debug_god_mode: return
	if is_dashing: return
	if is_invulnerable: return
	is_invulnerable = true
	
	var armor = _get_equip_stat("armor", false)
	var perm_armor = GameData.core_upgrades.get("blindaje_compuesto", 0) * 0.2
	var total_armor := int(armor + perm_armor)
	var final_amount := protocols.modify_incoming(amount, total_armor) if protocols else maxi(1, amount - total_armor)

	if stats.current_health - final_amount <= 0:
		GameData.last_killer = source_name
	
	invuln_timer.start(0.5)
	_invuln_blink_timer.start()
	stats.take_damage(final_amount)
	RunLog.note_damage(final_amount, source_name)
	_show_damage_text(final_amount)
	_play_hurt_sound()
	_animate_damage_vignette()
	_animate_damage_flash()
	if source_position != Vector2.INF:
		_show_damage_direction_indicator(source_position)

	var thorns_kb = _get_equip_stat("thorns_knockback", false)
	if thorns_kb > 0.0:
		_apply_thorns_knockback(thorns_kb)

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
	
	var dir_x = -1.0 if randf() < 0.5 else 1.0
	var random_x = dir_x * randf_range(15.0, 40.0)
	var random_y = randf_range(-45.0, -60.0)
	
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(random_x, random_y), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(floating_node.queue_free)

# número verde flotante que indica la vida regenerada al instalar una pieza nueva
func _show_heal_text(amount: int) -> void:
	var label = Label.new()
	label.text = "+%d" % amount
	label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0))
	label.add_theme_constant_override("outline_size", 4)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(100, 30)
	label.position = Vector2(-50, -15)

	var floating_node = Node2D.new()
	floating_node.global_position = global_position + Vector2(randf_range(-10.0, 10.0), -40.0)
	floating_node.add_child(label)

	get_tree().current_scene.call_deferred("add_child", floating_node)

	# sube derecho y despacio, más calmo que el número de daño
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(0, -50.0), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.chain().tween_callback(floating_node.queue_free)

# destello verde suave sobre el sprite, para que se note que hubo regeneración
func _animate_heal_flash() -> void:
	if not anim_sprite: return

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	anim_sprite.modulate = Color(0.5, 1.4, 0.6)
	_flash_tween = create_tween()
	_flash_tween.tween_property(anim_sprite, "modulate", _default_modulate, 0.4)

# flecha en el borde de pantalla apuntando hacia el origen del golpe recibido
func _show_damage_direction_indicator(source_position: Vector2) -> void:
	if not damage_indicator_layer: return
	var dir = source_position - global_position
	if dir.length() < 1.0: return

	var indicator := DamageDirectionIndicator.new()
	indicator.setup(dir.normalized(), get_viewport().get_visible_rect().size)
	damage_indicator_layer.add_child(indicator)

# variantes de sonido de golpe recibido, para no repetir siempre el mismo
var hurt_sounds: Array[AudioStream] = [
	preload("res://Audio/Sfx/damage_4_meghan.wav"),
	preload("res://Audio/Sfx/damage_4_meghan_2.wav"),
	preload("res://Audio/Sfx/damage_4_meghan_3.wav"),
]

func _play_hurt_sound() -> void:
	var hurt_sound = get_node_or_null("Hurt_sound")
	if not hurt_sound: hurt_sound = get_node_or_null("HurtSound")
	if not hurt_sound: return
	if not hurt_sound.has_method("play"): return
	hurt_sound.bus = "SFX"
	# elige al azar entre las variantes en vez de tocar siempre el mismo sonido
	if hurt_sounds.size() > 0:
		hurt_sound.stream = hurt_sounds.pick_random()
	hurt_sound.play()
	# golpe seco debajo de la voz: que el daño se sienta
	Sfx.play_at(Sfx.HURT, global_position, -2.0, 0.05)

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
	
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
		
	anim_sprite.modulate = Color.RED
	_flash_tween = create_tween()
	_flash_tween.tween_property(anim_sprite, "modulate", _default_modulate, 0.5)

func _on_invuln_timeout() -> void:
	is_invulnerable = false
	# corta el parpadeo y deja el sprite visible al terminar la invulnerabilidad
	_invuln_blink_timer.stop()
	if anim_sprite: anim_sprite.visible = true

func _on_health_changed(new_health: int, max_health: int) -> void:
	_update_hud_health(new_health, max_health)
	_update_low_health_state(new_health, max_health)

func _update_hud_health(new_health: int, max_health: int) -> void:
	var huds = get_tree().get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_health(new_health, max_health)

# prende o apaga el latido de pantalla según si la vida cruzó el umbral de "vida baja"
func _update_low_health_state(new_health: int, max_health: int) -> void:
	if max_health <= 0: return
	var ratio = float(new_health) / float(max_health)
	var should_pulse = new_health > 0 and ratio <= low_health_threshold

	if should_pulse == is_low_health: return
	is_low_health = should_pulse

	if is_low_health:
		low_health_pulse_timer.start()
		_on_low_health_pulse()
	else:
		low_health_pulse_timer.stop()
		if low_health_rect and low_health_rect.material:
			_tween_damage_intensity(0.0, low_health_rect.material)

# un "latido" completo: brillo rojo tenue que sube y baja, más el sonido
func _on_low_health_pulse() -> void:
	if not low_health_rect or not low_health_rect.material: return
	var mat = low_health_rect.material as ShaderMaterial
	var t = create_tween()
	t.tween_method(_tween_damage_intensity.bind(mat), 0.0, 0.5, 0.22).set_trans(Tween.TRANS_SINE)
	t.tween_method(_tween_damage_intensity.bind(mat), 0.5, 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	if low_health_sound:
		low_health_sound.play()

func _on_scrap_changed(amount: int) -> void:
	_update_hud_scrap(amount)

func _update_hud_scrap(amount: int) -> void:
	if not is_inside_tree(): return
	var tree = get_tree()
	if not tree: return
	var huds = tree.get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_scrap(amount)

func _on_flesh_changed(amount: int) -> void:
	_update_hud_flesh(amount)

func _update_hud_flesh(amount: int) -> void:
	if not is_inside_tree(): return
	var tree = get_tree()
	if not tree: return
	var huds = tree.get_nodes_in_group("hud")
	if huds.is_empty(): return
	huds[0].update_flesh(amount)

func _on_died() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	GameData.has_died_once = true
	GameData.clear_items()
	GameData.save_game()
	_play_death_sound()
	_show_death_screen()

func _play_death_sound() -> void:
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load("res://Audio/Sfx/death_5_sean.wav")
	sfx_player.bus = "SFX"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

# Pantalla de muerte con la UI nueva (también se usa con joystick).
func _show_death_screen() -> void:
	RunEndScreen.show_death(get_tree())

## title / subtitle vacíos = textos de siempre ("¡HAS GANADO!" y completaste la run).
func show_win_screen(next_scene: String, title: String = "", subtitle: String = "") -> void:
	freeze_player()
	_play_win_sound()
	_build_win_screen(next_scene, title, subtitle)

func _play_win_sound() -> void:
	var stream_path = "res://Audio/Sfx/Room_clear/Room_clear.wav"
	if not ResourceLoader.exists(stream_path): return
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = load(stream_path)
	sfx_player.bus = "SFX"
	get_tree().root.add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _build_win_screen(next_scene: String, title: String = "", subtitle: String = "") -> void:
	# Por si queda el juego pausado de algún popup anterior (ej. sinergia desbloqueada)
	# que no se haya despausado a tiempo: el cartel tiene que responder siempre.
	get_tree().paused = false
	RunEndScreen.show_victory(get_tree(), next_scene, title, subtitle, unfreeze_player)

func _unhandled_input(event: InputEvent) -> void:
	_handle_debug_cheats(event)

func _handle_debug_cheats(event: InputEvent) -> void:
	if not GameData.cheats_enabled():
		return
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	# Cheat de testeo (tecla "ç", sin asignar): mata a todos los enemigos de la sala
	# actual y fuerza la puerta a destrabarse, para poder recorrer salas rapido.
	# Se chequea por el caracter tipeado (event.unicode), no por keycode, para que
	# funcione sin importar el layout de teclado.
	if not event.echo and (event.unicode == 231 or event.unicode == 199): # ç / Ç
		_cheat_clear_room()
		return
	_process_debug_keycode(event.keycode)

func _cheat_clear_room() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("die"):
			enemy.die()
	var doors = get_tree().get_nodes_in_group("door")
	for door in doors:
		if door.has_method("unlock_door"):
			door.unlock_door()
	print("[CHEAT] Sala limpiada: ", enemies.size(), " enemigos eliminados, puertas destrabadas.")

func _process_debug_keycode(keycode: int) -> void:
	if keycode == KEY_F1:
		_cheat_synergy_items()
	if keycode == KEY_F2:
		_cheat_roadkill_items()
	if keycode == KEY_F3:
		_cheat_minigun_items()
	if keycode == KEY_F4:
		_cheat_musculoso_items()
	if keycode == KEY_F5:
		_cheat_ligero_items()
	if keycode == KEY_F6:
		_cheat_canino_items()
	if keycode == KEY_F9:
		_toggle_debug_scene()
	if keycode == KEY_F11:
		GameData.add_flesh(100)
	if keycode == KEY_F12:
		_toggle_cheat_weapon()

func _toggle_cheat_weapon() -> void:
	cheat_op_weapon_mode = not cheat_op_weapon_mode
	var msg = "MODO CHEAT ARMA: ACTIVADO (Daño 50 | Cadencia Ultra Rápida)" if cheat_op_weapon_mode else "MODO CHEAT ARMA: DESACTIVADO"
	print(msg)

func _toggle_debug_scene() -> void:
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path == "res://Scenes/Rooms/debug_scene.tscn":
		_return_to_previous_scene()
		return
	
	_enter_debug_scene(current_scene_path)

func _return_to_previous_scene() -> void:
	var target = GameData.previous_scene_path
	if target == "" or target == "res://Scenes/Rooms/debug_scene.tscn":
		target = "res://Scenes/Rooms/lab_room.tscn"
	SceneTransition.change_scene(target)

func _enter_debug_scene(current_path: String) -> void:
	GameData.previous_scene_path = current_path
	SceneTransition.change_scene("res://Scenes/Rooms/debug_scene.tscn")


func _cheat_synergy_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var colmena = load("res://Art/Items/Weapons/Item7_Colmena.tres") as ItemData
	var cerebro = load("res://Art/Items/Weapons/Item3.tres") as ItemData
	var cabeza = load("res://Art/Items/Weapons/Item8_CabezaHumana.tres") as ItemData
	_add_item_if_valid(inventory_node, colmena)
	_add_item_if_valid(inventory_node, cerebro)
	_add_item_if_valid(inventory_node, cabeza)
	print("Cheated items added to inventory!")

func _cheat_roadkill_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var moto = load("res://Art/Items/Weapons/Item6.tres") as ItemData
	var pulmones = load("res://Art/Items/Weapons/Item5.tres") as ItemData
	var sierra = load("res://Art/Items/Weapons/Item9_SierraCircular.tres") as ItemData
	_add_item_if_valid(inventory_node, moto)
	_add_item_if_valid(inventory_node, pulmones)
	_add_item_if_valid(inventory_node, sierra)
	print("Roadkill cheated items added to inventory!")

func _add_item_if_valid(inventory_node: Node, item: ItemData) -> void:
	if item:
		inventory_node.add_item(item)

func _cheat_minigun_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var mezcladora = load("res://Art/Items/Weapons/Item1.tres") as ItemData
	var motocicleta = load("res://Art/Items/Weapons/Item6.tres") as ItemData
	var sierra = load("res://Art/Items/Weapons/Item9_SierraCircular.tres") as ItemData
	_add_item_if_valid(inventory_node, mezcladora)
	_add_item_if_valid(inventory_node, motocicleta)
	_add_item_if_valid(inventory_node, sierra)
	print("Minigun cheated items added to inventory!")

func _cheat_musculoso_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var torso = load("res://Art/Items/Player/Body/Item2_TorsoBlindado.tres") as ItemData
	var brazo = load("res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres") as ItemData
	var piernas = load("res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres") as ItemData
	_add_item_if_valid(inventory_node, torso)
	_add_item_if_valid(inventory_node, brazo)
	_add_item_if_valid(inventory_node, piernas)
	print("Musculoso cheated items added to inventory!")

func _cheat_ligero_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var torso = load("res://Art/Items/Player/Body/Item4_TorsoLigero.tres") as ItemData
	var piernas = load("res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres") as ItemData
	var brazo = load("res://Art/Items/Player/Arms/Item3_BrazoLigero.tres") as ItemData
	_add_item_if_valid(inventory_node, torso)
	_add_item_if_valid(inventory_node, piernas)
	_add_item_if_valid(inventory_node, brazo)
	print("Ligero cheated items added to inventory!")

func _cheat_canino_items() -> void:
	var inventory_node = get_node_or_null("Inventory")
	if not inventory_node:
		return
	var torso = load("res://Art/Items/Player/Body/Item3_TorsoEspinado.tres") as ItemData
	var brazo = load("res://Art/Items/Player/Arms/Item4_BrazoArmado.tres") as ItemData
	var piernas = load("res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres") as ItemData
	_add_item_if_valid(inventory_node, torso)
	_add_item_if_valid(inventory_node, brazo)
	_add_item_if_valid(inventory_node, piernas)
	print("Canino cheated items added to inventory!")

func _play_dash_sound() -> void:
	var dash_sound = get_node_or_null("Dash")
	if not dash_sound: return
	if not dash_sound.has_method("play"): return
	dash_sound.bus = "SFX"
	dash_sound.play()

func _update_minigun_hold_time(delta: float) -> void:
	if _is_minigun_active() and Input.is_action_pressed("shoot"):
		minigun_hold_time += delta
	else:
		minigun_hold_time = 0.0

func _is_minigun_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	return active_syns.has("minigun")

func _get_minigun_level() -> int:
	if minigun_hold_time >= 4.0:
		return 5
	if minigun_hold_time >= 3.0:
		return 4
	if minigun_hold_time >= 2.0:
		return 3
	if minigun_hold_time >= 1.0:
		return 2
	if minigun_hold_time > 0.0:
		return 1
	return 0

func _get_minigun_stat_bonus(stat_name: String) -> float:
	if not _is_minigun_active():
		return 0.0
	var lvl = _get_minigun_level()
	if lvl == 0:
		return 0.0
	return _calculate_minigun_bonus(stat_name, lvl)

func _calculate_minigun_bonus(stat_name: String, lvl: int) -> float:
	if stat_name == "damage_multiplier":
		return _get_minigun_damage_bonus(lvl)
	if stat_name == "attack_speed":
		return _get_minigun_speed_bonus(lvl)
	if stat_name == "crit_chance":
		return _get_minigun_crit_bonus(lvl)
	return 0.0

func _get_minigun_damage_bonus(lvl: int) -> float:
	if lvl == 1:
		return 0.10
	if lvl == 2:
		return 0.20
	if lvl == 3:
		return 0.30
	if lvl == 4:
		return 0.40
	if lvl == 5:
		return 0.50
	return 0.0

func _get_minigun_speed_bonus(lvl: int) -> float:
	if lvl == 1:
		return 0.10
	if lvl == 2:
		return 0.20
	if lvl == 3:
		return 0.35
	if lvl == 4:
		return 0.50
	if lvl == 5:
		return 0.65
	return 0.0

func _get_minigun_crit_bonus(lvl: int) -> float:
	if lvl == 2:
		return 0.05
	if lvl == 3:
		return 0.10
	if lvl == 4:
		return 0.15
	if lvl == 5:
		return 0.20
	return 0.0

func _get_fragmentation_chance() -> float:
	if _is_minigun_active() and _get_minigun_level() == 5:
		return 0.25
	return 0.0

func _update_cerberus_hold_time(delta: float) -> void:
	if _is_cerberus_active() and Input.is_action_pressed("shoot"):
		cerberus_hold_time += delta
	else:
		cerberus_hold_time = 0.0

func _is_cerberus_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	return active_syns.has("lanzallamas") or active_syns.has("cerberus")

func _get_cerberus_range_bonus(stat_name: String) -> float:
	if stat_name != "lifetime":
		return 0.0
	if not _is_cerberus_active():
		return 0.0
	var ramp_time = 0.3
	var max_lifetime_bonus = 0.14
	var t = clamp(cerberus_hold_time / ramp_time, 0.0, 1.0)
	return max_lifetime_bonus * t

## Sinergia Daga del Odio: cuanto menos vida le queda al jugador, mas fuerte
## se vuelve la daga (dano, velocidad de ataque, alcance y probabilidad de
## critico escalan de forma continua segun la vida actual).
func _is_daga_del_odio_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("daga_del_odio")

func _get_daga_del_odio_bonus(stat_name: String) -> float:
	if not _is_daga_del_odio_active():
		return 0.0
	if stats.max_health <= 0:
		return 0.0
	var health_ratio = clamp(float(stats.current_health) / float(stats.max_health), 0.0, 1.0)
	var t = 1.0 - health_ratio
	match stat_name:
		# Con 10% de vida llegaba a ~800 de DPS (medido por Uri). Tope provisorio
		# hasta el rework: ronda los 100 de DPS con 10% de vida y 50 con la mitad.
		"damage":
			return 20.0 * t
		"attack_speed":
			return 1.0 * t
		"attack_range_percent":
			return 0.8 * t
		"crit_chance":
			return 0.4 * t
		"crit_damage":
			return 0.5 * t
	return 0.0

## Tiñe la hoja de la daga de rojo (mas intenso cuanta menos vida queda)
## mientras la sinergia Nemesis este activa.
func _update_daga_del_odio_visual(_delta: float = 0.0) -> void:
	if not second_weapon:
		return
	var weapon = second_weapon.get("current_weapon")
	if not weapon:
		return
	var sprite = weapon.get("melee_sprite") if "melee_sprite" in weapon else null
	if not sprite:
		return
	if not _is_daga_del_odio_active() or stats.max_health <= 0:
		sprite.modulate = Color(1.0, 1.0, 1.0)
		return
	var health_ratio = clamp(float(stats.current_health) / float(stats.max_health), 0.0, 1.0)
	var t = 1.0 - health_ratio
	sprite.modulate = Color(1.0, 1.0 - 0.85 * t, 1.0 - 0.85 * t)

## Efectos visuales del arma cuerpo a cuerpo. Cada sinergia trae su propia
## escena de arma con su sprite (weapon_scene_override en SynergyManager); acá
## solo se anima lo que cambia en partida: las hojas de varios cuadros (llama
## de Holy Fire, sierra de Speed Demon) y Nemesis, que crece y enrojece cuanto
## menos vida te queda.
func _update_melee_synergy_visual(_delta: float = 0.0) -> void:
	if not second_weapon:
		return
	var weapon = second_weapon.get("current_weapon")
	if not weapon:
		return
	var sprite = weapon.get("melee_sprite") if "melee_sprite" in weapon else null
	if sprite:
		_animate_weapon_sheet(sprite)
		_apply_nemesis_look(sprite)
	if is_instance_valid(_holy_fire_tongue) and not _is_holy_fire_active():
		_holy_fire_tongue.extinguish()

# Las hojas de varios cuadros se animan solas (si no, quedaban quietas en el primero).
func _animate_weapon_sheet(sprite: Node2D) -> void:
	if sprite is Sprite2D and sprite.hframes > 1:
		sprite.frame = int(Time.get_ticks_msec() / 1000.0 * WEAPON_SHEET_FPS) % sprite.hframes
	elif sprite is AnimatedSprite2D and not sprite.is_playing():
		sprite.play()

func _apply_nemesis_look(sprite: Node2D) -> void:
	if not sprite.has_meta("base_scale"):
		sprite.set_meta("base_scale", sprite.scale)
	var base_scale: Vector2 = sprite.get_meta("base_scale")
	if _is_daga_del_odio_active() and stats.max_health > 0:
		var t = 1.0 - clampf(float(stats.current_health) / float(stats.max_health), 0.0, 1.0)
		# antes se oscurecía casi a negro y crecía un 60%: la hoja (ya roja) se
		# volvía una mancha. Ahora el tinte es más suave y crece hasta un 25%.
		sprite.modulate = Color(1.0 + 0.3 * t, 1.0 - 0.4 * t, 1.0 - 0.4 * t)
		sprite.scale = base_scale * (1.0 + 0.25 * t)
	else:
		sprite.modulate = Color.WHITE
		sprite.scale = base_scale

## Si la sinergia Nemesis esta activa y el jugador tiene menos del 50% de vida,
## matar a un enemigo regenera vida.
func check_nemesis_kill_heal(_enemy: Node2D = null) -> void:
	if not _is_daga_del_odio_active():
		return
	if stats.max_health <= 0:
		return
	if stats.current_health >= stats.max_health * 0.5:
		return
	var heal_amount = 8
	stats.heal(heal_amount)
	_show_heal_text(heal_amount)
	_animate_heal_flash()

## Sinergia Arrogancia: mientras el swing de la maza esta activo, cualquier
## bala enemiga que te toque rebota devuelta (nerfeada) en vez de danarte.
## Lo consulta enemy_shooter_projectile.gd antes de aplicar su dano normal.
func _is_arrogancia_reflect_active() -> bool:
	if not second_weapon:
		return false
	if not second_weapon.has_method("is_attacking") or not second_weapon.is_attacking():
		return false
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("arrogancia")

func on_arrogancia_reflect(projectile_position: Vector2) -> void:
	if is_instance_valid(_arrogancia_shield):
		_arrogancia_shield.reflect_at(projectile_position)

## Speeddemon controla el arranque, el avance y la frenada desde su propia arma.
func _is_speed_demon_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("speed_demon")

func _apply_speed_demon_push(delta: float) -> void:
	if not is_instance_valid(_speed_demon_driver):
		_speed_demon_push_time = 0
		handle_movement(delta)
		return
	_speed_demon_push_time -= delta
	velocity = _speed_demon_push_dir * SPEED_DEMON_PUSH_SPEED * _speed_demon_driver.drive_multiplier * _speed_demon_driver.drive_speed_multiplier
	var collision := KinematicCollision2D.new()
	if test_move(global_transform, velocity * delta, collision):
		var obstacle := collision.get_collider()
		if obstacle and not obstacle.is_in_group("enemy"):
			_speed_demon_driver.brake_on_wall()
			velocity = Vector2.ZERO

func begin_speed_demon_drive(driver: Node2D, direction: Vector2, duration: float) -> void:
	_speed_demon_driver = driver
	_speed_demon_push_dir = direction
	_speed_demon_push_time = duration

func end_speed_demon_drive(driver: Node2D) -> void:
	if _speed_demon_driver == driver:
		_speed_demon_push_time = 0
		velocity = Vector2.ZERO

func _is_arrogancia_equipped() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("arrogancia")

## Sinergia Holy Fire: cada golpe de la maza quema al enemigo y le pone una
## lengua de fuego (HolyFireTongue) que escupe llamas alrededor. Si ya hay
## una lengua en otro enemigo, salta al recién golpeado. Lo llama melee_weapon.gd.
func _is_holy_fire_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("holy_fire")

func on_holy_fire_hit(enemy: Node2D, hit_damage: int) -> void:
	if not _is_holy_fire_active(): return
	if not is_instance_valid(enemy) or enemy.get("is_dying") == true: return
	IgniteEffect.apply_ignite(enemy, maxi(2, int(hit_damage * 0.12)), 0.4, 2.4)
	var spit_damage = maxi(4, int(hit_damage * 0.3))
	if is_instance_valid(_holy_fire_tongue) and not _holy_fire_tongue.is_leaving():
		_holy_fire_tongue.attach(enemy, spit_damage)
	else:
		_holy_fire_tongue = HolyFireTongue.spawn(enemy, spit_damage)

## Sinergia Oil of the Sick: cada hachazo mancha al enemigo con gasolina
## (FuelSoak). Una bala del jugador lo hace explotar (FuelExplosion), en cadena
## con los otros manchados. Lo llama melee_weapon.gd.
func _is_alto_octanaje_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("alto_octanaje")

func on_alto_octanaje_hit(enemy: Node2D, hit_damage: int) -> void:
	if not _is_alto_octanaje_active(): return
	var blast = clampi(int(hit_damage * ALTO_OCTANAJE_RATIO), ALTO_OCTANAJE_MIN, ALTO_OCTANAJE_MAX)
	FuelSoak.soak(enemy, blast)

## Sinergia Hombre Lobo: mientras el hacha tiene la sinergia activa, un
## enemigo de la sala queda "marcado". Golpear al enemigo marcado hace
## muchisimo mas dano y lo hace explotar, danando a los enemigos cercanos;
## al explotar la marca, aparece una marca nueva en otro enemigo.
func _is_hombre_lobo_active() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_melee_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
	return active_syns.has("hombre_lobo")

func _ensure_werewolf_mark() -> void:
	if not _is_hombre_lobo_active():
		if _werewolf_marked_enemy or _werewolf_mark_visual:
			_clear_werewolf_mark_visual()
			_werewolf_marked_enemy = null
		return
	if is_instance_valid(_werewolf_marked_enemy):
		return
	_werewolf_marked_enemy = null
	_clear_werewolf_mark_visual()
	var candidates: Array = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			candidates.append(enemy)
	if candidates.is_empty():
		return
	_werewolf_marked_enemy = candidates.pick_random()
	_werewolf_marked_enemy.set_meta("werewolf_mark", true)
	_spawn_werewolf_mark_visual(_werewolf_marked_enemy)

func _spawn_werewolf_mark_visual(enemy: Node2D) -> void:
	var mark_scene = preload("res://Scenes/Effects/WolfsbaneMark.tscn")
	var marker = mark_scene.instantiate()
	enemy.add_child(marker)
	_werewolf_mark_visual = marker

func _clear_werewolf_mark_visual() -> void:
	if is_instance_valid(_werewolf_mark_visual):
		_werewolf_mark_visual.queue_free()
	_werewolf_mark_visual = null

func _trigger_werewolf_mark_explosion(enemy: Node2D) -> void:
	if is_instance_valid(enemy) and enemy.has_meta("werewolf_mark"):
		enemy.remove_meta("werewolf_mark")
	_clear_werewolf_mark_visual()
	if _werewolf_marked_enemy == enemy:
		_werewolf_marked_enemy = null
	if not is_instance_valid(enemy):
		return
	var pos = enemy.global_position
	var explosion_dmg = 20
	for other in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(other) or other == enemy:
			continue
		var dist = pos.distance_to(other.global_position)
		if dist > 0.1 and dist < 140.0 and other.has_method("take_damage"):
			other.take_damage(explosion_dmg)
			record_enemy_hit(other)
			if other.has_method("apply_knockback"):
				var dir = (other.global_position - pos).normalized()
				if dir == Vector2.ZERO: dir = Vector2.UP
				other.apply_knockback(100.0, dir)
	var wave = load("res://Scripts/Effects/furia_shockwave.gd").new()
	wave.global_position = pos
	get_tree().current_scene.add_child(wave)

## Chorro continuo del lanzallamas: en vez de disparar proyectiles, mantiene
## un unico nodo FlameStream pegado al arma mientras se mantiene presionado
## el disparo, y lo extingue (con su propia animacion de fade) al soltar.
func _handle_cerberus_stream() -> void:
	if Input.is_action_pressed("shoot"):
		if not is_instance_valid(flame_stream_instance):
			_spawn_flame_stream()
		if is_instance_valid(flame_stream_instance):
			flame_stream_instance.update_hold(cerberus_hold_time)
	else:
		_force_stop_flame_stream()

func _spawn_flame_stream() -> void:
	if not active_weapon:
		return
	var stream_scene = load("res://Scenes/Weapon/FlameStream.tscn")
	if not stream_scene:
		return
	var target_parent = active_weapon
	if "current_weapon" in active_weapon and active_weapon.current_weapon:
		target_parent = active_weapon.current_weapon

	var stream = stream_scene.instantiate()
	target_parent.add_child(stream)
	var bullet_mark = target_parent.get_node_or_null("Bullet_mark_right")
	if bullet_mark:
		stream.position = bullet_mark.position
	else:
		stream.position = Vector2(18, -2)

	var bonus_aps_pct = _get_equip_stat("attack_speed")
	var final_aps = _get_weapon_attack_speed() * (1.0 + bonus_aps_pct)
	var dmg = (_get_weapon_damage() + _get_equip_stat("damage")) * (_get_weapon_damage_multiplier() + _get_equip_stat("damage_multiplier"))
	var dps = dmg * final_aps
	stream.setup(dps, 2, 0.4, 1.6)

	flame_stream_instance = stream
	_show_primary_weapon()
	_animate_cerberus_shoot()
	apply_camera_shake()

func _animate_cerberus_shoot() -> void:
	if not active_weapon:
		return
	var weapon_anim = active_weapon.get_node_or_null("Weapon_Sprites") as AnimatedSprite2D
	if not weapon_anim:
		return
	weapon_anim.play("shoot")

func _animate_cerberus_idle() -> void:
	if not active_weapon:
		return
	var weapon_anim = active_weapon.get_node_or_null("Weapon_Sprites") as AnimatedSprite2D
	if not weapon_anim:
		return
	weapon_anim.play("idle")

func _force_stop_flame_stream() -> void:
	if is_instance_valid(flame_stream_instance):
		flame_stream_instance.start_extinguish()
	flame_stream_instance = null
	_animate_cerberus_idle()

func _initialize_protocols() -> void:
	protocols = ProtocolRuntime.new()
	protocols.name = "Protocols"
	add_child(protocols)

func protocol_damage_multiplier() -> float:
	return protocols.damage_multiplier() if protocols else 1.0

func _spawn_dash_hologram(start_pos: Vector2) -> void:
	if not anim_sprite:
		return
	var holo = Sprite2D.new()
	if anim_sprite.sprite_frames and anim_sprite.animation:
		var frame_texture = anim_sprite.sprite_frames.get_frame_texture(anim_sprite.animation, anim_sprite.frame)
		holo.texture = frame_texture
	holo.global_position = start_pos
	holo.modulate = Color(0.0, 0.7, 1.0, 0.7)
	holo.scale = anim_sprite.scale
	holo.flip_h = anim_sprite.flip_h
	get_tree().current_scene.add_child(holo)
	
	var targets = get_tree().get_nodes_in_group("enemy").filter(ProtocolRuntime.valid_enemy)
	var target_dir = Vector2.RIGHT
	if not targets.is_empty():
		var nearest = targets[0]
		var min_d = start_pos.distance_to(nearest.global_position)
		for t in targets:
			var d = start_pos.distance_to(t.global_position)
			if d < min_d:
				nearest = t
				min_d = d
		target_dir = start_pos.direction_to(nearest.global_position)
	else:
		target_dir = dash_dir
		
	_spawn_protocol_echo(holo, target_dir)

	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(holo, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(holo.queue_free)

func _spawn_protocol_echo(holo: Node2D, direction: Vector2) -> void:
	if not active_weapon: return
	var dmg := (_get_weapon_damage() + _get_equip_stat("damage")) * (_get_weapon_damage_multiplier() + _get_equip_stat("damage_multiplier")) * 0.5
	if _is_cerberus_active():
		var stream = preload("res://Scenes/Weapon/FlameStream.tscn").instantiate()
		stream.set_meta("protocol_metric", "echo_damage")
		holo.add_child(stream)
		stream.rotation = direction.angle()
		stream.setup(dmg * _get_weapon_attack_speed(), 1, 0.4, 0.8)
		var stop := holo.create_tween()
		stop.tween_interval(0.25)
		stop.tween_callback(stream.start_extinguish)
		return
	var p_scene := _get_weapon_proj_scene(projectile_scene)
	var syns := SynergyManager.get_active_synergies(get_node_or_null("Equipment"), get_active_ranged_weapon_id(), true)
	var override_scene := SynergyManager.get_synergies_projectile_override(syns)
	if override_scene: p_scene = override_scene
	var count := _calculate_final_bullet_count(_get_weapon_bullets() + int(_get_equip_stat("bullet_count")), p_scene, get_active_ranged_weapon_id())
	var spread := _calculate_final_spread(maxf(0, _get_weapon_spread() + _get_equip_stat("cone_spread_angle")), p_scene, get_active_ranged_weapon_id())
	var volley := func():
		for i in count:
			var shot := _spawn_single_bullet(p_scene, i, count, _get_start_angle(direction, count, spread), _get_step_angle(count, spread), direction, dmg, _get_weapon_proj_speed(), holo.global_position, _get_weapon_piercing(), 0.0, 2.0, _get_weapon_lifetime())
			shot.set_meta("protocol_metric", "echo_damage")
			shot.set_meta("protocol_bonus_ratio", 0.0)
	volley.call()
	if get_active_ranged_weapon_id() == "uzi":
		var burst := holo.create_tween()
		burst.tween_interval(0.08)
		burst.tween_callback(volley)
		burst.tween_interval(0.08)
		burst.tween_callback(volley)

## Sinergia The Bride (relampago): mientras este activa, la UZI en mano se tine de un
## color electrico para que se note visualmente que esta equipada.
func _is_relampago_equipped() -> bool:
	var equip = get_node_or_null("Equipment")
	var active_weapon_id = get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	return active_syns.has("relampago")

func _update_ranged_synergy_visual(_delta: float = 0.0) -> void:
	if not active_weapon:
		return
	var sprite = active_weapon.get("sprite_anim") if "sprite_anim" in active_weapon else null
	if not sprite:
		return
	if not sprite.has_meta("base_modulate"):
		sprite.set_meta("base_modulate", sprite.modulate)
	var base_modulate: Color = sprite.get_meta("base_modulate")
	if _is_relampago_equipped():
		sprite.modulate = Color(0.6, 0.9, 1.6)
	else:
		sprite.modulate = base_modulate

func _exit_tree() -> void:
	GameData.unregister_player(self)

func apply_melee_item_status(body: Node2D) -> void:
	if not is_instance_valid(body) or body.get("is_dying") == true or not body.has_method("apply_status_effect"): return
	var effect := _roll_bullet_status_effect(false)
	if not effect.is_empty(): body.apply_status_effect(effect)
