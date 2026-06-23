extends Control

@onready var container = VBoxContainer.new()

func _ready() -> void:
	_setup_ui()
	_populate_slots()

func _setup_ui() -> void:
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.add_theme_constant_override("separation", 20)
	container.offset_top = -100
	add_child(container)
	
	var back_btn = Button.new()
	back_btn.text = "Volver"
	back_btn.add_theme_font_size_override("font_size", 32)
	back_btn.custom_minimum_size = Vector2(300, 60)
	back_btn.pressed.connect(func(): SceneTransition.change_scene("res://Scenes/UI/MainMenu.tscn"))
	
	var bottom_box = MarginContainer.new()
	bottom_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_box.add_theme_constant_override("margin_bottom", 40)
	var center = CenterContainer.new()
	center.add_child(back_btn)
	bottom_box.add_child(center)
	add_child(bottom_box)

func _populate_slots() -> void:
	for child in container.get_children():
		child.queue_free()

	for i in range(1, 4):
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(500, 100)
		
		var info = GameData.get_slot_info(i)
		if info.exists:
			var time_str = GameData.format_time(info.play_time)
			var last_save = info.get("last_save_time", "")
			if last_save == "":
				last_save = "--/--/----"
			slot_btn.text = "Slot %d - %s\nNivel Máx: %d-%d | Despliegues: %d\nGuardado: (%s)" % [
				i,
				time_str,
				info.get("max_reached_level", 1),
				info.get("max_reached_room", 1),
				info.get("total_deployments", 0),
				last_save
			]
		else:
			slot_btn.text = "Slot %d - Vacío" % i
			
		slot_btn.add_theme_font_size_override("font_size", 16)
		slot_btn.pressed.connect(_on_slot_selected.bind(i, info.exists))
		hbox.add_child(slot_btn)
		
		if info.exists:
			var del_btn = Button.new()
			del_btn.text = "Eliminar"
			del_btn.add_theme_font_size_override("font_size", 24)
			del_btn.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			del_btn.custom_minimum_size = Vector2(120, 100)
			del_btn.pressed.connect(_on_delete_slot.bind(i))
			hbox.add_child(del_btn)
			
		container.add_child(hbox)

func _on_delete_slot(slot: int) -> void:
	GameData.delete_save(slot)
	_populate_slots()

func _on_slot_selected(slot: int, exists: bool) -> void:
	if exists:
		GameData.load_game(slot)
		SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
	else:
		_show_tutorial_prompt(slot)

func _show_tutorial_prompt(slot: int) -> void:
	var popup = CanvasLayer.new()
	popup.layer = 100
	
	# Full-screen Control root to ensure layout is calculated correctly
	var root_control = Control.new()
	root_control.anchor_left = 0.0
	root_control.anchor_top = 0.0
	root_control.anchor_right = 1.0
	root_control.anchor_bottom = 1.0
	root_control.offset_left = 0.0
	root_control.offset_top = 0.0
	root_control.offset_right = 0.0
	root_control.offset_bottom = 0.0
	popup.add_child(root_control)
	
	# Background dimming
	var bg = ColorRect.new()
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 0.0
	bg.offset_bottom = 0.0
	bg.color = Color(0, 0, 0, 0.75)
	root_control.add_child(bg)
	
	# Main panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 200)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.pivot_offset = Vector2(200, 100)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	sb.border_color = Color(0.0, 0.8, 0.5, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	root_control.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "¿Quieres hacer el tutorial?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0, 1, 0.8))
	vbox.add_child(title)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	# Yes button
	var yes_btn = Button.new()
	yes_btn.text = "Si"
	yes_btn.custom_minimum_size = Vector2(120, 40)
	yes_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	yes_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	yes_btn.add_theme_font_size_override("font_size", 16)
	
	# No button
	var no_btn = Button.new()
	no_btn.text = "No, soy un capo"
	no_btn.custom_minimum_size = Vector2(180, 40)
	no_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	no_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	no_btn.add_theme_font_size_override("font_size", 16)
	
	# Styles for buttons
	var sb_yes_norm = StyleBoxFlat.new()
	sb_yes_norm.bg_color = Color(0.1, 0.3, 0.2)
	sb_yes_norm.set_border_width_all(1)
	sb_yes_norm.border_color = Color(0.15, 0.5, 0.3)
	sb_yes_norm.set_corner_radius_all(6)
	
	var sb_yes_hov = StyleBoxFlat.new()
	sb_yes_hov.bg_color = Color(0.15, 0.5, 0.3)
	sb_yes_hov.set_border_width_all(1)
	sb_yes_hov.border_color = Color(0.2, 0.7, 0.4)
	sb_yes_hov.set_corner_radius_all(6)
	
	var sb_no_norm = StyleBoxFlat.new()
	sb_no_norm.bg_color = Color(0.3, 0.1, 0.1)
	sb_no_norm.set_border_width_all(1)
	sb_no_norm.border_color = Color(0.5, 0.15, 0.15)
	sb_no_norm.set_corner_radius_all(6)
	
	var sb_no_hov = StyleBoxFlat.new()
	sb_no_hov.bg_color = Color(0.5, 0.15, 0.15)
	sb_no_hov.set_border_width_all(1)
	sb_no_hov.border_color = Color(0.7, 0.2, 0.2)
	sb_no_hov.set_corner_radius_all(6)
	
	yes_btn.add_theme_stylebox_override("normal", sb_yes_norm)
	yes_btn.add_theme_stylebox_override("hover", sb_yes_hov)
	no_btn.add_theme_stylebox_override("normal", sb_no_norm)
	no_btn.add_theme_stylebox_override("hover", sb_no_hov)
	
	yes_btn.pressed.connect(func():
		GameData.reset_data()
		GameData.current_slot = slot
		GameData.save_game(slot)
		popup.queue_free()
		SceneTransition.change_scene("res://Scenes/Rooms/training_room.tscn")
	)
	
	no_btn.pressed.connect(func():
		GameData.reset_data()
		GameData.current_slot = slot
		GameData.save_game(slot)
		popup.queue_free()
		SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
	)
	
	hbox.add_child(yes_btn)
	hbox.add_child(no_btn)
	
	add_child(popup)
