extends RefCounted
class_name ButtonFX

# FX reutilizables para botones de menu (los mismos que el menu principal):
# hover que crece, se inclina y titila el borde electrico con chispas; click con destello.
# Uso: ButtonFX.attach(mi_boton)   (index desfasa el brillo para que baje en cascada)

const SHADER = preload("res://Art/Menu/Animado/menu_boton.gdshader")

static func attach(btn: BaseButton, index: int = 0, hover_scale: float = 1.05) -> void:
	if btn.has_meta("button_fx"): return
	btn.set_meta("button_fx", true)
	var mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("hover", 0.0)
	mat.set_shader_parameter("flash", 0.0)
	mat.set_shader_parameter("desfase_brillo", -0.08 * index)
	btn.material = mat
	btn.add_child(_create_sparks())
	btn.resized.connect(ButtonFX._sync_size.bind(btn))
	btn.mouse_entered.connect(ButtonFX._on_hover.bind(btn, true, hover_scale))
	btn.mouse_exited.connect(ButtonFX._on_hover.bind(btn, false, hover_scale))
	btn.button_down.connect(ButtonFX._on_down.bind(btn))
	btn.button_up.connect(ButtonFX._on_up.bind(btn, hover_scale))
	_sync_size(btn)

static func _sync_size(btn: BaseButton) -> void:
	btn.pivot_offset = btn.size / 2.0
	var mat = btn.material as ShaderMaterial
	if mat: mat.set_shader_parameter("tam_px", btn.size)
	var p = btn.get_node_or_null("Chispas") as CPUParticles2D
	if p:
		p.position = btn.size / 2.0
		p.emission_rect_extents = btn.size / 2.0

static func _create_sparks() -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.name = "Chispas"
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.45
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 120)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 150.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	var grad = Gradient.new()
	grad.set_color(0, Color(0.7, 1.0, 0.95, 1.0))
	grad.set_color(1, Color(0.3, 0.9, 1.0, 0.0))
	p.color_ramp = grad
	return p

static func _on_hover(btn: BaseButton, entered: bool, hover_scale: float) -> void:
	if btn.disabled: return
	var t = btn.create_tween().set_parallel(true)
	t.tween_property(btn, "scale", Vector2.ONE * (hover_scale if entered else 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(btn, "rotation_degrees", randf_range(-1.0, 1.0) if entered else 0.0, 0.18)
	var mat = btn.material as ShaderMaterial
	if mat:
		var desde = mat.get_shader_parameter("hover")
		if desde == null: desde = 0.0
		t.tween_method(ButtonFX._set_param.bind(mat, "hover"), desde, 1.0 if entered else 0.0, 0.2)
	if entered:
		_burst(btn, 14)

static func _on_down(btn: BaseButton) -> void:
	if btn.disabled: return
	var t = btn.create_tween().set_parallel(true)
	t.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)
	var mat = btn.material as ShaderMaterial
	if mat:
		t.tween_method(ButtonFX._set_param.bind(mat, "flash"), 1.0, 0.0, 0.35)
	_burst(btn, 34)

static func _on_up(btn: BaseButton, hover_scale: float) -> void:
	if btn.disabled: return
	btn.create_tween().tween_property(btn, "scale", Vector2.ONE * hover_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func _burst(btn: BaseButton, amount: int) -> void:
	var p = btn.get_node_or_null("Chispas") as CPUParticles2D
	if not p: return
	p.amount = amount
	p.restart()
	p.emitting = true

static func _set_param(value: float, mat: ShaderMaterial, param: String) -> void:
	mat.set_shader_parameter(param, value)
