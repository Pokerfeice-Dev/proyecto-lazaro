extends Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred('_verify')
func _verify() -> void:
	GameData.begin_sandbox()
	var previous: Dictionary = GameSettings._values.accesibilidad.duplicate()
	var lab = load('res://Scenes/Rooms/lab_room.tscn').instantiate()
	add_child(lab)
	await get_tree().create_timer(0.5).timeout
	var hud = get_tree().get_first_node_in_group('hud')
	assert(hud != null)
	var weapon: Control = hud.get_node('Control/WeaponHUD')
	var base: Vector2 = hud._hud_base[weapon].scale
	var inventory_scale: Vector2 = hud.get_node('InventoryUI').scale
	for percent in [75.0, 150.0, 100.0]:
		GameSettings._values.accesibilidad.escala_hud = percent
		GameSettings.setting_changed.emit('accesibilidad', 'escala_hud', percent)
		assert(weapon.scale.is_equal_approx(base * percent / 100.0))
		assert(hud.get_node('InventoryUI').scale == inventory_scale)
		var viewport_size: Vector2 = hud.get_node('Control').size
		for name in ['CurrencyContainer', 'WeaponHUD']:
			var block: Control = hud.get_node('Control/' + name)
			var edge := block.position + block.size * block.scale
			assert(is_equal_approx(edge.x, viewport_size.x - 32.0), 'Right edge must stay anchored')
			assert(edge.y <= viewport_size.y - 32.0 + 0.1, 'HUD must fit vertically')
		assert(hud.health_bar.position.is_equal_approx(Vector2(32, 32)))
		assert(is_equal_approx(weapon.position.y + weapon.size.y * weapon.scale.y, viewport_size.y - 32.0))
		if DisplayServer.get_name() != 'headless':
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png('res://tmp/hud-anchor-%d.png' % int(percent))
	# A longer counter must keep the same right margin after container layout.
	hud.update_scrap(999999)
	for i in 3: await get_tree().process_frame
	var currency: Control = hud.get_node('Control/CurrencyContainer')
	assert(is_equal_approx(currency.position.x + currency.size.x * currency.scale.x, hud.get_node('Control').size.x - 32.0))
	GameSettings._values.accesibilidad.vida_numerica = true
	GameSettings.setting_changed.emit('accesibilidad', 'vida_numerica', true)
	hud.update_health(42, 100)
	assert(hud._health_numbers.visible)
	assert(hud._health_numbers.text == '42 / 100')
	for brightness in [70.0, 150.0, 100.0]:
		GameSettings._apply_brightness(brightness)
		assert(GameSettings._brightness_rect.visible == (brightness != 100.0))
	var options = load('res://Scenes/UI/options_screen.tscn').instantiate()
	get_tree().root.add_child(options)
	options._show_tab('accesibilidad', false)
	await get_tree().create_timer(0.3).timeout
	assert(options._pages.accesibilidad.visible)
	if DisplayServer.get_name() != 'headless':
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png('res://tmp/accessibility-options.png')
	GameSettings._values.accesibilidad = previous
	GameSettings._apply_brightness(previous.brillo)
	GameData.end_sandbox()
	print('ACCESSIBILITY_OK')
	get_tree().quit()
