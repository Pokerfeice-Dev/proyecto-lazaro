@tool
extends Area2D
## Instanciar después de la muerte del jefe. El destino se configura antes
## de add_child(), o desde el Inspector de una instancia colocada en la sala.
@export_file("*.tscn") var destination_scene := "res://Scenes/Rooms/lab_room.tscn"
@export var enter_on_touch := false
@export var portal_color := Color("52d8ed")
@export var defeated_boss: NodePath
@export var advance_after_boss := false

var _time := 0.0
var _used := false
var _ready_to_enter := false
var _preview: Node2D
var _revealed := false
var _reveal_age := 0.0
var _focus_camera: Camera2D
var _previous_camera: Camera2D

func _ready() -> void:
	if Engine.is_editor_hint(): return
	add_to_group("exit_portal")
	hide()
	set_deferred("monitoring", false)
	body_entered.connect(_on_body_entered)
	if not defeated_boss.is_empty():
		var boss := get_node_or_null(defeated_boss)
		if boss and boss.has_signal("enemy_died"):
			boss.enemy_died.connect(_on_boss_defeated, CONNECT_ONE_SHOT)
		return
	reveal.call_deferred()

func _on_boss_defeated(_boss: Node) -> void:
	await get_tree().create_timer(0.85, false).timeout
	reveal()
	_point_camera_to_portal()

func reveal() -> void:
	if _revealed: return
	if not ResourceLoader.exists(destination_scene):
		push_error("Portal: escena de destino inválida: " + destination_scene)
		return
	_revealed = true
	_reveal_age = 0.0
	var glow := CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = glow
	show()
	set_deferred("monitoring", true)
	_preview = preload("res://Scripts/Effects/door_destination_preview.gd").new()
	_preview.destination = destination_scene
	add_child(_preview)
	move_child(_preview, 0)
	_create_sparks()
	modulate.a = 0.0
	var appearance := create_tween()
	appearance.tween_property(self, "modulate:a", 1.0, 0.6)
	appearance.tween_callback(func(): _ready_to_enter = true)

func _create_sparks() -> void:
	for burst in [false, true]:
		var sparks := CPUParticles2D.new()
		sparks.use_parent_material = true
		sparks.position = Vector2(0, -25)
		sparks.amount = 90 if burst else 64
		sparks.lifetime = 0.85 if burst else 1.7
		sparks.one_shot = burst
		sparks.explosiveness = 1.0 if burst else 0.0
		sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
		sparks.emission_sphere_radius = 40.0
		sparks.spread = 180.0
		sparks.gravity = Vector2(0, -28)
		sparks.initial_velocity_min = 60.0 if burst else 8.0
		sparks.initial_velocity_max = 150.0 if burst else 30.0
		sparks.scale_amount_min = 1.0
		sparks.scale_amount_max = 3.0
		var ramp := Gradient.new()
		ramp.set_color(0, Color("e4ffff"))
		ramp.add_point(0.3, portal_color)
		ramp.set_color(1, Color(0.4, 0.2, 1.0, 0.0))
		sparks.color_ramp = ramp
		add_child(sparks)
		sparks.emitting = true

func _point_camera_to_portal() -> void:
	_previous_camera = get_viewport().get_camera_2d()
	if not _previous_camera: return
	_focus_camera = Camera2D.new()
	_focus_camera.top_level = true
	_focus_camera.zoom = _previous_camera.zoom
	add_child(_focus_camera)
	var start := _previous_camera.get_screen_center_position()
	_focus_camera.global_position = start
	_focus_camera.make_current()
	var target := start + (global_position + Vector2(0, -25) - start).limit_length(220.0)
	var pan := create_tween()
	pan.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.tween_property(_focus_camera, "global_position", target, 0.4)
	pan.tween_interval(0.25)
	pan.tween_method(func(weight: float):
		if is_instance_valid(_previous_camera):
			_focus_camera.global_position = target.lerp(_previous_camera.get_target_position(), weight)
	, 0.0, 1.0, 0.45)
	pan.tween_callback(_restore_camera)

func _restore_camera() -> void:
	if is_instance_valid(_previous_camera): _previous_camera.make_current()
	if is_instance_valid(_focus_camera): _focus_camera.queue_free()

func _exit_tree() -> void:
	if is_instance_valid(_focus_camera) and is_instance_valid(_previous_camera):
		_previous_camera.make_current()

func _process(delta: float) -> void:
	if not Engine.is_editor_hint() and not _revealed: return
	_time += delta
	_reveal_age += delta
	queue_redraw()
	if Engine.is_editor_hint(): return
	var nearby := _has_player()
	$Prompt.visible = nearby and _ready_to_enter and not _used
	$Prompt.text = "[X] Entrar" if InputMode.is_gamepad() else "[E] Entrar"
	if enter_on_touch and nearby and _ready_to_enter: _enter()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if not _ready_to_enter or _used or SceneTransition.is_transitioning: return
	if InputMode.is_interact(event) and _has_player():
		_enter()
		get_viewport().set_input_as_handled()

func _has_player() -> bool:
	if not monitoring: return false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"): return true
	return false

func _on_body_entered(body: Node2D) -> void:
	if enter_on_touch and body.is_in_group("player"): _enter()

func _enter() -> void:
	if _used or not _ready_to_enter or SceneTransition.is_transitioning: return
	if not ResourceLoader.exists(destination_scene): return
	_used = true
	if advance_after_boss:
		destination_scene = GameData.get_post_boss_scene()
	GameData.last_room_name = get_tree().current_scene.name
	SceneTransition.play_teleport_sound()
	SceneTransition.change_scene_through_portal(destination_scene, get_global_transform_with_canvas() * Vector2(0, -25))

func _draw() -> void:
	draw_set_transform(Vector2(0, -25), 0, Vector2(0.78, 1.0))
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 43, Color("10182e"))
	for i in 3:
		var radius := 44.0 + float(i) * 3.0 + sin(_time * 2.5) * 1.5
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(portal_color, 0.65 / float(i + 1)), 2.0, true)
	for i in 64:
		var phase := fmod(_time * (0.22 + float(i % 5) * 0.035) + float(i) / 64.0, 1.0)
		var orbit := float(i) * 2.39996 + _time * 0.9 + phase * 2.0
		var mote := (Vector2.from_angle(orbit) * lerpf(78.0, 32.0, phase)).round()
		var tint := portal_color.lerp(Color("b28aff"), float(i % 3) / 2.0)
		draw_rect(Rect2(mote, Vector2.ONE * (2 if i % 4 else 3)), Color(tint, sin(phase * PI) * 0.85))
	for i in 4:
		var angle := _time * (0.8 if i % 2 else -0.65) + float(i) * PI * 0.5
		draw_arc(Vector2.ZERO, 42.0 + float(i) * 3.0, angle, angle + 0.9, 18, Color("c0faff"), 2.0, false)
	if _reveal_age < 0.65 and not Engine.is_editor_hint():
		draw_arc(Vector2.ZERO, 45.0 + _reveal_age * 110.0, 0, TAU, 48, Color(portal_color, 1.0 - _reveal_age / 0.65), 3.0, false)
	for i in 12:
		var angle := _time * 0.6 + float(i) * TAU / 12.0
		var point := Vector2.from_angle(angle) * (46.0 + sin(_time * 3.0 + float(i)) * 3.0)
		draw_rect(Rect2(point - Vector2.ONE, Vector2(2, 2)), Color(portal_color, 0.8))
	draw_set_transform(Vector2.ZERO)
