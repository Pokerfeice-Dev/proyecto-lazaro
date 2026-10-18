extends Node2D
class_name FuelSoak

## Mancha de gasolina de la sinergia Alto Octanaje (hacha). Cada hachazo deja
## al enemigo empapado: gotea, tiene un charco debajo y brilla con el reflejo
## del combustible. Si una bala del jugador le pega mientras está manchado,
## explota (FuelExplosion), y la explosión hace estallar en cadena a los otros
## enemigos manchados que alcance.
## Uso: FuelSoak.soak(enemigo, daño_de_la_explosión)
##      FuelSoak.notify_bullet_hit(cuerpo)   (lo llaman los proyectiles del jugador)

const DURATION := 8.0
const PUDDLE_SIZE := Vector2(17.0, 6.0)
const FUEL_DARK := Color(0.1, 0.07, 0.04, 0.82)
const FUEL_SHEEN := Color(0.85, 0.55, 0.18)

var host: Node2D
var power := 20
var _life := DURATION
var _time := 0.0
var _drips: CPUParticles2D
var _detonating := false

## Mancha al enemigo (o renueva la mancha que ya tenía, quedándose con el daño mayor).
static func soak(target: Node2D, explosion_damage: int) -> FuelSoak:
	if not is_instance_valid(target) or target.get("is_dying") == true: return null
	var existing = target.get_node_or_null("FuelSoak") as FuelSoak
	if existing:
		existing.refresh(explosion_damage)
		return existing
	var s = FuelSoak.new()
	s.name = "FuelSoak"
	s.host = target
	s.power = explosion_damage
	target.add_child(s)
	return s

## Una bala del jugador le pegó a "body": si estaba manchado, explota.
static func notify_bullet_hit(body: Node) -> void:
	if not is_instance_valid(body): return
	var s = body.get_node_or_null("FuelSoak") as FuelSoak
	if s:
		s.detonate()

func _ready() -> void:
	z_index = -1 # el charco queda debajo del enemigo
	_drips = _make_drips()
	add_child(_drips)
	_pop()

func refresh(explosion_damage: int) -> void:
	power = maxi(power, explosion_damage)
	_life = DURATION
	_pop()

func _process(delta: float) -> void:
	_time += delta
	_life -= delta
	if not is_instance_valid(host) or host.get("is_dying") == true or _life <= 0.0:
		queue_free()
		return
	# en el último segundo el charco se seca (se desvanece)
	modulate.a = clampf(_life, 0.0, 1.0)
	queue_redraw()

# Charco debajo del enemigo con un reflejo que se mueve, como la gasolina al sol.
func _draw() -> void:
	draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, PUDDLE_SIZE.y / PUDDLE_SIZE.x))
	draw_circle(Vector2.ZERO, PUDDLE_SIZE.x, FUEL_DARK)
	var sheen = Color(FUEL_SHEEN, 0.6 + 0.25 * sin(_time * 3.0))
	draw_arc(Vector2.ZERO, PUDDLE_SIZE.x * 0.62, _time * 1.3, _time * 1.3 + 1.8, 12, sheen, 3.0)
	var violet = Color(0.6, 0.4, 1.0, 0.45 + 0.2 * sin(_time * 2.2 + 1.0))
	draw_arc(Vector2.ZERO, PUDDLE_SIZE.x * 0.35, -_time, -_time + 1.4, 10, violet, 2.5)
	var teal = Color(0.3, 0.9, 0.75, 0.35 + 0.15 * sin(_time * 1.7))
	draw_arc(Vector2.ZERO, PUDDLE_SIZE.x * 0.82, PI + _time * 0.8, PI + _time * 0.8 + 1.0, 10, teal, 2.0)
	draw_set_transform(Vector2.ZERO)

# Gotas oscuras que caen del enemigo.
func _make_drips() -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.amount = 9
	p.lifetime = 0.6
	p.position = Vector2(0, -6)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(8, 4)
	p.direction = Vector2.DOWN
	p.spread = 8.0
	p.gravity = Vector2(0, 260)
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 20.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	var g = Gradient.new()
	g.set_color(0, Color(0.95, 0.65, 0.2, 1.0))
	g.set_color(1, Color(0.1, 0.07, 0.05, 0.0))
	p.color_ramp = g
	return p

# Salto chiquito al mancharse.
func _pop() -> void:
	scale = Vector2(1.4, 1.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Explota (una sola vez). La explosión puede detonar otras manchas cercanas.
func detonate(delay: float = 0.0) -> void:
	if _detonating: return
	_detonating = true
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(host): return
	FuelExplosion.blast(host.get_parent(), host.global_position, power, host)
	queue_free()
