extends Node2D
class_name FuelExplosion

## Explosión de gasolina de la sinergia Alto Octanaje. Daño moderado en un
## radio chico, empuje y una quemadura corta. Si alcanza a otros enemigos
## manchados (FuelSoak), explotan en cadena un instante después.
## También lastima al jugador si está dentro del radio (menos que a los
## enemigos); si eso lo mata, la pantalla de muerte lo cuenta con un chiste.
## Uso: FuelExplosion.blast(padre, posición, daño, enemigo_que_explota)

const RADIUS := 72.0
const CHAIN_DELAY := 0.12
const KNOCKBACK := 180.0
const SELF_DAMAGE_RATIO := 0.4
const SELF_DAMAGE_MIN := 6
const SELF_DAMAGE_MAX := 18
const KILLER_NAME := "Tu propia gasolina"
const SOUND := "res://Audio/Enemy_snd/Boss1/Explosion.mp3"
const LIFETIME := 1.8 # vive lo que dura el sonido

var damage := 20
var _t := 0.0

static func blast(parent: Node, pos: Vector2, dmg: int, source: Node2D = null) -> FuelExplosion:
	if not is_instance_valid(parent): return null
	var e = FuelExplosion.new()
	e.damage = dmg
	parent.add_child(e)
	e.global_position = pos
	e._hit_enemies(source)
	e._hit_player()
	return e

func _ready() -> void:
	z_index = 40
	_spawn_fire()
	_spawn_smoke()
	_play_sound()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= LIFETIME:
		queue_free()

# Destello y onda expansiva.
func _draw() -> void:
	var k = clampf(_t / 0.35, 0.0, 1.0)
	if k < 1.0:
		draw_circle(Vector2.ZERO, RADIUS * (0.35 + 0.65 * k), Color(1.0, 0.75, 0.3, 0.45 * (1.0 - k)))
		draw_arc(Vector2.ZERO, RADIUS * (0.4 + 0.75 * k), 0.0, TAU, 40, Color(1.0, 0.9, 0.6, 0.9 * (1.0 - k)), 3.0)
	var scorch = clampf(1.0 - _t / LIFETIME, 0.0, 1.0)
	draw_set_transform(Vector2(0, 6), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, RADIUS * 0.45, Color(0.05, 0.03, 0.02, 0.35 * scorch))
	draw_set_transform(Vector2.ZERO)

# --- Daño ---

func _hit_enemies(source: Node2D) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node2D: continue
		if enemy.get("is_dying") == true: continue
		if enemy.global_position.distance_to(global_position) > RADIUS: continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, false)
		if enemy.has_method("apply_knockback"):
			var dir = (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(KNOCKBACK, dir if dir != Vector2.ZERO else Vector2.UP)
		IgniteEffect.apply_ignite(enemy, maxi(1, int(damage * 0.08)), 0.4, 1.2)
		# reacción en cadena con las otras manchas
		if enemy != source:
			var soak = enemy.get_node_or_null("FuelSoak") as FuelSoak
			if soak:
				soak.detonate(CHAIN_DELAY)

func _hit_player() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player or not player.has_method("take_damage"): return
	var dist = player.global_position.distance_to(global_position)
	if dist <= RADIUS:
		var self_damage = clampi(int(damage * SELF_DAMAGE_RATIO), SELF_DAMAGE_MIN, SELF_DAMAGE_MAX)
		player.take_damage(self_damage, KILLER_NAME, global_position)
	if dist <= RADIUS * 3.0 and player.has_method("apply_custom_camera_shake"):
		player.apply_custom_camera_shake(7.0, 0.25)

# --- Efectos ---

func _spawn_fire() -> void:
	var p = _burst(34, 0.5, 150.0, 260.0, 4.0, 10.0)
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.55, 1.0))
	g.add_point(0.35, Color(1.0, 0.45, 0.08, 0.95))
	g.set_color(1, Color(0.25, 0.06, 0.02, 0.0))
	p.color_ramp = g
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat

func _spawn_smoke() -> void:
	var p = _burst(14, 0.9, 30.0, 70.0, 7.0, 13.0)
	p.gravity = Vector2(0, -40)
	var g = Gradient.new()
	g.set_color(0, Color(0.15, 0.12, 0.1, 0.7))
	g.set_color(1, Color(0.1, 0.1, 0.1, 0.0))
	p.color_ramp = g

func _burst(amount: int, life: float, vmin: float, vmax: float, smin: float, smax: float) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 0.95
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 10.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.damping_min = 120.0
	p.damping_max = 220.0
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	add_child(p)
	p.emitting = true
	return p

func _play_sound() -> void:
	if not ResourceLoader.exists(SOUND): return
	var a = AudioStreamPlayer2D.new()
	a.stream = load(SOUND)
	a.bus = "SFX"
	a.volume_db = -4.0
	a.pitch_scale = randf_range(1.25, 1.45)
	add_child(a)
	a.play()
