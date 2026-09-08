extends Node
class_name WeaponSelectionMenu

## Popup de selección de arma primaria/secundaria, reutilizable. Nació como
## parte de door.gd (la puerta de inicio de run) y se separó acá para poder
## mostrarlo también desde la sala de entrenamiento sin duplicar ~250 líneas
## de UI. La lógica y el look son idénticos al original; lo único que cambia
## por caller es el texto y qué pasa al confirmar/cancelar.

## Muestra el popup. "caller" es cualquier Node dentro del árbol (se usa
## solo para llegar a get_tree()). "on_confirm" recibe el diccionario final
## {"primary": id, "melee": id} después de guardarlo en GameData; "on_cancel"
## se llama si el jugador cancela. Ambos son opcionales.
static func show_popup(caller: Node, title_text: String, subtitle_text: String, confirm_text: String, on_confirm: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	var tree = caller.get_tree()
	tree.paused = true

	var canvas = CanvasLayer.new()
	canvas.name = "WeaponSelectionMenu"
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.layer = 250
	tree.root.add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	sb.border_color = Color(0.2, 0.6, 0.8, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 35
	sb.content_margin_right = 35
	sb.content_margin_top = 25
	sb.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 24)
	panel.add_child(main_vbox)

	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0))
	main_vbox.add_child(title)

	var sub = Label.new()
	sub.text = subtitle_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	main_vbox.add_child(sub)

	var cols_hbox = HBoxContainer.new()
	cols_hbox.add_theme_constant_override("separation", 40)
	main_vbox.add_child(cols_hbox)

	var selections = {
		"primary": GameData.chosen_primary_weapon,
		"melee": GameData.chosen_melee_weapon
	}

	# Primary column
	var prim_vbox = VBoxContainer.new()
	prim_vbox.add_theme_constant_override("separation", 12)
	cols_hbox.add_child(prim_vbox)

	var prim_title = Label.new()
	prim_title.text = "DISTANCIA (PRIMARIA)"
	prim_title.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	prim_title.add_theme_font_size_override("font_size", 16)
	prim_title.add_theme_color_override("font_color", Color.WHITE)
	prim_vbox.add_child(prim_title)

	# Melee column
	var melee_vbox = VBoxContainer.new()
	melee_vbox.add_theme_constant_override("separation", 12)
	cols_hbox.add_child(melee_vbox)

	var melee_title = Label.new()
	melee_title.text = "MELEE (SECUNDARIA)"
	melee_title.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	melee_title.add_theme_font_size_override("font_size", 16)
	melee_title.add_theme_color_override("font_color", Color.WHITE)
	melee_vbox.add_child(melee_title)

	var prim_btn_group = ButtonGroup.new()
	var melee_btn_group = ButtonGroup.new()

	var prim_weapons = [
		{"id": "pistol", "name": "Pistola Base", "desc": "Precisión y cadencia estable"},
		{"id": "uzi", "name": "Uzi", "desc": "Fuego rápido a corta distancia"},
		{"id": "shotgun", "name": "Escopeta", "desc": "Gran dispersión a quemarropa"}
	]
	var melee_weapons = [
		{"id": "daga", "name": "Daga Base", "desc": "Cortes veloces de corto alcance"},
		{"id": "hacha", "name": "Hacha de Mano", "desc": "Ataques potentes de rango medio"},
		{"id": "maze", "name": "Maza Pesada", "desc": "Lento con gran fuerza de empuje"}
	]

	# Styles
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.12, 0.15)
	sb_normal.border_color = Color(0.2, 0.2, 0.25)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(6)
	sb_normal.content_margin_left = 12
	sb_normal.content_margin_right = 12
	sb_normal.content_margin_top = 8
	sb_normal.content_margin_bottom = 8

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.16, 0.16, 0.2)
	sb_hover.border_color = Color(0.3, 0.6, 0.8)
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(6)

	var sb_pressed = StyleBoxFlat.new()
	sb_pressed.bg_color = Color(0.1, 0.22, 0.32)
	sb_pressed.border_color = Color(0.2, 0.7, 1.0)
	sb_pressed.set_border_width_all(2)
	sb_pressed.set_corner_radius_all(6)

	var sb_disabled = StyleBoxFlat.new()
	sb_disabled.bg_color = Color(0.05, 0.05, 0.06)
	sb_disabled.border_color = Color(0.1, 0.1, 0.12)
	sb_disabled.set_border_width_all(1)
	sb_disabled.set_corner_radius_all(6)

	# Spawn Primaries
	for w in prim_weapons:
		var btn = Button.new()
		btn.toggle_mode = true
		btn.button_group = prim_btn_group
		btn.custom_minimum_size = Vector2(300, 64)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_stylebox_override("normal", sb_normal)
		btn.add_theme_stylebox_override("hover", sb_hover)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_stylebox_override("disabled", sb_disabled)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		var box = VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(box)

		var name_lbl = Label.new()
		name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		name_lbl.add_theme_font_size_override("font_size", 14)
		box.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		box.add_child(desc_lbl)

		var is_unlocked = GameData.is_codex_unlocked("weapons", w.id)
		if is_unlocked:
			name_lbl.text = w.name
			name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			desc_lbl.text = w.desc
			desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

			btn.pressed.connect(func(): selections.primary = w.id)
			if selections.primary == w.id:
				btn.button_pressed = true
		else:
			btn.disabled = true
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			name_lbl.text = "🔒 " + w.name + " (Bloqueada)"
			name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			desc_lbl.text = "Desbloquéala en el terminal de chatarra"
			desc_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

		prim_vbox.add_child(btn)

	# Spawn Melees
	for w in melee_weapons:
		var btn = Button.new()
		btn.toggle_mode = true
		btn.button_group = melee_btn_group
		btn.custom_minimum_size = Vector2(300, 64)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_stylebox_override("normal", sb_normal)
		btn.add_theme_stylebox_override("hover", sb_hover)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_stylebox_override("disabled", sb_disabled)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		var box = VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.set_anchors_preset(Control.PRESET_FULL_RECT)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(box)

		var name_lbl = Label.new()
		name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		name_lbl.add_theme_font_size_override("font_size", 14)
		box.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		box.add_child(desc_lbl)

		var is_unlocked = GameData.is_codex_unlocked("weapons", w.id)
		if is_unlocked:
			name_lbl.text = w.name
			name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
			desc_lbl.text = w.desc
			desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

			btn.pressed.connect(func(): selections.melee = w.id)
			if selections.melee == w.id:
				btn.button_pressed = true
		else:
			btn.disabled = true
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			name_lbl.text = "🔒 " + w.name + " (Bloqueada)"
			name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			desc_lbl.text = "Desbloquéala en el terminal de chatarra"
			desc_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

		melee_vbox.add_child(btn)

	# Action Buttons
	var act_hbox = HBoxContainer.new()
	act_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	act_hbox.add_theme_constant_override("separation", 24)
	main_vbox.add_child(act_hbox)

	# Cancel
	var btn_cancel = Button.new()
	btn_cancel.text = "CANCELAR"
	btn_cancel.custom_minimum_size = Vector2(140, 42)
	btn_cancel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_cancel.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	btn_cancel.add_theme_font_size_override("font_size", 16)

	var sb_c_normal = StyleBoxFlat.new()
	sb_c_normal.bg_color = Color(0.18, 0.1, 0.1)
	sb_c_normal.border_color = Color(0.3, 0.15, 0.15)
	sb_c_normal.set_border_width_all(1)
	sb_c_normal.set_corner_radius_all(5)

	var sb_c_hover = StyleBoxFlat.new()
	sb_c_hover.bg_color = Color(0.24, 0.12, 0.12)
	sb_c_hover.border_color = Color(0.45, 0.2, 0.2)
	sb_c_hover.set_border_width_all(1)
	sb_c_hover.set_corner_radius_all(5)

	btn_cancel.add_theme_stylebox_override("normal", sb_c_normal)
	btn_cancel.add_theme_stylebox_override("hover", sb_c_hover)
	btn_cancel.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	act_hbox.add_child(btn_cancel)

	btn_cancel.pressed.connect(func():
		tree.paused = false
		canvas.queue_free()
		if on_cancel.is_valid():
			on_cancel.call()
	)

	# Confirm
	var btn_confirm = Button.new()
	btn_confirm.text = confirm_text
	btn_confirm.custom_minimum_size = Vector2(220, 42)
	btn_confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_confirm.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	btn_confirm.add_theme_font_size_override("font_size", 16)

	var sb_ok_normal = StyleBoxFlat.new()
	sb_ok_normal.bg_color = Color(0.1, 0.3, 0.2)
	sb_ok_normal.border_color = Color(0.15, 0.45, 0.3)
	sb_ok_normal.set_border_width_all(1)
	sb_ok_normal.set_corner_radius_all(5)

	var sb_ok_hover = StyleBoxFlat.new()
	sb_ok_hover.bg_color = Color(0.12, 0.38, 0.25)
	sb_ok_hover.border_color = Color(0.2, 0.6, 0.4)
	sb_ok_hover.set_border_width_all(1)
	sb_ok_hover.set_corner_radius_all(5)

	btn_confirm.add_theme_stylebox_override("normal", sb_ok_normal)
	btn_confirm.add_theme_stylebox_override("hover", sb_ok_hover)
	btn_confirm.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	act_hbox.add_child(btn_confirm)

	btn_confirm.pressed.connect(func():
		GameData.chosen_primary_weapon = selections.primary
		GameData.chosen_melee_weapon = selections.melee
		GameData.save_game()

		tree.paused = false
		canvas.queue_free()

		if on_confirm.is_valid():
			on_confirm.call(selections)
	)
