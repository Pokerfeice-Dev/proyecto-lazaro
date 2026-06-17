extends Node2D

@onready var area_2d: Area2D = get_node_or_null("Area2D")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var player_nearby: bool = false
var interact_label: Label = null
var ui_instance: CanvasLayer = null

func _ready() -> void:
	set_process_input(true)
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.body_exited.connect(_on_body_exited)
	_setup_interact_label()

func _setup_interact_label() -> void:
	interact_label = Label.new()
	interact_label.text = "[E] Terminal de Mejoras"
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	interact_label.add_theme_font_size_override("font_size", 16)
	interact_label.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0))
	interact_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interact_label.add_theme_constant_override("outline_size", 4)
	interact_label.position = Vector2(-80, -60)
	interact_label.visible = false
	add_child(interact_label)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if interact_label:
			interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if interact_label:
			interact_label.visible = false
		_close_upgrade_ui()

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
		
	var is_interact = event.is_action_pressed("interact")
	if not is_interact and event is InputEventKey:
		if event.physical_keycode == KEY_E and event.pressed and not event.echo:
			is_interact = true
			
	if is_interact and not ui_instance:
		_open_upgrade_ui()

func _open_upgrade_ui() -> void:
	get_tree().paused = true
	if interact_label:
		interact_label.visible = false
		
	ui_instance = CanvasLayer.new()
	ui_instance.name = "UpgradesMenu"
	ui_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_instance.layer = 220
	get_tree().root.add_child(ui_instance)
	
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_instance.add_child(bg)
	
	var main_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	sb.border_color = Color(0.12, 0.15, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	main_panel.add_theme_stylebox_override("panel", sb)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(main_panel)
	ui_instance.add_child(center)
	
	main_panel.custom_minimum_size = Vector2(1100, 700)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	main_panel.add_child(vbox)
	
	_build_header(vbox)
	_build_body(vbox)

func _build_header(parent: Control) -> void:
	var header = HBoxContainer.new()
	parent.add_child(header)
	
	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_vbox)
	
	var title = Label.new()
	title.text = "PROTOCOLO LÁZARO"
	title.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	title_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Terminal de mejoras permanentes y configuración de hardware"
	subtitle.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	title_vbox.add_child(subtitle)
	
	var scrap_lbl = Label.new()
	scrap_lbl.name = "ScrapLabel"
	scrap_lbl.text = "CHATARRA: " + str(GameData.scrap)
	scrap_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	scrap_lbl.add_theme_font_size_override("font_size", 22)
	scrap_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1))
	header.add_child(scrap_lbl)
	
	var close_btn = Button.new()
	close_btn.text = "VOLVER"
	close_btn.custom_minimum_size = Vector2(100, 36)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	close_btn.add_theme_font_size_override("font_size", 14)
	
	var sb_c_normal = StyleBoxFlat.new()
	sb_c_normal.bg_color = Color(0.2, 0.08, 0.08)
	sb_c_normal.border_color = Color(0.35, 0.1, 0.1)
	sb_c_normal.set_border_width_all(1)
	sb_c_normal.set_corner_radius_all(5)
	
	var sb_c_hover = StyleBoxFlat.new()
	sb_c_hover.bg_color = Color(0.28, 0.1, 0.1)
	sb_c_hover.border_color = Color(0.5, 0.15, 0.15)
	sb_c_hover.set_border_width_all(1)
	sb_c_hover.set_corner_radius_all(5)
	
	close_btn.add_theme_stylebox_override("normal", sb_c_normal)
	close_btn.add_theme_stylebox_override("hover", sb_c_hover)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	header.add_child(close_btn)
	close_btn.pressed.connect(_close_upgrade_ui)

func _build_body(parent: Control) -> void:
	var body_hbox = HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 24)
	parent.add_child(body_hbox)
	
	var sidebar_panel = PanelContainer.new()
	var sb_side = StyleBoxFlat.new()
	sb_side.bg_color = Color(0.04, 0.04, 0.05)
	sb_side.set_corner_radius_all(8)
	sb_side.content_margin_left = 10
	sb_side.content_margin_right = 10
	sb_side.content_margin_top = 15
	sb_side.content_margin_bottom = 15
	sidebar_panel.add_theme_stylebox_override("panel", sb_side)
	body_hbox.add_child(sidebar_panel)
	
	var sidebar = VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 12)
	sidebar_panel.add_child(sidebar)
	
	var content_panel = PanelContainer.new()
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb_cont = StyleBoxFlat.new()
	sb_cont.bg_color = Color(0.04, 0.04, 0.05)
	sb_cont.set_corner_radius_all(8)
	sb_cont.content_margin_left = 20
	sb_cont.content_margin_right = 20
	sb_cont.content_margin_top = 20
	sb_cont.content_margin_bottom = 20
	content_panel.add_theme_stylebox_override("panel", sb_cont)
	body_hbox.add_child(content_panel)
	
	var content_container = ScrollContainer.new()
	content_container.name = "ContentScroll"
	content_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_panel.add_child(content_container)
	
	var categories = ["ESTRUCTURA", "RECURSOS", "ARSENAL", "SINERGIAS", "PROTOCOLOS"]
	for cat in categories:
		var btn = Button.new()
		btn.text = cat
		btn.custom_minimum_size = Vector2(160, 48)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		btn.add_theme_font_size_override("font_size", 14)
		
		var sb_norm = StyleBoxFlat.new()
		sb_norm.bg_color = Color(0.08, 0.08, 0.1)
		sb_norm.border_color = Color(0.15, 0.15, 0.18)
		sb_norm.set_border_width_all(1)
		sb_norm.set_corner_radius_all(5)
		
		var sb_hov = StyleBoxFlat.new()
		sb_hov.bg_color = Color(0.12, 0.12, 0.16)
		sb_hov.border_color = Color(0.2, 0.6, 0.8)
		sb_hov.set_border_width_all(1)
		sb_hov.set_corner_radius_all(5)
		
		btn.add_theme_stylebox_override("normal", sb_norm)
		btn.add_theme_stylebox_override("hover", sb_hov)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		sidebar.add_child(btn)
		btn.pressed.connect(func(): _load_category(cat, content_container))
		
	_load_category("ESTRUCTURA", content_container)

func _update_scrap_label() -> void:
	if ui_instance:
		var scrap_lbl = ui_instance.find_child("ScrapLabel", true, false)
		if scrap_lbl is Label:
			scrap_lbl.text = "CHATARRA: " + str(GameData.scrap)

func _load_category(cat_name: String, scroll: ScrollContainer) -> void:
	# Clear old children
	for child in scroll.get_children():
		child.queue_free()
		
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 16)
	scroll.add_child(list_vbox)
	
	match cat_name:
		"ESTRUCTURA":
			_load_estructura(list_vbox)
		"RECURSOS":
			_load_recursos(list_vbox)
		"ARSENAL":
			_load_arsenal(list_vbox)
		"SINERGIAS":
			_load_sinergias(list_vbox)
		"PROTOCOLOS":
			_load_protocolos(list_vbox)

func _load_estructura(parent: Control) -> void:
	var upgrades = [
		{"key": "integridad_estructural", "name": "Integridad Estructural", "desc": "Aumenta la salud máxima permanentemente (+2 HP por nivel)", "max": 10, "value_desc": "+%d HP"},
		{"key": "servomotores", "name": "Servomotores", "desc": "Aumenta la velocidad de movimiento permanentemente (+1% por nivel)", "max": 10, "value_desc": "+%d%% Velocidad"},
		{"key": "blindaje_compuesto", "name": "Blindaje Compuesto", "desc": "Incrementa la defensa básica permanentemente (+0.2 Defensa por nivel)", "max": 10, "value_desc": "+%.1f Defensa"},
		{"key": "sistema_ataque", "name": "Sistema de Ataque", "desc": "Aumenta permanentemente el daño de todas las armas (+1% por nivel)", "max": 20, "value_desc": "+%d%% Daño"},
		{"key": "sinapsis_acelerada", "name": "Sinapsis Acelerada", "desc": "Aumenta permanentemente la velocidad de ataque (+1% por nivel)", "max": 20, "value_desc": "+%d%% Vel. Ataque"},
		{"key": "balistica_predictiva", "name": "Balística Predictiva", "desc": "Aumenta la probabilidad de impacto crítico permanentemente (+0.5% por nivel)", "max": 10, "value_desc": "+%.1f%% Crítico"}
	]
	_build_leveled_upgrades(parent, upgrades)

func _load_recursos(parent: Control) -> void:
	var upgrades = [
		{"key": "compactador", "name": "Compactador", "desc": "Incrementa la Chatarra obtenida en combate (+2% por nivel)", "max": 20, "value_desc": "+%d%% Chatarra"},
		{"key": "biomasa_eficiente", "name": "Biomasa Eficiente", "desc": "Incrementa la Carne obtenida al derrotar enemigos (+2% por nivel)", "max": 20, "value_desc": "+%d%% Carne"},
		{"key": "imanes_industriales", "name": "Imanes Industriales", "desc": "Aumenta el radio de atracción de chatarra/carne (+5% por nivel)", "max": 10, "value_desc": "+%d%% Radio"},
		{"key": "recuperacion_restos", "name": "Recuperación de Restos", "desc": "Aumenta la probabilidad de caída de objetos y carne (+1% por nivel)", "max": 15, "value_desc": "+%d%% Drop"},
		{"key": "escaner_objetivos", "name": "Escáner de Objetivos", "desc": "Aumenta la probabilidad de aparición de enemigos Élite (+1% por nivel)", "max": 10, "value_desc": "+%d%% Élites"}
	]
	_build_leveled_upgrades(parent, upgrades)

func _build_leveled_upgrades(parent: Control, upgrades: Array) -> void:
	for up in upgrades:
		var current_lvl = GameData.core_upgrades.get(up.key, 0)
		var next_lvl = current_lvl + 1
		var cost = next_lvl * 50
		
		# Upgrade Card Panel
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.08, 0.08, 0.1)
		card_sb.border_color = Color(0.15, 0.15, 0.2)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left = 16
		card_sb.content_margin_right = 16
		card_sb.content_margin_top = 12
		card_sb.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", card_sb)
		parent.add_child(card)
		
		var card_hbox = HBoxContainer.new()
		card.add_child(card_hbox)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_hbox.add_child(text_vbox)
		
		# Title & Level
		var name_lbl = Label.new()
		name_lbl.text = up.name.to_upper() + "  (Nivel %d / %d)" % [current_lvl, up.max]
		name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		text_vbox.add_child(name_lbl)
		
		# Description
		var desc_lbl = Label.new()
		desc_lbl.text = up.desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		text_vbox.add_child(desc_lbl)
		
		# Values description
		var value_lbl = Label.new()
		if up.key == "blindaje_compuesto":
			value_lbl.text = "Bono actual: " + (up.value_desc % (current_lvl * 0.2))
		elif up.key == "balistica_predictiva":
			value_lbl.text = "Bono actual: " + (up.value_desc % (current_lvl * 0.5))
		elif up.key == "imanes_industriales":
			value_lbl.text = "Bono actual: " + (up.value_desc % (current_lvl * 5))
		else:
			var mul = 2 if (up.key == "compactador" or up.key == "biomasa_eficiente") else 1
			value_lbl.text = "Bono actual: " + (up.value_desc % (current_lvl * mul))
		value_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		value_lbl.add_theme_font_size_override("font_size", 12)
		value_lbl.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3) if current_lvl > 0 else Color(0.4, 0.4, 0.4))
		text_vbox.add_child(value_lbl)
		
		# Buy Button VBox
		var btn_vbox = VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_hbox.add_child(btn_vbox)
		
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(160, 40)
		buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		buy_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		buy_btn.add_theme_font_size_override("font_size", 14)
		
		var sb_b_norm = StyleBoxFlat.new()
		sb_b_norm.bg_color = Color(0.1, 0.22, 0.15)
		sb_b_norm.border_color = Color(0.15, 0.35, 0.2)
		sb_b_norm.set_border_width_all(1)
		sb_b_norm.set_corner_radius_all(4)
		
		var sb_b_hov = StyleBoxFlat.new()
		sb_b_hov.bg_color = Color(0.12, 0.28, 0.2)
		sb_b_hov.border_color = Color(0.2, 0.5, 0.3)
		sb_b_hov.set_border_width_all(1)
		sb_b_hov.set_corner_radius_all(4)
		
		var sb_b_dis = StyleBoxFlat.new()
		sb_b_dis.bg_color = Color(0.06, 0.06, 0.08)
		sb_b_dis.border_color = Color(0.12, 0.12, 0.15)
		sb_b_dis.set_border_width_all(1)
		sb_b_dis.set_corner_radius_all(4)
		
		buy_btn.add_theme_stylebox_override("normal", sb_b_norm)
		buy_btn.add_theme_stylebox_override("hover", sb_b_hov)
		buy_btn.add_theme_stylebox_override("disabled", sb_b_dis)
		buy_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn_vbox.add_child(buy_btn)
		
		if current_lvl >= up.max:
			buy_btn.text = "MÁXIMO"
			buy_btn.disabled = true
			buy_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			buy_btn.text = "MEJORAR (%d⚙)" % cost
			if GameData.scrap < cost:
				buy_btn.disabled = true
				buy_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				buy_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
			else:
				buy_btn.pressed.connect(func(): _buy_leveled_upgrade(up.key, cost, parent))

func _buy_leveled_upgrade(key: String, cost: int, parent_container: Control) -> void:
	if GameData.spend_scrap(cost):
		GameData.core_upgrades[key] += 1
		GameData.save_game()
		_update_scrap_label()
		# Reload list
		var scroll = parent_container.get_parent()
		if scroll is ScrollContainer:
			var cat = "ESTRUCTURA" if key in ["integridad_estructural", "servomotores", "blindaje_compuesto", "sistema_ataque", "sinapsis_acelerada", "balistica_predictiva"] else "RECURSOS"
			_load_category(cat, scroll)

func _load_arsenal(parent: Control) -> void:
	var weapons = [
		{"id": "hacha", "name": "Hacha de Mano", "desc": "Arma Melee: Ataques de tajo amplios y poderosos.", "cost": 300},
		{"id": "maze", "name": "Maza Pesada", "desc": "Arma Melee: Impactos contundentes de gran alcance y empuje.", "cost": 300},
		{"id": "uzi", "name": "Uzi", "desc": "Arma Distancia: Ráfagas de alta cadencia de fuego a corta distancia.", "cost": 500},
		{"id": "shotgun", "name": "Escopeta", "desc": "Arma Distancia: Fuego devastador con dispersión cónica.", "cost": 500}
	]
	
	for w in weapons:
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.08, 0.08, 0.1)
		card_sb.border_color = Color(0.15, 0.15, 0.2)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left = 16
		card_sb.content_margin_right = 16
		card_sb.content_margin_top = 12
		card_sb.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", card_sb)
		parent.add_child(card)
		
		var card_hbox = HBoxContainer.new()
		card.add_child(card_hbox)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_hbox.add_child(text_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = w.name.to_upper()
		name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		text_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = w.desc
		desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		text_vbox.add_child(desc_lbl)
		
		var is_unlocked = GameData.is_codex_unlocked("weapons", w.id)
		
		var btn_vbox = VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_hbox.add_child(btn_vbox)
		
		var unlock_btn = Button.new()
		unlock_btn.custom_minimum_size = Vector2(160, 40)
		unlock_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		unlock_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		unlock_btn.add_theme_font_size_override("font_size", 14)
		
		var sb_b_norm = StyleBoxFlat.new()
		sb_b_norm.bg_color = Color(0.1, 0.22, 0.15)
		sb_b_norm.border_color = Color(0.15, 0.35, 0.2)
		sb_b_norm.set_border_width_all(1)
		sb_b_norm.set_corner_radius_all(4)
		
		var sb_b_hov = StyleBoxFlat.new()
		sb_b_hov.bg_color = Color(0.12, 0.28, 0.2)
		sb_b_hov.border_color = Color(0.2, 0.5, 0.3)
		sb_b_hov.set_border_width_all(1)
		sb_b_hov.set_corner_radius_all(4)
		
		var sb_b_dis = StyleBoxFlat.new()
		sb_b_dis.bg_color = Color(0.06, 0.06, 0.08)
		sb_b_dis.border_color = Color(0.12, 0.12, 0.15)
		sb_b_dis.set_border_width_all(1)
		sb_b_dis.set_corner_radius_all(4)
		
		unlock_btn.add_theme_stylebox_override("normal", sb_b_norm)
		unlock_btn.add_theme_stylebox_override("hover", sb_b_hov)
		unlock_btn.add_theme_stylebox_override("disabled", sb_b_dis)
		unlock_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn_vbox.add_child(unlock_btn)
		
		if is_unlocked:
			unlock_btn.text = "DESBLOQUEADA"
			unlock_btn.disabled = true
			unlock_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		else:
			unlock_btn.text = "DESBLOQUEAR (%d⚙)" % w.cost
			if GameData.scrap < w.cost:
				unlock_btn.disabled = true
				unlock_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				unlock_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
			else:
				unlock_btn.pressed.connect(func(): _buy_weapon_unlock(w.id, w.cost, parent))

func _buy_weapon_unlock(weapon_id: String, cost: int, parent_container: Control) -> void:
	if GameData.spend_scrap(cost):
		GameData.unlock_codex_entry("weapons", weapon_id)
		GameData.save_game()
		_update_scrap_label()
		var scroll = parent_container.get_parent()
		if scroll is ScrollContainer:
			_load_category("ARSENAL", scroll)

func _load_sinergias(parent: Control) -> void:
	var synergies = [
		{"id": "pistola_mente_colmena", "name": "Pistola Mente Colmena", "desc": "Las balas de la pistola son reemplazadas por abejas teledirigidas.", "cost": 300},
		{"id": "roadkill", "name": "Roadkill", "desc": "Las balas rebotan en las paredes y enemigos.", "cost": 300},
		{"id": "bestia_de_caza", "name": "Bestia de Caza", "desc": "Dash activa furia, otorga un bonus del 50% de velocidad melee y ataque de área.", "cost": 500},
		{"id": "trituradora_biomecanica", "name": "Trituradora Biomecánica", "desc": "Acumulas energía de impacto al moverte. Dash genera onda de choque.", "cost": 500}
	]
	
	# Determine if Mente Colmena AND Roadkill are unlocked
	var mc_unlocked = GameData.is_synergy_unlocked("pistola_mente_colmena")
	var rk_unlocked = GameData.is_synergy_unlocked("roadkill")
	var advanced_synergies_available = mc_unlocked and rk_unlocked
	
	for s in synergies:
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.08, 0.08, 0.1)
		card_sb.border_color = Color(0.15, 0.15, 0.2)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left = 16
		card_sb.content_margin_right = 16
		card_sb.content_margin_top = 12
		card_sb.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", card_sb)
		parent.add_child(card)
		
		var card_hbox = HBoxContainer.new()
		card.add_child(card_hbox)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_hbox.add_child(text_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = s.name.to_upper()
		name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		text_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = s.desc
		desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		text_vbox.add_child(desc_lbl)
		
		var is_unlocked = GameData.is_synergy_unlocked(s.id)
		var is_locked_advanced = (s.id in ["bestia_de_caza", "trituradora_biomecanica"]) and not advanced_synergies_available
		
		var btn_vbox = VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_hbox.add_child(btn_vbox)
		
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(160, 40)
		buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		buy_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		buy_btn.add_theme_font_size_override("font_size", 14)
		
		var sb_b_norm = StyleBoxFlat.new()
		sb_b_norm.bg_color = Color(0.1, 0.22, 0.15)
		sb_b_norm.border_color = Color(0.15, 0.35, 0.2)
		sb_b_norm.set_border_width_all(1)
		sb_b_norm.set_corner_radius_all(4)
		
		var sb_b_hov = StyleBoxFlat.new()
		sb_b_hov.bg_color = Color(0.12, 0.28, 0.2)
		sb_b_hov.border_color = Color(0.2, 0.5, 0.3)
		sb_b_hov.set_border_width_all(1)
		sb_b_hov.set_corner_radius_all(4)
		
		var sb_b_dis = StyleBoxFlat.new()
		sb_b_dis.bg_color = Color(0.06, 0.06, 0.08)
		sb_b_dis.border_color = Color(0.12, 0.12, 0.15)
		sb_b_dis.set_border_width_all(1)
		sb_b_dis.set_corner_radius_all(4)
		
		buy_btn.add_theme_stylebox_override("normal", sb_b_norm)
		buy_btn.add_theme_stylebox_override("hover", sb_b_hov)
		buy_btn.add_theme_stylebox_override("disabled", sb_b_dis)
		buy_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn_vbox.add_child(buy_btn)
		
		if is_unlocked:
			buy_btn.text = "DESBLOQUEADA"
			buy_btn.disabled = true
			buy_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
		elif is_locked_advanced:
			buy_btn.text = "BLOQUEADO"
			buy_btn.disabled = true
			buy_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			desc_lbl.text = "Requiere desbloquear Mente Colmena y Roadkill"
			desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.2, 0.2))
		else:
			buy_btn.text = "DESBLOQUEAR (%d⚙)" % s.cost
			if GameData.scrap < s.cost:
				buy_btn.disabled = true
				buy_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				buy_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
			else:
				buy_btn.pressed.connect(func(): _buy_synergy_unlock(s.id, s.cost, parent))

func _buy_synergy_unlock(syn_id: String, cost: int, parent_container: Control) -> void:
	if GameData.spend_scrap(cost):
		if not GameData.unlocked_synergies.has(syn_id):
			GameData.unlocked_synergies.append(syn_id)
		GameData.save_game()
		_update_scrap_label()
		var scroll = parent_container.get_parent()
		if scroll is ScrollContainer:
			_load_category("SINERGIAS", scroll)

func _load_protocolos(parent: Control) -> void:
	var protocols = [
		{"id": "circuito_emergencia", "name": "Circuito de Emergencia", "desc": "Primer golpe de cada sala: -30% daño recibido.", "cost": 400},
		{"id": "reparacion_autonoma", "name": "Reparación Autónoma", "desc": "Al limpiar una sala: +1 HP.", "cost": 500},
		{"id": "nucleo_vampirico", "name": "Núcleo Vampírico", "desc": "Cada 25 enemigos derrotados: +2 HP.", "cost": 600},
		{"id": "sobrecarga", "name": "Sobrecarga", "desc": "Al entrar a una sala: +10% daño durante 5 segundos.", "cost": 700},
		{"id": "reflejo_sintetico", "name": "Reflejo Sintético", "desc": "Después de un dash: dejas una copia holográfica que dispara una vez.", "cost": 800},
		{"id": "enjambre_residual", "name": "Enjambre Residual", "desc": "Comenzás cada run con una abeja mecánica aliada.", "cost": 900},
		{"id": "blindaje_reactivo", "name": "Blindaje Reactivo", "desc": "Al recibir daño: ganás +2 defensa durante 3 segundos.", "cost": 900},
		{"id": "furia_de_titanio", "name": "Furia de Titanio", "desc": "Al bajar de 30% HP: +25% velocidad de ataque.", "cost": 1000},
		{"id": "reciclaje_instantaneo", "name": "Reciclaje Instantáneo", "desc": "Cada jefe derrotado: ganás 50 Chatarra extra.", "cost": 1200}
	]
	
	for p in protocols:
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.08, 0.08, 0.1)
		card_sb.border_color = Color(0.15, 0.15, 0.2)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(6)
		card_sb.content_margin_left = 16
		card_sb.content_margin_right = 16
		card_sb.content_margin_top = 12
		card_sb.content_margin_bottom = 12
		
		var is_active = (GameData.active_protocol == p.id)
		if is_active:
			card_sb.border_color = Color(0.2, 0.7, 1.0)
			card_sb.set_border_width_all(2)
			
		card.add_theme_stylebox_override("panel", card_sb)
		parent.add_child(card)
		
		var card_hbox = HBoxContainer.new()
		card.add_child(card_hbox)
		
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_hbox.add_child(text_vbox)
		
		var name_lbl = Label.new()
		name_lbl.text = p.name.to_upper()
		if is_active:
			name_lbl.text += "  [ACTIVO]"
		name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0) if is_active else Color.WHITE)
		text_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = p.desc
		desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		text_vbox.add_child(desc_lbl)
		
		var is_unlocked = GameData.unlocked_protocols.has(p.id)
		
		var btn_vbox = VBoxContainer.new()
		btn_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_hbox.add_child(btn_vbox)
		
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(160, 40)
		action_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		action_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
		action_btn.add_theme_font_size_override("font_size", 14)
		
		var sb_b_norm = StyleBoxFlat.new()
		sb_b_norm.bg_color = Color(0.1, 0.22, 0.15) if not is_unlocked else Color(0.12, 0.18, 0.25)
		sb_b_norm.border_color = Color(0.15, 0.35, 0.2) if not is_unlocked else Color(0.2, 0.3, 0.4)
		sb_b_norm.set_border_width_all(1)
		sb_b_norm.set_corner_radius_all(4)
		
		var sb_b_hov = StyleBoxFlat.new()
		sb_b_hov.bg_color = Color(0.12, 0.28, 0.2) if not is_unlocked else Color(0.15, 0.24, 0.35)
		sb_b_hov.border_color = Color(0.2, 0.5, 0.3) if not is_unlocked else Color(0.3, 0.5, 0.7)
		sb_b_hov.set_border_width_all(1)
		sb_b_hov.set_corner_radius_all(4)
		
		var sb_b_dis = StyleBoxFlat.new()
		sb_b_dis.bg_color = Color(0.06, 0.06, 0.08)
		sb_b_dis.border_color = Color(0.12, 0.12, 0.15)
		sb_b_dis.set_border_width_all(1)
		sb_b_dis.set_corner_radius_all(4)
		
		action_btn.add_theme_stylebox_override("normal", sb_b_norm)
		action_btn.add_theme_stylebox_override("hover", sb_b_hov)
		action_btn.add_theme_stylebox_override("disabled", sb_b_dis)
		action_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn_vbox.add_child(action_btn)
		
		if is_unlocked:
			if is_active:
				action_btn.text = "DESACTIVAR"
				action_btn.pressed.connect(func(): _deactivate_protocol(parent))
			else:
				action_btn.text = "EQUIPAR"
				action_btn.pressed.connect(func(): _equip_protocol(p.id, parent))
		else:
			action_btn.text = "DESBLOQUEAR (%d⚙)" % p.cost
			if GameData.scrap < p.cost:
				action_btn.disabled = true
				action_btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				action_btn.add_theme_color_override("font_color", Color(0.5, 0.3, 0.3))
			else:
				action_btn.pressed.connect(func(): _buy_protocol_unlock(p.id, p.cost, parent))

func _buy_protocol_unlock(proto_id: String, cost: int, parent_container: Control) -> void:
	if GameData.spend_scrap(cost):
		if not GameData.unlocked_protocols.has(proto_id):
			GameData.unlocked_protocols.append(proto_id)
		GameData.save_game()
		_update_scrap_label()
		var scroll = parent_container.get_parent()
		if scroll is ScrollContainer:
			_load_category("PROTOCOLOS", scroll)

func _equip_protocol(proto_id: String, parent_container: Control) -> void:
	GameData.active_protocol = proto_id
	GameData.save_game()
	var scroll = parent_container.get_parent()
	if scroll is ScrollContainer:
		_load_category("PROTOCOLOS", scroll)

func _deactivate_protocol(parent_container: Control) -> void:
	GameData.active_protocol = ""
	GameData.save_game()
	var scroll = parent_container.get_parent()
	if scroll is ScrollContainer:
		_load_category("PROTOCOLOS", scroll)

func _close_upgrade_ui() -> void:
	if ui_instance:
		ui_instance.queue_free()
		ui_instance = null
		get_tree().paused = false
		if interact_label:
			interact_label.visible = player_nearby
