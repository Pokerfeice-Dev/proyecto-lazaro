extends Node2D

## Sala libre de práctica. Conserva las estaciones, el maniquí y el sandbox,
## pero no ejecuta pasos guiados ni bloquea al jugador con objetivos.

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")

func _ready() -> void:
	GameData.begin_sandbox()
	_spawn_or_reposition_player()

func _exit_tree() -> void:
	GameData.end_sandbox()

func _spawn_or_reposition_player() -> void:
	var spawn = get_node_or_null("player_spawn") as Node2D
	if not spawn:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = spawn.global_position
		if player.process_mode == Node.PROCESS_MODE_DISABLED:
			player.process_mode = Node.PROCESS_MODE_INHERIT
			player.show()
		_restore_player_health(player)
		return
	if not player_scene:
		return
	var instance = player_scene.instantiate()
	instance.global_position = spawn.global_position
	instance.ready.connect(_restore_player_health.bind(instance), CONNECT_ONE_SHOT)
	get_tree().current_scene.call_deferred("add_child", instance)

func _restore_player_health(player: Node) -> void:
	if not is_instance_valid(player) or not "stats" in player:
		return
	var stats = player.stats
	stats.current_health = stats.max_health
	stats.min_health_floor = 0
	stats.health_changed.emit(stats.current_health, stats.max_health)
	if player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()
