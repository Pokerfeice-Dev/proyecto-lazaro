extends Node

class PortalBoss extends Boss3Prometeo:
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

class Runner extends Node:
	func run() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().change_scene_to_file("res://Scenes/Rooms/lab_room.tscn")
		await get_tree().scene_changed
		await get_tree().create_timer(0.5).timeout
		var door = get_tree().get_first_node_in_group("door")
		assert(door != null)
		var boss := PortalBoss.new()
		get_tree().current_scene.add_child(boss)
		var player = get_tree().get_first_node_in_group("player")
		assert(player != null)
		boss.global_position = player.global_position
		boss._spawn_victory_portal("res://Scenes/Rooms/training_room.tscn")
		boss._spawn_victory_portal("res://Scenes/Rooms/training_room.tscn")
		assert(get_tree().get_nodes_in_group("exit_portal").size() == 1)
		var portal = get_tree().get_first_node_in_group("exit_portal")
		boss.queue_free()
		await get_tree().create_timer(0.8).timeout
		assert(is_instance_valid(portal))
		assert(portal._has_player())
		var transition = get_tree().root.get_node("SceneTransition")
		portal._enter()
		await get_tree().create_timer(0.6).timeout
		assert(transition.is_transitioning)
		assert(get_tree().paused)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tmp/portal_wave_check.png")
		await get_tree().create_timer(1.5).timeout
		assert(not transition.is_transitioning)
		assert(not get_tree().paused)
		assert(get_tree().current_scene.scene_file_path.ends_with("training_room.tscn"))
		print("BOSS_PORTAL_AND_TRANSITION_OK")
		get_tree().quit()

func _ready() -> void:
	var runner := Runner.new()
	get_tree().root.add_child.call_deferred(runner)
	runner.run.call_deferred()
