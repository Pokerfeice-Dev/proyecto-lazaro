extends Node2D

var checks := 0

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.begin_sandbox()
	var player = preload("res://Scenes/Player/Player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.position = Vector2(700, 450)
	var ranged := ["Revolver", "uzi", "shotgun", "Minigun", "Flamethrower", "Cerberus"]
	var melee := ["dagger", "axe", "mace", "PacemakerMace", "SpeedDemonDagger", "HolyFireMace"]
	for index in ranged.size():
		player.active_weapon.switch_weapon(load("res://Scenes/Weapon/%s.tscn" % ranged[index]))
		player.second_weapon.switch_weapon(load("res://Scenes/Weapon/%s.tscn" % melee[index]))
		for mode in ["idle", "run", "dash"]:
			player.velocity = Vector2(100, 0) if mode == "run" else Vector2.ZERO
			player.is_dashing = mode == "dash"
			# Ambos sentidos incluyen los cruces de escala positiva/negativa.
			for sign_value in [1, -1]:
				for degree in range(360):
					var dir := Vector2.from_angle(deg_to_rad(degree * sign_value))
					player._set_aim_facing(dir)
					player._play_player_sprite_animation()
					var target: Vector2 = player.global_position + dir * 300.0
					player._update_primary_weapon_pivot(target, dir, 25.0)
					player._update_secondary_weapon_pivot(target, dir, 25.0)
					for weapon in [player.active_weapon, player.second_weapon]:
						assert(weapon.position.is_equal_approx(player._get_weapon_base_position(dir)))
						var actual: Vector2 = weapon.global_transform.x.normalized()
						var expected: Vector2 = (target - weapon.global_position).normalized()
						assert(actual.dot(expected) > 0.9999, "El espejo no debe desviar la puntería")
						assert((weapon.scale.y < 0) == player._weapon_uses_left_hand())
						assert(weapon.show_behind_parent == player._weapon_is_behind_body())
						if player.last_dir == "down": assert(weapon.position.x > 0)
						if player.last_dir == "up": assert(weapon.position.x < 0)
						checks += 1
	# Ningún salto de mano o espejo al atravesar el centro de la pose frontal.
	player.last_dir = "down"
	for degree in [89.9, 90.1, 89.8, 90.2, 112.4, 112.6, 112.3]:
		player._set_aim_facing(Vector2.from_angle(deg_to_rad(degree)))
		assert(player.last_dir == "down", "Evitar parpadeo en el límite de poses")
	player._set_aim_facing(Vector2.from_angle(deg_to_rad(118.0)))
	assert(player.last_dir == "down_left", "El margen no debe impedir girar")
	player.queue_free()
	await get_tree().process_frame
	GameData.end_sandbox()
	print("WEAPON_POSE_OK: %d poses, 12 armas, reposo/carrera/dash, ambos sentidos" % checks)
	get_tree().quit()
