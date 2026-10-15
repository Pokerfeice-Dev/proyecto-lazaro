extends EnemyBase
class_name CryptEnemy

enum Kind { GARGOYLE, GHOUL, CENTIPEDE, DEATH_SQUAD, LASER_EYE, DEAD_BEEKEEPER, FLESH_BEE, BELL_KEEPER }
enum Phase { CHASE, ANTICIPATION, ATTACK, RECOVERY, STONE_WARNING, STONE }

@export_category("Identidad de la cripta")
@export var kind: Kind = Kind.GARGOYLE
@export var codex_id := "crypt_gargoyle"
@export var display_name := "Gárgola"
@export_category("Ritmo de combate")
@export var attack_range := 58.0
@export var anticipation_time := 0.55
@export var attack_duration := 0.35
@export var recovery_time := 0.95
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/crypt_projectile.tscn")
@export var projectile_speed := 300.0
@export_category("Gárgola")
@export var stone_duration := 2.0
@export var stone_cooldown := 5.0
@export var stone_warning_time := 0.45
@export_category("Ghoul")
@export var rear_speed_multiplier := 1.75
@export_range(-1.0, 1.0) var rear_dot_threshold := -0.35
@export_category("Spray tóxico")
@export_range(10.0, 160.0) var spray_angle_degrees := 56.0
@export var poison_scene: PackedScene = preload("res://Scenes/Effects/crypt_poison.tscn")
@export_category("Ojo láser")
@export var laser_lock_time := 0.55
@export var laser_half_width := 10.0
@export_category("Invocación")
@export var summon_scene: PackedScene
@export var max_summons := 3
@export var summons_per_attack := 2
@export_category("Campanero")
@export var echo_scene: PackedScene = preload("res://Scenes/Effects/crypt_echo.tscn")
@export var echo_count := 3

var phase: Phase = Phase.CHASE
var locked_direction := Vector2.RIGHT
var _shield_cooldown := 2.0
var _shots_remaining := 0
var _attack_hit := false
var _spray_tick := 0.0
var _summons: Array[Node] = []
var _echoes: Array[Node] = []
var is_summoned := false

@onready var gargoyle_sprite: AnimatedSprite2D = get_node_or_null("GargoyleSprite") as AnimatedSprite2D

func _ready() -> void:
	super._ready()
	has_footstep_fx = false
	$PhaseTimer.timeout.connect(_next_phase)
	$BurstTimer.timeout.connect(_fire_burst_shot)
	$NameLabel.text = display_name
	$HealthBar.max_value = max_health
	$HealthBar.value = current_health
	if kind == Kind.DEAD_BEEKEEPER: add_to_group("crypt_summoner")
	if gargoyle_sprite:
		$Sprite2D.hide()
		gargoyle_sprite.play(&"idle")
	_update_telegraph_geometry()

# Las barras y el arte provisional son nodos de la escena, no se crean al ejecutar.
func _setup_health_bar() -> void:
	pass

func process_movement(delta: float) -> void:
	velocity = Vector2.ZERO
	if is_dying or is_spawning or not is_instance_valid(target): return
	_shield_cooldown = maxf(0.0, _shield_cooldown - delta)
	if phase == Phase.ANTICIPATION and kind == Kind.LASER_EYE:
		if $PhaseTimer.time_left > laser_lock_time:
			locked_direction = global_position.direction_to(target.global_position)
		_update_aim()
	elif phase == Phase.ATTACK:
		if kind == Kind.LASER_EYE: _damage_laser()
		elif kind == Kind.CENTIPEDE:
			_spray_tick -= delta
			if _spray_tick <= 0.0:
				_spray_tick = 0.3
				_apply_poison_in_cone()
	if phase != Phase.CHASE or not has_detected_player: return
	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range and _clear_path_to(target.global_position):
		if kind != Kind.DEAD_BEEKEEPER or _live_summons() < max_summons:
			_begin_attack()
		return
	if kind == Kind.LASER_EYE: return
	var speed_multiplier = rear_speed_multiplier if kind == Kind.GHOUL and player_has_back_turned() else 1.0
	velocity = get_nav_direction_to_target() * move_speed * speed_multiplier
	if gargoyle_sprite:
		gargoyle_sprite.flip_h = velocity.x < 0.0
		_play_gargoyle_animation(&"walk" if velocity.length_squared() > 1.0 else &"idle")
	$RearRush.visible = speed_multiplier > 1.0

func player_has_back_turned() -> bool:
	if not is_instance_valid(target): return false
	var facing = (target.get_global_mouse_position() - target.global_position).normalized()
	if "last_dir" in target:
		var directions = {"right": Vector2.RIGHT, "left": Vector2.LEFT, "up": Vector2.UP, "down": Vector2.DOWN, "up_right": Vector2(1, -1).normalized(), "up_left": Vector2(-1, -1).normalized(), "down_right": Vector2(1, 1).normalized(), "down_left": Vector2(-1, 1).normalized()}
		facing = directions.get(target.last_dir, facing)
	var to_enemy = target.global_position.direction_to(global_position)
	return facing.dot(to_enemy) < rear_dot_threshold

func _begin_attack() -> void:
	locked_direction = global_position.direction_to(target.global_position)
	_attack_hit = false
	$RearRush.hide()
	_update_aim()
	_enter_phase(Phase.ANTICIPATION, anticipation_time)

func _enter_phase(next: Phase, duration: float) -> void:
	phase = next
	velocity = Vector2.ZERO
	$Telegraph.visible = phase == Phase.ANTICIPATION
	$AttackVisual.visible = phase == Phase.ATTACK
	$StoneShield.visible = (phase == Phase.STONE or phase == Phase.STONE_WARNING) and gargoyle_sprite == null
	$StateLabel.text = {Phase.ANTICIPATION: "¡CUIDADO!", Phase.RECOVERY: "", Phase.STONE_WARNING: "PETRIFICANDO", Phase.STONE: "INMUNE"}.get(phase, "")
	$StoneShield.modulate.a = 1.0 if phase == Phase.STONE else 0.4
	if phase == Phase.ANTICIPATION or phase == Phase.STONE_WARNING:
		$AnimationPlayer.play("anticipation")
	elif phase == Phase.ATTACK:
		$AnimationPlayer.play("attack")
	else:
		$AnimationPlayer.play("RESET")
	if gargoyle_sprite:
		match phase:
			Phase.ANTICIPATION: _play_gargoyle_animation(&"attack_windup")
			Phase.ATTACK: _play_gargoyle_animation(&"attack_cone", true)
			Phase.STONE_WARNING: _play_gargoyle_animation(&"petrify", true)
			Phase.STONE: _play_gargoyle_animation(&"stone_shield")
			Phase.RECOVERY: _play_gargoyle_animation(&"idle")
	$PhaseTimer.start(maxf(duration, 0.01))

func _play_gargoyle_animation(animation_name: StringName, restart := false) -> void:
	if not gargoyle_sprite: return
	if restart or gargoyle_sprite.animation != animation_name:
		gargoyle_sprite.play(animation_name)

func _next_phase() -> void:
	if is_dying: return
	match phase:
		Phase.ANTICIPATION:
			_enter_phase(Phase.ATTACK, attack_duration)
			_perform_attack()
		Phase.ATTACK:
			$BurstTimer.stop()
			_enter_phase(Phase.RECOVERY, recovery_time)
		Phase.RECOVERY:
			if kind == Kind.GARGOYLE and _shield_cooldown <= 0.0:
				_enter_phase(Phase.STONE_WARNING, stone_warning_time)
			else:
				phase = Phase.CHASE
		Phase.STONE_WARNING:
			knockback_velocity = Vector2.ZERO
			_enter_phase(Phase.STONE, stone_duration)
		Phase.STONE:
			_shield_cooldown = stone_cooldown
			_enter_phase(Phase.RECOVERY, recovery_time)

func _perform_attack() -> void:
	$AttackSound.play()
	match kind:
		Kind.GARGOYLE, Kind.GHOUL:
			if _target_in_cone(attack_range + 12.0, 100.0):
				target.take_damage(damage, display_name, global_position)
		Kind.CENTIPEDE:
			_spray_tick = 0.0
		Kind.DEATH_SQUAD:
			_shots_remaining = 3
			_fire_burst_shot()
		Kind.BELL_KEEPER:
			_shots_remaining = mini(echo_count, 3)
			_fire_burst_shot()
		Kind.FLESH_BEE:
			_spawn_projectile()
		Kind.DEAD_BEEKEEPER:
			for index in mini(summons_per_attack, max_summons - _live_summons()):
				_spawn_bee(index)

func _fire_burst_shot() -> void:
	if is_dying or phase != Phase.ATTACK or _shots_remaining <= 0: return
	if kind == Kind.BELL_KEEPER:
		_place_echo()
	else:
		_spawn_projectile()
	_shots_remaining -= 1
	if _shots_remaining > 0: $BurstTimer.start()

func _place_echo() -> void:
	if not is_instance_valid(target) or not _clear_path_to(target.global_position): return
	_echoes = _echoes.filter(func(echo): return is_instance_valid(echo))
	if _echoes.size() >= 3: return
	var echo = echo_scene.instantiate()
	echo.damage = damage
	get_parent().add_child(echo)
	echo.global_position = target.global_position
	_echoes.append(echo)
	$AttackSound.play()

func _spawn_projectile() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.direction = locked_direction
	projectile.damage = damage
	projectile.speed = projectile_speed
	projectile.source_name = display_name
	get_parent().add_child(projectile)
	projectile.global_position = global_position + locked_direction * 20.0

func _target_in_cone(reach: float, angle_degrees: float) -> bool:
	if not is_instance_valid(target): return false
	var offset = target.global_position - global_position
	return offset.length() <= reach and locked_direction.dot(offset.normalized()) >= cos(deg_to_rad(angle_degrees * 0.5)) and _clear_path_to(target.global_position)

func _apply_poison_in_cone() -> void:
	if not _target_in_cone(attack_range, spray_angle_degrees): return
	if target.get("is_dashing") == true or target.get("is_invulnerable") == true: return
	var poison = target.get_node_or_null("CryptPoison")
	if poison == null:
		poison = poison_scene.instantiate()
		target.add_child(poison)
	poison.refresh(global_position)

func _damage_laser() -> void:
	_update_aim()
	if _attack_hit or not is_instance_valid(target): return
	var end = _beam_end()
	var closest = Geometry2D.get_closest_point_to_segment(target.global_position, global_position, end)
	if closest.distance_to(target.global_position) <= laser_half_width + 8.0 and _clear_path_to(target.global_position):
		target.take_damage(damage, display_name, global_position)
		_attack_hit = true

func _beam_end() -> Vector2:
	var end = global_position + locked_direction * attack_range
	var query = PhysicsRayQueryParameters2D.create(global_position, end, 5, [get_rid(), target.get_rid()])
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else end

func _clear_path_to(point: Vector2) -> bool:
	var query = PhysicsRayQueryParameters2D.create(global_position, point, 5, [get_rid(), target.get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _update_aim() -> void:
	$Telegraph.rotation = locked_direction.angle()
	$AttackVisual.rotation = locked_direction.angle()
	if kind == Kind.LASER_EYE:
		var length = global_position.distance_to(_beam_end())
		$Telegraph/Line.points = PackedVector2Array([Vector2.ZERO, Vector2(length, 0)])
		$AttackVisual/Line.points = $Telegraph/Line.points

func _update_telegraph_geometry() -> void:
	var cone = PackedVector2Array([Vector2.ZERO])
	var angle = spray_angle_degrees if kind == Kind.CENTIPEDE else 100.0
	for step in 13:
		cone.append(Vector2.from_angle(deg_to_rad(-angle * 0.5 + angle * step / 12.0)) * attack_range)
	$Telegraph/Cone.polygon = cone
	$AttackVisual/Cone.polygon = cone
	var use_cone = kind in [Kind.GARGOYLE, Kind.GHOUL, Kind.CENTIPEDE]
	$Telegraph/Cone.visible = use_cone
	$AttackVisual/Cone.visible = use_cone
	$Telegraph/Line.visible = not use_cone
	$AttackVisual/Line.visible = kind == Kind.LASER_EYE
	$Telegraph/Line.points = PackedVector2Array([Vector2.ZERO, Vector2(attack_range, 0)])
	$AttackVisual/Line.width = laser_half_width * 2.0

func _live_summons() -> int:
	_summons = _summons.filter(func(bee): return is_instance_valid(bee) and not bee.is_dying)
	return _summons.size()

func _spawn_bee(index: int) -> void:
	if summon_scene == null: return
	var offset = Vector2(44.0, 0).rotated(locked_direction.angle() + (PI * 0.5 if index % 2 == 0 else -PI * 0.5))
	var position_to_use = global_position + offset
	if not _clear_path_to(position_to_use): return
	var bee = summon_scene.instantiate()
	bee.is_summoned = true
	get_parent().add_child(bee)
	bee.global_position = position_to_use
	bee.alert_to_player()
	bee.flesh_drop_chance = 0.0
	bee.item_drop_chance = 0.0
	_summons.append(bee)
	bee.spawn_appear()

func take_damage(amount: int, is_crit: bool = false) -> void:
	if is_dying or phase == Phase.STONE: return
	super.take_damage(amount, is_crit)
	if not is_dying and kind == Kind.GARGOYLE and phase == Phase.CHASE and _shield_cooldown <= 0.0:
		_enter_phase(Phase.STONE_WARNING, stone_warning_time)

func apply_knockback(force: float, direction: Vector2) -> void:
	if phase == Phase.STONE: return
	super.apply_knockback(force, direction)

func _unlock_bestiary_entry() -> void:
	GameData.unlock_codex_entry("enemies", codex_id)

func _attempt_drops() -> void:
	if is_summoned: return
	super._attempt_drops()

func _hide_sprite() -> void:
	$Sprite2D.hide()
	$NameLabel.hide()
	$StateLabel.hide()

func die() -> void:
	if is_dying: return
	$PhaseTimer.stop()
	$BurstTimer.stop()
	$Telegraph.hide()
	$AttackVisual.hide()
	$StoneShield.hide()
	$RearRush.hide()
	for bee in _summons:
		if is_instance_valid(bee): bee.queue_free()
	_summons.clear()
	for echo in _echoes:
		if is_instance_valid(echo): echo.queue_free()
	_echoes.clear()
	super.die()
