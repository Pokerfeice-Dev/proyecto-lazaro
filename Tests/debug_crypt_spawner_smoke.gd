extends Node2D

func _ready() -> void:
	call_deferred("verify")

func verify() -> void:
	var player = CharacterBody2D.new()
	player.name = "TestPlayer"
	player.add_to_group("player")
	add_child(player)
	for entry in DebugMenu.CRYPT_ENEMIES:
		assert(ResourceLoader.exists(entry.path), "crypt cheat scene exists: " + entry.name)
		DebugMenu._spawn_scene_near_player(entry.path, entry.name)
	await get_tree().process_frame
	var spawned = get_tree().get_nodes_in_group("enemy")
	assert(spawned.size() == DebugMenu.CRYPT_ENEMIES.size(), "all crypt cheats spawn an enemy")
	for enemy in spawned:
		assert(enemy is CryptEnemy, "cheat spawned a crypt enemy")
		assert(enemy.global_position.distance_to(player.global_position) > 100.0, "enemy spawns away from player")
	print("DEBUG_CRYPT_SPAWNER_PASS")
	get_tree().quit()
