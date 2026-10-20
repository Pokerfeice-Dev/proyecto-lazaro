extends Area2D
class_name SynergyTerminal

## Terminal interactivo en la sala de entrenamiento para probar cualquier
## sinergia al instante contra el maniquí. Equipa el arma, desbloquea
## la sinergia y monta los tres componentes necesarios de forma inmediata.

const SIGN_ICON := preload("res://Art/Ui/svg/icon_energy.svg")
const SIGN_COLOR := Color("#B07CFF")

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
		"name": "Cerberus",
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
		"name": "The Bride",
		"weapon_type": "primary",
		"weapon_id": "uzi",
		"desc": "Uzi + The Bride (Balas eléctricas en cadena)",
		"items": [
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
			"res://Art/Items/Weapons/Item10_Bateria.tres",
			"res://Art/Items/Weapons/Item3.tres"
		]
	},
	{
		"id": "daga_del_odio",
		"name": "Nemesis",
		"weapon_type": "melee",
		"weapon_id": "daga",
		"desc": "Daga + Nemesis (Poder masivo a baja vida y robo de vida)",
		"items": [
			"res://Art/Items/Weapons/Item9_SierraCircular.tres",
			"res://Art/Items/Weapons/Item2.tres",
			"res://Art/Items/Weapons/Item4.tres"
		]
	},
	{
		"id": "hombre_lobo",
		"name": "Wolfsbane",
		"weapon_type": "melee",
		"weapon_id": "hacha",
		"desc": "Hacha + Marca Wolfsbane explosiva en enemigos",
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
	},
	{
		"id": "holy_fire",
		"name": "Holy Fire",
		"weapon_type": "melee",
		"weapon_id": "maze",
		"desc": "Maza + Lengua de fuego que escupe llamas alrededor",
		"items": [
			"res://Art/Items/Weapons/Item11_Gasolina.tres",
			"res://Art/Items/Weapons/Item5.tres",
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres"
		]
	},
	{
		"id": "alto_octanaje",
		"name": "Alto Octanaje",
		"weapon_type": "melee",
		"weapon_id": "hacha",
		"desc": "Hacha + Manchas de gasolina que explotan con un disparo",
		"items": [
			"res://Art/Items/Weapons/Item11_Gasolina.tres",
			"res://Art/Items/Weapons/Item6.tres",
			"res://Art/Items/Crypt/glandula_toxica.tres"
		]
	},
	{
		"id": "speed_demon",
		"name": "Speed Demon",
		"weapon_type": "melee",
		"weapon_id": "daga",
		"desc": "Daga + Golpes rapidísimos que te empujan hacia adelante",
		"items": [
			"res://Art/Items/Weapons/Item9_SierraCircular.tres",
			"res://Art/Items/Weapons/Item6.tres",
			"res://Art/Items/Weapons/Item10_Bateria.tres"
		]
	},
	{
		"id": "snowman",
		"name": "Avalanche",
		"weapon_type": "primary",
		"weapon_id": "shotgun",
		"desc": "Escopeta + Bola de nieve que congela",
		"items": [
			"res://Art/Items/Weapons/Item1.tres",
			"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
			"res://Art/Items/Weapons/Item12_Nitrogeno.tres"
		]
	}
]

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_interaction_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interaction_label)
	# cartel fijo con el nombre de la estación, como las puertas del laboratorio
	DoorSign.create(self, "SINERGIAS", SIGN_ICON, SIGN_COLOR, Vector2(0, -46))

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
	interaction_label.position = global_position + Vector2(-120, 34)
	interaction_label.text = "Presiona E: Probar Sinergias"
	interaction_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = true
	_set_highlight(true)
	if interaction_label:
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = false
	_set_highlight(false)
	if interaction_label:
		interaction_label.visible = false

# La estación se ilumina mientras el jugador está cerca.
func _set_highlight(on: bool) -> void:
	var art = get_node_or_null("Sprite2D")
	if art and art.has_method("set_highlight"):
		art.set_highlight(on)

func _input(event: InputEvent) -> void:
	if not player_inside: return
	if not InputMode.is_interact(event): return # E o X del joystick

	_open_synergy_menu()

# Ventana con el estilo de la UI del juego: una tarjeta por sinergia
# (arma + efecto). Elegir una la equipa al instante.
func _open_synergy_menu() -> void:
	var window = UIWindow.open("  INCUBADORA DE SINERGIAS", SIGN_ICON, 780)
	var sub = UIStyle.label("Elige una sinergia para equiparla de inmediato y probarla en el maniquí.", 18, UIStyle.COLOR_MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	window.body.add_child(sub)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	window.body.add_child(grid)
	for syn in TEST_SYNERGIES:
		grid.add_child(_create_synergy_card_button(syn, window))
	window.add_button("CERRAR", false, "ESC", window.close)

func _create_synergy_card_button(syn: Dictionary, window: UIWindow) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(350, 66)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UIStyle.style_slot_button(btn, "normal")
	var m = UIStyle.padded(12)
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(m)
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(box)
	var name_lbl = UIStyle.label(syn.name.to_upper(), 18, SIGN_COLOR.lerp(Color.WHITE, 0.35))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_lbl)
	var desc_lbl = UIStyle.label(syn.desc, 14, UIStyle.COLOR_MUTED)
	desc_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc_lbl)
	btn.pressed.connect(func():
		_apply_test_synergy(syn)
		window.close()
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
