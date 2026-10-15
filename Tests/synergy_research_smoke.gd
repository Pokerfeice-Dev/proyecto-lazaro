extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("RESEARCH_FAILED: " + message)
		get_tree().quit(1)
		assert(condition, message)

func verify() -> void:
	GameData.current_slot = 99
	GameData.unlocked_synergies.clear()
	GameData.activated_synergies.clear()
	GameData.synergy_item_hints.clear()
	GameData.scrap = 1300
	var id = "pistola_mente_colmena"
	var entry = OmniaCatalog._synergy_entries()[0]
	check(entry.name != SynergyManager.SYNERGIES[id].name, "hidden name before purchase")
	check(not OmniaCatalog.purchase_hint(id, 1), "cannot buy before unlock")
	check(OmniaCatalog.purchase(entry), "unlock purchase")
	check(GameData.scrap == 1000, "unlock costs 300")
	check(OmniaCatalog.is_ingredient_revealed(id, 0), "first item revealed")
	check(not OmniaCatalog.is_ingredient_revealed(id, 1), "second hidden")
	check(not OmniaCatalog.is_ingredient_revealed(id, 2), "third hidden")
	check(OmniaCatalog.purchase_hint(id, 1), "second hint purchase")
	check(GameData.scrap == 600, "second costs 400")
	check(not OmniaCatalog.purchase_hint(id, 1), "no double charge")
	check(not OmniaCatalog.purchase_hint(id, -1), "invalid index rejected")
	GameData.scrap = 599
	check(not OmniaCatalog.purchase_hint(id, 2), "insufficient currency rejected")
	GameData.scrap = 600
	check(OmniaCatalog.purchase_hint(id, 2), "third hint purchase")
	check(GameData.scrap == 0, "third costs 600")
	GameData.synergy_item_hints.clear()
	check(GameData.load_game(99), "reload save")
	check(OmniaCatalog.is_ingredient_revealed(id, 1) and OmniaCatalog.is_ingredient_revealed(id, 2), "hints persist")
	GameData.begin_sandbox()
	GameData.synergy_item_hints.clear()
	GameData.end_sandbox()
	check(OmniaCatalog.is_ingredient_revealed(id, 2), "sandbox restores hints")
	GameData.synergy_item_hints.clear()
	GameData.scrap = 1000
	var menu = OmniaMenu.new()
	add_child(menu)
	menu._show_category("SINERGIAS")
	menu._select(id)
	await get_tree().create_timer(0.5).timeout
	var recipe = menu._detail_box.get_node("ResearchRecipe")
	check(recipe.get_node("RecipeChips/FirstItem/Frame/Icon").texture != null, "visible first sprite")
	check(recipe.get_node("RecipeChips/SecondItem/Frame/Icon").texture == null, "no hidden sprite leak")
	check(not menu._is_revealed(menu._find_entry(id)), "unlock does not discover weapon")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("lazaro-research.png"))
	recipe._ask_hint(1)
	check(recipe.confirmation.visible, "confirmation shown")
	check(recipe.dismiss_confirmation(), "can cancel")
	check(GameData.scrap == 1000, "cancel spends nothing")
	GameData.activated_synergies.append(id)
	check(OmniaCatalog._synergy_entries()[0].name == SynergyManager.SYNERGIES[id].name, "discovery reveals name")
	check(OmniaCatalog.is_ingredient_revealed(id, 2), "discovery reveals recipe freely")
	print("RESEARCH_PASS")
	get_tree().quit()
