extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
func _ready() -> void:
	_spawn_or_reposition_player()
	_setup_music_loop()

func _setup_music_loop() -> void:
	var music_node = get_node_or_null("Ygor_music")
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

func _reposition_existing_player(player: Node, spawn_pos: Vector2) -> void:
	player.global_position = spawn_pos
	# Re-enable the player in case they were disabled after death
	if player.process_mode == Node.PROCESS_MODE_DISABLED:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.show()
	if player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()
