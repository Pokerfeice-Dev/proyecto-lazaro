extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")

var is_collapsed: bool = false
var panel_node: PanelContainer = null
var toggle_btn: Button = null
var god_mode_btn: Button = null

const ITEMS: Array[Dictionary] = [
	{"name": "Brazo Reforzado", "path": "res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres"},
	{"name": "Brazo Ligero", "path": "res://Art/Items/Player/Arms/Item3_BrazoLigero.tres"},
	{"name": "Brazo Armado", "path": "res://Art/Items/Player/Arms/Item4_BrazoArmado.tres"},
	{"name": "Torso Blindado", "path": "res://Art/Items/Player/Body/Item2_TorsoBlindado.tres"},
	{"name": "Torso Espinado", "path": "res://Art/Items/Player/Body/Item3_TorsoEspinado.tres"},
	{"name": "Torso Ligero", "path": "res://Art/Items/Player/Body/Item4_TorsoLigero.tres"},
	{"name": "Piernas Rodantes", "path": "res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres"},
	{"name": "Piernas Caninas", "path": "res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres"},
	{"name": "Piernas Bionicas", "path": "res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres"},
	{"name": "Weapon Upgrade 1", "path": "res://Art/Items/Weapons/Item1.tres"},
	{"name": "Weapon Upgrade 2", "path": "res://Art/Items/Weapons/Item2.tres"},
	{"name": "Weapon Upgrade 3", "path": "res://Art/Items/Weapons/Item3.tres"},
	{"name": "Weapon Upgrade 4", "path": "res://Art/Items/Weapons/Item4.tres"},
	{"name": "Weapon Upgrade 5", "path": "res://Art/Items/Weapons/Item5.tres"},
	{"name": "Weapon Upgrade 6", "path": "res://Art/Items/Weapons/Item6.tres"},
	{"name": "Colmena", "path": "res://Art/Items/Weapons/Item7_Colmena.tres"},
	{"name": "Cabeza Humana", "path": "res://Art/Items/Weapons/Item8_CabezaHumana.tres"},
	{"name": "Sierra Circular", "path": "res://Art/Items/Weapons/Item9_SierraCircular.tres"}
]

const RANGED_WEAPONS: Array[Dictionary] = [
	{"name": "Pistol", "path": "res://Scenes/Weapon/pistol.tscn"},
	{"name": "Uzi", "path": "res://Scenes/Weapon/uzi.tscn"},
	{"name": "Shotgun", "path": "res://Scenes/Weapon/shotgun.tscn"}
]

const MELEE_WEAPONS: Array[Dictionary] = [
	{"name": "Dagger", "path": "res://Scenes/Weapon/dagger.tscn"},
	{"name": "Mace", "path": "res://Scenes/Weapon/mace.tscn"},
	{"name": "Axe", "path": "res://Scenes/Weapon/axe.tscn"}
]

const ENEMIES: Array[Dictionary] = [
	{"name": "Follower", "path": "res://Scenes/Enemies/EnemyFollower.tscn"},
	{"name": "Shooter", "path": "res://Scenes/Enemies/EnemyShooter.tscn"},
	{"name": "Summoner", "path": "res://Scenes/Enemies/EnemySummoner.tscn"},
	{"name": "Tank", "path": "res://Scenes/Enemies/EnemyTank.tscn"},
	{"name": "Turret", "path": "res://Scenes/Enemies/EnemyTurret.tscn"},
	{"name": "Bee Minion", "path": "res://Scenes/Enemies/Enemy_bee_summon.tscn"},
	{"name": "Genesis Boss", "path": "res://Scenes/Enemies/boss1.tscn"}
]

func _ready() -> void:
	_spawn_or_reposition_player()
	_setup_debug_ui()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	if event.keycode == KEY_F6:
		_return_to_game()

func _spawn_or_reposition_player() -> void:
	var p_spawn = get_node_or_null("player_spawn")
	if not p_spawn:
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		_spawn_fresh_player(p_spawn.global_position)
	else:
		_reposition_existing_player(players[0], p_spawn.global_position)

func _spawn_fresh_player(spawn_pos: Vector2) -> void:
	if not player_scene:
		return
	var p_inst = player_scene.instantiate()
	p_inst.global_position = spawn_pos
	call_deferred("add_child", p_inst)
	p_inst.ready.connect(func():
		_initialize_player_stats(p_inst)
	)

func _reposition_existing_player(player: Node, spawn_pos: Vector2) -> void:
	player.global_position = spawn_pos
	_reset_player_state(player)

func _initialize_player_stats(player: Node) -> void:
	if not "stats" in player:
		return
	var s = player.stats
	s.current_health = s.max_health
	s.health_changed.emit(s.current_health, s.max_health)

func _reset_player_state(player: Node) -> void:
	if player.process_mode == Node.PROCESS_MODE_DISABLED:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.show()
	_initialize_player_stats(player)
	if player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()

func _setup_debug_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 110
	add_child(canvas)
	
	panel_node = PanelContainer.new()
	panel_node.custom_minimum_size = Vector2(500, 1080)
	panel_node.size = Vector2(500, 1080)
	panel_node.position = Vector2(1920 - 500, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.06, 0.9)
	style.border_width_left = 2
	style.border_color = Color(0.2, 0.8, 1.0, 0.8) # Cyan border
	panel_node.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel_node)
	
	toggle_btn = Button.new()
	toggle_btn.text = ">"
	toggle_btn.custom_minimum_size = Vector2(40, 80)
	toggle_btn.size = Vector2(40, 80)
	toggle_btn.position = Vector2(-40, 500)
	
	var style_toggle = StyleBoxFlat.new()
	style_toggle.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	style_toggle.border_width_left = 2
	style_toggle.border_width_top = 2
	style_toggle.border_width_bottom = 2
	style_toggle.border_color = Color(0.2, 0.8, 1.0, 0.8)
	style_toggle.corner_radius_top_left = 8
	style_toggle.corner_radius_bottom_left = 8
	toggle_btn.add_theme_stylebox_override("normal", style_toggle)
	toggle_btn.add_theme_stylebox_override("hover", style_toggle)
	toggle_btn.add_theme_stylebox_override("pressed", style_toggle)
	toggle_btn.pressed.connect(_toggle_panel_collapse)
	panel_node.add_child(toggle_btn)
	
	var main_layout = VBoxContainer.new()
	main_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_node.add_child(main_layout)
	
	# Margin Container for spacing
	var margins = MarginContainer.new()
	margins.add_theme_constant_override("margin_left", 20)
	margins.add_theme_constant_override("margin_right", 20)
	margins.add_theme_constant_override("margin_top", 20)
	margins.add_theme_constant_override("margin_bottom", 20)
	margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margins.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_layout.add_child(margins)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margins.add_child(scroll)
	
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 15)
	scroll.add_child(content)
	
	# Title
	var title = Label.new()
	title.text = "SANDBOX CONTROLLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	content.add_child(title)
	
	var tab_container = TabContainer.new()
	tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(tab_container)
	
	_create_cheats_tab(tab_container)
	_create_weapons_tab(tab_container)
	_create_items_tab(tab_container)
	_create_enemies_tab(tab_container)

func _toggle_panel_collapse() -> void:
	is_collapsed = not is_collapsed
	_update_panel_position(true)

func _update_panel_position(animate: bool) -> void:
	if not panel_node:
		return
	var target_x = 1920 - 500
	if is_collapsed:
		target_x = 1920 - 20
	toggle_btn.text = "<" if is_collapsed else ">"
	if not animate:
		panel_node.position.x = target_x
		return
	var tween = create_tween()
	tween.tween_property(panel_node, "position:x", target_x, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _create_styled_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.12, 0.12, 0.16, 0.9)
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.2, 0.2, 0.25, 0.5)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.18, 0.18, 0.24, 0.9)
	style_hover.border_width_bottom = 2
	style_hover.border_color = Color(0.2, 0.8, 1.0, 0.8) # Cyan border on hover
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", style_hover)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	style_pressed.border_width_bottom = 2
	style_pressed.border_color = Color(0.1, 0.6, 0.8, 0.8)
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("pressed", style_pressed)
	
	btn.pressed.connect(callback)
	return btn

func _create_cheats_tab(tabs: TabContainer) -> void:
	var tab = VBoxContainer.new()
	tab.name = "Cheats"
	tab.add_theme_constant_override("separation", 12)
	tabs.add_child(tab)
	
	# Spacing margin
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	tab.add_child(spacer)
	
	tab.add_child(_create_styled_button("Heal to Full Health", _heal_player))
	
	god_mode_btn = _create_styled_button("God Mode: OFF", _toggle_god_mode)
	tab.add_child(god_mode_btn)
	_update_god_mode_button_text()
	
	tab.add_child(_create_styled_button("Add 1000 Scrap", func(): _add_scrap(1000)))
	tab.add_child(_create_styled_button("Add 1000 Flesh", func(): _add_flesh(1000)))
	tab.add_child(_create_styled_button("Kill All Enemies", _kill_all_enemies))
	tab.add_child(_create_styled_button("Cheat Minigun Synergy", _cheat_minigun_synergy))
	
	# Separation line
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.2, 0.2, 0.25, 0.5)
	tab.add_child(sep)
	
	var return_btn = _create_styled_button("Return to Game", _return_to_game)
	return_btn.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	tab.add_child(return_btn)

func _create_weapons_tab(tabs: TabContainer) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Weapons"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	
	var tab = VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 10)
	scroll.add_child(tab)
	
	# Spacing margin
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	tab.add_child(spacer)
	
	var ranged_title = Label.new()
	ranged_title.text = "Primary (Ranged)"
	ranged_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	tab.add_child(ranged_title)
	
	for w in RANGED_WEAPONS:
		var btn = _create_styled_button(w.name, func(): _equip_ranged(w.path))
		tab.add_child(btn)
		
	var melee_title = Label.new()
	melee_title.text = "Secondary (Melee)"
	melee_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	tab.add_child(melee_title)
	
	for w in MELEE_WEAPONS:
		var btn = _create_styled_button(w.name, func(): _equip_melee(w.path))
		tab.add_child(btn)

func _create_items_tab(tabs: TabContainer) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Items"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	
	var tab = VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 10)
	scroll.add_child(tab)
	
	# Spacing margin
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	tab.add_child(spacer)
	
	var add_all = _create_styled_button("Add All Items to Inv", _add_all_items)
	add_all.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	tab.add_child(add_all)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	tab.add_child(grid)
	
	for item in ITEMS:
		var btn = _create_styled_button(item.name, func(): _add_item(item.path))
		grid.add_child(btn)

func _create_enemies_tab(tabs: TabContainer) -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Enemies"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	
	var tab = VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 10)
	scroll.add_child(tab)
	
	# Spacing margin
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	tab.add_child(spacer)
	
	var spawn_title = Label.new()
	spawn_title.text = "Click to Spawn Enemy:"
	spawn_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	tab.add_child(spawn_title)
	
	for enemy in ENEMIES:
		var btn = _create_styled_button(enemy.name, func(): _spawn_enemy(enemy.path))
		tab.add_child(btn)

func _heal_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	if "stats" in player and player.stats:
		player.stats.heal(9999)

func _toggle_god_mode() -> void:
	GameData.debug_god_mode = not GameData.debug_god_mode
	_update_god_mode_button_text()

func _update_god_mode_button_text() -> void:
	if not god_mode_btn:
		return
	if GameData.debug_god_mode:
		god_mode_btn.text = "God Mode: ON (Invulnerable)"
		god_mode_btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		god_mode_btn.text = "God Mode: OFF (Vulnerable)"
		god_mode_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

func _add_scrap(amount: int) -> void:
	GameData.add_scrap(amount)

func _add_flesh(amount: int) -> void:
	GameData.add_flesh(amount)

func _kill_all_enemies() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(99999)
		else:
			enemy.queue_free()

func _equip_ranged(scene_path: String) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var weapon_wrapper = player.get("active_weapon")
	if not weapon_wrapper:
		return
	var weapon_scene = load(scene_path)
	if not weapon_scene:
		return
	weapon_wrapper.switch_weapon(weapon_scene)

func _equip_melee(scene_path: String) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var second_weapon_container = player.get("second_weapon")
	if not second_weapon_container:
		return
	var melee_scene = load(scene_path)
	if not melee_scene:
		return
	second_weapon_container.switch_weapon(melee_scene)

func _add_item(item_path: String) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var inventory_node = player.get_node_or_null("Inventory")
	if not inventory_node:
		return
	var item_res = load(item_path) as ItemData
	if not item_res:
		return
	inventory_node.add_item(item_res)

func _add_all_items() -> void:
	for item in ITEMS:
		_add_item(item.path)

func _spawn_enemy(enemy_path: String) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var enemy_scene = load(enemy_path)
	if not enemy_scene:
		return
	var enemy = enemy_scene.instantiate()
	var angle = randf_range(0, 2 * PI)
	var offset = Vector2(250, 0).rotated(angle)
	enemy.global_position = player.global_position + offset
	get_tree().current_scene.add_child(enemy)

func _return_to_game() -> void:
	var target = GameData.previous_scene_path
	if target == "" or target == "res://Scenes/Rooms/debug_scene.tscn":
		target = "res://Scenes/Rooms/lab_room.tscn"
	SceneTransition.change_scene(target)

func _cheat_minigun_synergy() -> void:
	_equip_ranged("res://Scenes/Weapon/uzi.tscn")
	_add_item("res://Art/Items/Weapons/Item1.tres")
	_add_item("res://Art/Items/Weapons/Item6.tres")
	_add_item("res://Art/Items/Weapons/Item9_SierraCircular.tres")
