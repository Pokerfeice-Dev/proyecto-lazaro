extends Node2D

var elapsed := 0.0
var strength := 1.0

func _ready() -> void:
	z_index = 80
	var sparks := CPUParticles2D.new()
	sparks.amount = 64
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.lifetime = 1.3
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 180)
	sparks.initial_velocity_min = 70.0 * strength
	sparks.initial_velocity_max = 260.0 * strength
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 6.0 * strength
	var gradient := Gradient.new()
	gradient.set_color(0, Color("fff4bd"))
	gradient.add_point(0.25, Color("ff923d"))
	gradient.set_color(1, Color(0.25, 0.08, 0.05, 0))
	sparks.color_ramp = gradient
	add_child(sparks)
	sparks.emitting = true
	var sound := AudioStreamPlayer2D.new()
	sound.stream = preload("res://Audio/Enemy_snd/Boss1/Explosion.mp3")
	sound.bus = "SFX"
	sound.volume_db = -3.0 if strength > 1.0 else -12.0
	sound.pitch_scale = 0.75 if strength > 1.0 else randf_range(1.1, 1.4)
	add_child(sound)
	sound.play()
	get_tree().create_timer(4.0, false).timeout.connect(queue_free)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var fade := maxf(0.0, 1.0 - elapsed / 0.7)
	if fade <= 0.0: return
	draw_circle(Vector2.ZERO, (12.0 + elapsed * 70.0) * strength, Color(1.0, 0.65, 0.25, fade * fade * 0.75))
	draw_arc(Vector2.ZERO, (8.0 + elapsed * 190.0) * strength, 0, TAU, 64, Color(1.0, 0.85, 0.5, fade), 4.0 * fade, true)
