extends Node2D

func _ready() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var index := 0
	var all_arsenals: Array[PrometeoArsenal] = []
	for id in PrometeoArsenal.WEAPONS:
		var cell = Node2D.new()
		cell.position = Vector2(180 + (index % 3) * 620, 190 + floori(index / 3.0) * 330)
		cell.scale = Vector2(2, 2)
		add_child(cell)
		var body = AnimatedSprite2D.new()
		body.sprite_frames = load("res://Art/Enemies/Prometeo/prometeo_frames.tres")
		body.animation = "idle_down"
		body.scale = Vector2(1.95, 1.95)
		body.modulate = Color(0.55, 0.45, 0.65)
		cell.add_child(body)
		var arsenal = PrometeoArsenal.new()
		arsenal.position.y = -6
		cell.add_child(arsenal)
		arsenal.equip(id, false)
		all_arsenals.append(arsenal)
		var source = load(PrometeoArsenal.WEAPONS[id].scene).instantiate()
		var visual: Node2D
		for node_name in ["Weapon_Sprites", "Melee_sprite", "Sprite2D"]:
			visual = source.get_node_or_null(node_name)
			if visual: break
		assert(arsenal._weapon_sprite.scale.is_equal_approx(visual.scale))
		if visual is Sprite2D:
			assert(arsenal._weapon_sprite.texture == visual.texture)
			assert(arsenal._weapon_sprite.hframes == visual.hframes)
		else:
			assert(arsenal._weapon_sprite.sprite_frames == visual.sprite_frames)
		var grip = source.find_child("Weapon_mark", true, false)
		var grip_pos: Vector2 = grip.position
		if grip.get_parent() == visual:
			grip_pos = visual.transform * grip_pos
		assert(arsenal._weapon_sprite.position.is_equal_approx(visual.position - grip_pos))
		var muzzle = source.get_node_or_null("Bullet_mark_right")
		for angle in [0.0, PI, -PI / 2.0, PI / 2.0]:
			arsenal.aim_angle = angle
			arsenal._update_weapon_transform()
			assert(arsenal._weapon_pivot.scale.y == (-1.0 if Vector2.from_angle(angle).x < 0 else 1.0))
			if muzzle:
				var expected = arsenal._weapon_pivot.to_global(muzzle.position - grip_pos)
				assert(arsenal._muzzle().is_equal_approx(expected))
		arsenal.aim_angle = 0.0
		arsenal._update_weapon_transform()
		source.free()
		var label = Label.new()
		label.text = id
		label.position = Vector2(-35, 60)
		cell.add_child(label)
		index += 1
	# Cambiar de arma durante el destello no debe dejar tweens del sprite anterior.
	var changing = all_arsenals[0]
	changing.equip("minigun", true)
	changing.equip("colmena", true)
	changing.equip("pistola", false)
	var pistol_transform = changing._weapon_sprite.transform
	var pistol_muzzle = changing._muzzle_offset
	# El remate con escopeta es temporal: no cambia el arma elegida por el boss.
	changing._set_weapon_visual("escopeta")
	assert(changing.current_id == "pistola")
	changing._set_weapon_visual(changing.current_id)
	assert(changing._weapon_sprite.transform.is_equal_approx(pistol_transform))
	assert(changing._muzzle_offset.is_equal_approx(pistol_muzzle))
	await get_tree().create_timer(0.5).timeout
	assert(changing._weapon_sprite.scale.is_equal_approx(Vector2(1.3, 1.3)))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("prometeo-arsenal.png"))
	print("PROMETEO_ARSENAL_VISUAL_OK: nine weapons, grip, scale, frames, four aim directions and rapid swaps")
	get_tree().quit()
