extends Node
func _ready():
	GameData.begin_sandbox()
	GameData.inventory_items.clear()
	var hud = load("res://Scenes/UI/HUD.tscn").instantiate()
	add_child(hud)
	await get_tree().process_frame
	assert(hud._inventory_count.text == "0/12")
	for i in 5: GameData.inventory_items.append(ItemData.new())
	await get_tree().process_frame
	hud._update_inventory_count()
	assert(hud._inventory_count.text == "5/12")
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/inventory-hud-preview.png")
	GameData.inventory_items.pop_back()
	hud._update_inventory_count()
	assert(hud._inventory_count.text == "4/12")
	GameData.end_sandbox()
	print("INVENTORY_HUD_OK")
	get_tree().quit()
