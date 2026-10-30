extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
@export var mannequin_scene: PackedScene = preload("res://Scenes/Enemies/dummy.tscn")
@export var shooter_scene: PackedScene = preload("res://Scenes/Enemies/EnemyShooter.tscn")

enum TutorialState {
	MOVE,
	DODGE,
	AIM,
	SHOOT,
	MELEE,
	MANNEQUIN,
	COMBAT,
	SYNERGY_PICKUP,
	SYNERGY_OPEN_INVENTORY,
	SYNERGY_EQUIP,
	SYNERGY_ATTACK,
	COMPLETE
}

var current_state: TutorialState = TutorialState.MOVE

const ICON_CHECK := preload("res://Art/Ui/svg/icon_check.svg")
const STEP_TOTAL := 11 # pasos antes de COMPLETE
const LEARNED := [
	"Moverte y esquivar",
	"Disparar y golpear cuerpo a cuerpo",
	"Pelear con obstáculos de por medio",
	"Combinar piezas en una sinergia",
]

# Tarjeta del paso (abajo) y manito/círculo/teclas en el mundo.
var tutorial_hud: TutorialHud = null
var pointer: TutorialPointer = null
var _synergy_drops: Array = []
var _drops_picked := 0
var _last_step_text := ""
var _mannequin_home := Vector2(-96, -104)

var mannequin_inst: Node2D = null
var shooter_inst: Node = null
var mannequin_hits_received: int = 0
var synergy_hits_received: int = 0
var _synergy_transition_pending := false
var _step_hint_elapsed := 0.0
var _dodge_cinematic: Node = null
# Apuntar: tiempo acumulado moviendo la mira (mouse o analógico derecho).
var _aim_time := 0.0
# Golpes al maniquí con el arma cuerpo a cuerpo (paso MELEE).
var _melee_hits := 0
var _last_melee_msec := -10000

func _ready() -> void:
	# El inventario pausa el árbol: el tutorial debe detectar cuando se abre para
	# poder pasar del paso 7 (abrir) al 8 (equipar con clic derecho).
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Lo que se desbloquee o equipe aquí es de prueba: al salir se vuelve atrás.
	GameData.begin_sandbox()
	_spawn_player()
	_spawn_mannequin()
	# Tutorial ya hecho: la sala queda libre (armería, incubadora, Victoria y el maniquí).
	if GameData.has_completed_tutorial:
		current_state = TutorialState.COMPLETE
		return
	_setup_tutorial_ui()
	InputMode.instance().mode_changed.connect(_on_input_mode_changed)
	_update_dialogue_text()

# Teclado <-> joystick: los textos del paso cambian (clic derecho / X, etc.).
func _on_input_mode_changed(_gamepad: bool) -> void:
	_last_step_text = ""
	_update_dialogue_text()

func _exit_tree() -> void:
	if is_instance_valid(_dodge_cinematic):
		_dodge_cinematic.restore()
	_set_synergy_tutorial_inventory_guidance(false)
	GameData.end_sandbox()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack_melee"):
		_last_melee_msec = Time.get_ticks_msec()
	if current_state == TutorialState.DODGE:
		_process_dodge()
	elif current_state == TutorialState.AIM:
		_process_aim(delta)
	_check_state_transitions()
	_check_drops_picked()
	_step_hint_elapsed += delta
	if current_state != TutorialState.COMPLETE and _step_hint_elapsed >= 7.0 and tutorial_hud:
		_step_hint_elapsed = 0.0
		tutorial_hud.nudge()

func _is_move_input_pressed() -> bool:
	return Input.is_action_pressed("move_left") or \
		Input.is_action_pressed("move_right") or \
		Input.is_action_pressed("move_up") or \
		Input.is_action_pressed("move_down")

func _check_state_transitions() -> void:
	if current_state == TutorialState.MOVE:
		_check_move_transition()
	elif current_state == TutorialState.SHOOT:
		_check_shoot_transition()
	elif current_state == TutorialState.MELEE:
		_check_melee_transition()
	elif current_state == TutorialState.SYNERGY_EQUIP:
		_check_synergy_equip_transition()
	elif current_state == TutorialState.SYNERGY_OPEN_INVENTORY:
		_check_inventory_open_transition()

func _check_move_transition() -> void:
	if _is_move_input_pressed():
		_transition_to_state(TutorialState.AIM)

func _check_shoot_transition() -> void:
	if Input.is_action_just_pressed("shoot"):
		_transition_to_state(TutorialState.MELEE)

func _check_melee_transition() -> void:
	if _melee_hits >= 2:
		_transition_to_state(TutorialState.MANNEQUIN)

# --- Esquivar con dash ---

func _process_dodge() -> void:
	if is_instance_valid(_dodge_cinematic): return
	var player = GameData.get_player()
	if not is_instance_valid(player) or player.is_dashing: return
	if not is_instance_valid(shooter_inst) or shooter_inst.is_dying:
		_spawn_shooter()
		return
	if not shooter_inst.is_inside_tree() or shooter_inst.is_spawning: return
	_dodge_cinematic = preload("res://Scripts/World/tutorial_dodge_cinematic.gd").new()
	_dodge_cinematic.player = player
	_dodge_cinematic.shooter = shooter_inst
	_dodge_cinematic.completed.connect(func(): _transition_to_state(TutorialState.COMBAT))
	add_child(_dodge_cinematic)

# --- Apuntar ---

func _process_aim(delta: float) -> void:
	var aiming := false
	if InputMode.is_gamepad():
		var pads = Input.get_connected_joypads()
		var pad = pads[0] if not pads.is_empty() else 0
		aiming = Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)).length() > 0.5
	else:
		aiming = Input.get_last_mouse_velocity().length() > 150.0
	if aiming:
		_aim_time += delta
	if _aim_time >= 1.2:
		_transition_to_state(TutorialState.SHOOT)

func _check_synergy_equip_transition() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var equip = player.get_node_or_null("Equipment")
	if not equip:
		return
	var active_syns = SynergyManager.get_active_synergies(equip, "pistol", true)
	if not active_syns.has("pistola_mente_colmena"):
		return
	_transition_to_state(TutorialState.SYNERGY_ATTACK)

func _check_inventory_open_transition() -> void:
	if _is_player_inventory_open():
		_transition_to_state(TutorialState.SYNERGY_EQUIP)

func _transition_to_state(new_state: TutorialState) -> void:
	current_state = new_state
	_step_hint_elapsed = 0.0
	# primero se arma el paso (enemigo, piezas) para que la manito tenga a quién señalar
	if new_state != TutorialState.DODGE:
		if is_instance_valid(_dodge_cinematic):
			_dodge_cinematic.restore()
			_dodge_cinematic.queue_free()
	if current_state == TutorialState.DODGE or current_state == TutorialState.COMBAT:
		_spawn_shooter()
	elif current_state == TutorialState.SYNERGY_PICKUP:
		_setup_synergy_step()
	elif current_state == TutorialState.SYNERGY_EQUIP:
		_set_synergy_tutorial_inventory_guidance(true)
	elif current_state == TutorialState.SYNERGY_ATTACK:
		_set_synergy_tutorial_inventory_guidance(false)
		_setup_synergy_attack_step()
	elif current_state == TutorialState.COMPLETE:
		_set_synergy_tutorial_inventory_guidance(false)
		_show_complete_screen()
	_update_dialogue_text()

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
	p_inst.ready.connect(_initialize_tutorial_player.bind(p_inst), CONNECT_ONE_SHOT)

func _initialize_tutorial_player(player: Node) -> void:
	if not is_instance_valid(player) or not "stats" in player or not player.stats:
		return
	var s = player.stats
	s.current_health = s.max_health
	s.min_health_floor = 10 # en el tutorial de combate el jugador no puede morir
	s.health_changed.emit(s.current_health, s.max_health)

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
		_mannequin_home = mannequin_inst.global_position
		mannequin_inst.hit_received.connect(_on_mannequin_hit)
	elif mannequin_scene:
		mannequin_inst = mannequin_scene.instantiate()
		mannequin_inst.global_position = _mannequin_home
		mannequin_inst.hit_received.connect(_on_mannequin_hit)
		get_tree().current_scene.call_deferred("add_child", mannequin_inst)

func _on_mannequin_hit() -> void:
	if current_state == TutorialState.MELEE:
		# cuenta solo si el golpe llegó justo después de usar el arma cuerpo a cuerpo
		if Time.get_ticks_msec() - _last_melee_msec < 700:
			_melee_hits += 1
			_update_dialogue_text()
		return
	if current_state == TutorialState.MANNEQUIN:
		mannequin_hits_received += 1
		_update_dialogue_text()
		if mannequin_hits_received >= 3:
			_transition_to_state(TutorialState.DODGE)
		return
	if current_state == TutorialState.SYNERGY_ATTACK:
		synergy_hits_received += 1
		_update_dialogue_text()
		if synergy_hits_received >= 3:
			_transition_to_state(TutorialState.COMPLETE)

func _setup_synergy_step() -> void:
	GameData.unlock_synergy("pistola_mente_colmena")
	_connect_tutorial_equipment()
	_spawn_synergy_items()

func _connect_tutorial_equipment() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var equipment = player.get_node_or_null("Equipment")
	if equipment and not equipment.equipment_changed.is_connected(_on_tutorial_equipment_changed):
		equipment.equipment_changed.connect(_on_tutorial_equipment_changed)

func _on_tutorial_equipment_changed() -> void:
	if current_state != TutorialState.SYNERGY_EQUIP or _drops_picked < _synergy_drops.size():
		return
	_update_dialogue_text()
	if _get_equipped_synergy_piece_count() == 3:
		_finish_synergy_equipping()

func _finish_synergy_equipping() -> void:
	if _synergy_transition_pending:
		return
	_synergy_transition_pending = true
	_set_synergy_tutorial_inventory_guidance(false)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inventory_ui = player.find_child("InventoryUI", true, false)
		if inventory_ui and inventory_ui.visible:
			inventory_ui.toggle_visibility()
	_transition_to_state(TutorialState.SYNERGY_ATTACK)

func _spawn_synergy_items() -> void:
	var item_drop_scene = preload("res://Scenes/Items/item_drop_world.tscn")
	var items = [
		preload("res://Art/Items/Weapons/Item7_Colmena.tres"),
		preload("res://Art/Items/Weapons/Item3.tres"),
		preload("res://Art/Items/Weapons/Item8_CabezaHumana.tres")
	]
	var base_pos = Vector2(-120, -40) # piso libre, lejos de las jardineras
	var offsets = [Vector2(-50, 0), Vector2(0, 0), Vector2(50, 0)]
	for i in range(items.size()):
		_spawn_single_synergy_drop(item_drop_scene, items[i], base_pos + offsets[i])

func _spawn_single_synergy_drop(scene: PackedScene, data: ItemData, pos: Vector2) -> void:
	if not scene or not data:
		return
	var inst = scene.instantiate()
	inst.item_data = data
	inst.global_position = pos
	get_tree().current_scene.call_deferred("add_child", inst)
	_synergy_drops.append(inst)

# Cuenta las piezas que ya se levantaron del suelo para avanzar el sub-paso.
func _check_drops_picked() -> void:
	if current_state != TutorialState.SYNERGY_PICKUP or _synergy_drops.is_empty(): return
	var picked = _synergy_drops.filter(func(d): return not is_instance_valid(d)).size()
	if picked == _drops_picked: return
	_drops_picked = picked
	if _drops_picked == _synergy_drops.size():
		_transition_to_state(TutorialState.SYNERGY_OPEN_INVENTORY)
	else:
		_update_dialogue_text()

func _setup_synergy_attack_step() -> void:
	synergy_hits_received = 0
	_respawn_or_reset_mannequin()

func _respawn_or_reset_mannequin() -> void:
	if not mannequin_inst or not is_instance_valid(mannequin_inst):
		_spawn_mannequin()
		return
	mannequin_inst.global_position = _mannequin_home

func _spawn_shooter() -> void:
	if is_instance_valid(shooter_inst) and not shooter_inst.is_dying:
		return
	if not shooter_scene:
		return
	
	var spawn_node = get_node_or_null("Spawns/Spawn1")
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
		_transition_to_state(TutorialState.SYNERGY_PICKUP)

func _setup_tutorial_ui() -> void:
	tutorial_hud = TutorialHud.new()
	add_child(tutorial_hud)
	pointer = TutorialPointer.new()
	add_child(pointer)

# Cada paso: tarjeta con las teclas, teclas sobre el jugador para los pasos
# de control, y manito + círculo sobre el objetivo cuando hay que ir a algún lado.
func _update_dialogue_text() -> void:
	if not tutorial_hud:
		return
	match current_state:
		TutorialState.MOVE:
			_show_step(0, "Muévete por la sala", ["W", "A", "S", "D"], true)
		TutorialState.DODGE:
			tutorial_hud.hide_card()
			pointer.clear()
		TutorialState.AIM:
			_show_step(1, _pad_or_keys("Apunta con el analógico derecho: la mira lo sigue", "Apunta con el mouse: tus armas siguen al cursor"), ["MOUSE_MOVE"], true)
		TutorialState.SHOOT:
			_show_step(2, "Dispara con tu arma a distancia", ["MOUSE_L"], true)
		TutorialState.MELEE:
			_show_step(3, "Golpea al maniquí con tu arma cuerpo a cuerpo", ["MOUSE_R"], false, [mannequin_inst], "%d/2" % _melee_hits)
		TutorialState.MANNEQUIN:
			_show_step(4, "Ahora dispárale al maniquí", ["MOUSE_L"], false, [mannequin_inst], "%d/3" % mannequin_hits_received)
		TutorialState.COMBAT:
			_show_step(6, "Elimina al enemigo. Los obstáculos bloquean sus disparos", ["MOUSE_L"], false, [shooter_inst])
		TutorialState.SYNERGY_PICKUP:
			_show_synergy_pickup_step()
		TutorialState.SYNERGY_OPEN_INVENTORY:
			_show_synergy_open_inventory_step()
		TutorialState.SYNERGY_EQUIP:
			_show_synergy_right_click_step()
		TutorialState.SYNERGY_ATTACK:
			_show_step(10, "¡Tu pistola mutó en Mente Colmena! Dispárale al maniquí", ["MOUSE_L"], false, [mannequin_inst], "%d/3" % synergy_hits_received)
		TutorialState.COMPLETE:
			tutorial_hud.hide_card()
			pointer.clear()

# Paso 7: levantar las piezas.
func _show_synergy_pickup_step() -> void:
	_set_synergy_tutorial_inventory_guidance(false)
	var remaining = _synergy_drops.filter(func(d): return is_instance_valid(d))
	_show_step(7, "Recoge las 3 piezas del suelo", ["E"], false, remaining, "%d/3" % _drops_picked, 26.0)

func _show_synergy_open_inventory_step() -> void:
	var equipped_count := _get_equipped_synergy_piece_count()
	_set_synergy_tutorial_inventory_guidance(false)
	_show_step(8, _pad_or_keys("Abre el inventario para instalar las piezas de la sinergia", "Abre el inventario (I o TAB) para instalar las piezas de la sinergia"), ["I"], true, [], "%d/3" % equipped_count)

# Paso 8: el inventario ya está abierto; ahora se muestra la acción exacta.
func _show_synergy_right_click_step() -> void:
	if not _is_player_inventory_open():
		_transition_to_state(TutorialState.SYNERGY_OPEN_INVENTORY)
		return
	var equipped_count := _get_equipped_synergy_piece_count()
	_set_synergy_tutorial_inventory_guidance(true)
	if InputMode.is_gamepad():
		_show_step(9, "Elige cada pieza y presiona X. Se equipan en los 3 huecos resaltados de ARMA PRINCIPAL", ["E"], false, [], "%d/3" % equipped_count)
	else:
		_show_step(9, "Haz CLIC DERECHO sobre cada pieza. Se equipan en los 3 huecos resaltados de ARMA PRINCIPAL", ["MOUSE_R"], false, [], "%d/3" % equipped_count)

# Texto distinto para joystick y para teclado.
func _pad_or_keys(pad_text: String, keys_text: String) -> String:
	return pad_text if InputMode.is_gamepad() else keys_text

func _get_equipped_synergy_piece_count() -> int:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return 0
	var equipment = player.get_node_or_null("Equipment")
	if not equipment:
		return 0
	var pieces := [
		preload("res://Art/Items/Weapons/Item7_Colmena.tres"),
		preload("res://Art/Items/Weapons/Item3.tres"),
		preload("res://Art/Items/Weapons/Item8_CabezaHumana.tres")
	]
	var slots := [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3]
	var count := 0
	for slot in slots:
		if pieces.has(equipment.slots.get(slot)):
			count += 1
	return count

func _is_player_inventory_open() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false
	var inventory_ui = player.find_child("InventoryUI", true, false)
	return inventory_ui != null and inventory_ui.visible

func _set_synergy_tutorial_inventory_guidance(enabled: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var inventory_ui = player.find_child("InventoryUI", true, false)
	if inventory_ui and inventory_ui.has_method("set_synergy_tutorial_weapon_slots"):
		inventory_ui.set_synergy_tutorial_weapon_slots(enabled)

func _show_step(index: int, text: String, inputs: Array, inputs_over_player: bool, targets: Array = [], counter := "", hand_height := 44.0) -> void:
	# mismo paso y mismo texto: solo se actualiza el contador (sin re-animar la tarjeta)
	if text == _last_step_text:
		tutorial_hud.set_counter(counter)
	else:
		tutorial_hud.set_step(index, STEP_TOTAL, text, inputs, counter)
	_last_step_text = text
	var valid_targets = targets.filter(func(t): return t != null and is_instance_valid(t))
	pointer.point_at(valid_targets, hand_height)
	pointer.show_inputs(inputs if inputs_over_player else [])
	tutorial_hud.track(valid_targets[0] if not valid_targets.is_empty() else null)

# --- Fin del tutorial ---

func _show_complete_screen() -> void:
	GameData.has_completed_tutorial = true
	GameData.save_game(GameData.current_slot)
	var window = UIWindow.open("  ENTRENAMIENTO", ICON_CHECK, 640)
	window.body.add_child(_complete_header())
	window.body.add_child(UIStyle.divider())
	for skill in LEARNED:
		window.body.add_child(_learned_row(skill))
	# Tanto confirmar como cerrar con ESC/B llevan al laboratorio.
	window.closed.connect(_complete_tutorial_and_exit, CONNECT_ONE_SHOT)
	window.add_button("VOLVER AL LABORATORIO", true, "E", window.close)

func _complete_header() -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var badge = UIStyle.panel(UIStyle.TEX_SLOT["equipped"])
	badge.custom_minimum_size = Vector2(76, 76)
	var check = UIStyle.icon(ICON_CHECK, 44)
	check.modulate = UIStyle.COLOR_TEAL
	badge.add_child(check)
	row.add_child(badge)
	var col = VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(UIStyle.label("TUTORIAL COMPLETADO", 34, UIStyle.COLOR_GOLD))
	col.add_child(UIStyle.label("Sinergia aprendida: Mente Colmena", 18, UIStyle.COLOR_TEAL))
	row.add_child(col)
	return row

func _learned_row(text: String) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var check = UIStyle.icon(ICON_CHECK, 20)
	check.modulate = UIStyle.COLOR_TEAL
	row.add_child(check)
	row.add_child(UIStyle.label(text, 18, UIStyle.COLOR_TEXT))
	return row

func _complete_tutorial_and_exit() -> void:
	get_tree().paused = false
	GameData.last_room_name = name # el laboratorio aparece junto a la puerta de entrenamiento
	SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")
