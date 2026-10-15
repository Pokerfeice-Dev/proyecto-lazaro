extends Node2D
class_name BileGlob

## Escupitajo de bilis de El Primogénito: vuela en arco hasta un punto del
## suelo, marcado con su sombra, y al caer salpica y deja un charco de bilis.

@export var flight_time := 0.75
@export var arc_height := 70.0
@export var damage := 10
@export var splash_radius := 24.0
@export var puddle_radius := 30.0
@export var puddle_duration := 4.5
@export var source_name := "El Primogénito"

const BILE := Color("#a6cf2e")
const BILE_DARK := Color("#3e5a14")
const BILE_LIGHT := Color("#e4f78a")

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _t := 0.0

## Lanza el escupitajo desde "from" hasta "to" (posiciones globales).
func launch(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	global_position = from

func _ready() -> void:
	z_as_relative = false
	z_index = 6

func _process(delta: float) -> void:
	_t = minf(1.0, _t + delta / maxf(flight_time, 0.05))
	global_position = _from.lerp(_to, _t)
	queue_redraw()
	if _t >= 1.0:
		_land()

func _draw() -> void:
	var height := sin(_t * PI) * arc_height
	# sombra en el suelo, crece a medida que cae
	var shadow := lerpf(4.0, 9.0, _t)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, shadow, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var center := Vector2(0, -height)
	draw_circle(center, 7.0, BILE_DARK)
	draw_circle(center, 5.5, BILE)
	draw_rect(Rect2(center + Vector2(-3, -4), Vector2(2, 2)), BILE_LIGHT)

func _land() -> void:
	set_process(false)
	for player in get_tree().get_nodes_in_group("player"):
		if player.global_position.distance_to(global_position) <= splash_radius and player.has_method("take_damage"):
			player.take_damage(damage, source_name, global_position)
	var puddle := BilePuddle.new()
	puddle.radius = puddle_radius
	puddle.duration = puddle_duration
	get_parent().add_child(puddle)
	puddle.global_position = global_position
	_splash()
	queue_free()

func _splash() -> void:
	var drops := CPUParticles2D.new()
	drops.one_shot = true
	drops.explosiveness = 1.0
	drops.amount = 14
	drops.lifetime = 0.45
	drops.direction = Vector2(0, -1)
	drops.spread = 80.0
	drops.gravity = Vector2(0, 260)
	drops.initial_velocity_min = 60.0
	drops.initial_velocity_max = 120.0
	drops.scale_amount_min = 2.0
	drops.scale_amount_max = 4.0
	drops.color = BILE
	drops.z_as_relative = false
	drops.z_index = 6
	get_parent().add_child(drops)
	drops.global_position = global_position
	drops.emitting = true
	drops.finished.connect(drops.queue_free)
