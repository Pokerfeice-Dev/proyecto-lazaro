extends Node2D
func _ready() -> void:
	call_deferred('_preview')

func _preview() -> void:
	GameData.begin_sandbox()
	WeaponSelectionMenu.show_popup(self, 'PREPARACIÓN DE INVASIÓN', 'Selecciona el equipamiento para comenzar la run', 'INICIAR RUN')
	await get_tree().create_timer(0.5, true, false, true).timeout
	var menu = get_tree().root.get_node('WeaponSelectionMenu')
	for control in menu.find_children('*', 'Button', true, false):
		if not control.toggle_mode: continue
		var content = control.find_children('*', 'MarginContainer', false, false)[0]
		assert(control.size.y >= content.get_combined_minimum_size().y)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png('res://tmp/weapon-menu-layout.png')
	print('WEAPON_MENU_LAYOUT_OK')
	menu._close()
	GameData.end_sandbox()
	get_tree().quit()


