extends Node2D
class_name MeleeWeaponBase

@export_category("Melee Nodes")
@export var melee_sprite: Sprite2D
@export var slash_attack: Area2D
@export var attack_fx: AnimatedSprite2D

@export_category("Melee Stats")
@export var id: String = ""
@export var damage: int = 15
@export var attack_speed: float = 1.0
@export var attack_range: float = 1.0
@export var knockback_force: float = 150.0

@export_category("Melee Visuals")
@export var sprite_rotation_offset: float = 0.0 # In degrees
@export var swing_start_angle: float = -60.0 # In degrees
@export var swing_end_angle: float = 60.0 # In degrees

var _is_attacking: bool = false
var hit_enemies: Array[Node2D] = []

var attack_sounds: Array[AudioStream] = [
	preload("res://Audio/Sfx/Melee/07_human_atk_sword_1.wav"),
	preload("res://Audio/Sfx/Melee/07_human_atk_sword_2.wav"),
	preload("res://Audio/Sfx/Melee/07_human_atk_sword_3.wav"),
]
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	_initialize_id()
	_init_audio_player()
	_init_collision()
	_init_attack_fx()
	rotation = deg_to_rad(sprite_rotation_offset)

func _initialize_id() -> void:
	if id == "":
		id = _get_id_from_name()

func _get_id_from_name() -> String:
	var lower_name = name.to_lower()
	if "daga" in lower_name or "dagger" in lower_name:
		return "daga"
	if "maze" in lower_name or "mace" in lower_name:
		return "maze"
	if "hacha" in lower_name or "axe" in lower_name:
		return "hacha"
	return lower_name

func _init_audio_player() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	scale = Vector2(attack_range, attack_range)

func _init_collision() -> void:
	if slash_attack:
		slash_attack.body_entered.connect(_on_body_entered)
		slash_attack.monitoring = false
		return
	slash_attack = get_node_or_null("Slash_attack")
	if slash_attack:
		slash_attack.body_entered.connect(_on_body_entered)
		slash_attack.monitoring = false

func _init_attack_fx() -> void:
	if not attack_fx:
		attack_fx = get_node_or_null("attack_fx")
	if attack_fx:
		attack_fx.hide()
		attack_fx.animation_finished.connect(_on_attack_fx_finished)

func _on_attack_fx_finished() -> void:
	if attack_fx:
		attack_fx.hide()

func attack() -> void:
	if _is_attacking: return
	_is_attacking = true
	hit_enemies.clear()
	if slash_attack: slash_attack.monitoring = true
	
	var tween = create_tween()
	var offset_rot = deg_to_rad(sprite_rotation_offset)
	var start_rot = deg_to_rad(swing_start_angle) + offset_rot
	var end_rot = deg_to_rad(swing_end_angle) + offset_rot
	
	var final_speed = attack_speed
	var final_range = attack_range
	var equip_owner = _find_equip_owner()
	if equip_owner:
		var bonus_speed_pct = equip_owner._get_equip_stat("attack_speed", false)
		final_speed *= (1.0 + bonus_speed_pct)
		var flat_range = equip_owner._get_equip_stat("attack_range", false)
		var pct_range = equip_owner._get_equip_stat("attack_range_percent", false)
		final_range = (final_range + flat_range) * (1.0 + pct_range)
		
	scale = Vector2(final_range, final_range)
	var safe_speed = maxf(0.1, final_speed)
	var swing_time = 0.4 / safe_speed
	var recovery_time = 0.6 / safe_speed
	
	_play_attack_sound()
	_play_attack_fx()
	
	rotation = start_rot
	tween.tween_property(self, "rotation", end_rot, swing_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_disable_slash_monitoring)
	tween.tween_property(self, "rotation", offset_rot, recovery_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_attack_finished)

func _find_equip_owner() -> Node:
	var p = get_parent()
	if not p: return null
	if p.has_method("_get_equip_stat"): return p
	var gp = p.get_parent()
	if gp and gp.has_method("_get_equip_stat"): return gp
	return null

func _play_attack_sound() -> void:
	var custom_snd = get_node_or_null("Snd_mele1")
	if custom_snd and custom_snd.has_method("play"):
		custom_snd.play()
		return
	if audio_player and attack_sounds.size() > 0:
		audio_player.stream = attack_sounds.pick_random()
		audio_player.play()

func _play_attack_fx() -> void:
	if attack_fx:
		attack_fx.show()
		attack_fx.stop()
		attack_fx.play("attack")

func _disable_slash_monitoring() -> void:
	if slash_attack:
		slash_attack.set_deferred("monitoring", false)

func _on_attack_finished() -> void:
	_is_attacking = false
	rotation = deg_to_rad(sprite_rotation_offset)
	if slash_attack: slash_attack.monitoring = false

func is_attacking() -> bool:
	return _is_attacking

func _on_body_entered(body: Node2D) -> void:
	if not _is_attacking: return
	if body in hit_enemies: return
	if not body.is_in_group("enemy"): return
	if not body.has_method("take_damage"): return
	
	hit_enemies.append(body)
	_apply_damage_to_enemy(body)

func _apply_damage_to_enemy(body: Node2D) -> void:
	var final_dmg = damage
	var final_kb = knockback_force
	var is_crit = false
	var crit_chance = 0.0
	var crit_damage = 2.0
	
	var equip_owner = _find_equip_owner()
	if equip_owner:
		final_dmg += int(equip_owner._get_equip_stat("damage", false))
		var flat_kb = equip_owner._get_equip_stat("knockback_force", false)
		var pct_kb = equip_owner._get_equip_stat("knockback_percent", false)
		final_kb = (final_kb + flat_kb) * (1.0 + pct_kb)
		crit_chance += equip_owner._get_equip_stat("crit_chance", false)
		crit_damage += equip_owner._get_equip_stat("crit_damage", false)
		
	if randf() <= crit_chance:
		final_dmg = int(final_dmg * crit_damage)
		is_crit = true
		
	body.take_damage(final_dmg, is_crit)
	_apply_knockback_to_enemy(body, final_kb)
	
	if equip_owner and equip_owner.get("is_furia_active") == true:
		_trigger_furia_area_attack(body.global_position, final_dmg)

func _apply_knockback_to_enemy(body: Node2D, force: float) -> void:
	if force <= 0.0: return
	if not body.has_method("apply_knockback"): return
	var dir = (body.global_position - global_position).normalized()
	body.apply_knockback(force, dir)

func _trigger_furia_area_attack(pos: Vector2, base_damage: float) -> void:
	var area_dmg = int(base_damage * 0.5)
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		var dist = pos.distance_to(enemy.global_position)
		if dist > 0.1 and dist < 120.0:
			enemy.take_damage(area_dmg)
			if enemy.has_method("apply_knockback"):
				var dir = (enemy.global_position - pos).normalized()
				if dir == Vector2.ZERO: dir = Vector2.UP
				enemy.apply_knockback(100.0, dir)
	_spawn_furia_spark_fx(pos)

func _spawn_furia_spark_fx(pos: Vector2) -> void:
	var wave = load("res://Scripts/Effects/furia_shockwave.gd").new()
	wave.global_position = pos
	get_tree().current_scene.add_child(wave)
