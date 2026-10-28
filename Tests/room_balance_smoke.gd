extends Node2D
class Room extends CombatRoom:
	func _ready() -> void: pass
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameData.event_demo_active = true
	var room := Room.new()
	add_child(room)
	for level in range(1, 4):
		GameData.current_level = level
		var previous := 0
		for depth in range(1, 13):
			GameData.current_run_room = depth
			var config := GameData.get_room_config()
			check(config.total_enemies >= previous and config.total_enemies <= 30, "Invalid total progression")
			check(config.max_concurrent <= 7 and config.max_concurrent <= config.total_enemies, "Invalid cap")
			check(config.spawn_interval >= 0.9, "Spawn interval too short")
			previous = config.total_enemies
			room._apply_difficulty_settings()
			check(not room.enemy_pool.is_empty(), "Empty pool")
			for scene in room.enemy_pool:
				check(config.allowed_enemies.has(room._enemy_id(scene.resource_path)), "Wrong enemy mapping")
	GameData.current_level = 1
	GameData.current_run_room = 10
	room._apply_difficulty_settings()
	var summoner = load("res://Scenes/Enemies/EnemySummoner.tscn").instantiate()
	room._scheduled_enemies.append(weakref(summoner))
	for scene in room._filter_available_enemy_pool():
		check(room._enemy_id(scene.resource_path) != "summoner", "Pending summoner bypasses cap")
	summoner.free()
	var counts := {}
	seed(42)
	for i in range(5000):
		var id := room._enemy_id(room._pick_random_enemy_scene().resource_path)
		counts[id] = int(counts.get(id, 0)) + 1
	check(counts.get("follower", 0) > counts.get("shooter", 0) and counts.get("shooter", 0) > counts.get("tank", 0), "Weights ignored")
	var player := CharacterBody2D.new()
	add_child(player)
	player.add_to_group("player")
	GameData.register_player(player)
	for pos in [Vector2(20, 0), Vector2(250, 0)]:
		var marker := Marker2D.new()
		marker.position = pos
		room.add_child(marker)
		room.spawn_points.append(marker)
	check(room._choose_spawn_point() == room.spawn_points[1], "Spawn too close to player")
	GameData.unregister_player(player)
	print("ROOM_BALANCE_SMOKE failures=", failures, " distribution=", counts)
	get_tree().quit(failures)
