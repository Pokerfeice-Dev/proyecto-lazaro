extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
@export var mannequin_scene: PackedScene = preload("res://Scenes/Enemies/dummy.tscn")
@export var shooter_scene: PackedScene = preload("res://Scenes/Enemies/EnemyShooter.tscn")

enum TutorialState {
	MOVE,
	DASH,
	SHOOT,
	MELEE,
	MANNEQUIN,
	COMBAT,
	COMPLETE
}

var current_state: TutorialState = TutorialState.MOVE

var hud_layer: CanvasLayer = null
var dialogue_panel: PanelContainer = null
var dialogue_label: Label = null

var center_layer: CanvasLayer = null
var center_label: Label = null

var mannequin_inst: Node2D = null
var shooter_inst: Node = null
var mannequin_hits_received: int = 0

func _ready() -> void:
	_spawn_player()
	_setup_tutorial_ui()
	_spawn_mannequin()
	_update_dialogue_text()

func _process(_delta: float) -> void:
	_check_state_transitions()

func _is_move_input_pressed() -> bool:
	return Input.is_action_pressed("move_left") or \
		Input.is_action_pressed("move_right") or \
		Input.is_action_pressed("move_up") or \
		Input.is_action_pressed("move_down")

func _check_state_transitions() -> void:
	if current_state == TutorialState.MOVE:
		_check_move_transition()
	elif current_state == TutorialState.DASH:
		_check_dash_transition()
	elif current_state == TutorialState.SHOOT:
		_check_shoot_transition()
	elif current_state == TutorialState.MELEE:
		_check_melee_transition()

func _check_move_transition() -> void:
	if _is_move_input_pressed():
		_transition_to_state(TutorialState.DASH)

func _check_dash_transition() -> void:
	if Input.is_action_just_pressed("dash"):
		_transition_to_state(TutorialState.SHOOT)

func _check_shoot_transition() -> void:
	if Input.is_action_just_pressed("shoot"):
		_transition_to_state(TutorialState.MELEE)

func _check_melee_transition() -> void:
	if Input.is_action_just_pressed("attack_melee"):
		_transition_to_state(TutorialState.MANNEQUIN)

func _transition_to_state(new_state: TutorialState) -> void:
	current_state = new_state
	_update_dialogue_text()
	
	if current_state == TutorialState.COMBAT:
		_spawn_shooter()
	elif current_state == TutorialState.COMPLETE:
		_show_complete_screen()

func _spawn_player() -> void:
	var spawn_node = get_node_or_null("player_spawn")
	if not spawn_node:
		return
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		_spawn_fresh_player(spawn_node.global_position)
	else:
		_reposition_existing_player(players[0], spawn_node.global_position)

func _spawn_fresh_player(spawn_pos: Vector2) -> void:
	if not player_scene:
		return
	var p_inst = player_scene.instantiate()
	p_inst.global_position = spawn_pos
	get_tree().current_scene.call_deferred("add_child", p_inst)
	p_inst.ready.connect(func():
		var s = p_inst.stats
		s.current_health = s.max_health
		s.min_health_floor = 10 # en el tutorial de combate el jugador no puede morir
		s.health_changed.emit(s.current_health, s.max_health)
	)

func _reposition_existing_player(player: Node, spawn_pos: Vector2) -> void:
	player.global_position = spawn_pos
	if player.process_mode == Node.PROCESS_MODE_DISABLED:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.show()
	if "stats" in player:
		var s = player.stats
		s.current_health = s.max_health
		s.min_health_floor = 10 # en el tutorial de combate el jugador no puede morir
		s.health_changed.emit(s.current_health, s.max_health)
	if player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()

func _spawn_mannequin() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is Mannequin or enemy.name == "Dummy":
			mannequin_inst = enemy
			break
			
	if mannequin_inst:
		mannequin_inst.hit_received.connect(_on_mannequin_hit)
	elif mannequin_scene:
		mannequin_inst = mannequin_scene.instantiate()
		mannequin_inst.global_position = Vector2(0, -100) # Centered in the arena map
		mannequin_inst.hit_received.connect(_on_mannequin_hit)
		get_tree().current_scene.call_deferred("add_child", mannequin_inst)

func _on_mannequin_hit() -> void:
	if current_state == TutorialState.MANNEQUIN:
		mannequin_hits_received += 1
		_update_dialogue_text()
		if mannequin_hits_received >= 3:
			_transition_to_state(TutorialState.COMBAT)

func _spawn_shooter() -> void:
	if not shooter_scene:
		return
	
	var spawn_node = get_node_or_null("Spawn1")
	var spawn_pos = Vector2(1, -84)
	if spawn_node:
		spawn_pos = spawn_node.global_position
		
	shooter_inst = shooter_scene.instantiate()
	shooter_inst.global_position = spawn_pos
	shooter_inst.enemy_died.connect(_on_shooter_died)
	get_tree().current_scene.call_deferred("add_child", shooter_inst)
	
	if shooter_inst.has_method("spawn_appear"):
		shooter_inst.call_deferred("spawn_appear")

func _on_shooter_died(_enemy: Node) -> void:
	if current_state == TutorialState.COMBAT:
		_transition_to_state(TutorialState.COMPLETE)

func _setup_tutorial_ui() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 95
	add_child(hud_layer)
	
	dialogue_panel = PanelContainer.new()
	dialogue_panel.custom_minimum_size = Vector2(0, 100)
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 100
	dialogue_panel.offset_right = -100
	dialogue_panel.offset_bottom = -30
	dialogue_panel.offset_top = -130
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	sb.border_color = Color(0.0, 0.8, 0.5)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	dialogue_panel.add_theme_stylebox_override("panel", sb)
	
	hud_layer.add_child(dialogue_panel)
	
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_top", 10)
	margin_container.add_theme_constant_override("margin_bottom", 10)
	dialogue_panel.add_child(margin_container)
	
	dialogue_label = Label.new()
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	dialogue_label.add_theme_font_size_override("font_size", 24)
	dialogue_label.add_theme_color_override("font_color", Color(0, 1, 0.8))
	margin_container.add_child(dialogue_label)

func _update_dialogue_text() -> void:
	if not dialogue_label:
		return
		
	match current_state:
		TutorialState.MOVE:
			dialogue_label.text = "Movimiento con WASD"
		TutorialState.DASH:
			dialogue_label.text = "Esquiva con ESPACIO"
		TutorialState.SHOOT:
			dialogue_label.text = "Click izquierdo disparar arma a distancia"
		TutorialState.MELEE:
			dialogue_label.text = "Click derecho arma melee"
		TutorialState.MANNEQUIN:
			if mannequin_hits_received == 0:
				dialogue_label.text = "Bien, ve a golpear al maniqui"
			else:
				dialogue_label.text = "Bien, ve a golpear al maniqui (%d/3)" % mannequin_hits_received
		TutorialState.COMBAT:
			dialogue_label.text = "Los obstáculos bloquean los proyectiles, elimina a tu enemigo"
		TutorialState.COMPLETE:
			dialogue_panel.visible = false

func _show_complete_screen() -> void:
	_setup_center_ui()
	center_label.text = "Tutorial completado"
	
	var t = get_tree().create_timer(3.0)
	t.timeout.connect(_complete_tutorial_and_exit)

func _setup_center_ui() -> void:
	center_layer = CanvasLayer.new()
	center_layer.layer = 96
	add_child(center_layer)
	
	center_label = Label.new()
	center_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.text = ""
	center_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	center_label.add_theme_font_size_override("font_size", 48)
	center_label.add_theme_color_override("font_color", Color(0, 1, 0.8))
	center_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	center_label.add_theme_constant_override("outline_size", 6)
	
	center_layer.add_child(center_label)

func _complete_tutorial_and_exit() -> void:
	GameData.current_slot = GameData.current_slot
	GameData.save_game(GameData.current_slot)
	SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
