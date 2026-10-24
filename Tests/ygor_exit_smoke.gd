extends Node

## Regresión del encierro en tiendas: salir sin dinero, rechazar una compra,
## gastar toda la carne y abandonar una tienda agotada, con teclado y mando.
class Runner extends Node:
	const ROOMS := [
		"res://Scenes/Rooms/Level1_Room12(Ygor1).tscn",
		"res://Scenes/Rooms/Level2_Room13(Ygor1).tscn",
		"res://Scenes/Rooms/Level2_Room13(Ygor2).tscn",
	]

	func run() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		# No guardar el progreso artificial de la prueba en un slot del jugador.
		GameData.event_demo_active = true
		GameData.active_protocol = ""
		GameData.rooms_before_boss = 10
		GameData.rooms_pool.assign(["res://Scenes/Rooms/Level1_Room1.tscn"])
		GameData.rooms_pool_level2.assign(["res://Scenes/Rooms/Level2_Room1.tscn"])
		for room_path in ROOMS:
			for starting_flesh in [0, 9, 10, 85]:
				await _check_exit(room_path, starting_flesh)
		print("YGOR_EXIT_OK: 3 salas, sin carne, compra rechazada, compra exacta, tienda agotada, teclado y mando")
		get_tree().quit()

	func _check_exit(room_path: String, starting_flesh: int) -> void:
		GameData.current_level = 2 if "Level2" in room_path else 1
		GameData.current_run_room = 3
		GameData.flesh = starting_flesh
		GameData.last_room_path = room_path
		get_tree().change_scene_to_file(room_path)
		await get_tree().scene_changed
		await get_tree().create_timer(0.15).timeout
		var room = get_tree().current_scene
		var door: Door = room.get_node("Door")
		var player = get_tree().get_first_node_in_group("player")
		assert(player != null)
		assert(not room.has_node("Area_entered"), "Una tienda no debe iniciar oleadas sin puntos de aparición")
		assert(not door.is_locked, "Ygor debe permitir salir con %d carne" % starting_flesh)
		assert(door.collision_shape.disabled, "La salida abierta no debe bloquear físicamente al jugador")

		var pedestals = get_tree().get_nodes_in_group("ygor_shop_pedestal")
		if starting_flesh == 9 and not pedestals.is_empty():
			var heal = room.get_node("Hologram_Ygor_Store")
			heal._on_body_entered(player)
			heal._attempt_purchase()
			assert(not heal.purchased and GameData.flesh == 9)
			heal._on_body_exited(player)
		elif starting_flesh >= 10 and not pedestals.is_empty():
			for pedestal in pedestals:
				if starting_flesh == 10 and pedestal.shop_item_type != "Heal":
					continue
				pedestal._on_body_entered(player)
				pedestal._attempt_purchase()
				assert(pedestal.purchased, "La prueba debe completar la compra")
				pedestal._on_body_exited(player)
			assert(GameData.flesh == 0, "Las compras deben agotar la carne de la prueba")
		assert(not door.is_locked, "Comprar o no poder comprar nunca debe bloquear la salida")

		player.set_physics_process(false)
		player.global_position = door.area_2d.get_node("CollisionShape2D").global_position
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().process_frame
		await get_tree().create_timer(0.1).timeout
		assert(door.player_inside, "El área real de la puerta debe detectar al jugador")
		assert(door.interaction_label.visible, "Debe verse el aviso de salida")
		var event: InputEvent
		if starting_flesh == 9 or starting_flesh == 85:
			var pad := InputEventJoypadButton.new()
			pad.button_index = JOY_BUTTON_X
			pad.pressed = true
			event = pad
		else:
			var key := InputEventKey.new()
			key.physical_keycode = KEY_E
			key.pressed = true
			event = key
		Input.parse_input_event(event)
		await get_tree().process_frame
		event.pressed = false
		Input.parse_input_event(event)
		assert(SceneTransition.is_transitioning, "La interacción debe iniciar la salida")
		await get_tree().scene_changed
		while SceneTransition.is_transitioning:
			await get_tree().process_frame
		assert(GameData.current_run_room == 4, "Salir debe avanzar exactamente una sala")
		assert(get_tree().current_scene.scene_file_path != room_path, "Debe cargarse la próxima sala")
		assert(not get_tree().paused)
		print("YGOR_EXIT_CASE_OK: %s / %d carne" % [room_path.get_file(), starting_flesh])

func _ready() -> void:
	var runner := Runner.new()
	get_tree().root.add_child.call_deferred(runner)
	runner.run.call_deferred()
