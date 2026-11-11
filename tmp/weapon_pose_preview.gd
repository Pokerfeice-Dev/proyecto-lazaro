extends Node2D
func _ready():
	var source = load("res://Scenes/Player/Player.tscn").instantiate()
	var original = source.get_node("AnimatedSprite2D")
	source.anim_sprite = original
	var angles = [60, 85, 90, 95, 120]
	var weapons = ["Revolver", "Minigun", "axe"]
	for row in weapons.size():
		for column in angles.size():
			var root = Node2D.new()
			root.position = Vector2(185 + column * 380, 155 + row * 340)
			root.scale = Vector2.ONE * 3
			add_child(root)
			var dir = Vector2.from_angle(deg_to_rad(angles[column]))
			source.last_dir = source._get_8_dir_string(dir)
			var sprite = AnimatedSprite2D.new()
			sprite.sprite_frames = original.sprite_frames
			sprite.scale = original.scale
			sprite.animation = "idle_" + ("diagonal_" if "_" in source.last_dir else "") + source.last_dir
			original.animation = sprite.animation
			root.add_child(sprite)
			var pivot = Node2D.new()
			root.add_child(pivot)
			pivot.position = source._get_weapon_base_position(dir)
			source._flip_weapon(pivot, dir)
			pivot.rotation = (dir * 300 - pivot.position).angle()
			var weapon = load("res://Scenes/Weapon/" + weapons[row] + ".tscn").instantiate()
			pivot.add_child(weapon)
			var mark = weapon.get_node_or_null("Weapon_mark")
			if mark:
				var offset = mark.position
				for child in weapon.get_children():
					if child is Node2D: child.position -= offset
			var label = Label.new()
			label.text = "%s %d° / %s" % [weapons[row], angles[column], source.last_dir]
			label.position = root.position + Vector2(-150, 120)
			label.add_theme_font_size_override("font_size", 22)
			add_child(label)
	source.free()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/weapon-down-poses.png")
	get_tree().quit()
