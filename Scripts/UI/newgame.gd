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
			slot_btn.text = "Slot %d - %s\nScrap: %d" % [i, time_str, info.scrap]
		else:
			slot_btn.text = "Slot %d - Vacío" % i
			
		slot_btn.add_theme_font_size_override("font_size", 28)
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
	else:
		GameData.reset_data()
		GameData.current_slot = slot
		GameData.save_game(slot)
		
	SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
