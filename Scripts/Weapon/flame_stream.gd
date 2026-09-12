class_name FlameStream
extends Area2D

## Chorro continuo del Lanzallamas: un unico objeto pegado al arma mientras se
## mantiene presionado el disparo, en vez de disparar muchos proyectiles chicos.
## Reproduce ignite -> burn (loop) mientras se dispara, y extinguish al soltar.

const FLAME_FRAMES := preload("res://Art/Effects/FlameStreamAnim.tres")
const FLAME_SFX_PATH := "res://Audio/Sfx/Flamethrower_sfx.mp3"
const BASE_SCALE := 0.15
const FLAME_BASE_Y := 349.45

@export var base_range: float = 55.0
@export var max_range_bonus: float = 70.0
@export var range_ramp_time: float = 0.3
@export var thickness: float = 22.0
@export var tick_interval: float = 0.15

@export_category("Audio Settings")
@export var target_volume_db: float = -2.0
@export var min_volume_db: float = -45.0
@export var fade_in_duration: float = 0.15
@export var fade_out_duration: float = 0.28

var damage_per_second: float = 20.0
var ignite_damage_per_tick: int = 2
var ignite_tick_interval: float = 0.4
var ignite_duration: float = 1.6
var hold_time: float = 0.0
var is_extinguishing: bool = false

var audio_player: AudioStreamPlayer2D = null
var audio_tween: Tween = null

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
	_setup_audio_player()
	_start_audio_fade_in()

	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

func _exit_tree() -> void:
	_cancel_audio_tween()

func _setup_audio_player() -> void:
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "FlameAudio"
	audio_player.bus = "SFX"
	var sfx = load(FLAME_SFX_PATH) as AudioStreamMP3
	if sfx:
		sfx.loop = true
	audio_player.stream = sfx
	audio_player.volume_db = min_volume_db
	add_child(audio_player)

func _start_audio_fade_in() -> void:
	if not audio_player:
		return
	audio_player.play()
	_cancel_audio_tween()
	audio_tween = create_tween()
	audio_tween.tween_property(audio_player, "volume_db", target_volume_db, fade_in_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _start_audio_fade_out() -> void:
	if not audio_player:
		return
	_cancel_audio_tween()
	audio_tween = create_tween()
	audio_tween.tween_property(audio_player, "volume_db", min_volume_db, fade_out_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _cancel_audio_tween() -> void:
	if not audio_tween:
		return
	if not audio_tween.is_valid():
		return
	audio_tween.kill()

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
	if is_extinguishing:
		return
	is_extinguishing = true
	monitoring = false
	tick_timer.stop()
	sprite.play("extinguish")
	_start_audio_fade_out()

func _on_animation_finished() -> void:
	if sprite.animation == "ignite":
		sprite.play("burn")
		return
	if sprite.animation == "extinguish":
		_stop_audio_and_free()

func _stop_audio_and_free() -> void:
	_cancel_audio_tween()
	if audio_player and audio_player.playing:
		audio_player.stop()
	queue_free()

func _on_tick() -> void:
	if is_extinguishing:
		return
	var tick_damage = damage_per_second * tick_interval
	for body in get_overlapping_bodies():
		_apply_tick_to_body(body, tick_damage)

func _apply_tick_to_body(body: Node2D, tick_damage: float) -> void:
	if not body.is_in_group("enemy"):
		return
	if body.has_method("take_damage"):
		body.take_damage(tick_damage, false)
	IgniteEffect.apply_ignite(body, ignite_damage_per_tick, ignite_tick_interval, ignite_duration)
