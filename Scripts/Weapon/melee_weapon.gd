extends Node2D
class_name MeleeWeaponBase

@export_category("Melee Nodes")
@export var melee_sprite: Node2D
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

@export_category("Estilos de ataque")
enum AttackStyle { SWING, SWING_BACK, STAB, STAB_FLURRY, CHOP, SPIN }
## Cada golpe usa el siguiente estilo de la lista, en ciclo. Vacío = la lista del arma según su id
## (daga: puntadas y estocadas; hacha y maza: hachazos y giros).
@export var attack_styles: Array[AttackStyle] = []

var _is_attacking: bool = false
var _style_index: int = 0
var _style_hit_scale: float = 1.0
var _style_active: bool = false
var _rest_position: Vector2 = Vector2.ZERO
var _rest_scale: Vector2 = Vector2.ONE
var _fx_base_flip_v: bool = false
var _slash_rest_pos: Vector2 = Vector2.ZERO
var _ghost_left: float = 0.0
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
	if slash_attack: _slash_rest_pos = slash_attack.position
	_init_melee_sprite()
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
	audio_player.bus = "SFX"
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

func _init_melee_sprite() -> void:
	# fallback: en dagger.tscn y axe.tscn el NodePath de melee_sprite no
	# esta asignado en la escena (solo mace.tscn lo tiene), asi que sin esto
	# el sprite quedaba null y los tintes de sinergia nunca se veian.
	if not melee_sprite:
		melee_sprite = get_node_or_null("Melee_sprite")

func _init_attack_fx() -> void:
	if not attack_fx:
		attack_fx = get_node_or_null("attack_fx")
	if attack_fx:
		_fx_base_flip_v = attack_fx.flip_v
		attack_fx.hide()
		attack_fx.animation_finished.connect(_on_attack_fx_finished)

func _on_attack_fx_finished() -> void:
	if attack_fx:
		attack_fx.hide()

func attack() -> void:
	if _is_attacking: return
	_is_attacking = true
	hit_enemies.clear()
	_style_hit_scale = 1.0

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
	_rest_scale = scale
	_rest_position = position
	_style_active = true
	# Duración total del golpe (antes 0,4 de ataque + 0,6 de recuperación): todos los estilos la respetan.
	var total = 1.0 / maxf(0.1, final_speed)
	var style = _next_style()

	_play_attack_sound()
	_ghost_left = 0.0
	match style:
		AttackStyle.SWING, AttackStyle.SWING_BACK:
			if not _play_trail(style == AttackStyle.SWING_BACK, 0.27 / (total * 0.4)):
				_play_attack_fx(style == AttackStyle.SWING_BACK)
		AttackStyle.SPIN:
			if not _play_spin_ring(total * 0.55):
				_play_attack_fx(false)

	var tween = create_tween()
	match style:
		AttackStyle.SWING_BACK: _tween_swing(tween, end_rot, start_rot, offset_rot, total)
		AttackStyle.STAB: _tween_stab(tween, offset_rot, total)
		AttackStyle.STAB_FLURRY: _tween_flurry(tween, offset_rot, total)
		AttackStyle.CHOP: _tween_chop(tween, start_rot, end_rot, offset_rot, total)
		AttackStyle.SPIN: _tween_spin(tween, offset_rot, total)
		_: _tween_swing(tween, start_rot, end_rot, offset_rot, total)

# ── Estilos de ataque ───────────────────────────────────────────────────────
# Cada golpe usa el siguiente estilo de la lista del arma. El estilo mueve el arma entera (giro,
# desplazamiento hacia adelante y escala) y ajusta el daño de cada impacto para que el promedio
# por segundo no cambie respecto del tajo de siempre.

func _next_style() -> int:
	var list: Array = attack_styles if not attack_styles.is_empty() else _default_styles()
	var style: int = list[_style_index % list.size()]
	_style_index += 1
	return style

# Lista por defecto según el arma (por su id).
func _default_styles() -> Array:
	match id:
		"daga": return [AttackStyle.STAB_FLURRY, AttackStyle.SWING_BACK, AttackStyle.STAB, AttackStyle.SWING]
		"hacha": return [AttackStyle.CHOP, AttackStyle.SWING, AttackStyle.CHOP, AttackStyle.SPIN]
		"maze": return [AttackStyle.CHOP, AttackStyle.SWING_BACK, AttackStyle.SPIN]
	return [AttackStyle.SWING]

# Giro que deja el arma apuntando justo hacia donde se apunta (para las estocadas).
# Los sprites de las armas cuerpo a cuerpo tienen la hoja hacia arriba: girándola 90° queda apuntando
# justo hacia donde se apunta (el contenedor ya rota todo hacia el cursor).
func _aim_rotation(offset_rot: float) -> float:
	return deg_to_rad(90.0) + offset_rot

# Coloca la zona de golpe delante del arma mientras apunta recta (estocadas): sin esto la caja de
# impacto, que está pensada para el tajo, queda de costado cuando el arma gira 90°.
func _hitbox_ahead(aim_rot: float, dist: float) -> void:
	if not slash_attack: return
	var shape := slash_attack.find_child("CollisionShape2D", false, false) as Node2D
	var shape_off := shape.position if shape else Vector2.ZERO
	slash_attack.position = Vector2(dist, 0.0).rotated(-aim_rot) / maxf(0.1, scale.x) - shape_off

# ── Efectos visuales (ver WeaponFx) ──
func _blade_len() -> float:
	match id:
		"daga": return 23.0
		"hacha": return 31.0
		"maze": return 39.0
	return 28.0

func _fx_scale() -> float:
	return (_blade_len() + 4.0) / 36.0

# Estela de luz detrás de la hoja (hija del arma: gira con ella). backhand = tajo de revés.
func _play_trail(backhand: bool, speed_mult: float = 1.0) -> bool:
	var s := _fx_scale()
	return WeaponFx.play(self, "slash_trail", Vector2.ZERO, 0.0, Vector2(s, s), backhand, false, 1, clampf(speed_mult, 0.6, 2.5)) != null

# Anillo de luz del giro completo (queda quieto en el contenedor mientras el arma gira).
func _play_spin_ring(duration: float) -> bool:
	var host := get_parent()
	if host == null: return false
	var s := _fx_scale() * scale.x
	return WeaponFx.play(host, "spin_ring", position, 0.0, Vector2(s, s), false, false, 1, clampf(0.25 / maxf(0.05, duration), 0.6, 2.5)) != null

# Estela de la puntada (apunta al frente del jugador).
func _stab_fx(y: float) -> void:
	var host := get_parent()
	if host == null: return
	var s := scale.x * 0.95
	WeaponFx.play(host, "thrust_streak", _rest_position + Vector2(2.0, y), 0.0, Vector2(s, s), false, true, 1, 1.4)

func _ghost_host() -> Node:
	var p := get_parent()
	return p.get_parent() if p and p.get_parent() else null

func _process(delta: float) -> void:
	if not _is_attacking: return
	_ghost_left -= delta
	if _ghost_left > 0.0: return
	_ghost_left = 0.03
	var host := _ghost_host()
	var p := get_parent()
	if host and melee_sprite and p is CanvasItem:
		WeaponFx.ghost(melee_sprite, host, (p as CanvasItem).show_behind_parent)

# Chispa en el punto de impacto.
func _spawn_hit_fx(body: Node2D, is_crit: bool) -> void:
	if not is_instance_valid(body) or not is_inside_tree(): return
	var s := 1.0
	if is_crit: s = 1.7
	elif _style_hit_scale < 0.6: s = 0.75
	var pos := body.global_position.lerp(global_position, 0.2)
	WeaponFx.play_world(get_tree(), "hit_spark", pos, randf() * TAU * 0.125, Vector2(s, s))

func _arm_hits() -> void:
	if slash_attack: slash_attack.monitoring = true

func _arm_hits_deferred() -> void:
	if slash_attack: slash_attack.set_deferred("monitoring", true)

# Vuelve a habilitar los impactos para el mismo enemigo (cada puntada de la ráfaga pega por separado).
func _rearm_hits() -> void:
	hit_enemies.clear()
	if slash_attack:
		slash_attack.monitoring = false
		slash_attack.set_deferred("monitoring", true)

# Tajo: el de siempre (de start a end y de vuelta). SWING_BACK es el mismo en sentido contrario.
func _tween_swing(tween: Tween, from_rot: float, to_rot: float, offset_rot: float, total: float) -> void:
	_arm_hits()
	rotation = from_rot
	tween.tween_property(self, "rotation", to_rot, total * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_disable_slash_monitoring)
	tween.tween_property(self, "rotation", offset_rot, total * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_attack_finished)

# Estocada: se echa hacia atrás, apunta recto y se clava hacia adelante.
func _tween_stab(tween: Tween, offset_rot: float, total: float) -> void:
	var aim := _aim_rotation(offset_rot)
	if slash_attack: slash_attack.monitoring = false
	_hitbox_ahead(aim, 20.0)
	rotation = offset_rot
	tween.tween_property(self, "position", _rest_position + Vector2(-9.0, 0.0), total * 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", aim, total * 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_arm_hits_deferred)
	tween.tween_callback(_stab_fx.bind(0.0))
	tween.tween_property(self, "position", _rest_position + Vector2(30.0, 0.0), total * 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(total * 0.08)
	tween.tween_callback(_disable_slash_monitoring)
	tween.tween_property(self, "position", _rest_position, total * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "rotation", offset_rot, total * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(total * 0.22)
	tween.tween_callback(_on_attack_finished)

# Ráfaga de tres puntadas: una recta, una desde arriba y una desde abajo, cada una con su impacto.
func _tween_flurry(tween: Tween, offset_rot: float, total: float) -> void:
	var aim := _aim_rotation(offset_rot)
	var ys := [0.0, -10.0, 10.0]
	var tilts := [0.0, -0.2, 0.2]
	_style_hit_scale = 0.42
	if slash_attack: slash_attack.monitoring = false
	_hitbox_ahead(aim, 20.0)
	rotation = aim
	for i in 3:
		var y: float = ys[i]
		tween.tween_property(self, "position", _rest_position + Vector2(-7.0, y), total * 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "rotation", aim + float(tilts[i]), total * 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_rearm_hits)
		tween.tween_callback(_stab_fx.bind(y))
		tween.tween_property(self, "position", _rest_position + Vector2(26.0, y), total * 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_interval(total * 0.04)
	tween.tween_callback(_disable_slash_monitoring)
	tween.tween_property(self, "position", _rest_position, total * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "rotation", offset_rot, total * 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(total * 0.17)
	tween.tween_callback(_on_attack_finished)

# Hachazo: levanta el arma por encima, la deja caer con un golpe seco y un pequeño aplastamiento.
func _tween_chop(tween: Tween, start_rot: float, end_rot: float, offset_rot: float, total: float) -> void:
	_style_hit_scale = 1.2
	if slash_attack: slash_attack.monitoring = false
	rotation = offset_rot
	tween.tween_property(self, "rotation", start_rot - deg_to_rad(40.0), total * 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", _rest_position + Vector2(-8.0, 0.0), total * 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_chop_slam.bind(total * 0.1))
	tween.tween_property(self, "rotation", end_rot, total * 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "position", _rest_position + Vector2(12.0, 0.0), total * 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "scale", _rest_scale * 1.15, total * 0.1)
	tween.tween_callback(_chop_impact)
	tween.tween_interval(total * 0.08)
	tween.tween_callback(_disable_slash_monitoring)
	tween.tween_property(self, "rotation", offset_rot, total * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "position", _rest_position, total * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "scale", _rest_scale, total * 0.4)
	tween.tween_interval(total * 0.2)
	tween.tween_callback(_on_attack_finished)

# Arranque de la caída del hachazo: arma los impactos y deja la estela del golpe.
func _chop_slam(drop_time: float) -> void:
	_arm_hits_deferred()
	if not _play_trail(false, 0.3 / maxf(0.03, drop_time)):
		_play_attack_fx(false)

# Cuando el arma llega abajo: anillo de polvo y chispa en la punta.
func _chop_impact() -> void:
	if not is_inside_tree(): return
	var tip := to_global(Vector2(0.0, -_blade_len()))
	WeaponFx.play_world(get_tree(), "dust_ring", tip + Vector2(0.0, 4.0), 0.0, Vector2.ONE * (_fx_scale() * 1.1), 3)
	WeaponFx.play_world(get_tree(), "hit_spark", tip, 0.0, Vector2.ONE * 0.9)

# Giro completo: pega a todo lo que rodea al jugador.
func _tween_spin(tween: Tween, offset_rot: float, total: float) -> void:
	_style_hit_scale = 0.9
	_arm_hits()
	rotation = offset_rot
	tween.tween_property(self, "rotation", offset_rot + TAU, total * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "scale", _rest_scale * 1.12, total * 0.55)
	tween.tween_callback(_disable_slash_monitoring)
	tween.tween_property(self, "scale", _rest_scale, total * 0.15)
	tween.tween_interval(total * 0.3)
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
		custom_snd.bus = "SFX"
		custom_snd.play()
		return
	if audio_player and attack_sounds.size() > 0:
		audio_player.stream = attack_sounds.pick_random()
		audio_player.play()

func _play_attack_fx(backhand: bool = false) -> void:
	if attack_fx:
		attack_fx.flip_v = _fx_base_flip_v != backhand
		attack_fx.show()
		attack_fx.stop()
		attack_fx.play("attack")

func _disable_slash_monitoring() -> void:
	if slash_attack:
		slash_attack.set_deferred("monitoring", false)

func _on_attack_finished() -> void:
	_is_attacking = false
	rotation = deg_to_rad(sprite_rotation_offset)
	if slash_attack: slash_attack.position = _slash_rest_pos
	if _style_active:
		_style_active = false
		position = _rest_position
		scale = _rest_scale
	_style_hit_scale = 1.0
	if slash_attack: slash_attack.monitoring = false

func is_attacking() -> bool:
	return _is_attacking

func _on_body_entered(body: Node2D) -> void:
	if not _is_attacking: return
	if body in hit_enemies: return
	if body.is_in_group("player"): return
	if not body.has_method("take_damage"): return
	
	hit_enemies.append(body)
	_apply_damage_to_enemy(body, _style_hit_scale)

func _apply_damage_to_enemy(body: Node2D, damage_scale: float = 1.0) -> void:
	var final_dmg = damage
	var final_kb = knockback_force
	var is_crit = false
	var crit_chance = 0.0
	var crit_damage = 2.0
	
	var equip_owner = _find_equip_owner()
	if equip_owner:
		final_dmg += int(equip_owner._get_equip_stat("damage", false))
		final_dmg = maxi(1, roundi(final_dmg * maxf(0.1, 1.0 + equip_owner._get_equip_stat("damage_multiplier", false))))
		var flat_kb = equip_owner._get_equip_stat("knockback_force", false)
		var pct_kb = equip_owner._get_equip_stat("knockback_percent", false)
		final_kb = (final_kb + flat_kb) * (1.0 + pct_kb)
		crit_chance += equip_owner._get_equip_stat("crit_chance", false)
		crit_damage += equip_owner._get_equip_stat("crit_damage", false)
		
	if randf() <= crit_chance:
		final_dmg = int(final_dmg * crit_damage)
		is_crit = true
	final_dmg = maxi(1, roundi(final_dmg * damage_scale))
	_spawn_hit_fx(body, is_crit)

	var is_marked_hit = false
	if equip_owner and body.has_meta("werewolf_mark") and equip_owner.has_method("_is_hombre_lobo_active") and equip_owner._is_hombre_lobo_active():
		is_marked_hit = true
	var was_enemy_alive = not (body.get("is_dying") == true)
	var protocol_mult: float = equip_owner.protocol_damage_multiplier() if equip_owner and equip_owner.has_method("protocol_damage_multiplier") else 1.0
	ProtocolRuntime.deal_damage(body, final_dmg * protocol_mult, is_crit, "overload_damage" if protocol_mult > 1.0 else "", 1.0 - 1.0 / protocol_mult)
	if equip_owner and equip_owner.has_method("apply_melee_item_status"):
		equip_owner.apply_melee_item_status(body)
	if equip_owner and equip_owner.has_method("record_enemy_hit"):
		equip_owner.record_enemy_hit(body)
	_apply_knockback_to_enemy(body, final_kb)
	
	if was_enemy_alive and body.get("is_dying") == true and equip_owner and equip_owner.has_method("check_nemesis_kill_heal"):
		equip_owner.check_nemesis_kill_heal(body)
	
	if equip_owner and equip_owner.get("is_furia_active") == true:
		_trigger_furia_area_attack(body.global_position, final_dmg)
	
	# Holy Fire: quema y pone (o pasa) la lengua de fuego al enemigo golpeado
	if equip_owner and equip_owner.has_method("on_holy_fire_hit"):
		equip_owner.on_holy_fire_hit(body, final_dmg)
	if equip_owner and equip_owner.has_method("on_alto_octanaje_hit"):
		equip_owner.on_alto_octanaje_hit(body, final_dmg)

	if is_marked_hit and equip_owner and equip_owner.has_method("_trigger_werewolf_mark_explosion"):
		equip_owner._trigger_werewolf_mark_explosion(body)

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
