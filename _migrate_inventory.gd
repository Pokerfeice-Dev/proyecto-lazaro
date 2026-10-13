extends SceneTree

var ui: Control
var bindings: Dictionary = {}

func _initialize() -> void:
	call_deferred("migrate")

func migrate() -> void:
	ui = load("res://Scenes/UI/inventory_ui.tscn").instantiate()
	root.add_child(ui)
	current_scene = ui
	for i in range(4):
		await process_frame
	# Preserve the existing design as editable nodes and resources.
	for prop in ui.get_script().get_script_property_list():
		var value = ui.get(prop.name)
		if value is Node and ui.is_ancestor_of(value):
			value.name = str(prop.name).to_pascal_case()
			value.owner = ui
			value.unique_name_in_owner = true
			bindings[prop.name] = str(value.name)
	var currency = ui.coin_label.get_parent()
	currency.get_parent().remove_child(currency)
	currency.free()
	bindings.erase("coin_label")
	ui.main_three_columns.get_child(0).name = "InventoryColumn"
	ui.main_three_columns.get_child(2).name = "EquipmentColumn"
	ui.main_three_columns.get_child(4).name = "AttributesColumn"
	for key in ui.codex_category_buttons:
		var button = ui.codex_category_buttons[key]
		button.name = str(key).to_pascal_case() + "Category"
		button.set_meta("category", key)
	ui.codex_category_buttons.values()[0].get_parent().name = "CodexCategories"
	ui.codex_category_buttons.values()[0].get_parent().owner = ui
	ui.codex_category_buttons.values()[0].get_parent().unique_name_in_owner = true
	for index in range(ui.inventory_slots.size()):
		ui.inventory_slots[index].name = "InventorySlot%02d" % (index + 1)
	var anchors = [Vector2(0.5, 0.12), Vector2(0.18, 0.28), Vector2(0.82, 0.28), Vector2(0.22, 0.72), Vector2(0.78, 0.72)]
	for index in range(ui.ui_slots.size()):
		var slot = ui.ui_slots[index]
		slot.name = ItemData.ItemSlot.keys()[slot.slot_type].to_pascal_case() + "Slot"
		slot.set_meta("equipped", true)
		if index < 5:
			var wrapper: Control = slot.get_parent()
			wrapper.name = ItemData.ItemSlot.keys()[slot.slot_type].to_pascal_case()
			wrapper.anchor_left = anchors[index].x
			wrapper.anchor_right = anchors[index].x
			wrapper.anchor_top = anchors[index].y
			wrapper.anchor_bottom = anchors[index].y
			wrapper.offset_left = -36
			wrapper.offset_right = 36
			wrapper.offset_top = -46
			wrapper.offset_bottom = 46
			wrapper.grow_horizontal = Control.GROW_DIRECTION_BOTH
			wrapper.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui.primary_weapon_slot_panel.get_parent().name = "PrimaryWeaponRow"
	ui.secondary_weapon_slot_panel.get_parent().name = "SecondaryWeaponRow"
	var portrait_anchor = Control.new()
	portrait_anchor.name = "PortraitCenter"
	ui.portrait_container.add_child(portrait_anchor)
	portrait_anchor.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	portrait_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.portrait_anim_sprite.reparent(portrait_anchor, false)
	ui.portrait_anim_sprite.position = Vector2.ZERO
	var player = load("res://Scenes/Player/Player.tscn").instantiate()
	ui.portrait_anim_sprite.sprite_frames = player.get_node("AnimatedSprite2D").sprite_frames
	ui.portrait_anim_sprite.animation = &"idle_down"
	player.free()
	# Save button state styles to a theme instead of regenerating them in code.
	var inventory_theme = Theme.new()
	for entry in [["InventoryTab", ui.tab_codex_btn], ["InventoryTabActive", ui.tab_inventory_btn], ["InventorySecondary", ui.filter_all_btn], ["InventoryPrimary", ui.detail_equip_btn]]:
		inventory_theme.set_type_variation(entry[0], "Button")
		for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			inventory_theme.set_stylebox(style_name, entry[0], entry[1].get_theme_stylebox(style_name))
		for color_name in ["font_color", "font_hover_color"]:
			inventory_theme.set_color(color_name, entry[0], entry[1].get_theme_color(color_name))
	for state in ["empty", "normal", "hover", "selected", "equipped", "valid", "invalid"]:
		var style = StyleBoxTexture.new()
		style.texture = load("res://Art/Ui/svg/slot_%s.svg" % state)
		style.texture_margin_left = 16
		style.texture_margin_top = 16
		style.texture_margin_right = 16
		style.texture_margin_bottom = 16
		var variation = "InventorySlot" + state.to_pascal_case()
		inventory_theme.set_type_variation(variation, "PanelContainer")
		inventory_theme.set_stylebox("panel", variation, style)
	ResourceSaver.save(inventory_theme, "res://Art/Ui/inventory_theme.tres")
	ui.theme = inventory_theme
	for btn in [ui.tab_inventory_btn, ui.tab_codex_btn, ui.filter_all_btn, ui.filter_weapons_btn, ui.filter_body_btn, ui.detail_equip_btn, ui.detail_compare_btn] + ui.codex_category_buttons.values():
		for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			btn.remove_theme_stylebox_override(style_name)
		for color_name in ["font_color", "font_hover_color"]:
			btn.remove_theme_color_override(color_name)
		btn.theme_type_variation = "InventorySecondary"
	ui.tab_inventory_btn.theme_type_variation = "InventoryTabActive"
	ui.tab_codex_btn.theme_type_variation = "InventoryTab"
	ui.detail_equip_btn.theme_type_variation = "InventoryPrimary"
	# Attribute rows are fixed nodes; only their values change during play.
	var char_rows = [["Health", ui.tex_icon_health, "Vida máxima", "100"], ["Energy", ui.tex_icon_energy, "Energía", "0"], ["Armor", ui.tex_icon_armor, "Armadura", "0"]]
	var weapon_rows = [["Damage", ui.tex_icon_damage, "Daño", "10"], ["FireRate", ui.tex_icon_fire_rate, "Cadencia", "1.0/s"], ["Projectiles", ui.tex_icon_projectiles, "Proyectiles", "1"], ["CritChance", ui.tex_icon_critical, "Prob. crítica", "0%"], ["CritDamage", ui.tex_icon_critical, "Daño crítico", "x2.0"], ["ProjectileSpeed", ui.tex_icon_range, "Vel. Proyectil", "400"], ["Piercing", ui.tex_icon_pierce, "Perforación", "0"]]
	for pair in [[ui.stats_char_vbox, char_rows], [ui.stats_weapon_vbox, weapon_rows]]:
		for entry in pair[1]:
			ui._add_attribute_row(pair[0], entry[1], entry[2], entry[3], "+0")
			var row = pair[0].get_child(-1)
			row.name = entry[0]
			var names = ["Icon", "Caption", "Value", "Delta"]
			for index in range(row.get_child_count()): row.get_child(index).name = names[index]
			row.get_node("Delta").hide()
	for slot in ui.inventory_slots + ui.ui_slots:
		add_slot_content(slot)
		if slot.empty_icon_name != "":
			slot.get_node("Visuals/EmptyIcon").texture = load("res://Art/Ui/svg/%s.svg" % slot.empty_icon_name)
			slot.get_node("Visuals/EmptyIcon").show()
			slot.get_node("Visuals/EmptyText").hide()
		else:
			slot.get_node("Visuals/EmptyText").text = slot.empty_text
		# Keep the equipped state serialized even before the script exports it.
		slot.theme_type_variation = "InventorySlotEquipped" if slot.is_equipped_slot else "InventorySlotEmpty"
		slot.remove_theme_stylebox_override("panel")
	var template = PanelContainer.new()
	template.set_script(load("res://Scripts/Inventory/ui_slot.gd"))
	template.name = "InventorySlot"
	template.custom_minimum_size = Vector2(72, 72)
	template.theme = inventory_theme
	template.theme_type_variation = "InventorySlotEmpty"
	add_slot_content(template)
	prepare_tree(template, template, false)
	var slot_scene = PackedScene.new()
	assert(slot_scene.pack(template) == OK)
	assert(ResourceSaver.save(slot_scene, "res://Scenes/UI/inventory_slot.tscn") == OK)
	template.free()
	prepare_tree(ui, ui, true)
	var packed = PackedScene.new()
	assert(packed.pack(ui) == OK)
	assert(ResourceSaver.save(packed, "res://Scenes/UI/inventory_ui.tscn") == OK)
	var file = FileAccess.open("res://_inventory_bindings.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(bindings, "\t"))
	print("INVENTORY_MIGRATION_OK")
	quit()

func add_slot_content(slot: Control) -> void:
	var visuals = Control.new()
	visuals.name = "Visuals"
	visuals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(visuals)
	for name_text in ["EmptyIcon", "ItemIcon", "EquippedBadge"]:
		var icon = TextureRect.new()
		icon.name = name_text
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		visuals.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.hide()
		if name_text == "EmptyIcon": icon.modulate = Color(0.22, 0.38, 0.42, 0.5)
		if name_text == "ItemIcon":
			icon.offset_left = 8
			icon.offset_top = 8
			icon.offset_right = -8
			icon.offset_bottom = -8
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if name_text == "EquippedBadge":
			icon.texture = load("res://Art/Ui/svg/badge_equipped.svg")
			icon.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			icon.offset_left = -22
			icon.offset_top = -22
			icon.offset_right = -4
			icon.offset_bottom = -4
	for name_text in ["EmptyText", "ItemName", "Quantity"]:
		var label = Label.new()
		label.name = name_text
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.add_theme_font_size_override("font_size", 11)
		visuals.add_child(label)
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.visible = name_text == "EmptyText"
		if name_text == "EmptyText":
			label.text = "+"
			label.add_theme_color_override("font_color", Color(0.35, 0.45, 0.48))
		if name_text == "Quantity":
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			label.offset_right = -6
			label.offset_bottom = -4
			label.add_theme_font_size_override("font_size", 12)
			label.add_theme_color_override("font_color", Color(0.32, 0.85, 0.78))
			label.add_theme_color_override("font_outline_color", Color(0.09, 0.11, 0.13))
			label.add_theme_constant_override("outline_size", 3)

func prepare_tree(node: Node, owner_root: Node, persist: bool) -> void:
	if node != owner_root:
		node.owner = owner_root
		if str(node.name).begins_with("@"):
			var base = node.get_class()
			if node is Button and node.text == "Cerrar": base = "CloseButton"
			node.name = base
	if persist:
		for signal_info in node.get_signal_list():
			for connection in node.get_signal_connection_list(signal_info.name):
				var callback: Callable = connection.callable
				if callback.get_object() == ui:
					node.disconnect(signal_info.name, callback)
					if callback.get_method() in ["_position_paperdoll_node", "_center_portrait_sprite", "<anonymous lambda>"] or callback.is_custom() and str(callback.get_method()) == "": continue
					if ui.has_method(callback.get_method()): node.connect(signal_info.name, callback, CONNECT_PERSIST)
	for child in node.get_children(): prepare_tree(child, owner_root, persist)
