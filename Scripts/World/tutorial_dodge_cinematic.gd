extends Node2D
## Un disparo dirigido: el tiempo de lectura nunca consume la ventana de evasión.
signal completed

var player: Node2D
var shooter: Node2D
var camera: Camera2D
var previous_camera: Camera2D
var overlay: CanvasLayer
var prompt: Label
var bullet: Sprite2D
var elapsed := 0.0
var stage := 0
var released := false
var restored := false
var hidden_layers: Array[CanvasLayer] = []
var previous_scale := 1.0
var previous_mode := Node.PROCESS_MODE_INHERIT
var body_disable_mode := 0
var sprite_mode := Node.PROCESS_MODE_INHERIT
var shooter_mode := Node.PROCESS_MODE_INHERIT
var shooter_sprite_mode := Node.PROCESS_MODE_INHERIT
var shooter_position := Vector2.ZERO
var previous_position := Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_scale = Engine.time_scale
	previous_mode = player.process_mode
	body_disable_mode = player.disable_mode
	player.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	previous_position = player.global_position
	previous_camera = get_viewport().get_camera_2d()
	sprite_mode = player.anim_sprite.process_mode
	player.anim_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	player.freeze_player()
	player.process_mode = Node.PROCESS_MODE_DISABLED
	# El corredor inferior de esta sala está libre de jardineras y estaciones.
	player.global_position = Vector2(-210, -40)
	player.last_dir = "right"
	player.anim_sprite.play("idle_right")
	player.update_glock()
	shooter_mode = shooter.process_mode
	shooter_sprite_mode = shooter.anim_sprite.process_mode
	shooter_position = shooter.global_position
	shooter.velocity = Vector2.ZERO
	shooter.process_mode = Node.PROCESS_MODE_DISABLED
	shooter.global_position = Vector2(-30, -40)
	shooter.get_node("Summon_anim").hide()
	shooter.anim_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	shooter.anim_sprite.play("idle")
	shooter.anim_sprite.flip_h = true
	camera = Camera2D.new()
	add_child(camera)
	camera.global_position = Vector2(-120, -40)
	camera.zoom = Vector2.ONE * minf(3.2, get_viewport_rect().size.x / 290.0)
	camera.make_current()
	_hide_hud(get_tree().root)
	_build_overlay()
	var push_in := create_tween().set_ignore_time_scale(true)
	push_in.tween_property(camera, "zoom", camera.zoom * 1.08, 1.8).set_trans(Tween.TRANS_SINE)
	Engine.time_scale = 0.12

func _hide_hud(node: Node) -> void:
	if node is CanvasLayer and node.visible:
		hidden_layers.append(node)
		node.hide()
	for child in node.get_children():
		_hide_hud(child)

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 110
	add_child(overlay)
	for bottom in [false, true]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(bar)
		bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
		bar.offset_top = -65 if bottom else 0
		bar.offset_bottom = 0 if bottom else 65
	prompt = Label.new()
	overlay.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -62
	prompt.offset_bottom = -8
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.text = "OBSERVA EL DISPARO"

func _input(event: InputEvent) -> void:
	if restored: return
	if stage == 2 and released and not event.is_echo():
		var keyboard: bool = event is InputEventKey and event.pressed and event.keycode == KEY_SHIFT
		var gamepad: bool = event is InputEventJoypadButton and event.is_action_pressed("dash")
		if keyboard or gamepad:
			stage = 3
			elapsed = 0.0
			player.velocity = Vector2.DOWN
			player._start_dash()
			player.dash_dir = Vector2.DOWN
			prompt.text = "¡EVASIÓN PERFECTA!"
			prompt.modulate = Color(0.3, 1.0, 0.8)
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if restored: return
	if not is_instance_valid(player):
		restore()
		queue_free()
		return
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	elapsed += real_delta
	if not Input.is_action_pressed("dash") and not Input.is_key_pressed(KEY_SHIFT):
		released = true
	match stage:
		0:
			if elapsed >= 0.65:
				shooter.anim_sprite.play("attack_side")
				shooter._play_attack_sound()
				bullet = Sprite2D.new()
				bullet.texture = preload("res://Art/Weapons/Distance/Pistol/enemyprojectile16x6.png")
				bullet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				bullet.rotation = PI
				add_child(bullet)
				bullet.global_position = shooter.global_position + Vector2(-18, 0)
				stage = 1
				elapsed = 0.0
		1:
			bullet.position.x -= 500.0 * delta
			if bullet.global_position.x <= player.global_position.x + 55.0:
				stage = 2
				elapsed = 0.0
		2:
			prompt.text = "PULSA EL BOTÓN DE EVASIÓN" if InputMode.is_gamepad() else "PULSA SHIFT PARA EVADIR"
			prompt.modulate = Color(1.0, 0.85 + sin(elapsed * 5.0) * 0.15, 0.4)
		3:
			# Movimiento dirigido con colisión real; no admite disparos ni movimiento libre.
			if elapsed < 0.3:
				player.move_and_collide(Vector2.DOWN * 150.0 * real_delta)
				player._process_dash_ghosts(real_delta)
			bullet.position.x -= 420.0 * real_delta
			if elapsed >= 0.8:
				restore(false)
				completed.emit()
				queue_free()

func restore(cancelled := true) -> void:
	if restored: return
	restored = true
	Engine.time_scale = previous_scale
	for layer in hidden_layers:
		if is_instance_valid(layer): layer.show()
	hidden_layers.clear()
	if is_instance_valid(shooter):
		shooter.anim_sprite.process_mode = shooter_sprite_mode
		shooter.process_mode = shooter_mode
		if cancelled: shooter.global_position = shooter_position
	if is_instance_valid(player):
		if player.is_dashing:
			player.dash_timer.stop()
			player._on_dash_timer_timeout()
		player.dash_cd_timer.stop()
		if cancelled: player.global_position = previous_position
		player.anim_sprite.process_mode = sprite_mode
		player.unfreeze_player()
		player.process_mode = previous_mode
		player.disable_mode = body_disable_mode
	if is_instance_valid(previous_camera) and previous_camera.is_inside_tree() and previous_camera.enabled:
		previous_camera.make_current()
	if is_instance_valid(overlay): overlay.hide()

func _exit_tree() -> void:
	restore()
