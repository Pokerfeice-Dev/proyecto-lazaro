extends Node2D

func _ready() -> void:
	call_deferred("_verify")

func _verify() -> void:
	GameData.begin_sandbox()
	GameData.chosen_melee_weapon = "mace"
	GameData.unlocked_synergies.append("arrogancia")
	GameData.activated_synergies.append("arrogancia")
	var ids = ["mezcladora", "cabeza_humana", "colmena"]
	var slots = [ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]
	for i in range(3):
		var item = ItemData.new()
		item.id = ids[i]
		item.type = ItemData.ItemType.WEAPON
		item.slot = slots[i]
		GameData.equipment_slots[slots[i]] = item
	var player = load("res://Scenes/Player/Player.tscn").instantiate()
	player.position = Vector2(960, 540)
	add_child(player)
	await get_tree().create_timer(0.4).timeout
	assert(player._is_arrogancia_equipped())
	var shield = player._arrogancia_shield
	assert(not shield.active and not shield.visible)
	player.second_weapon.attack()
	await get_tree().create_timer(0.12).timeout
	assert(player._is_arrogancia_reflect_active() and shield.active)
	assert(shield._sound.stream != null and shield._sound.volume_db <= -18.0)
	var health = player.stats.current_health
	var bullet = load("res://Scenes/Enemies/enemy_shooter_projectile.tscn").instantiate()
	add_child(bullet)
	bullet.global_position = player.global_position + Vector2(18, -8)
	bullet._on_body_entered(player)
	assert(player.stats.current_health == health)
	assert(shield._impacts.size() == 1)
	var crypt_bullet = load("res://Scripts/Projectiles/crypt_projectile.gd").new()
	add_child(crypt_bullet)
	crypt_bullet.global_position = player.global_position + Vector2(-18, -8)
	crypt_bullet._hit(player)
	assert(player.stats.current_health == health)
	assert(shield._impacts.size() == 2)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("arrogancia-shield.png"))
	await get_tree().create_timer(2.4).timeout
	assert(not player._is_arrogancia_reflect_active())
	assert(not shield.active and not shield.visible)
	player.second_weapon.attack()
	await get_tree().create_timer(0.1).timeout
	assert(shield.active)
	GameData.equipment_slots[slots[0]] = null
	await get_tree().create_timer(0.45).timeout
	assert(not shield.active and not shield.visible)
	player.queue_free()
	await get_tree().process_frame
	GameData.end_sandbox()
	print("ARROGANCIA_SHIELD_OK: activation, reflection, audio, expiration and unequip")
	get_tree().quit()
