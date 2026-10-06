extends Area2D
class_name SynergyTerminal

## Terminal interactivo en la sala de entrenamiento para probar cualquier
## sinergia al instante contra el maniquí Manny. Equipa el arma, desbloquea
## la sinergia y monta los tres componentes necesarios de forma inmediata.

var player_inside: bool = false
var interaction_label: Label = null

const TEST_SYNERGIES: Array[Dictionary] = [
	{
		"id": "pistola_mente_colmena",
		"name": "Mente Colmena",
		"weapon_type": "primary",
		"weapon_id": "pistol",
		"desc": "Pistola + Abejas teledirigidas",
		"items": [
			"res://Art/Items/Weapons/Item7_Colmena.tres",
			"res://Art/Items/Weapons/Item3.tres",
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres"
		]
	},
	{
		"id": "minigun",
		"name": "Minigun",
		"weapon_type": "primary",
		"weapon_id": "uzi",
		"desc": "Uzi + Ametralladora acelerada",
		"items": [
			"res://Art/Items/Weapons/Item1.tres",
			"res://Art/Items/Weapons/Item6.tres",
			"res://Art/Items/Weapons/Item9_SierraCircular.tres"
		]
	},
	{
		"id": "lanzallamas",
		"name": "Lanzallamas",
		"weapon_type": "primary",
		"weapon_id": "shotgun",
		"desc": "Escopeta + Fuego continuo",
		"items": [
			"res://Art/Items/Weapons/Item4.tres",
			"res://Art/Items/Weapons/Item4.tres",
			"res://Art/Items/Weapons/Item4.tres"
		]
	},
	{
		"id": "roadkill",
		"name": "Roadkill",
		"weapon_type": "primary",
		"weapon_id": "pistol",
		"desc": "Pistola + Balas que rebotan",
		"items": [
			"res://Art/Items/Weapons/Item6.tres",
			"res://Art/Items/Weapons/Item9_SierraCircular.tres",
			"res://Art/Items/Weapons/Item5.tres"
		]
	},
	{
		"id": "relampago",
		"name": "Relámpago",
		"weapon_type": "primary",
		"weapon_id": "uzi",
		"desc": "Uzi + Balas eléctricas en cadena",
		"items": [
			"res://Art/Items/Weapons/Item3.tres",
			"res://Art/Items/Weapons/Item2.tres",
			"res://Art/Items/Weapons/Item6.tres"
		]
	},
	{
		"id": "daga_del_odio",
		"name": "Daga del Odio",
		"weapon_type": "melee",
		"weapon_id": "daga",
		"desc": "Daga + Furia crítica y velocidad",
		"items": [
			"res://Art/Items/Weapons/Item5.tres",
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
			"res://Art/Items/Weapons/Item9_SierraCircular.tres"
		]
	},
	{
		"id": "hombre_lobo",
		"name": "Hombre Lobo",
		"weapon_type": "melee",
		"weapon_id": "hacha",
		"desc": "Hacha + Marca explosiva en enemigos",
		"items": [
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
			"res://Art/Items/Weapons/Item4.tres",
			"res://Art/Items/Weapons/Item2.tres"
		]
	},
	{
		"id": "arrogancia",
		"name": "Arrogancia",
		"weapon_type": "melee",
		"weapon_id": "maze",
		"desc": "Maza + Reflejo de proyectiles",
		"items": [
			"res://Art/Items/Weapons/Item1.tres",
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
			"res://Art/Items/Weapons/Item7_Colmena.tres"
		]
	}
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_interaction_label()

func _setup_interaction_label() -> void:
	interaction_label = get_node_or_null("Label") as Label
	if not interaction_label:
		interaction_label = Label.new()
		interaction_label.name = "Label"
		add_child(interaction_label)
		interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interaction_label.custom_minimum_size = Vector2(240, 30)
		interaction_label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
		interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
		interaction_label.add_theme_constant_override("outline_size", 4)

	interaction_label.top_level = true
	interaction_label.rotation = 0.0
	interaction_label.scale = Vector2.ONE
	interaction_label.position = global_position + Vector2(-120, -70)
	interaction_label.text = "Presiona E: Probar Sinergias"
	interaction_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = true
	if interaction_label:
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = false
	if interaction_label:
		interaction_label.visible = false

func _input(event: InputEvent) -> void:
	if not player_inside: return
	if not event is InputEventKey: return
	if event.physical_keycode != KEY_E: return
	if not event.pressed or event.echo: return

	_open_synergy_menu()

func _open_synergy_menu() -> void:
	var tree = get_tree()
	tree.paused = true

	var canvas = CanvasLayer.new()
	canvas.name = "SynergySelectionMenu"
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
	sb.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	sb.border_color = Color(0.7, 0.4, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "ESTACIÓN DE PRUEBA DE SINERGIAS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "Elegí una sinergia para equiparla de inmediato y probarla en Manny"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(sub)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	for syn in TEST_SYNERGIES:
		var btn = _create_synergy_card_button(syn, canvas)
		grid.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(160, 36)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(func():
		canvas.queue_free()
		tree.paused = false
	)
	vbox.add_child(close_btn)

func _create_synergy_card_button(syn: Dictionary, canvas: CanvasLayer) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(280, 56)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(box)

	var name_lbl = Label.new()
	name_lbl.text = syn.name
	name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 1.0))
	box.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = syn.desc
	desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	box.add_child(desc_lbl)

	btn.pressed.connect(func():
		_apply_test_synergy(syn)
		canvas.queue_free()
		get_tree().paused = false
	)
	return btn

func _apply_test_synergy(syn: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return

	GameData.unlock_synergy(syn.id)

	if syn.weapon_type == "primary":
		GameData.chosen_primary_weapon = syn.weapon_id
	else:
		GameData.chosen_melee_weapon = syn.weapon_id

	_equip_synergy_items_on_player(player, syn)
	_reset_player_weapons(player)

func _equip_synergy_items_on_player(player: Node2D, syn: Dictionary) -> void:
	var equip = player.get_node_or_null("Equipment")
	if not equip: return

	var is_primary = syn.weapon_type == "primary"
	var slots = [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3] if is_primary else [ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]

	for i in range(syn.items.size()):
		var path = syn.items[i]
		if not ResourceLoader.exists(path): continue
		var item_res = load(path) as ItemData
		if item_res:
			equip.slots[slots[i]] = item_res

	equip.equipment_changed.emit()

func _reset_player_weapons(player: Node2D) -> void:
	if "active_weapon" in player and player.active_weapon and player.active_weapon.has_method("_load_default_weapon"):
		player.active_weapon._load_default_weapon()
	if "second_weapon" in player and player.second_weapon and player.second_weapon.has_method("_load_default_weapon"):
		player.second_weapon._load_default_weapon()
