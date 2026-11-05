extends Node2D

class ReturnProbe extends RunEndScreen:
	var returned := false
	func _leave() -> void:
		returned = true

func _ready() -> void:
	call_deferred('_verify')

func _verify() -> void:
	GameData.begin_sandbox()
	GameData.run_enemies_killed = 137
	GameData.run_scrap_collected = 249
	GameData.last_killer = 'Ghoul'
	Engine.time_scale = 0.8
	var screen := RunEndScreen.show_death(get_tree(), Vector2(500, 500))
	await get_tree().create_timer(0.10, true, false, true).timeout
	assert(is_equal_approx(Engine.time_scale, 0.05))
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	screen._input(key)
	assert(screen.death_fx.is_ready())
	assert(not screen._leaving)
	assert(screen.death_rows[2].value.text == '137')
	assert(screen.death_rows[3].value.text == '249')
	assert(screen.death_rows[4].value.text == 'Ghoul')
	await get_tree().create_timer(0.1, true, false, true).timeout
	screen.queue_free()
	await get_tree().process_frame
	assert(is_equal_approx(Engine.time_scale, 0.8))
	var natural := ReturnProbe.new()
	natural.title_text = 'HAS MUERTO'
	natural.subtitle_text = 'VUÉLVETE MÁS FUERTE E INTÉNTALO DE NUEVO'
	get_tree().root.add_child(natural)
	await get_tree().create_timer(1.9, true, false, true).timeout
	assert(natural.death_fx.is_ready())
	assert(natural.death_fx.revealed == 5)
	assert(natural.death_fx.slammed)
	if DisplayServer.get_name() != 'headless':
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png('res://tmp/death-monitor.png')
	# Exercise the complete closure using an isolated return callback.
	natural._on_return()
	assert(natural._leaving)
	assert(natural.death_fx.closing == 0)
	await get_tree().create_timer(0.45, true, false, true).timeout
	assert(natural.returned)
	assert(is_equal_approx(Engine.time_scale, 0.8))
	natural.queue_free()
	await get_tree().process_frame
	assert(is_equal_approx(Engine.time_scale, 0.8))
	Engine.time_scale = 1
	GameData.end_sandbox()
	print('DEATH_MONITOR_OK')
	get_tree().quit()
