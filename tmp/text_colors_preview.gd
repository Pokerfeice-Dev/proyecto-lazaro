extends Node
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("run")
func run() -> void:
	GameData.begin_sandbox()
	GameData.show_title_screen = false
	var menu = load("res://Scenes/UI/MainMenu.tscn").instantiate()
	add_child(menu)
	await get_tree().create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/text-colors-menu.png")
	menu.queue_free()
	await get_tree().process_frame
	var ui = load("res://Scenes/UI/inventory_ui.tscn").instantiate()
	var inventory = Inventory.new()
	var equipment = Equipment.new()
	var old = load("res://Art/Items/Weapons/Item10_Bateria.tres").duplicate()
	old.stats = {"damage": 4.0, "attack_speed": 0.2}
	var candidate = old.duplicate()
	candidate.stats = {"damage": 8.0, "attack_speed": 0.1}
	equipment.slots[ItemData.ItemSlot.MAIN_W1] = old
	inventory.items.append(candidate)
	ui.inventory = inventory
	ui.equipment = equipment
	add_child(ui)
	ui.show()
	ui.selected_item = candidate
	ui.is_comparing = true
	ui.update_ui()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/text-colors-inventory.png")
	ui.free()
	inventory.free()
	equipment.free()
	GameData.end_sandbox()
	print("TEXT_COLORS_PREVIEW_OK")
	get_tree().quit()
