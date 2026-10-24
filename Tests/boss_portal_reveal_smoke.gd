extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameData.current_level = 1
	GameData.boss_fight_phase = 2
	var room = preload("res://Scenes/Rooms/Level1_Room16-BossFight.tscn").instantiate()
	get_tree().root.add_child(room)
	get_tree().current_scene = room
	var portal = room.get_node("CosmicPortal")
	var boss = room.get_node("Boss")
	await get_tree().process_frame
	assert(not portal.visible)
	assert(not portal._ready_to_enter)
	assert(not portal.monitoring)
	assert(not portal._has_player())
	var interact := InputEventKey.new()
	interact.physical_keycode = KEY_E
	interact.pressed = true
	portal._unhandled_input(interact)
	portal._enter()
	assert(not portal._used)
	assert(GameData.current_level == 1)
	await get_tree().create_timer(6.5).timeout
	var original_camera = get_viewport().get_camera_2d()
	boss.die()
	await get_tree().create_timer(1.5).timeout
	assert(not is_instance_valid(boss) or not boss.visible, "El cuerpo debe desaparecer al explotar")
	assert(not portal.visible, "El portal espera al final de la explosión")
	await get_tree().create_timer(1.0).timeout
	assert(portal.visible)
	assert(portal.destination_scene.contains("Level2_"))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tmp/portal_reveal_review.png")
	await get_tree().create_timer(1.2).timeout
	assert(portal._ready_to_enter)
	assert(get_viewport().get_camera_2d() == original_camera)
	assert(GameData.current_level == 1, "Revelar el portal no avanza de nivel")
	assert(portal.advance_after_boss)
	if DisplayServer.get_name() != "headless":
		portal._enter()
		print("PORTAL_ENTER_REQUESTED")
		await get_tree().create_timer(3.5).timeout
		print("PORTAL_DESTINATION: ", get_tree().current_scene.scene_file_path)
		assert(not SceneTransition.is_transitioning)
		assert(not get_tree().paused)
		assert(GameData.current_level == 2)
		assert(get_tree().current_scene.scene_file_path.contains("Level2_"))
	else:
		var destination := GameData.get_post_boss_scene()
		assert(GameData.current_level == 2)
		assert(destination.contains("Level2_"))
	print("BOSS_PORTAL_REVEAL_OK: oculto, muerte, aparición, cámara y Cripta")
	if is_instance_valid(room): room.queue_free()
	await get_tree().process_frame
	get_tree().quit()
