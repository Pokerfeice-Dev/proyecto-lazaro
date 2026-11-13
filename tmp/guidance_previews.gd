extends Node
func _ready():
	GameData.begin_sandbox()
	var menu = load('res://Scenes/UI/newgame.tscn').instantiate()
	add_child(menu)
	menu._show_tutorial_prompt(1)
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png('res://tmp/tutorial-choice-preview.png')
	menu.queue_free()
	await get_tree().process_frame
	var layer = CanvasLayer.new()
	add_child(layer)
	var reminder = load('res://Scripts/UI/inventory_reminder.gd').new()
	layer.add_child(reminder)
	GameData.reset_inventory_guidance()
	for i in 3: GameData.note_inventory_item_received()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png('res://tmp/inventory-reminder-preview.png')
	GameData.end_sandbox()
	print('GUIDANCE_PREVIEWS_OK')
	get_tree().quit()
