extends CanvasLayer

var is_open: bool = false
var panel_node: PanelContainer = null
var god_mode_btn: Button = null
var status_label: Label = null
var log_box: VBoxContainer = null
var log_toggle_btn: Button = null

const RANGED_WEAPONS: Array[Dictionary] = [
	{"name": "Revólver Base", "path": "res://Scenes/Weapon/Revolver.tscn"},
	{"name": "Uzi", "path": "res://Scenes/Weapon/uzi.tscn"},
	{"name": "Escopeta", "path": "res://Scenes/Weapon/shotgun.tscn"},
	{"name": "Pistola Mente Colmena (Sinergia)", "path": "res://Scenes/Weapon/HivemindPistol.tscn"},
	{"name": "Pistola Roadkill (Sinergia)", "path": "res://Scenes/Weapon/RoadkillPistol.tscn"},
	{"name": "Heavy Metal (Sinergia)", "path": "res://Scenes/Weapon/Minigun.tscn"},
	{"name": "Cerberus (Sinergia)", "path": "res://Scenes/Weapon/Cerberus.tscn"}
]

const MELEE_WEAPONS: Array[Dictionary] = [
	{"name": "Daga", "path": "res://Scenes/Weapon/dagger.tscn"},
	{"name": "Maza", "path": "res://Scenes/Weapon/mace.tscn"},
	{"name": "Hacha", "path": "res://Scenes/Weapon/axe.tscn"}
]

const ITEMS: Array[Dictionary] = [
	{"name": "Brazo Reforzado", "path": "res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres"},
	{"name": "Brazo Ligero", "path": "res://Art/Items/Player/Arms/Item3_BrazoLigero.tres"},
	{"name": "Brazo Armado", "path": "res://Art/Items/Player/Arms/Item4_BrazoArmado.tres"},
	{"name": "Torso Blindado", "path": "res://Art/Items/Player/Body/Item2_TorsoBlindado.tres"},
	{"name": "Torso Espinado", "path": "res://Art/Items/Player/Body/Item3_TorsoEspinado.tres"},
	{"name": "Torso Ligero", "path": "res://Art/Items/Player/Body/Item4_TorsoLigero.tres"},
	{"name": "Piernas Rodantes", "path": "res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres"},
	{"name": "Piernas Caninas", "path": "res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres"},
	{"name": "Piernas Biónicas", "path": "res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres"},
	{"name": "Licuadora", "path": "res://Art/Items/Weapons/Item1.tres"},
	{"name": "Aguijón", "path": "res://Art/Items/Weapons/Item2.tres"},
	{"name": "Cerebro", "path": "res://Art/Items/Weapons/Item3.tres"},
	{"name": "Cabeza de Perro", "path": "res://Art/Items/Weapons/Item4.tres"},
	{"name": "Pulmones", "path": "res://Art/Items/Weapons/Item5.tres"},
	{"name": "Motocicleta", "path": "res://Art/Items/Weapons/Item6.tres"},
	{"name": "Colmena", "path": "res://Art/Items/Weapons/Item7_Colmena.tres"},
	{"name": "Cabeza Humana", "path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres"},
	{"name": "Sierra", "path": "res://Art/Items/Weapons/Item9_SierraCircular.tres"},
	{"name": "Batería", "path": "res://Art/Items/Weapons/Item10_Bateria.tres"},
	{"name": "Gasolina", "path": "res://Art/Items/Weapons/Item11_Gasolina.tres"},
	{"name": "Nitrógeno", "path": "res://Art/Items/Weapons/Item12_Nitrogeno.tres"}
]

const TELEPORTS: Array[Dictionary] = [
	{"name": "💀 Jefe 1 (Génesis) - Sala 15", "path": "res://Scenes/Rooms/Level1_Room15-BossFight.tscn"},
	{"name": "💀 Jefe 1 (Génesis) - Sala 16", "path": "res://Scenes/Rooms/Level1_Room16-BossFight.tscn"},
	{"name": "💀 Jefe 2 (Slime) - Sala 14", "path": "res://Scenes/Rooms/Level2_Room14BossFight.tscn"},
	{"name": "💀 Jefe 3 (Prometeo) - Sala de prueba", "path": "res://Scenes/Rooms/Level3_BossPrometeo_Prueba.tscn"},
	{"name": "🏢 Nivel 1 - Inicio (Room 1)", "path": "res://Scenes/Rooms/Level1_Room1.tscn"},
	{"name": "🎁 Nivel 1 - Tesoro (Room 11)", "path": "res://Scenes/Rooms/Level1_Room11(treasure).tscn"},
	{"name": "🛒 Nivel 1 - Tienda Ygor (Room 12)", "path": "res://Scenes/Rooms/Level1_Room12(Ygor1).tscn"},
	{"name": "🏭 Nivel 2 - Inicio (Room 1)", "path": "res://Scenes/Rooms/Level2_Room1.tscn"},
	{"name": "🔬 Laboratorio / Hub", "path": "res://Scenes/Rooms/lab_room.tscn"},
	{"name": "⚡ Mejoras de Núcleo", "path": "res://Scenes/Rooms/Core_Upgrade_Room.tscn"},
	{"name": "🧪 Sala Sandbox de Pruebas", "path": "res://Scenes/Rooms/debug_scene.tscn"}
]

const ENEMIES: Array[Dictionary] = [
	{"name": "Perro Infectado (Follower)", "path": "res://Scenes/Enemies/EnemyFollower.tscn"},
	{"name": "Carpenter", "path": "res://Scenes/Enemies/EnemyShooter.tscn"},
	{"name": "Invocador (Summoner)", "path": "res://Scenes/Enemies/EnemySummoner.tscn"},
	{"name": "Mecha", "path": "res://Scenes/Enemies/EnemyTank.tscn"},
	{"name": "Delivery", "path": "res://Scenes/Enemies/EnemyTurret.tscn"},
	{"name": "Abeja Robótica (Bee)", "path": "res://Scenes/Enemies/Enemy_bee_summon.tscn"},
	{"name": "Dummy / Maniquí de Pruebas", "path": "res://Scenes/Enemies/Mannequin.tscn"},
	{"name": "Jefe 1 (Génesis)", "path": "res://Scenes/Enemies/boss1.tscn"},
	{"name": "Jefe 2 (Slime Gigante)", "path": "res://Scenes/Enemies/Boss2.tscn"},
	{"name": "Jefe 3 (Prometeo)", "path": "res://Scenes/Enemies/Boss3_Prometeo.tscn"}
]

## El Spawner separa los encuentros de La Cripta para probar sus fases sin
## avanzar hasta el nivel 2 ni mezclar los nombres con los enemigos del nivel 1.
const CRYPT_ENEMIES: Array[Dictionary] = [
	{"name": "Gárgola (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptGargoyle.tscn"},
	{"name": "Ghoul Acechante (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptGhoul.tscn"},
	{"name": "Ciempiés Tóxico (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptCentipede.tscn"},
	{"name": "Escuadrón de la Muerte (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptDeathSquad.tscn"},
	{"name": "Ojo Torreta (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptLaserEye.tscn"},
	{"name": "Apicultora Muerta (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptDeadBeekeeperSummoner.tscn"},
	{"name": "Abeja Carnívora (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptFleshBee.tscn"},
	{"name": "Campanero de Réquiem (Cripta)", "path": "res://Scenes/Enemies/Crypt/CryptBellKeeper.tscn"}
]

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not event.pressed or event.echo: return
	if not GameData.cheats_enabled(): return
	if event.keycode == KEY_U or event.keycode == KEY_T:
		_toggle_menu()
		return
	if is_open and event.keycode == KEY_ESCAPE:
		close_menu()

func _toggle_menu() -> void:
	if is_open:
		close_menu()
		return
	open_menu()

func open_menu() -> void:
	is_open = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_god_mode_btn()
	_refresh_log()
	_show_status("Menú de depuración y cheats abierto (Tecla U / T)")

func close_menu() -> void:
	is_open = false
	visible = false

func _show_status(text: String) -> void:
	if not status_label: return
	status_label.text = text

func _build_ui() -> void:
	var root_control = Control.new()
	root_control.anchors_preset = Control.PRESET_FULL_RECT
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	panel_node = PanelContainer.new()
	panel_node.custom_minimum_size = Vector2(540, 960)
	panel_node.size = Vector2(540, 960)
	panel_node.position = Vector2(1920 - 560, 60)
	panel_node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.96)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.18, 0.78, 0.95, 0.85)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel_node.add_theme_stylebox_override("panel", style)
	root_control.add_child(panel_node)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel_node.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	_build_header(vbox)
	_build_tabs(vbox)

func _build_header(parent: Control) -> void:
	var header_hbox = HBoxContainer.new()
	parent.add_child(header_hbox)
	
	var title = Label.new()
	title.text = "DEBUG & CHEATS (TECLA U)"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.25, 0.85, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var close_btn = Button.new()
	close_btn.text = " X "
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(36, 32)
	close_btn.pressed.connect(close_menu)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.65, 0.15, 0.15, 0.85)
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_style)
	close_btn.add_theme_stylebox_override("pressed", close_style)
	header_hbox.add_child(close_btn)
	
	status_label = Label.new()
	status_label.text = "Listo."
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(status_label)

func _build_tabs(parent: Control) -> void:
	var tabs = TabContainer.new()
	tabs.focus_mode = Control.FOCUS_NONE
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(tabs)
	
	_create_synergies_tab(tabs)
	_create_teleport_tab(tabs)
	_create_cheats_tab(tabs)
	_create_weapons_tab(tabs)
	_create_items_tab(tabs)
	_create_spawner_tab(tabs)
	_create_log_tab(tabs)

func _create_button(text: String, callback: Callable, color: Color = Color.WHITE) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 36)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 13)
	if color != Color.WHITE:
		btn.add_theme_color_override("font_color", color)
	
	var style_norm = StyleBoxFlat.new()
	style_norm.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style_norm.border_width_bottom = 2
	style_norm.border_color = Color(0.2, 0.25, 0.32, 0.6)
	style_norm.corner_radius_top_left = 4
	style_norm.corner_radius_top_right = 4
	style_norm.corner_radius_bottom_left = 4
	style_norm.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_norm)
	
	var style_hov = StyleBoxFlat.new()
	style_hov.bg_color = Color(0.18, 0.22, 0.28, 0.95)
	style_hov.border_width_bottom = 2
	style_hov.border_color = Color(0.25, 0.85, 1.0, 0.85)
	style_hov.corner_radius_top_left = 4
	style_hov.corner_radius_top_right = 4
	style_hov.corner_radius_bottom_left = 4
	style_hov.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hov)
	
	btn.pressed.connect(callback)
	return btn

func _create_scroll_tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.name = tab_name
	scroll.focus_mode = Control.FOCUS_NONE
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	return vbox

func _create_synergies_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Sinergias")
	
	tab.add_child(_create_button("Desbloquear TODAS las Sinergias", _unlock_all_synergies_action, Color(1.0, 0.85, 0.2)))
	tab.add_child(_create_button("Limpiar Todo el Equipamiento", _clear_equipment_action, Color(0.9, 0.4, 0.4)))
	
	var sep1 = HSeparator.new()
	tab.add_child(sep1)
	
	_add_synergy_card(tab, "Mente Colmena", "pistola_mente_colmena", "Pistola + Colmena, Cerebro, Cabeza Humana", func():
		_activate_synergy_mente_colmena()
	)
	
	_add_synergy_card(tab, "Roadkill", "roadkill", "Pistola + Motocicleta, Sierra, Pulmones", func():
		_activate_synergy_roadkill()
	)
	
	_add_synergy_card(tab, "Minigun", "minigun", "Uzi + Mezcladora, Motocicleta, Sierra", func():
		_activate_synergy_minigun()
	)
	
	_add_synergy_card(tab, "Cerberus", "lanzallamas", "Escopeta + 3x Cabeza de Perro", func():
		_activate_synergy_cerberus()
	)
	
	_add_synergy_card(tab, "Instinto Canino", "bestia_de_caza", "Torso Espinado, Brazo Armado, Piernas Caninas", func():
		_activate_synergy_canino()
	)
	
	_add_synergy_card(tab, "Impulso Ligero", "trituradora_biomecanica", "Torso Ligero, Piernas Rodantes, Brazo Ligero", func():
		_activate_synergy_ligero()
	)
	
	_add_synergy_card(tab, "Set Musculoso", "acorazado_muscular", "Torso Blindado, Brazo Reforzado, Piernas Biónicas", func():
		_activate_synergy_musculoso()
	)

	_add_synergy_card(tab, "Nemesis", "daga_del_odio", "Sierra, Aguijón, Cabeza de Perro", func():
		_activate_synergy_daga_del_odio()
	)

	_add_synergy_card(tab, "Arrogancia", "arrogancia", "Mezcladora, Cabeza Humana, Colmena", func():
		_activate_synergy_arrogancia()
	)

	_add_synergy_card(tab, "Holy Fire", "holy_fire", "Maza + Gasolina, Pulmones, Cabeza Humana", func():
		_activate_synergy_holy_fire()
	)

	_add_synergy_card(tab, "Wolfsbane", "hombre_lobo", "Cabeza Humana, Cabeza de Perro, Aguijón", func():
		_activate_synergy_wolfsbane()
	)

	_add_synergy_card(tab, "Oil of the Sick", "alto_octanaje", "Hacha + Gasolina, Motocicleta, Glándula tóxica", func():
		_activate_synergy_alto_octanaje()
	)

	_add_synergy_card(tab, "The Bride", "relampago", "Cabeza Humana, Batería, Cerebro", func():
		_activate_synergy_the_bride()
	)

	_add_synergy_card(tab, "Speed Demon", "speed_demon", "Daga + Sierra, Motocicleta, Batería", func():
		_activate_synergy_speed_demon()
	)

	_add_synergy_card(tab, "Avalanche", "snowman", "Escopeta + Mezcladora, Cabeza Humana, Nitrógeno", func():
		_activate_synergy_snowman()
	)

func _add_synergy_card(parent: Control, syn_name: String, syn_id: String, req_desc: String, callback: Callable) -> void:
	# nombre y receta salen de los datos reales (así no quedan desactualizados)
	syn_name = SynergyManager.SYNERGIES.get(syn_id, {}).get("name", syn_name)
	req_desc = _recipe_text(syn_id, req_desc)
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 3)
	parent.add_child(card)
	
	var lbl = Label.new()
	lbl.text = syn_name
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	card.add_child(lbl)
	
	var sub = Label.new()
	sub.text = req_desc
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	card.add_child(sub)
	
	var btn = _create_button("Desbloquear y Equipar " + syn_name, callback, Color(0.4, 1.0, 0.7))
	card.add_child(btn)

# "Hacha de Mano + Gasolina, Motocicleta, Glándula tóxica"
func _recipe_text(syn_id: String, fallback: String) -> String:
	var def: Dictionary = SynergyManager.SYNERGIES.get(syn_id, {})
	if def.is_empty(): return fallback
	var parts = []
	for item_id in def.get("required_items", []):
		parts.append(CodexData.DATA.get("items", {}).get(item_id, {}).get("name", item_id))
	var text = ", ".join(parts)
	var weapon = def.get("required_weapon", "")
	return (SynergyManager.get_weapon_display_name(weapon) + " + " + text) if weapon != "" else text

func _unlock_all_synergies_action() -> void:
	GameData.unlock_all_synergies()
	_show_status("¡Todas las sinergias desbloqueadas en GameData!")

func _clear_equipment_action() -> void:
	var player = _get_player()
	if not player: return
	var equip = player.get_node_or_null("Equipment")
	if not equip: return
	for slot in equip.slots.keys():
		equip.slots[slot] = null
	equip.equipment_changed.emit()
	_show_status("Equipamiento del jugador vaciado.")

func _activate_synergy_mente_colmena() -> void:
	GameData.unlock_synergy("pistola_mente_colmena")
	_equip_weapon_and_mods("res://Scenes/Weapon/Revolver.tscn", [
		{"path": "res://Art/Items/Weapons/Item7_Colmena.tres", "slot": ItemData.ItemSlot.MAIN_W1},
		{"path": "res://Art/Items/Weapons/Item3.tres", "slot": ItemData.ItemSlot.MAIN_W2},
		{"path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres", "slot": ItemData.ItemSlot.MAIN_W3}
	])
	_show_status("Sinergia 'Mente Colmena' activada y equipada.")

func _activate_synergy_roadkill() -> void:
	GameData.unlock_synergy("roadkill")
	_equip_weapon_and_mods("res://Scenes/Weapon/Revolver.tscn", [
		{"path": "res://Art/Items/Weapons/Item6.tres", "slot": ItemData.ItemSlot.MAIN_W1},
		{"path": "res://Art/Items/Weapons/Item9_SierraCircular.tres", "slot": ItemData.ItemSlot.MAIN_W2},
		{"path": "res://Art/Items/Weapons/Item5.tres", "slot": ItemData.ItemSlot.MAIN_W3}
	])
	_show_status("Sinergia 'Roadkill' activada y equipada.")

func _activate_synergy_minigun() -> void:
	GameData.unlock_synergy("minigun")
	_equip_weapon_and_mods("res://Scenes/Weapon/uzi.tscn", [
		{"path": "res://Art/Items/Weapons/Item1.tres", "slot": ItemData.ItemSlot.MAIN_W1},
		{"path": "res://Art/Items/Weapons/Item6.tres", "slot": ItemData.ItemSlot.MAIN_W2},
		{"path": "res://Art/Items/Weapons/Item9_SierraCircular.tres", "slot": ItemData.ItemSlot.MAIN_W3}
	])
	_show_status("Sinergia 'Heavy Metal' activada y equipada.")

func _activate_synergy_cerberus() -> void:
	GameData.unlock_synergy("lanzallamas")
	_equip_weapon_and_mods("res://Scenes/Weapon/shotgun.tscn", [
		{"path": "res://Art/Items/Weapons/Item4.tres", "slot": ItemData.ItemSlot.MAIN_W1},
		{"path": "res://Art/Items/Weapons/Item4.tres", "slot": ItemData.ItemSlot.MAIN_W2},
		{"path": "res://Art/Items/Weapons/Item4.tres", "slot": ItemData.ItemSlot.MAIN_W3}
	])
	_show_status("Sinergia 'Cerberus' (Escopeta) activada y equipada.")

func _activate_synergy_canino() -> void:
	GameData.unlock_synergy("bestia_de_caza")
	_equip_body_parts([
		{"path": "res://Art/Items/Player/Body/Item3_TorsoEspinado.tres", "slot": ItemData.ItemSlot.TORSO},
		{"path": "res://Art/Items/Player/Arms/Item4_BrazoArmado.tres", "slot": ItemData.ItemSlot.ARM_L},
		{"path": "res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres", "slot": ItemData.ItemSlot.LEG_L}
	])
	_show_status("Sinergia 'Instinto Canino' activada y equipada.")

func _activate_synergy_ligero() -> void:
	GameData.unlock_synergy("trituradora_biomecanica")
	_equip_body_parts([
		{"path": "res://Art/Items/Player/Body/Item4_TorsoLigero.tres", "slot": ItemData.ItemSlot.TORSO},
		{"path": "res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres", "slot": ItemData.ItemSlot.LEG_L},
		{"path": "res://Art/Items/Player/Arms/Item3_BrazoLigero.tres", "slot": ItemData.ItemSlot.ARM_L}
	])
	_show_status("Sinergia 'Impulso Ligero' activada y equipada.")

func _activate_synergy_musculoso() -> void:
	GameData.unlock_synergy("acorazado_muscular")
	_equip_body_parts([
		{"path": "res://Art/Items/Player/Body/Item2_TorsoBlindado.tres", "slot": ItemData.ItemSlot.TORSO},
		{"path": "res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres", "slot": ItemData.ItemSlot.ARM_L},
		{"path": "res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres", "slot": ItemData.ItemSlot.LEG_L}
	])
	_show_status("Sinergia 'Set Musculoso' activada y equipada.")

func _activate_synergy_daga_del_odio() -> void:
	GameData.unlock_synergy("daga_del_odio")
	_equip_melee_weapon_and_mods("res://Scenes/Weapon/dagger.tscn", [
		{"path": "res://Art/Items/Weapons/Item9_SierraCircular.tres", "slot": ItemData.ItemSlot.SEC_W1},
		{"path": "res://Art/Items/Weapons/Item2.tres", "slot": ItemData.ItemSlot.SEC_W2},
		{"path": "res://Art/Items/Weapons/Item4.tres", "slot": ItemData.ItemSlot.SEC_W3}
	])
	_show_status("Sinergia 'Nemesis' activada y equipada.")

func _activate_synergy_arrogancia() -> void:
	GameData.unlock_synergy("arrogancia")
	_equip_melee_weapon_and_mods("res://Scenes/Weapon/mace.tscn", [
		{"path": "res://Art/Items/Weapons/Item1.tres", "slot": ItemData.ItemSlot.SEC_W1},
		{"path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres", "slot": ItemData.ItemSlot.SEC_W2},
		{"path": "res://Art/Items/Weapons/Item7_Colmena.tres", "slot": ItemData.ItemSlot.SEC_W3}
	])
	_show_status("Sinergia 'Arrogancia' activada y equipada.")

func _activate_synergy_holy_fire() -> void:
	GameData.unlock_synergy("holy_fire")
	_equip_melee_weapon_and_mods("res://Scenes/Weapon/mace.tscn", [
		{"path": "res://Art/Items/Weapons/Item11_Gasolina.tres", "slot": ItemData.ItemSlot.SEC_W1},
		{"path": "res://Art/Items/Weapons/Item5.tres", "slot": ItemData.ItemSlot.SEC_W2},
		{"path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres", "slot": ItemData.ItemSlot.SEC_W3}
	])
	_show_status("Sinergia 'Holy Fire' (Maza) activada y equipada.")

func _activate_synergy_speed_demon() -> void:
	GameData.unlock_synergy("speed_demon")
	_equip_melee_weapon_and_mods("res://Scenes/Weapon/dagger.tscn", [
		{"path": "res://Art/Items/Weapons/Item9_SierraCircular.tres", "slot": ItemData.ItemSlot.SEC_W1},
		{"path": "res://Art/Items/Weapons/Item6.tres", "slot": ItemData.ItemSlot.SEC_W2},
		{"path": "res://Art/Items/Weapons/Item10_Bateria.tres", "slot": ItemData.ItemSlot.SEC_W3}
	])
	_show_status("Sinergia 'Speed Demon' (Daga) activada y equipada.")

func _activate_synergy_snowman() -> void:
	GameData.unlock_synergy("snowman")
	_equip_weapon_and_mods("res://Scenes/Weapon/shotgun.tscn", [
		{"path": "res://Art/Items/Weapons/Item1.tres", "slot": ItemData.ItemSlot.MAIN_W1},
		{"path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres", "slot": ItemData.ItemSlot.MAIN_W2},
		{"path": "res://Art/Items/Weapons/Item12_Nitrogeno.tres", "slot": ItemData.ItemSlot.MAIN_W3}
	])
	_show_status("Sinergia 'Avalanche' (Escopeta) activada y equipada.")

func _activate_synergy_wolfsbane() -> void:
	GameData.unlock_synergy("hombre_lobo")
	_equip_melee_weapon_and_mods("res://Scenes/Weapon/axe.tscn", [
		{"path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres", "slot": ItemData.ItemSlot.SEC_W1},
		{"path": "res://Art/Items/Weapons/Item4.tres", "slot": ItemData.ItemSlot.SEC_W2},
		{"path": "res://Art/Items/Weapons/Item2.tres", "slot": ItemData.ItemSlot.SEC_W3}
	])
	_show_status("Sinergia 'Wolfsbane' activada y equipada.")

func _activate_synergy_the_bride() -> void:
	GameData.unlock_synergy("relampago")
	_equip_weapon_and_mods("res://Scenes/Weapon/uzi.tscn", [
		{"path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres", "slot": ItemData.ItemSlot.MAIN_W1},
		{"path": "res://Art/Items/Weapons/Item10_Bateria.tres", "slot": ItemData.ItemSlot.MAIN_W2},
		{"path": "res://Art/Items/Weapons/Item3.tres", "slot": ItemData.ItemSlot.MAIN_W3}
	])
	_show_status("Sinergia 'The Bride' activada y equipada.")

func _equip_weapon_and_mods(weapon_path: String, mods: Array[Dictionary]) -> void:
	var player = _get_player()
	if not player: return
	var weapon_wrapper = player.get("active_weapon")
	if weapon_wrapper:
		var scene = load(weapon_path)
		if scene: weapon_wrapper.switch_weapon(scene)
	var equip = player.get_node_or_null("Equipment")
	var inv = player.get_node_or_null("Inventory")
	for mod_info in mods:
		_equip_slot_item(equip, inv, mod_info.path, mod_info.slot)

func _activate_synergy_alto_octanaje() -> void:
	GameData.unlock_synergy("alto_octanaje")
	_equip_melee_weapon_and_mods("res://Scenes/Weapon/axe.tscn", [
		{"path": "res://Art/Items/Weapons/Item11_Gasolina.tres", "slot": ItemData.ItemSlot.SEC_W1},
		{"path": "res://Art/Items/Weapons/Item6.tres", "slot": ItemData.ItemSlot.SEC_W2},
		{"path": "res://Art/Items/Crypt/glandula_toxica.tres", "slot": ItemData.ItemSlot.SEC_W3}
	])
	_show_status("Sinergia 'Oil of the Sick' (Hacha) activada y equipada.")

func _equip_melee_weapon_and_mods(weapon_path: String, mods: Array[Dictionary]) -> void:
	var player = _get_player()
	if not player: return
	var second_weapon_container = player.get("second_weapon")
	if second_weapon_container:
		var scene = load(weapon_path)
		if scene: second_weapon_container.switch_weapon(scene)
	var equip = player.get_node_or_null("Equipment")
	var inv = player.get_node_or_null("Inventory")
	for mod_info in mods:
		_equip_slot_item(equip, inv, mod_info.path, mod_info.slot)

func _equip_body_parts(parts: Array[Dictionary]) -> void:
	var player = _get_player()
	if not player: return
	var equip = player.get_node_or_null("Equipment")
	var inv = player.get_node_or_null("Inventory")
	for part_info in parts:
		_equip_slot_item(equip, inv, part_info.path, part_info.slot)

func _equip_slot_item(equip: Node, inv: Node, item_path: String, target_slot: ItemData.ItemSlot) -> void:
	var item = load(item_path) as ItemData
	if not item: return
	if equip and equip.has_method("equip_item"):
		var clone = item.duplicate()
		clone.slot = target_slot
		equip.equip_item(clone)
	if inv and inv.has_method("add_item"):
		inv.add_item(item)

func _create_teleport_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Teleport")
	
	var boss_lbl = Label.new()
	boss_lbl.text = "Salas de Jefes (Boss Fights):"
	boss_lbl.add_theme_font_size_override("font_size", 14)
	boss_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	tab.add_child(boss_lbl)
	
	for tp in TELEPORTS:
		if "Jefe" in tp.name:
			var btn = _create_button(tp.name, func(): _teleport_to(tp.path, tp.name), Color(1.0, 0.5, 0.5))
			tab.add_child(btn)
			
	var sep = HSeparator.new()
	tab.add_child(sep)
	
	var hub_lbl = Label.new()
	hub_lbl.text = "Niveles y Hubs:"
	hub_lbl.add_theme_font_size_override("font_size", 14)
	hub_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	tab.add_child(hub_lbl)
	
	for tp in TELEPORTS:
		if not ("Jefe" in tp.name):
			var btn = _create_button(tp.name, func(): _teleport_to(tp.path, tp.name))
			tab.add_child(btn)

func _teleport_to(scene_path: String, scene_name: String) -> void:
	if not ResourceLoader.exists(scene_path):
		_show_status("Error: No existe escena " + scene_path)
		return
	GameData.previous_scene_path = get_tree().current_scene.scene_file_path
	_show_status("Teletransportando a " + scene_name + "...")
	close_menu()
	SceneTransition.change_scene(scene_path)

func _create_cheats_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Cheats")
	
	tab.add_child(_create_button("Curar Vida al 100%", _heal_player, Color(0.3, 1.0, 0.5)))
	
	god_mode_btn = _create_button("Modo Dios: OFF", _toggle_god_mode, Color(1.0, 0.4, 0.4))
	tab.add_child(god_mode_btn)
	_update_god_mode_btn()
	
	var grid_eco = GridContainer.new()
	grid_eco.columns = 2
	grid_eco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_child(grid_eco)
	
	grid_eco.add_child(_create_button("+1000 Chatarra", func(): _add_scrap(1000)))
	grid_eco.add_child(_create_button("+1000 Carne", func(): _add_flesh(1000)))
	grid_eco.add_child(_create_button("+5000 de Todo", func():
		_add_scrap(5000)
		_add_flesh(5000)
	))
	grid_eco.add_child(_create_button("Reset Monedas a 0", func():
		GameData.scrap = 0
		GameData.flesh = 0
		GameData.scrap_changed.emit(0)
		GameData.flesh_changed.emit(0)
		_show_status("Monedas reseteadas a 0.")
	))
	
	var sep = HSeparator.new()
	tab.add_child(sep)
	
	tab.add_child(_create_button("Matar a Todos los Enemigos de la Sala", _kill_all_enemies, Color(1.0, 0.35, 0.35)))
	tab.add_child(_create_button("Abrir / Destrabar Todas las Puertas", _unlock_all_doors, Color(0.3, 0.9, 1.0)))
	tab.add_child(_create_button("Desbloquear Todo en Omnia / Códice", _unlock_everything_in_omnia, Color(0.8, 0.5, 1.0)))
	tab.add_child(_create_button("Maxear Mejoras del Núcleo (Core Upgrades)", _max_core_upgrades, Color(1.0, 0.8, 0.2)))
	tab.add_child(_create_button("Alternar Polvo Ambiental (ON / OFF)", _toggle_ambient_dust, Color(0.9, 0.9, 0.5)))
	tab.add_child(_create_button("Alternar Luces Parpadeantes (ON / OFF)", _toggle_flickering_lights, Color(1.0, 0.9, 0.4)))
	tab.add_child(_create_button("Alternar Viñeta Cinemática (ON / OFF)", _toggle_cinematic_vignette, Color(0.8, 0.6, 1.0)))
	
	var time_lbl = Label.new()
	time_lbl.text = "Velocidad de Juego (Time Scale):"
	time_lbl.add_theme_font_size_override("font_size", 12)
	time_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	tab.add_child(time_lbl)
	
	var time_grid = GridContainer.new()
	time_grid.columns = 3
	time_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_child(time_grid)
	
	time_grid.add_child(_create_button("0.5x Lento", func(): _set_time_scale(0.5)))
	time_grid.add_child(_create_button("1.0x Normal", func(): _set_time_scale(1.0)))
	time_grid.add_child(_create_button("2.0x Rápido", func(): _set_time_scale(2.0)))

func _heal_player() -> void:
	var player = _get_player()
	if not player: return
	if "stats" in player and player.stats:
		player.stats.heal(9999)
		_show_status("¡Jugador curado al máximo!")

func _toggle_god_mode() -> void:
	GameData.debug_god_mode = not GameData.debug_god_mode
	_update_god_mode_btn()
	var msg = "Modo Dios ACTIVADO (Invulnerable)" if GameData.debug_god_mode else "Modo Dios DESACTIVADO"
	_show_status(msg)

func _update_god_mode_btn() -> void:
	if not god_mode_btn: return
	if GameData.debug_god_mode:
		god_mode_btn.text = "Modo Dios: ON (Invulnerable)"
		god_mode_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		return
	god_mode_btn.text = "Modo Dios: OFF (Vulnerable)"
	god_mode_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _add_scrap(amount: int) -> void:
	GameData.add_scrap(amount)
	_show_status("+" + str(amount) + " Chatarra agregada. Total: " + str(GameData.scrap))

func _add_flesh(amount: int) -> void:
	GameData.add_flesh(amount)
	_show_status("+" + str(amount) + " Carne agregada. Total: " + str(GameData.flesh))

func _kill_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var count = 0
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		count += 1
		if enemy.has_method("die"):
			enemy.die()
		elif enemy.has_method("take_damage"):
			enemy.take_damage(99999)
		else:
			enemy.queue_free()
	_show_status("Eliminados " + str(count) + " enemigos en la sala.")

func _unlock_all_doors() -> void:
	var doors = get_tree().get_nodes_in_group("door")
	for door in doors:
		if is_instance_valid(door) and door.has_method("unlock_door"):
			door.unlock_door()
	_show_status("Puertas de la sala destrabadas (" + str(doors.size()) + ").")

func _unlock_everything_in_omnia() -> void:
	if GameData.has_method("unlock_all_omnia"):
		GameData.unlock_all_omnia()
	_show_status("¡Todo en Omnia y Códice desbloqueado!")

func _max_core_upgrades() -> void:
	for key in GameData.core_upgrades.keys():
		GameData.core_upgrades[key] = 10
	var player = _get_player()
	if player and player.has_method("_update_player_stats"):
		player._update_player_stats()
	_show_status("Mejoras de Núcleo al nivel máximo (10).")

func _set_time_scale(val: float) -> void:
	Engine.time_scale = val
	_show_status("Velocidad del motor fijada en " + str(val) + "x.")

func _toggle_ambient_dust() -> void:
	var state = AmbientDust.toggle_global_dust(get_tree())
	_show_status("Polvo ambiental: " + ("ACTIVADO" if state else "DESACTIVADO"))

func _toggle_flickering_lights() -> void:
	var state = FlickeringLight.toggle_global_flicker(get_tree())
	_show_status("Luces parpadeantes: " + ("ACTIVADO" if state else "DESACTIVADO"))

func _toggle_cinematic_vignette() -> void:
	var state = CinematicVignette.toggle_global_vignette(get_tree())
	_show_status("Viñeta cinemática: " + ("ACTIVADO" if state else "DESACTIVADO"))

func _create_weapons_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Armas")
	
	var r_lbl = Label.new()
	r_lbl.text = "Armas Primarias (A Rango):"
	r_lbl.add_theme_font_size_override("font_size", 14)
	r_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	tab.add_child(r_lbl)
	
	for w in RANGED_WEAPONS:
		var btn = _create_button(w.name, func(): _equip_ranged(w.path, w.name))
		tab.add_child(btn)
		
	var sep = HSeparator.new()
	tab.add_child(sep)
	
	var m_lbl = Label.new()
	m_lbl.text = "Armas Secundarias (Cuerpo a Cuerpo):"
	m_lbl.add_theme_font_size_override("font_size", 14)
	m_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	tab.add_child(m_lbl)
	
	for w in MELEE_WEAPONS:
		var btn = _create_button(w.name, func(): _equip_melee(w.path, w.name))
		tab.add_child(btn)

func _equip_ranged(path: String, w_name: String) -> void:
	var player = _get_player()
	if not player: return
	var weapon_wrapper = player.get("active_weapon")
	if not weapon_wrapper: return
	var scene = load(path)
	if not scene: return
	weapon_wrapper.switch_weapon(scene)
	_show_status("Arma primaria equipada: " + w_name)

func _equip_melee(path: String, w_name: String) -> void:
	var player = _get_player()
	if not player: return
	var second_weapon_container = player.get("second_weapon")
	if not second_weapon_container: return
	var scene = load(path)
	if not scene: return
	second_weapon_container.switch_weapon(scene)
	_show_status("Arma secundaria equipada: " + w_name)

func _create_items_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Ítems")
	
	tab.add_child(_create_button("Dar TODOS los Ítems al Inventario", _add_all_items_to_inv, Color(0.25, 0.9, 1.0)))
	
	var sep = HSeparator.new()
	tab.add_child(sep)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	tab.add_child(grid)
	
	for item in ITEMS:
		var btn = _create_button(item.name, func(): _add_single_item(item.path, item.name))
		grid.add_child(btn)

func _add_single_item(item_path: String, item_name: String) -> void:
	var player = _get_player()
	if not player: return
	var inv = player.get_node_or_null("Inventory")
	if not inv: return
	var item_res = load(item_path) as ItemData
	if not item_res: return
	inv.add_item(item_res)
	_show_status("Ítem añadido al inventario: " + item_name)

func _add_all_items_to_inv() -> void:
	for item in ITEMS:
		_add_single_item(item.path, item.name)
	_show_status("¡Todos los ítems (" + str(ITEMS.size()) + ") añadidos al inventario!")

func _create_spawner_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Spawner")
	
	var spawn_lbl = Label.new()
	spawn_lbl.text = "Spawnear Enemigo frente al jugador:"
	spawn_lbl.add_theme_font_size_override("font_size", 14)
	spawn_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	tab.add_child(spawn_lbl)
	
	for enemy in ENEMIES:
		var btn = _create_button(enemy.name, func(): _spawn_scene_near_player(enemy.path, enemy.name))
		tab.add_child(btn)

	var crypt_sep = HSeparator.new()
	tab.add_child(crypt_sep)
	var crypt_label = Label.new()
	crypt_label.text = "Enemigos de La Cripta · Nivel 2:"
	crypt_label.add_theme_font_size_override("font_size", 14)
	crypt_label.add_theme_color_override("font_color", Color(0.68, 0.45, 0.95))
	tab.add_child(crypt_label)
	for enemy in CRYPT_ENEMIES:
		var btn = _create_button(enemy.name, func(): _spawn_scene_near_player(enemy.path, enemy.name), Color(0.72, 0.55, 1.0))
		tab.add_child(btn)
		
	var sep = HSeparator.new()
	tab.add_child(sep)
	
	var prop_lbl = Label.new()
	prop_lbl.text = "Spawnear Objetos & Cofres:"
	prop_lbl.add_theme_font_size_override("font_size", 14)
	prop_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	tab.add_child(prop_lbl)
	
	tab.add_child(_create_button("Cofre de Recompensa", func():
		_spawn_scene_near_player("res://Scenes/World/Chest.tscn", "Cofre")
	))
	tab.add_child(_create_button("Barril de Fuego Explosivo", func():
		_spawn_scene_near_player("res://Scenes/Objects/FireBarrel.tscn", "Barril de Fuego")
	))
	tab.add_child(_create_button("Barril de Hielo Congelante", func():
		_spawn_scene_near_player("res://Scenes/Objects/IceBarrel.tscn", "Barril de Hielo")
	))
	tab.add_child(_create_button("Drop de Carne (Flesh)", func():
		_spawn_scene_near_player("res://Scenes/UI/flesh.tscn", "Carne")
	))

func _spawn_scene_near_player(scene_path: String, entity_name: String) -> void:
	var player = _get_player()
	if not player:
		_show_status("No se encontró al jugador en la escena.")
		return
	var scene = load(scene_path)
	if not scene:
		_show_status("Error cargando escena: " + scene_path)
		return
	var inst = scene.instantiate()
	var angle = randf_range(0, 2 * PI)
	var spawn_offset = Vector2(160, 0).rotated(angle)
	inst.global_position = player.global_position + spawn_offset
	get_tree().current_scene.add_child(inst)
	_show_status("Spawneado: " + entity_name)

func _get_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return null
	return players[0]

# --- Registro de runs (lo que jugó la gente en el evento) ---

func _create_log_tab(tabs: TabContainer) -> void:
	var tab = _create_scroll_tab(tabs, "Registro")
	log_toggle_btn = _create_button("", _toggle_log)
	log_toggle_btn.custom_minimum_size.y = 48
	tab.add_child(log_toggle_btn)
	tab.add_child(_create_button("Actualizar", _refresh_log, Color(0.3, 0.85, 1.0)))
	tab.add_child(_create_button("Abrir carpeta del registro (CSV para Excel)", _open_log_folder, Color(1.0, 0.85, 0.2)))
	tab.add_child(_create_button("Archivar runs anteriores (empezar de cero)", _archive_log, Color(0.9, 0.6, 0.4)))
	log_box = VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 6)
	tab.add_child(log_box)

# Solo cuentan las runs jugadas con el registro prendido (para no mezclar
# nuestras pruebas con las de los jugadores).
func _toggle_log() -> void:
	RunLog.set_enabled(not RunLog.is_enabled())
	_update_log_toggle()
	_show_status("Registro de runs " + ("ACTIVADO: cuentan las runs que empiecen desde ahora" if RunLog.is_enabled() else "DESACTIVADO"))

func _update_log_toggle() -> void:
	if not log_toggle_btn: return
	var on = RunLog.is_enabled()
	log_toggle_btn.text = "REGISTRO: ACTIVADO (tocar para apagar)" if on else "REGISTRO: DESACTIVADO (tocar para prender)"
	log_toggle_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5) if on else Color(1.0, 0.4, 0.4))
	log_toggle_btn.add_theme_font_size_override("font_size", 16)

func _archive_log() -> void:
	var moved = RunLog.archive()
	_show_status(("Registro anterior guardado como " + moved) if moved != "" else "No había runs para archivar")
	_refresh_log()

func _open_log_folder() -> void:
	OS.shell_open(RunLog.folder_path())

func _refresh_log() -> void:
	if not log_box: return
	for c in log_box.get_children():
		c.queue_free()
	_update_log_toggle()
	var rows = RunLog.read_rows()
	_log_line(RunLog.file_path(), Color(0.55, 0.6, 0.68), 11)
	if rows.is_empty():
		_log_line("Todavía no hay runs registradas.", Color.WHITE, 14)
		return
	var total_sec := 0
	for r in rows:
		total_sec += int(r.get("duracion_seg", "0"))
	var avg: int = total_sec / rows.size()
	var event_runs = rows.filter(func(r): return r.get("modo", "") == "evento").size()
	var deaths = rows.filter(func(r): return r.get("resultado", "") == "muerte")
	_log_title("RESUMEN")
	_log_line("Runs: %d (del evento: %d)" % [rows.size(), event_runs], Color.WHITE, 14)
	_log_line("Duración promedio: %d:%02d · tiempo total jugado: %d min" % [avg / 60, avg % 60, total_sec / 60], Color.WHITE, 14)
	_log_line("Resultado: " + _count_text(rows, "resultado"), Color.WHITE, 13)
	_log_line("Hasta dónde llegaron: " + _count_text(rows, "sala"), Color.WHITE, 13)
	_log_line("Qué los mató: " + _count_text(deaths, "causa"), Color.WHITE, 13)
	_log_line("Arma principal: " + _count_text(rows, "arma_principal"), Color.WHITE, 13)
	_log_line("Arma secundaria: " + _count_text(rows, "arma_secundaria"), Color.WHITE, 13)
	_log_line("Sinergias armadas: " + _count_text(rows, "sinergias", true), Color.WHITE, 13)
	_log_line("Control: " + _count_text(rows, "control"), Color.WHITE, 13)
	var inv = rows.filter(func(r): return int(r.get("veces_inventario", "0")) > 0).size()
	_log_line("Abrieron el inventario: %d de %d runs" % [inv, rows.size()], Color.WHITE, 13)
	_log_line("Jugadores (estimado): %d" % _distinct(rows, "jugador"), Color.WHITE, 13)
	_log_line("Promedio por run: %s salas · %s golpes · %s de daño · %s objetos · %s dashes · %s FPS" % [
		_avg(rows, "salas_completadas"), _avg(rows, "golpes_recibidos"), _avg(rows, "dano_recibido"),
		_avg(rows, "objetos_recogidos"), _avg(rows, "dashes"), _avg(rows, "fps_promedio")], Color.WHITE, 13)
	_log_line("Objetos agarrados: " + _count_text(rows, "objetos", true), Color.WHITE, 13)
	_log_title("ÚLTIMAS RUNS")
	for i in range(rows.size() - 1, maxi(rows.size() - 25, 0) - 1, -1):
		var r = rows[i]
		var syn: String = r.get("sinergias", "")
		_log_line("%s %s · %s · %s · %s · %s + %s%s" % [
			r.get("fecha", ""), r.get("hora_inicio", "").left(5), r.get("duracion", ""),
			r.get("resultado", ""), r.get("sala", ""), r.get("arma_principal", ""),
			r.get("arma_secundaria", ""), (" · " + syn) if syn != "" else ""], Color(0.85, 0.88, 0.92), 12)

# "muerte 12 · victoria 3 ...", de mayor a menor. Con "split", una celda puede
# traer varios valores separados por coma (las sinergias).
func _count_text(rows: Array, column: String, split := false) -> String:
	var counts := {}
	for r in rows:
		var cell: String = r.get(column, "")
		var values = cell.split(",", false) if split else PackedStringArray([cell])
		for v in values:
			var key = v.strip_edges()
			if key == "": continue
			counts[key] = counts.get(key, 0) + 1
	if counts.is_empty(): return "-"
	var keys = counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	return " · ".join(keys.map(func(k): return "%s %d" % [k, counts[k]]))

# Promedio de una columna numérica (las celdas vacías no cuentan).
func _avg(rows: Array, column: String) -> String:
	var total := 0.0
	var n := 0
	for r in rows:
		var v: String = r.get(column, "")
		if v.is_valid_float():
			total += v.to_float()
			n += 1
	return "%.1f" % (total / n) if n > 0 else "-"

func _distinct(rows: Array, column: String) -> int:
	var seen := {}
	for r in rows:
		if r.get(column, "") != "": seen[r[column]] = true
	return seen.size()

func _log_title(text: String) -> void:
	log_box.add_child(HSeparator.new())
	_log_line(text, Color(1.0, 0.85, 0.2), 15)

func _log_line(text: String, color: Color, size: int) -> void:
	var l = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 480
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	log_box.add_child(l)
