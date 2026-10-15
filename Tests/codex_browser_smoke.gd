extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("BROWSER_FAILED: " + message)
		get_tree().quit(1)
		assert(condition, message)

func snapshot(file_name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(file_name))

func verify() -> void:
	var lab = load("res://Scenes/Rooms/lab_room.tscn").instantiate()
	add_child(lab)
	for i in 5: await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	var ui = player.get_node("HUD/InventoryUI")
	ui.show()
	get_tree().paused = true
	GameData.unlocked_synergies.clear()
	GameData.activated_synergies.clear()
	GameData.synergy_item_hints.clear()
	ui._on_research_tab_pressed()
	check(ui.research_browser._entries.is_empty(), "empty book has no locked entries")
	GameData.unlocked_synergies.append("pistola_mente_colmena")
	ui._on_research_tab_pressed()
	var browser = ui.research_browser
	check(browser._entries.size() == 1, "only unlocked recipe listed")
	check(not browser.get_node("%Recipe").allow_purchase, "book is reference only")
	check(browser.get_node("%Recipe").get_node("RecipeChips/SecondItem/Frame/Icon").texture == null, "book honors hidden hints")
	await get_tree().create_timer(0.3).timeout
	await snapshot("lazaro-synthesis-book.png")
	GameData.unlock_codex_entry("items", "colmena")
	ui._on_codex_tab_pressed()
	ui._on_codex_category_pressed("items")
	browser = ui.codex_browser
	browser._select("colmena")
	await get_tree().create_timer(0.3).timeout
	await snapshot("lazaro-codex-browser.png")
	check(browser.get_node("%Description").text == CodexData.DATA.items.colmena.lore, "complete item description")
	browser._filter("not-an-existing-record")
	check(browser.get_node("%Empty").visible, "empty search state")
	for category in ["enemies", "weapons", "npcs", "levels", "synergies"]:
		ui._on_codex_category_pressed(category)
		await get_tree().process_frame
		check(not browser._entries.is_empty(), "category loads: " + category)
	ui._on_inventory_tab_pressed()
	check(not ui.research_browser.visible and not ui.codex_view.visible and ui.main_three_columns.visible, "return to inventory")
	print("BROWSER_PASS")
	get_tree().quit()
