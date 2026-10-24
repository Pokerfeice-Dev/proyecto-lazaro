extends Node
class Runner extends Node:
	func run() -> void:
		get_tree().change_scene_to_file("res://Scenes/Rooms/lab_room.tscn")
		await get_tree().scene_changed
		for frame in 300:
			if not get_tree().get_nodes_in_group("player_arrival_fx").is_empty(): break
			await get_tree().process_frame
		await get_tree().create_timer(0.10).timeout
		var effects = get_tree().get_nodes_in_group("player_arrival_fx")
		assert(effects.size() == 1)
		var player = get_tree().get_first_node_in_group("player")
		assert(player.is_physics_processing())
		var origin: Vector2 = effects[0].global_position
		player.global_position += Vector2(12, 0)
		assert(effects[0].global_position == origin)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tmp/arrival_check.png")
		await get_tree().create_timer(0.4).timeout
		assert(get_tree().get_nodes_in_group("player_arrival_fx").is_empty())
		player._queue_arrival_fx()
		await get_tree().process_frame
		await get_tree().process_frame
		assert(get_tree().get_nodes_in_group("player_arrival_fx").is_empty())
		await get_tree().create_timer(1.0).timeout
		var preview = preload("res://Scripts/Effects/player_arrival_fx.gd").spawn(player)
		preview.set_process(false)
		assert(not player.visible, "El cuerpo completo no debe verse antes de los píxeles")
		preview._process(0.05)
		assert(not player.visible, "Los fragmentos aparecen primero")
		assert(player.is_physics_processing())
		preview._process(0.07)
		assert(not player.visible, "La reconstrucción todavía no terminó")
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tmp/arrival_detail.png")
		preview._process(0.25)
		assert(player.visible, "El jugador aparece al terminar de reconstruirse")
		await get_tree().process_frame
		for style in [1, 2]:
			player.arrival_pixel_style = style
			var variant = preload("res://Scripts/Effects/player_arrival_fx.gd").spawn(player)
			variant.set_process(false)
			assert(not player.visible)
			player.global_position += Vector2(10, 0)
			variant._process(0.18)
			assert(variant.global_position == player.anim_sprite.global_position)
			variant._process(0.20)
			assert(player.visible)
			await get_tree().process_frame
		print("ARRIVAL_FX_OK")
		get_tree().quit()
func _ready() -> void:
	var runner := Runner.new()
	get_tree().root.add_child.call_deferred(runner)
	runner.run.call_deferred()
