extends Node2D

@export_category("Melee Nodes")
@export var melee_sprite: Sprite2D
@export var slash_attack: Area2D
@export var attack_fx: AnimatedSprite2D

@export_category("Melee Stats")
@export var damage: int = 15
@export var attack_speed: float = 1.0
@export var attack_range: float = 1.0
@export var knockback_force: float = 150.0

var _is_attacking: bool = false
var hit_enemies: Array[Node2D] = []

var attack_sounds: Array[AudioStream] = [
	preload("res://Audio/Sfx/Melee/07_human_atk_sword_1.wav"),
]
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	audio_player.bus = "SFX"
	add_child(audio_player)
	scale = Vector2(attack_range, attack_range)
	if slash_attack:
		slash_attack.body_entered.connect(_on_body_entered)
		slash_attack.monitoring = false
	else:
		# Fallback para armas viejas que no asignaron los exports
		slash_attack = get_node_or_null("Slash_attack")
		if slash_attack:
			slash_attack.body_entered.connect(_on_body_entered)
			slash_attack.monitoring = false
			
	if not attack_fx:
		attack_fx = get_node_or_null("attack_fx")
	if attack_fx:
		attack_fx.hide()
		attack_fx.animation_finished.connect(_on_attack_fx_finished)

func _on_attack_fx_finished() -> void:
	attack_fx.hide()

func attack() -> void:
	if _is_attacking: return
	_is_attacking = true
	hit_enemies.clear()
	if slash_attack: slash_attack.monitoring = true
	
	var tween = create_tween()
	var start_rot = rotation - deg_to_rad(60)
	var end_rot = rotation + deg_to_rad(60)
	
	var p = get_parent()
	var final_speed = attack_speed
	var final_range = attack_range
	if p and p.has_method("_get_equip_stat"):
		var bonus_speed_pct = p._get_equip_stat("attack_speed", false)
		final_speed *= (1.0 + bonus_speed_pct)
		var flat_range = p._get_equip_stat("attack_range", false)
		var pct_range = p._get_equip_stat("attack_range_percent", false)
		final_range = (final_range + flat_range) * (1.0 + pct_range)
		
	scale = Vector2(final_range, final_range)
	var safe_speed = maxf(0.1, final_speed)
	var swing_time = 0.4 / safe_speed
	var recovery_time = 0.6 / safe_speed
	
	audio_player.stream = attack_sounds.pick_random()
	audio_player.play()
	
	if attack_fx:
		attack_fx.show()
		attack_fx.stop()
		attack_fx.play("attack")
	
	rotation = start_rot
	tween.tween_property(self, "rotation", end_rot, swing_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): if slash_attack: slash_attack.set_deferred("monitoring", false))
	tween.tween_property(self, "rotation", start_rot, recovery_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_attack_finished)

func _on_attack_finished() -> void:
	_is_attacking = false
	if slash_attack: slash_attack.monitoring = false

func is_attacking() -> bool:
	return _is_attacking

func _on_body_entered(body: Node2D) -> void:
	if not _is_attacking: return
	if body in hit_enemies: return
	if body.has_method("take_damage") and not body.is_in_group("player"):
		hit_enemies.append(body)
		
		var p = get_parent()
		var final_dmg = damage
		var final_kb = knockback_force
		var is_crit = false
		var crit_chance = 0.0
		var crit_damage = 2.0
		
		if p and p.has_method("_get_equip_stat"):
			final_dmg += int(p._get_equip_stat("damage", false))
			var flat_kb = p._get_equip_stat("knockback_force", false)
			var pct_kb = p._get_equip_stat("knockback_percent", false)
			final_kb = (final_kb + flat_kb) * (1.0 + pct_kb)
			crit_chance += p._get_equip_stat("crit_chance", false)
			crit_damage += p._get_equip_stat("crit_damage", false)
			
		if randf() <= crit_chance:
			final_dmg = int(final_dmg * crit_damage)
			is_crit = true
			
		body.take_damage(final_dmg, is_crit)
		if final_kb > 0.0 and body.has_method("apply_knockback"):
			var dir = (body.global_position - global_position).normalized()
			body.apply_knockback(final_kb, dir)
			
		if p and p.get("is_furia_active") == true:
			_trigger_furia_area_attack(body.global_position, final_dmg)

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
