extends Node2D
class_name HolyFireTongue

## Lengua de fuego de la sinergia Holy Fire (maza). Flota sobre la cabeza del
## último enemigo golpeado y cada tanto escupe fuego en 8 direcciones: los
## escupitajos suben en arco y caen alrededor, quemando a los enemigos cercanos.
## Si golpeas a otro enemigo, la lengua salta hacia él. Si su enemigo muere,
## busca al más cercano; si no hay ninguno (o pasa un rato sin golpes), se apaga.
## La maneja el jugador (player.gd): HolyFireTongue.spawn(enemigo, daño) / attach().

const SHEET := preload("res://Art/Effects/HolyFire/statuseffect_firetongue_spritesheet.png")
const SPIT_SOUND := preload("res://Audio/Sfx/IA/lengua_escupe.wav") # lengua que escupe fuego (antes, el lanzallamas)
const FRAMES := 4
const FPS := 10.0
const SPIT_INTERVAL := 1.2
const SPIT_RADIUS := 80.0
const DIRECTIONS := 8
const LIFETIME := 8.0
const JUMP_RADIUS := 220.0
const JUMP_TIME := 0.25
const DEFAULT_HEAD := -34.0

var host: Node2D
var damage := 6
var _sprite: Sprite2D
var _time := 0.0
var _spit_left := 0.5
var _life := LIFETIME
var _jumping := false
var _leaving := false
var _sfx: AudioStreamPlayer2D

static func spawn(target: Node2D, dmg: int) -> HolyFireTongue:
	var tongue = HolyFireTongue.new()
	tongue.damage = dmg
	target.get_tree().current_scene.add_child(tongue)
	tongue.host = target
	tongue.global_position = tongue._head_of(target)
	tongue._pop_in()
	return tongue

func _ready() -> void:
	z_as_relative = false
	z_index = 45
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = FRAMES
	_sprite.scale = Vector2(2, 2)
	_sprite.offset = Vector2(0, -6)
	add_child(_sprite)
	_sfx = AudioStreamPlayer2D.new()
	_sfx.stream = SPIT_SOUND
	_sfx.bus = "SFX"
	_sfx.volume_db = -12.0
	_sfx.pitch_scale = 1.5
	add_child(_sfx)

func is_leaving() -> bool:
	return _leaving

## Golpe con la maza: si es el mismo enemigo renueva la lengua; si es otro, salta hacia él.
func attach(target: Node2D, dmg: int) -> void:
	damage = dmg
	_life = LIFETIME
	if target == host or _leaving: return
	_jump_to(target)

## Se apaga (sinergia desequipada, sin enemigos o sin golpes por un rato).
func extinguish() -> void:
	if _leaving: return
	_leaving = true
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2(0.2, 0.2), 0.25)
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	_time += delta
	_sprite.frame = int(_time * FPS) % FRAMES
	if _leaving or _jumping: return
	if not _host_alive():
		_find_new_host()
		return
	global_position = _head_of(host) + Vector2(0, sin(_time * 4.0) * 2.0)
	_life -= delta
	if _life <= 0.0:
		extinguish()
		return
	_spit_left -= delta
	if _spit_left <= 0.0:
		_spit_left = SPIT_INTERVAL
		_spit()

func _host_alive() -> bool:
	return is_instance_valid(host) and host.is_inside_tree() and host.get("is_dying") != true

# Punto sobre la cabeza: encima de la barra de vida si tiene, si no a una altura fija.
func _head_of(target: Node2D) -> Vector2:
	var bar = target.get_node_or_null("HealthBar") as Control
	var y = bar.position.y - 12.0 if bar else DEFAULT_HEAD
	return target.global_position + Vector2(0, minf(y, DEFAULT_HEAD))

func _find_new_host() -> void:
	var best: Node2D = null
	var best_dist := JUMP_RADIUS
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or enemy == host or enemy.get("is_dying") == true: continue
		var d = enemy.global_position.distance_to(global_position)
		if d < best_dist:
			best = enemy
			best_dist = d
	if best:
		_jump_to(best)
	else:
		extinguish()

# Salto en arco hasta la cabeza del nuevo enemigo.
func _jump_to(target: Node2D) -> void:
	host = target
	_jumping = true
	var t = create_tween()
	t.tween_method(_jump_step.bind(global_position, target), 0.0, 1.0, JUMP_TIME)
	t.tween_callback(_on_jump_landed)

func _jump_step(k: float, from: Vector2, target: Node2D) -> void:
	if not is_instance_valid(target): return
	global_position = from.lerp(_head_of(target), k) + Vector2(0, -40.0 * 4.0 * k * (1.0 - k))

func _on_jump_landed() -> void:
	_jumping = false
	_spit_left = minf(_spit_left, 0.35)
	_pop_in()

func _pop_in() -> void:
	scale = Vector2(0.3, 0.3)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Escupe en 8 direcciones alrededor del enemigo; los escupitajos caen en arco.
func _spit() -> void:
	var ground = host.global_position
	var height = ground.y - global_position.y
	var offset = randf() * TAU / DIRECTIONS
	for i in DIRECTIONS:
		var dir = Vector2.from_angle(offset + TAU * i / DIRECTIONS)
		HolyFireSpit.launch(get_parent(), height, ground, ground + dir * SPIT_RADIUS, damage, host)
	var t = create_tween()
	t.tween_property(_sprite, "scale", Vector2(2.6, 1.6), 0.06)
	t.tween_property(_sprite, "scale", Vector2(2, 2), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_sfx.play(0.15)
	get_tree().create_timer(0.3, false).timeout.connect(_sfx.stop)
