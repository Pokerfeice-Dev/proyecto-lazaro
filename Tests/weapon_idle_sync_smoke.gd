extends Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	GameData.begin_sandbox()
	var player = preload("res://Scenes/Player/Player.tscn").instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	player.is_cutscene_frozen = false
	player.last_dir = "down"
	player._play_idle_animation()
	var body: AnimatedSprite2D = player.anim_sprite
	# Cambiar de dirección conserva cuadro y progreso, sin reiniciar respiración.
	for frame in 8:
		for direction in ["up", "up_right", "right", "down_right", "down", "down_left", "left", "up_left"]:
			body.set_frame_and_progress(frame, 0.37)
			var before: float = player._animation_phase(body)
			player.last_dir = direction
			player._play_idle_animation()
			assert(is_equal_approx(player._animation_phase(body), before))
	player.last_dir = "down"
	player._play_idle_animation()
	player.second_weapon.switch_weapon(preload("res://Scenes/Weapon/HolyFireMace.tscn"))
	for tick in 120:
		if tick == 30:
			player.active_weapon.switch_weapon(preload("res://Scenes/Weapon/uzi.tscn"))
		if tick == 60:
			player.active_weapon.switch_weapon(preload("res://Scenes/Weapon/Revolver.tscn"))
		if tick == 90: body.speed_scale = 0.5
		await RenderingServer.frame_post_draw
		var phase: float = player._animation_phase(body)
		for sprite in player.active_weapon.find_children("*", "AnimatedSprite2D", true, false):
			if sprite.animation.begins_with("idle"):
				assert(is_equal_approx(player._animation_phase(sprite), phase), "Idle debe coincidir en el cuadro dibujado")
		assert(player.active_weapon.position.is_equal_approx(player._get_weapon_base_position(Vector2.DOWN)))
		var sheet = player.second_weapon.current_weapon.melee_sprite
		assert(sheet.frame == mini(int(phase * sheet.hframes), sheet.hframes - 1))
	# La pausa no consume fase; reanudar no usa tiempo de pared para el idle.
	get_tree().paused = true
	var paused_phase: float = player._animation_phase(body)
	for tick in 8: await get_tree().process_frame
	assert(is_equal_approx(player._animation_phase(body), paused_phase))
	get_tree().paused = false
	# Sincronizar no pisa la animación de disparo.
	var gun: AnimatedSprite2D = player.active_weapon.current_weapon.get_node("Weapon_Sprites")
	gun.play("shoot")
	gun.set_frame_and_progress(0, 0.25)
	player._sync_weapon_idle_pose()
	assert(gun.animation == "shoot" and gun.frame == 0 and is_equal_approx(gun.frame_progress, 0.25))
	player.queue_free()
	await get_tree().process_frame
	GameData.end_sandbox()
	print("WEAPON_IDLE_SYNC_OK: 64 giros, 120 cuadros renderizados, cambios de arma, pausa, velocidad y disparo")
	get_tree().quit()

