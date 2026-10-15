extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("VERIFY_FAILED: " + message)
		get_tree().quit(1)
		assert(condition, message)

func snapshot(file_name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join(file_name))

func verify() -> void:
	var lab = load("res://Scenes/Rooms/lab_room.tscn").instantiate()
	add_child(lab)
	for i in range(8): await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	check(player != null, "player spawned")
	var ui = player.get_node("HUD/InventoryUI")
	ui.show()
	ui.update_ui()
	get_tree().paused = true
	check(ui.inventory_slots.size() == 24, "24 inventory slots")
	check(ui.ui_slots.size() == 11, "11 equipment slots")
	check(ui.inventory != null and ui.equipment != null, "inventory references")
	check(ui.find_children("*Coin*", "", true, false).is_empty(), "currency removed")
	for i in range(4): await get_tree().process_frame
	await snapshot("lazaro-inventory-editable.png")
	var item = load("res://Art/Items/Weapons/Item10_Bateria.tres").duplicate()
	ui.inventory.add_item(item)
	ui.update_ui()
	check(ui.inventory_slots[0].item == item, "item shown")
	ui._on_slot_clicked(item)
	check(ui.detail_content_box.visible, "details displayed")
	ui._on_item_dropped(item, ui.inventory_slots[0], ui.main_weapon_slots[0])
	check(ui.equipment.slots[ItemData.ItemSlot.MAIN_W1] == item, "equip by drag and drop")
	ui._on_item_dropped(item, ui.main_weapon_slots[0], ui.inventory_slots[0])
	check(ui.inventory.items.has(item), "unequip by drag and drop")
	ui.filter_body_btn.pressed.emit()
	check(ui.inventory_slots[0].item == null, "body filter")
	ui.filter_all_btn.pressed.emit()
	ui.stats_tab_secondary_btn.pressed.emit()
	check(ui.stats_weapon_vbox.get_node("Range").visible, "secondary range shown")
	check(not ui.stats_weapon_vbox.get_node("Projectiles").visible, "primary rows hidden")
	ui.stats_tab_primary_btn.pressed.emit()
	ui.tab_codex_btn.pressed.emit()
	check(ui.codex_view.visible and not ui.codex_browser._entries.is_empty(), "codex populated")
	ui.codex_category_buttons["items"].pressed.emit()
	await get_tree().process_frame
	ui.tab_inventory_btn.pressed.emit()
	ui.selected_item = null
	ui.update_ui()
	# Complete a real recipe. Record it as known to avoid writing a save in this fixture.
	GameData.unlocked_synergies.append("pistola_mente_colmena")
	GameData.activated_synergies.append("pistola_mente_colmena")
	var ids = ["colmena", "cerebro", "cabeza_humana"]
	for index in range(3):
		var part = ItemData.new()
		part.id = ids[index]
		part.type = ItemData.ItemType.WEAPON
		part.slot = index
		ui.equipment.equip_item(part)
	for i in range(4): await get_tree().process_frame
	var popup = get_tree().root.get_node_or_null("SynergyActivation")
	check(popup != null, "recipe triggers activation")
	check(popup.synergy_id == "pistola_mente_colmena", "correct synergy")
	player._update_player_stats()
	check(SynergyManager._presentation_queue.is_empty(), "no duplicate on refresh")
	await wait_for_reveal(popup)
	check(popup._can_dismiss, "reveal completes while paused")
	await snapshot("lazaro-synergy-activation.png")
	SynergyManager.present_activation("roadkill", true)
	popup._on_continue_pressed()
	await get_tree().create_timer(.4, true).timeout
	popup = get_tree().root.get_node_or_null("SynergyActivation")
	check(popup != null and popup.synergy_id == "roadkill", "queue advances")
	await wait_for_reveal(popup)
	popup._on_continue_pressed()
	await get_tree().create_timer(.4, true).timeout
	check(get_tree().paused, "inventory pause preserved")
	check(not SynergyManager._presentation_active, "queue drained")
	ui.hide()
	get_tree().paused = false
	SynergyManager.present_activation("relampago")
	await get_tree().process_frame
	popup = get_tree().root.get_node_or_null("SynergyActivation")
	await wait_for_reveal(popup)
	popup._on_continue_pressed()
	await get_tree().create_timer(.4, true).timeout
	check(not get_tree().paused, "gameplay resumes if originally unpaused")
	print("INVENTORY_AND_SYNERGY_VERIFIED")
	get_tree().quit()

func wait_for_reveal(popup: Node) -> void:
	for attempt in 60:
		if not is_instance_valid(popup) or popup._can_dismiss: return
		await get_tree().create_timer(0.1, true).timeout
