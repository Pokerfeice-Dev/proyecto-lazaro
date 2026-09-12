class_name FlameStream
extends Area2D

## Chorro continuo del Lanzallamas: un unico objeto pegado al arma mientras se
## mantiene presionado el disparo, en vez de disparar muchos proyectiles chicos.
## Reproduce ignite -> burn (loop) mientras se dispara, y extinguish al soltar.

const FLAME_FRAMES := preload("res://Art/Effects/FlameStreamAnim.tres")
const BASE_SCALE := 0.15
const FLAME_BASE_Y := 349.45

@export var base_range: float = 55.0
@export var max_range_bonus: float = 70.0
@export var range_ramp_time: float = 0.3
@export var thickness: float = 22.0
@export var tick_interval: float = 0.15

var damage_per_second: float = 20.0
var ignite_damage_per_tick: int = 2
var ignite_tick_interval: float = 0.4
var ignite_duration: float = 1.6
var hold_time: float = 0.0
var is_extinguishing: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer

func _ready() -> void:
	collision_layer = 8
	collision_mask = 7
	monitoring = true
	monitorable = false

	sprite.sprite_frames = FLAME_FRAMES
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("ignite")

	collision.shape = RectangleShape2D.new()

	_update_visual_scale()

	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

func setup(dps: float, ign_dmg: int, ign_interval: float, ign_duration: float) -> void:
	damage_per_second = dps
	ignite_damage_per_tick = ign_dmg
	ignite_tick_interval = ign_interval
	ignite_duration = ign_duration

func update_hold(current_hold_time: float) -> void:
	hold_time = current_hold_time
	if not is_extinguishing:
		_update_visual_scale()

func _current_range() -> float:
	var t = clamp(hold_time / range_ramp_time, 0.0, 1.0)
	return base_range + max_range_bonus * t

func _update_visual_scale() -> void:
	var range_now = _current_range()
	var scale_factor = BASE_SCALE * (range_now / base_range)
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position = Vector2(0, -FLAME_BASE_Y * scale_factor)

	var shape: RectangleShape2D = collision.shape
	shape.size = Vector2(range_now, thickness)
	collision.position = Vector2(range_now * 0.5, 0)

func start_extinguish() -> void:
	if is_extinguishing: return
	is_extinguishing = true
	monitoring = false
	tick_timer.stop()
	sprite.play("extinguish")

func _on_animation_finished() -> void:
	if sprite.animation == "ignite":
		sprite.play("burn")
	elif sprite.animation == "extinguish":
		queue_free()

func _on_tick() -> void:
	if is_extinguishing: return
	var tick_damage = damage_per_second * tick_interval
	for body in get_overlapping_bodies():
		if not body.is_in_group("enemy"): continue
		if body.has_method("take_damage"):
			body.take_damage(tick_damage, false)
		IgniteEffect.apply_ignite(body, ignite_damage_per_tick, ignite_tick_interval, ignite_duration)
