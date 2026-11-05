extends Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred('_preview')
func _preview() -> void:
	GameData.begin_sandbox()
	var lab = load('res://Scenes/Rooms/lab_room.tscn').instantiate()
	add_child(lab)
	await get_tree().create_timer(0.6).timeout
	var ui = get_tree().get_first_node_in_group('player').get_node('HUD/InventoryUI')
	ui.show()
	ui.update_ui()
	ui.stats_synergy_description.text = 'Dispara un proyectil que rebota en las paredes hasta 3 veces o hasta que impacta sobre 3 enemigos. Aumenta el daño, velocidad de proyectil, velocidad de ataque y perforación.'
	ui.stats_synergy_description.show()
	await get_tree().create_timer(0.2).timeout
	print('TOP_BAR_HEIGHT ', ui.top_bar.size.y, ' CONTENT_BOTTOM ', ui.main_three_columns.get_global_rect().end.y, ' FOOTER_TOP ', ui.bottom_bar.global_position.y)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png('res://tmp/inventory-layout-fix.png')
	GameData.end_sandbox()
	get_tree().quit()
