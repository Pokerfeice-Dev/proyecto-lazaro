extends Area2D
class_name BilePuddle

## Charco de bilis corrosiva que deja El Primogénito al escupir. Quema al
## jugador mientras lo pisa y se seca solo. El arte sale de PuddleVisuals, con
## la misma pixelación que los charcos de los barriles.

@export var duration := 4.5
@export var radius := 30.0
@export var tick_damage := 3
@export var tick_interval := 0.5
@export var source_name := "Bilis de El Primogénito"

var _sprite: Sprite2D
var _tick := 0.0
var _time := 0.0
var _bodies: Array[Node2D] = []

func _ready() -> void:
	z_as_relative = false
	z_index = 1
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build()
	_start_lifecycle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _bodies.has(body):
		_bodies.append(body)

func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)

func _build() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	_sprite = Sprite2D.new()
	_sprite.texture = PuddleVisuals.build_bile_texture(randi())
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var stretch := radius / 30.0
	_sprite.scale = Vector2.ONE * PuddleVisuals.PIXEL * stretch
	add_child(_sprite)
	var bubbles := PuddleVisuals.bile_bubbles()
	bubbles.emission_rect_extents *= stretch
	add_child(bubbles)

func _start_lifecycle() -> void:
	scale = Vector2(0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(maxf(0.1, duration - 0.8))
	tween.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	_time += delta
	# la bilis late despacio, como si respirara
	var k := 0.5 + 0.5 * sin(_time * 3.0)
	_sprite.self_modulate = Color(1.0 + 0.06 * k, 1.0 + 0.1 * k, 1.0)

func _physics_process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0 or modulate.a < 0.4: return
	_tick = tick_interval
	for body in _bodies:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(tick_damage, source_name, global_position)
