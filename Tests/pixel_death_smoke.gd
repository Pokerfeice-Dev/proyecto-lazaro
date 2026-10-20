extends Node2D

const FX = preload("res://Scripts/Effects/pixel_death.gd")

func _ready() -> void:
	call_deferred("_verify")

func _verify() -> void:
	GameData.begin_sandbox()
	var target = CharacterBody2D.new()
	target.position = Vector2(-10000, -10000)
	target.add_to_group("player")
	add_child(target)
	var enemies: Array[Node] = []
	var paths := [
		"res://Scenes/Enemies/EnemyFollower.tscn",
		"res://Scenes/Enemies/EnemyTurret.tscn",
		"res://Scenes/Enemies/Crypt/CryptGhoul.tscn",
	]
	for i in paths.size():
		var enemy = load(paths[i]).instantiate()
		enemy.position = Vector2(450 + i * 450, 540)
		add_child(enemy)
		if enemy.has_node("Sprite_BaseTurret"):
			enemy.get_node("Sprite_BaseTurret").show()
		enemies.append(enemy)
	await get_tree().create_timer(0.3).timeout
	for enemy in enemies:
		assert(not enemy.use_legacy_death_fx)
		enemy.die()
		if enemy.has_node("Death_fx"):
			assert(not enemy.get_node("Death_fx").visible)
	var effects := 0
	for child in get_children():
		if child.get_script() == FX:
			effects += 1
			assert(not child.pieces.is_empty())
			assert(child.pieces.size() <= 256)
	assert(effects >= 4, "Follower, turret base/cannon and ghoul must fragment")
	await get_tree().create_timer(0.25).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("pixel-death-smoke.png"))
	await get_tree().create_timer(1.2).timeout
	for child in get_children():
		assert(child.get_script() != FX, "Fragments must clean themselves up")
	for enemy in enemies:
		assert(not is_instance_valid(enemy), "Dead enemies must be freed")
	GameData.end_sandbox()
	print("PIXEL_DEATH_OK")
	get_tree().quit()
