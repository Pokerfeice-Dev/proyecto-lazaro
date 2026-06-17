extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
func _ready() -> void:
	_spawn_or_reposition_player()
	_setup_music_loop()
	_setup_room_specific_logic()

func _setup_room_specific_logic() -> void:
	if name == "Lab_room":
		_setup_lab_upgrades_door()
	elif name == "Core_Upgrade_Room":
		_setup_core_upgrade_room()

func _setup_lab_upgrades_door() -> void:
	# Configure pre-existing Door_CoreUpgrades node if it exists
	var scene_door = get_node_or_null("Door_CoreUpgrades")
	if scene_door:
		scene_door.custom_next_scene = "res://Scenes/Rooms/Core_Upgrade_Room.tscn"
		if scene_door.is_open or GameData.has_died_once:
			scene_door.unlock_door()
		else:
			scene_door.lock_door()

	# Instantiate the dynamic door
	var door_scene = load("res://Scenes/Rooms/door_CoreUpgrades.tscn")
	if not door_scene: return
	
	var door_inst = door_scene.instantiate()
	door_inst.name = "door_coreupgrades"
	door_inst.position = Vector2(324, 9)
	door_inst.custom_next_scene = "res://Scenes/Rooms/Core_Upgrade_Room.tscn"
	add_child(door_inst)
	
	if door_inst.is_open or GameData.has_died_once:
		door_inst.unlock_door()
	else:
		door_inst.lock_door()

func _setup_core_upgrade_room() -> void:
	var npc = get_node_or_null("Npc_Chatarra")
	if npc:
		npc.set_script(load("res://Scripts/NPC/npc_chatarra.gd"))
		npc._ready()
		
	var exit_door = get_node_or_null("Door")
	if exit_door:
		exit_door.custom_next_scene = "res://Scenes/Rooms/lab_room.tscn"
		exit_door.unlock_door()

func _setup_music_loop() -> void:
	var music_node = get_node_or_null("Audio_lab")
	if not music_node:
		return
	if not music_node.stream:
		return
	music_node.stream.loop = true

func _spawn_or_reposition_player() -> void:
	var p_spawn = get_node_or_null("player_spawn")
	if not p_spawn:
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		_spawn_fresh_player(p_spawn.global_position)
	else:
		_reposition_existing_player(players[0], p_spawn.global_position)

func _spawn_fresh_player(spawn_pos: Vector2) -> void:
	if not player_scene:
		return
	var p_inst = player_scene.instantiate()
	p_inst.global_position = spawn_pos
	get_tree().current_scene.call_deferred("add_child", p_inst)
	# Ensure health is max and HUD is synced after spawning
	p_inst.ready.connect(func():
		var s = p_inst.stats
		s.current_health = s.max_health
		s.health_changed.emit(s.current_health, s.max_health)
	)

func _reposition_existing_player(player: Node, spawn_pos: Vector2) -> void:
	player.global_position = spawn_pos
	# Re-enable the player in case they were disabled after death
	if player.process_mode == Node.PROCESS_MODE_DISABLED:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.show()
	# Reset health to max and re-apply upgrades/sync HUD
	if "stats" in player:
		var s = player.stats
		s.current_health = s.max_health
		s.health_changed.emit(s.current_health, s.max_health)
	if player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()
