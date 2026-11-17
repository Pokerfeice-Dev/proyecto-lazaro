class_name EnemyHollowTorso
extends Mecha
# Torso hueco (zona 3). Ya no pega como el Mecha: es un "nido" lento que juega con su núcleo.
#  - Cerrado: la placa lo blinda (recibe x0,4), camina hacia ti y se planta a media distancia.
#  - Se abre: aviso de 0,6 s (la placa tiembla y se escapa luz por las rendijas).
#  - Abierto: núcleo expuesto (recibe x2) y ASPIRA: si estás cerca te arrastra hacia él y te
#    cuesta alejarte. El dash corta la succión. Si llegas hasta el núcleo te AGARRA: te
#    aturde (sin caminar ni hacer dash; sí apuntar y disparar) y te aprieta con una caja
#    torácica (GripOverlay) mientras te hace daño. Con el torso abierto recibe x2: ataca ahí.
#  - Descarga: levanta los brazos y golpea el piso; del núcleo sale un anillo de esquirlas o,
#    cada dos aperturas, pare un brazo errante por el pecho (máximo 2 vivos; si el torso
#    muere, sus brazos mueren con él).
# El sprite tiene un hueco transparente en el pecho: el núcleo (o la placa) que dibuja _draw()
# queda debajo del sprite y se ve a través del hueco; de espaldas, el cuerpo lo tapa.

@export_category("Torso hueco")
@export var torso_speed: float = 55.0
@export var torso_health: int = 120
@export var closed_time: float = 2.4
@export var opening_warn_time: float = 0.6
@export var open_time: float = 3.0
@export var open_damage_multiplier: float = 2.0
@export var closed_damage_multiplier: float = 0.4
## Se queda a esta distancia: lo justo para que la succión importe.
@export var keep_distance: float = 110.0
@export_group("Succión")
@export var suction_radius: float = 190.0
@export var suction_speed: float = 95.0
## Multiplicador de velocidad del jugador mientras lo aspira (cuesta alejarse).
@export var suction_slow: float = 0.8
@export_group("Agarre")
## Si llegas a esta distancia del núcleo mientras aspira, te agarra.
@export var grab_radius: float = 30.0
## Cuánto te tiene aturdido y apretado.
@export var grip_time: float = 1.3
@export var grip_tick_damage: int = 4
@export var grip_tick_interval: float = 0.4
@export var grip_pull_speed: float = 200.0
## Tiempo sin poder volver a agarrarte después de soltarte.
@export var grip_cooldown: float = 3.0
@export_group("Descarga")
@export var burst_count: int = 10
@export var burst_speed: float = 150.0
@export var burst_damage: int = 8
@export var max_children: int = 2
@export var arm_scene: PackedScene = preload("res://Scenes/Enemies/EnemyWanderingArm.tscn")
@export_group("Núcleo")
@export var core_radius: float = 8.0
@export var core_offset: Vector2 = Vector2(0, -6)
@export var body_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

enum Core { CLOSED, OPENING, OPEN, DISCHARGE }
const SUCTION_MOD := "hollow_torso_suction"
const GRIP_KEY := "hollow_torso_grip"
const GRIP_SHEET := "res://Art/Enemies/Redesign/hollow_torso_grip.png"
const BURST_SCENE := preload("res://Scenes/Enemies/enemy_shooter_projectile.tscn")
const DISCHARGE_FRAME := 8   # cuadro de la animación "attack" en el que los puños tocan el piso

var _core: Core = Core.CLOSED
var _core_time_left: float = 0.0
var _cycle: int = 0
var _pulse: float = 0.0
var _discharged: bool = false
var _sucking: bool = false
var _gripped: bool = false
var _grip_left: float = 0.0
var _grip_tick_left: float = 0.0
var _grip_cd: float = 0.0
var _grip_overlay: GripOverlay = null
var _children: Array = []   # WeakRef de los brazos que parió

func _ready() -> void:
	super._ready()
	charge_enabled = false
	_can_attack = false          # nunca hace el golpe del Mecha
	move_speed = torso_speed
	max_health = torso_health
	current_health = max_health
	_default_modulate = body_tint
	var sprite := _get_sprite()
	if sprite: sprite.modulate = body_tint
	if anim_sprite: anim_sprite.frame_changed.connect(_on_torso_frame_changed)
	_set_core(Core.CLOSED)

func _exit_tree() -> void:
	_end_grip()
	_release_player()
	super._exit_tree()

# --- El golpe del Mecha queda anulado ---

func perform_attack() -> void:
	pass

func _try_attack(_body: Node2D) -> void:
	pass

func _on_attack_cooldown_ready() -> void:
	_can_attack = false

# --- Ciclo del núcleo ---

func process_movement(delta: float) -> void:
	if is_dying:
		_end_grip()
		_release_player()
		super.process_movement(delta)
		return
	_pulse += delta
	_grip_cd = maxf(0.0, _grip_cd - delta)
	if _gripped: _process_grip(delta)
	if not has_detected_player or not is_instance_valid(target):
		super.process_movement(delta) # deambula como el Mecha
		queue_redraw()
		return
	_core_time_left -= delta
	match _core:
		Core.CLOSED:
			_walk_closer()
			if _core_time_left <= 0.0: _set_core(Core.OPENING)
		Core.OPENING:
			velocity = Vector2.ZERO
			play_animation("idle")
			if _core_time_left <= 0.0: _set_core(Core.OPEN)
		Core.OPEN:
			velocity = Vector2.ZERO
			play_animation("idle")
			update_sprite_direction()
			_suck_player(delta)
			if _core_time_left <= 0.0: _set_core(Core.DISCHARGE)
		Core.DISCHARGE:
			velocity = Vector2.ZERO
			if _core_time_left <= 0.0:
				if not _discharged: _discharge()
				_set_core(Core.CLOSED)
	queue_redraw()

func _set_core(state: Core) -> void:
	_core = state
	match state:
		Core.CLOSED:
			_core_time_left = closed_time
			_release_player()
			if anim_sprite and anim_sprite.animation == "attack": play_animation("idle")
		Core.OPENING:
			_core_time_left = opening_warn_time
		Core.OPEN:
			_core_time_left = open_time
			_cycle += 1
		Core.DISCHARGE:
			_release_player()
			_discharged = false
			_core_time_left = _get_anim_duration("attack") + 0.1
			if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("attack"):
				anim_sprite.speed_scale = 1.0
				anim_sprite.play("attack")
				anim_sprite.frame = 0
			_play_hydraulic_sound()

func _walk_closer() -> void:
	var dist := global_position.distance_to(target.global_position)
	if dist > keep_distance:
		velocity = get_nav_direction_to_target() * move_speed
	else:
		velocity = Vector2.ZERO
	update_sprite_direction()
	update_animation_state()

# Aspira al jugador hacia el núcleo (respeta paredes: se mueve con move_and_collide).
func _suck_player(delta: float) -> void:
	if not (target is CharacterBody2D) or _gripped: return
	var core_pos := global_position + core_offset
	var to_core := core_pos - target.global_position
	var d := to_core.length()
	if d <= grab_radius and _grip_cd <= 0.0 and target.get("is_dashing") != true:
		_start_grip()
		return
	if d > suction_radius or d < 20.0 or target.get("is_dashing") == true:
		_release_player()
		return
	var closeness := 1.0 - d / suction_radius
	(target as CharacterBody2D).move_and_collide(to_core / d * suction_speed * (0.35 + 0.65 * closeness) * delta)
	if not _sucking and target.has_method("set_speed_modifier"):
		target.set_speed_modifier(SUCTION_MOD, suction_slow)
	_sucking = true

# --- Agarre: si llegas al núcleo, te aturde y te aprieta ---

func _start_grip() -> void:
	_gripped = true
	_grip_left = grip_time
	_grip_tick_left = grip_tick_interval
	_release_player()   # la succión termina: ahora te tiene agarrado
	if target.has_method("apply_stun"): target.apply_stun(grip_time + 0.05, GRIP_KEY)
	_grip_overlay = GripOverlay.attach(target, GRIP_SHEET)
	_play_hydraulic_sound()

func _process_grip(delta: float) -> void:
	if is_dying or not is_instance_valid(target):
		_end_grip()
		return
	var to_core := global_position + core_offset - target.global_position
	if to_core.length() > 3.0 and target is CharacterBody2D:
		(target as CharacterBody2D).move_and_collide(to_core.limit_length(grip_pull_speed * delta))
	_grip_left -= delta
	_grip_tick_left -= delta
	if _grip_tick_left <= 0.0:
		_grip_tick_left = grip_tick_interval
		if target.has_method("take_damage"):
			target.take_damage(grip_tick_damage, "Torso hueco", global_position)
	if _grip_left <= 0.0: _end_grip()

func _end_grip() -> void:
	if not _gripped: return
	_gripped = false
	_grip_cd = grip_cooldown
	if is_instance_valid(target) and target.has_method("release_stun"): target.release_stun(GRIP_KEY)
	if is_instance_valid(_grip_overlay): _grip_overlay.release()
	_grip_overlay = null

func _release_player() -> void:
	if not _sucking: return
	_sucking = false
	if is_instance_valid(target) and target.has_method("remove_speed_modifier"):
		target.remove_speed_modifier(SUCTION_MOD)

func _on_torso_frame_changed() -> void:
	if is_dying or _core != Core.DISCHARGE or _discharged: return
	if anim_sprite.animation == "attack" and anim_sprite.frame >= DISCHARGE_FRAME:
		_discharge()

func _discharge() -> void:
	_discharged = true
	_play_explosion_sound()
	_shake_ground_impact()
	if _cycle % 2 == 0 and _alive_children() < max_children and arm_scene:
		_birth_arm()
	else:
		_burst()

func _burst() -> void:
	var start := randf() * TAU
	for i in burst_count:
		var dir := Vector2.RIGHT.rotated(start + TAU * float(i) / float(burst_count))
		var proj = BURST_SCENE.instantiate()
		register_attack(proj)
		proj.source_name = "Torso hueco"
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + core_offset
		proj.setup(dir, burst_damage, "player")
		proj.speed = burst_speed

func _birth_arm() -> void:
	var arm = arm_scene.instantiate()
	arm.global_position = global_position + core_offset + Vector2(0, 8)
	# Igual que la invocadora con sus abejas: cuelga del mismo padre, así la sala lo cuenta.
	get_parent().add_child(arm)
	_children.append(weakref(arm))
	arm.alert_to_player()

func _alive_children() -> int:
	_children = _children.filter(func(r): return is_instance_valid(r.get_ref()) and not r.get_ref().is_dying)
	return _children.size()

func die() -> void:
	if is_dying: return
	_end_grip()
	_release_player()
	# los brazos que parió mueren con él (como el enjambre de la apicultora muerta)
	for r in _children:
		var arm = r.get_ref()
		if is_instance_valid(arm) and not arm.is_dying and arm.has_method("die"): arm.die()
	_children.clear()
	super.die()

func take_damage(amount: int, is_crit: bool = false) -> void:
	var open := _core == Core.OPEN or (_core == Core.DISCHARGE and not _discharged)
	var multiplier := open_damage_multiplier if open else closed_damage_multiplier
	super.take_damage(maxi(1, int(round(amount * multiplier))), is_crit)
	if is_instance_valid(_grip_overlay): _grip_overlay.flash()

# Muerte animada con el sprite propio (animación "death"); sin ella, desintegración normal.
func _spawn_pixel_death() -> void:
	if not EnemyDeathAnim.play(self): super._spawn_pixel_death()

# --- Dibujo del núcleo (debajo del sprite, se ve por el hueco del pecho) ---

func _draw() -> void:
	super._draw()
	if is_dying: return
	var open := _core == Core.OPEN or (_core == Core.DISCHARGE and not _discharged)
	if open:
		var glow := 0.75 + 0.25 * sin(_pulse * 8.0)
		draw_circle(core_offset, core_radius * 1.6, Color(1.0, 0.4, 0.1, 0.25 * glow))
		draw_circle(core_offset, core_radius, Color(1.0, 0.65, 0.2, 0.95 * glow))
		if _core == Core.OPEN: _draw_suction()
		return
	# Pecho cerrado: una placa tapa el hueco del sprite.
	var shake := Vector2.ZERO
	if _core == Core.OPENING:
		shake = Vector2(sin(_pulse * 70.0), cos(_pulse * 55.0)) * 1.2
	draw_circle(core_offset + shake, core_radius * 1.3, Color(0.42, 0.45, 0.55, 1.0))
	draw_arc(core_offset + shake, core_radius * 1.3, 0.0, TAU, 20, Color(0.7, 0.75, 0.85, 1.0), 2.0)
	draw_line(core_offset + shake + Vector2(-core_radius, 0.0), core_offset + shake + Vector2(core_radius, 0.0), Color(0.2, 0.2, 0.28, 1.0), 1.5)
	if _core == Core.OPENING:
		# luz que se escapa por las rendijas: avisa que se va a abrir
		var k := 1.0 - clampf(_core_time_left / opening_warn_time, 0.0, 1.0)
		draw_line(core_offset + shake + Vector2(-core_radius, 0.0), core_offset + shake + Vector2(core_radius, 0.0), Color(1.0, 0.6, 0.2, 0.4 + 0.6 * k), 2.0)

# Anillos que se cierran hacia el núcleo mientras aspira (en coordenadas del enemigo).
func _draw_suction() -> void:
	for i in 3:
		var t := fmod(_pulse * 0.9 + float(i) / 3.0, 1.0)
		var r := lerpf(suction_radius, core_radius * 2.0, t)
		var a := 0.22 * (1.0 - t) + 0.05
		var segs := 10
		for s in segs:
			var ang := TAU * float(s) / float(segs) + _pulse * 0.6
			draw_arc(core_offset, r, ang, ang + TAU / float(segs) * 0.45, 4, Color(1.0, 0.6, 0.25, a), 1.5)
