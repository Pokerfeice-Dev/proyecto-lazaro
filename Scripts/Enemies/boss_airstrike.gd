extends Node2D
class_name BossAirstrike

@export var delay_before_impact: float = 1.0
@export var damage_radius: float = 55.0
@export var damage: int = 20

var elapsed_time: float = 0.0
var has_exploded: bool = false

var explosion_frames: SpriteFrames
var explosion_sprite: AnimatedSprite2D
var explosion_audio: AudioStreamPlayer2D

func _ready() -> void:
	z_index = 5
	_setup_resources()
	_setup_audio()

func _setup_resources() -> void:
	explosion_frames = SpriteFrames.new()
	explosion_frames.add_animation("explode")
	explosion_frames.set_animation_speed("explode", 14.0)
	explosion_frames.set_animation_loop("explode", false)
	
	for i in range(11):
		var frame_num = str(i).lpad(4, "0")
		var path = "res://Art/Enemy_Boss_1/Fx/frame" + frame_num + ".png"
		var tex = load(path)
		if tex:
			explosion_frames.add_frame("explode", tex)

func _setup_audio() -> void:
	explosion_audio = AudioStreamPlayer2D.new()
	var snd = load("res://Audio/Enemy_snd/Boss1/Explosion.mp3")
	if snd:
		explosion_audio.stream = snd
	explosion_audio.volume_db = -2.0
	add_child(explosion_audio)

func _process(delta: float) -> void:
	if has_exploded: return
	
	elapsed_time += delta
	queue_redraw()
	
	if elapsed_time >= delay_before_impact:
		_trigger_impact()

func _draw() -> void:
	if has_exploded: return
	
	var progress = clampf(elapsed_time / delay_before_impact, 0.0, 1.0)
	var pulse = (sin(elapsed_time * 15.0) + 1.0) * 0.5
	
	var outer_color = Color(1.0, 0.15, 0.15, 0.5 + pulse * 0.3)
	var fill_color = Color(1.0, 0.2, 0.1, 0.25)
	var ring_color = Color(1.0, 0.8, 0.2, 0.8)
	
	# Background fill
	draw_circle(Vector2.ZERO, damage_radius, fill_color)
	
	# Outer warning circle
	draw_arc(Vector2.ZERO, damage_radius, 0, TAU, 32, outer_color, 2.5)
	
	# Countdown shrinking / growing circle
	draw_circle(Vector2.ZERO, damage_radius * progress, Color(1.0, 0.1, 0.1, 0.35))
	draw_arc(Vector2.ZERO, damage_radius * progress, 0, TAU, 32, ring_color, 2.0)

func _trigger_impact() -> void:
	has_exploded = true
	queue_redraw()
	_deal_area_damage()
	_spawn_explosion_fx()
	_play_explosion_sound()

func _deal_area_damage() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player): return
	
	var dist = global_position.distance_to(player.global_position)
	if dist <= damage_radius and player.has_method("take_damage"):
		player.take_damage(damage, "Mutante Génesis (Misil)")

func _spawn_explosion_fx() -> void:
	explosion_sprite = AnimatedSprite2D.new()
	explosion_sprite.sprite_frames = explosion_frames
	explosion_sprite.scale = Vector2(2.5, 2.5)
	add_child(explosion_sprite)
	
	explosion_sprite.animation_finished.connect(_on_explosion_finished)
	explosion_sprite.play("explode")

func _play_explosion_sound() -> void:
	if explosion_audio:
		explosion_audio.play()

func _on_explosion_finished() -> void:
	var t = create_tween()
	t.tween_interval(0.3)
	t.tween_callback(queue_free)
