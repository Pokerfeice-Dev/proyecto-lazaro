extends Node
class_name PrometeoIntro

## Cinemática de entrada de Prometeo (boss 3). Sigue la misma estructura que la
## del boss 2: congela al jugador, la cámara va hasta el boss, pasa algo, y la
## cámara vuelve. Acá el "algo" es que Prometeo se arma de las sombras: el humo
## se junta, aparece el cuerpo, ruge y sale el título.
## Uso: var intro = PrometeoIntro.new(); add_child(intro); await intro.play(boss, delay)

const FONT_PATH := "res://Art/Fonts/Dekatron-SemiBold.otf"
const BOSS_ZOOM := Vector2(1.35, 1.35)
const TITLE_COLOR := Color(1.0, 0.25, 0.3)
const SUBTITLE_COLOR := Color(1.0, 0.6, 0.25)

var boss: Node2D
var _player: Node
var _camera: Camera2D
var _base_zoom: Vector2 = Vector2.ONE
var _base_position: Vector2 = Vector2.ZERO
var _layer: CanvasLayer
var _title: Control

func play(p_boss: Node2D, start_delay: float, subtitle: String) -> void:
	boss = p_boss
	_hide_boss()
	# espera a que termine el fundido de entrada a la sala (y a que la sala ponga al jugador)
	await _wait(start_delay)
	if not _boss_alive():
		_finish()
		return
	_player = get_tree().get_first_node_in_group("player")
	_set_player_frozen(true)
	_capture_camera()
	_build_title(subtitle)
	_move_camera_to_boss(1.0)
	await _wait(0.8)
	_gather_shadows(1.4)
	await _wait(1.3)
	_emerge()
	await _wait(0.45)
	_roar()
	await _wait(2.2)
	_move_camera_back(1.0)
	await _wait(0.8)
	_fade_title(0.4)
	await _wait(0.4)
	_finish()

func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, false).timeout

func _boss_alive() -> bool:
	return is_instance_valid(boss) and not boss.is_dying

# --- Boss ---

func _hide_boss() -> void:
	if boss.sprite:
		boss.sprite.modulate.a = 0.0
	if boss.arsenal:
		boss.arsenal.visible = false
	_set_aura(false)

func _set_aura(on: bool) -> void:
	var aura = boss.get_node_or_null("ShadowAura") as CPUParticles2D
	if aura:
		aura.emitting = on

# El humo se junta en un remolino donde va a aparecer el cuerpo.
func _gather_shadows(duration: float) -> void:
	var p = CPUParticles2D.new()
	p.amount = 60
	p.lifetime = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 70.0
	p.emission_ring_inner_radius = 55.0
	p.gravity = Vector2.ZERO
	p.radial_accel_min = -160.0
	p.radial_accel_max = -120.0
	p.tangential_accel_min = 60.0
	p.tangential_accel_max = 90.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 8.0
	var g = Gradient.new()
	g.set_color(0, Color(0.1, 0.02, 0.12, 0.0))
	g.set_color(1, Color(0.05, 0.0, 0.05, 0.9))
	g.add_point(0.4, Color(0.35, 0.08, 0.3, 0.8))
	p.color_ramp = g
	p.position = Vector2(0, -10)
	boss.add_child(p)
	p.emitting = true
	boss.play_sfx("teleport")
	var t = create_tween()
	t.tween_interval(duration)
	t.tween_callback(func(): p.emitting = false)
	t.tween_interval(p.lifetime)
	t.tween_callback(p.queue_free)

# El cuerpo sale de la sombra: de negro puro a su color, estirándose hacia arriba.
func _emerge() -> void:
	if not boss.sprite: return
	var spr = boss.sprite
	var base_scale = spr.scale
	var base_modulate = boss.sprite_base_modulate()
	spr.modulate = Color(0, 0, 0, 0)
	spr.scale = base_scale * Vector2(0.5, 1.5)
	var t = create_tween().set_parallel(true)
	t.tween_property(spr, "modulate", base_modulate, 0.45).set_trans(Tween.TRANS_SINE)
	t.tween_property(spr, "scale", base_scale, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_set_aura(true)

func _roar() -> void:
	if boss.arsenal:
		boss.arsenal.visible = true
		boss.arsenal.equip(boss.arsenal.current_id, true)
	boss.play_sfx("roar")
	boss.shake(18.0, 1.4)
	boss.flash(Color(2.2, 0.3, 0.5))
	_burst_embers()
	_show_title()

func _burst_embers() -> void:
	var p = CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 50
	p.lifetime = 1.2
	p.spread = 180.0
	p.gravity = Vector2(0, -50)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 180.0
	p.damping_min = 60.0
	p.damping_max = 120.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var g = Gradient.new()
	g.set_color(0, Color(1.0, 0.75, 0.3, 1.0))
	g.set_color(1, Color(0.8, 0.05, 0.1, 0.0))
	p.color_ramp = g
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.position = Vector2(0, -10)
	boss.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)

# --- Cámara y jugador (igual que el boss 2) ---

# Guarda el zoom de la pelea para dejar la cámara igual que estaba al terminar.
func _capture_camera() -> void:
	_camera = get_viewport().get_camera_2d()
	if not _camera: return
	_base_zoom = _camera.zoom
	_base_position = _camera.position

func _move_camera_to_boss(duration: float) -> void:
	if not _camera or not _camera.get_parent(): return
	var offset = boss.global_position - _camera.get_parent().global_position
	var t = create_tween().set_parallel(true)
	t.tween_property(_camera, "zoom", BOSS_ZOOM, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(_camera, "position", offset, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _move_camera_back(duration: float) -> void:
	if not is_instance_valid(_camera): return
	var t = create_tween().set_parallel(true)
	t.tween_property(_camera, "zoom", _base_zoom, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_camera, "position", _base_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _set_player_frozen(frozen: bool) -> void:
	if not _player or not is_instance_valid(_player): return
	var method = "freeze_player" if frozen else "unfreeze_player"
	if _player.has_method(method):
		_player.call(method)

# --- Título ---

func _build_title(subtitle: String) -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 10
	get_tree().current_scene.add_child(_layer)
	var box = VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_END
	box.offset_bottom = -150.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.modulate.a = 0.0
	_layer.add_child(box)
	var font_res = load(FONT_PATH) as Font
	box.add_child(_make_label(boss.boss_display_name.to_upper(), 46, TITLE_COLOR, 12, font_res))
	if subtitle != "":
		box.add_child(_make_label(subtitle, 20, SUBTITLE_COLOR, 8, font_res))
	_title = box

func _make_label(text: String, size: int, color: Color, outline: int, font_res: Font) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_res:
		label.add_theme_font_override("font", font_res)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", outline)
	return label

func _show_title() -> void:
	if not _title: return
	create_tween().tween_property(_title, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)

func _fade_title(duration: float) -> void:
	if not _title or not is_instance_valid(_title): return
	create_tween().tween_property(_title, "modulate:a", 0.0, duration)

# --- Cierre ---

func _finish() -> void:
	if _layer and is_instance_valid(_layer):
		_layer.queue_free()
	if is_instance_valid(_camera):
		_camera.zoom = _base_zoom
		_camera.position = _base_position
	_set_player_frozen(false)
	if is_instance_valid(boss) and boss.arsenal:
		boss.arsenal.visible = true
	queue_free()
