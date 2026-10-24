class_name DistortionShockwave
extends Sprite2D

var max_radius: float = 80.0
var duration: float = 0.28
var max_strength: float = 0.045
var _elapsed: float = 0.0

static func spawn(parent: Node, pos: Vector2, radius: float = 80.0, shock_duration: float = 0.28, strength: float = 0.045) -> void:
	if not is_instance_valid(parent): return
	var wave := DistortionShockwave.new()
	wave.max_radius = radius
	wave.duration = shock_duration
	wave.max_strength = strength
	wave.global_position = pos
	parent.add_child(wave)

func _ready() -> void:
	z_index = 52
	z_as_relative = false
	centered = true
	
	# Usar un GradientTexture2D radial blanco como base limpia
	var grad := Gradient.new()
	grad.set_color(0, Color.WHITE)
	grad.set_color(1, Color.TRANSPARENT)
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	grad_tex.width = 64
	grad_tex.height = 64
	texture = grad_tex
	
	var shader = load("res://Art/Effects/shockwave_distortion.gdshader")
	if shader:
		var sm := ShaderMaterial.new()
		sm.shader = shader
		sm.set_shader_parameter("strength", max_strength)
		sm.set_shader_parameter("chromatic_aberration", 0.02)
		material = sm
	
	scale = Vector2.ZERO

func _process(delta: float) -> void:
	_elapsed += delta
	var t := _elapsed / maxf(duration, 0.001)
	if t >= 1.0:
		queue_free()
		return
	
	# Expansión rápida inicial y desvanecimiento
	var current_radius := lerpf(10.0, max_radius, ease(t, 0.4))
	var target_scale := (current_radius * 2.0) / 64.0
	scale = Vector2(target_scale, target_scale)
	
	var alpha := (1.0 - t) * (1.0 - t)
	modulate.a = alpha
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("strength", max_strength * alpha)
