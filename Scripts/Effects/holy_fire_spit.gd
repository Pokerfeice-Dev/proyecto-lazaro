extends Node2D
class_name HolyFireSpit

## Escupitajo de la lengua de fuego (sinergia Holy Fire). Sale de la lengua,
## sube en arco y cae en un punto del piso: ahí quema a los enemigos que
## agarra (daño + quemadura corta). El nodo vive en el piso: la sombra marca
## dónde va a caer y el proyectil se dibuja levantado según la altura.
## Uso: HolyFireSpit.launch(parent, desde_altura, punto_piso_inicio, punto_piso_fin, daño, excluido)

const BULLET := preload("res://Art/Effects/HolyFire/firetonguebullet8x8.png")
const FLIGHT_TIME := 0.55
const ARC_HEIGHT := 46.0
const HIT_RADIUS := 28.0
const BURN_TICK := 0.4
const BURN_TIME := 1.6

var damage := 6
var exclude: Node2D
var _start: Vector2
var _end: Vector2
var _start_height := 30.0
var _t := 0.0
var _bullet: Sprite2D
var _landed := false

static func launch(parent: Node, start_height: float, ground_from: Vector2, ground_to: Vector2, dmg: int, excluded: Node2D = null) -> HolyFireSpit:
	var spit = HolyFireSpit.new()
	spit.damage = dmg
	spit.exclude = excluded
	spit._start = ground_from
	spit._end = ground_to
	spit._start_height = start_height
	parent.add_child(spit)
	spit.global_position = ground_from
	return spit

func _ready() -> void:
	z_index = 5
	_bullet = Sprite2D.new()
	_bullet.texture = BULLET
	_bullet.scale = Vector2(2, 2)
	add_child(_bullet)

func _process(delta: float) -> void:
	_t += delta / FLIGHT_TIME
	var k = minf(_t, 1.0)
	global_position = _start.lerp(_end, k)
	# altura: arranca en la boca de la lengua, sube en arco y cae al piso
	var height = _start_height * (1.0 - k) + ARC_HEIGHT * 4.0 * k * (1.0 - k)
	_bullet.position = Vector2(0, -height)
	_bullet.rotation += delta * 14.0
	queue_redraw()
	if _t >= 1.0 and not _landed:
		_landed = true
		_land()

# Sombra en el piso que se achica y oscurece a medida que baja.
func _draw() -> void:
	var k = clampf(_t, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 4.0 + 3.0 * k, Color(0, 0, 0, 0.25 + 0.25 * k))
	draw_set_transform(Vector2.ZERO)

func _land() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or enemy == exclude: continue
		if enemy.get("is_dying") == true: continue
		if enemy.global_position.distance_to(global_position) > HIT_RADIUS: continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, false)
			IgniteEffect.apply_ignite(enemy, maxi(1, int(damage * 0.3)), BURN_TICK, BURN_TIME)
	_splash()
	queue_free()

# Salpicadura de fuego donde cae.
func _splash() -> void:
	var p = CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 12
	p.lifetime = 0.45
	p.direction = Vector2.UP
	p.spread = 70.0
	p.gravity = Vector2(0, 180)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 80.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	g.set_color(1, Color(0.85, 0.15, 0.2, 0.0))
	p.color_ramp = g
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	get_parent().add_child(p)
	p.global_position = global_position
	p.emitting = true
	p.finished.connect(p.queue_free)
