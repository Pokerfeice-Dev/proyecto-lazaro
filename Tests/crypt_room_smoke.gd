extends Node2D

func _ready() -> void:
	GameData.current_level = 2
	GameData.debug_god_mode = true
	call_deferred("verify")

func verify() -> void:
	var room = load("res://Scenes/Rooms/Level2_Room1.tscn").instantiate()
	room.reveal_tiles_on_load = false
	room.reveal_props_on_load = false
	add_child(room)
	for frame in 5: await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	assert(player != null, "player exists")
	assert(room.enemy_pool.size() == 7, "crypt pool active in real room")
	var index = 0
	for scene in room.enemy_pool:
		var enemy = scene.instantiate()
		room.add_child(enemy)
		enemy.global_position = player.global_position + Vector2(180, 0).rotated(index * TAU / 7.0)
		enemy.alert_to_player()
		index += 1
	await get_tree().create_timer(3.0).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("lazaro-crypt-enemies.png"))
	await get_tree().create_timer(2.0).timeout
	print("CRYPT_ROOM_PASS")
	get_tree().quit()
