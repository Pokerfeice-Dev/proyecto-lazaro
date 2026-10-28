extends Node2D

func _ready() -> void:
	GameData.has_completed_tutorial = false
	var room = load("res://Scenes/Rooms/tutorial_room.tscn").instantiate()
	add_child(room)
	await get_tree().create_timer(0.5).timeout
	room._transition_to_state(room.TutorialState.DASH)
	Input.action_press("dash")
	room._check_dash_transition()
	Input.action_release("dash")
	assert(room.current_state == room.TutorialState.AIM)
	assert(not is_instance_valid(room.shooter_inst))
	room._transition_to_state(room.TutorialState.MANNEQUIN)
	for i in range(3): room._on_mannequin_hit()
	assert(room.current_state == room.TutorialState.DODGE)
	var carpenter = room.shooter_inst
	await get_tree().create_timer(4.8, true, false, true).timeout
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.15, true, false, true).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://tutorial_dodge_preview.png")
	var cine = room._dodge_cinematic
	assert(cine.shooter == carpenter)
	assert(cine.stage == 2, "Must wait for Shift")
	var player = GameData.get_player()
	assert(player.is_cutscene_frozen)
	var pos = player.global_position
	Input.action_press("move_right")
	Input.action_press("shoot")
	await get_tree().create_timer(0.4, true, false, true).timeout
	assert(player.global_position == pos)
	Input.action_release("move_right")
	Input.action_release("shoot")
	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().create_timer(1.0, true, false, true).timeout
	key.pressed = false
	Input.parse_input_event(key)
	assert(room.current_state == room.TutorialState.COMBAT)
	assert(room.shooter_inst == carpenter and carpenter.is_inside_tree())
	assert(carpenter.process_mode != Node.PROCESS_MODE_DISABLED)
	assert(is_equal_approx(Engine.time_scale, 1.0))
	assert(not player.is_cutscene_frozen)
	assert(player.global_position.y > pos.y + 25.0, "Dodge route must be clear")
	room._transition_to_state(room.TutorialState.COMBAT)
	await get_tree().process_frame
	assert(is_instance_valid(room.shooter_inst))
	room._dodge_cinematic = null
	room._transition_to_state(room.TutorialState.DODGE)
	await get_tree().process_frame
	await get_tree().process_frame
	room.current_state = room.TutorialState.AIM
	room._dodge_cinematic.queue_free()
	await get_tree().process_frame
	assert(is_equal_approx(Engine.time_scale, 1.0))
	assert(not player.is_cutscene_frozen)
	print("TUTORIAL_DODGE_SMOKE_OK")
	room.queue_free()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
