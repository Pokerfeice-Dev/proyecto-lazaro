extends Node
# Temporal (se borra al terminar): graba con Movie Maker clips de "gameplay
# simulado" para el video del final del evento. Un clip por ejecución:
#   godot --write-movie clip.avi --fixed-fps 30 res://tmp_reel.tscn -- clip=cripta

const TERMINAL := preload("res://Scripts/World/synergy_terminal.gd")
const CRYPT := "res://Scenes/Enemies/Crypt/"

var clip := "cripta"
var room: Node
var player: Node2D
var _drive := false
var _melee := false
var _keep_closing := true
var _t := 0.0
var _melee_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("clip="): clip = a.substr(5)
	GameData.current_slot = 99
	GameData.debug_god_mode = true
	GameData.has_completed_tutorial = true
	GameData.has_shown_inventory_tutorial = true
	GameSettings._set_fps_visible(false)
	# todo registrado de antemano: sin carteles de "nueva arma descubierta"
	for cat in CodexData.DATA:
		for id in CodexData.DATA[cat]:
			GameData.unlock_codex_entry(cat, id, false)
	_run()

func _run() -> void:
	await get_tree().process_frame
	match clip:
		"cripta": await _clip_combat(2, "res://Scenes/Rooms/Level2_Room3.tscn", "shotgun", "maze", "lanzallamas", ["CryptGhoul", "CryptGargoyle", "CryptDeadBeekeeperSummoner", "CryptGhoul", "CryptBellKeeper"], 12.0)
		"nucleo": await _clip_combat(3, "res://Scenes/Rooms/Level3_Room2.tscn", "pistol", "maze", "holy_fire", [], 12.0, true)
		"avalanche": await _clip_avalanche()
		"primogenito": await _clip_boss(2, "res://Scenes/Rooms/Level2_Room14BossFight.tscn", 14.0)
		"prometeo": await _clip_boss(3, "res://Scenes/Rooms/Level3_Room4BossFight.tscn", 15.0)
		"omnia": await _clip_omnia()
		"asphodel": await _clip_combat(1, "res://Scenes/Rooms/Level1_Room5.tscn", "pistol", "hacha", "pistola_mente_colmena", [], 12.0)
		"oil": await _clip_combat(1, "res://Scenes/Rooms/Level1_Room7.tscn", "uzi", "hacha", "alto_octanaje", [], 12.0, true)
		"centinela": await _clip_boss(1, "res://Scenes/Rooms/Level1_Room15-BossFight.tscn", 14.0)
	get_tree().quit()

# --- Clips ---

func _clip_combat(level: int, path: String, primary: String, melee: String, syn: String, extra: Array, length: float, use_melee := false) -> void:
	_loadout(level, primary, melee, syn, true)
	center_player = use_melee or level == 1
	await _load_room(path)
	if room.has_method("_start_room"): room._start_room()
	await _wait(0.6)
	for i in extra.size():
		_spawn(CRYPT + extra[i] + ".tscn", Vector2.RIGHT.rotated(i * TAU / extra.size()) * 190.0)
	if extra.is_empty():
		for i in 4:
			_spawn(["res://Scenes/Enemies/EnemyFollower.tscn", "res://Scenes/Enemies/EnemyTank.tscn", "res://Scenes/Enemies/EnemyShooter.tscn", "res://Scenes/Enemies/EnemyFollower.tscn"][i], Vector2.RIGHT.rotated(i * TAU / 4 + 0.4) * 150.0)
	_melee = use_melee
	_drive = true
	await _wait(length)

func _clip_avalanche() -> void:
	_loadout(2, "shotgun", "daga", "", false)
	center_player = true
	await _load_room("res://Scenes/Rooms/Level2_Room1.tscn")
	if room.has_method("_start_room"): room._start_room()
	for i in 4:
		_spawn(CRYPT + ["CryptGhoul", "CryptGargoyle", "CryptGhoul", "CryptDeathSquad"][i] + ".tscn", Vector2.RIGHT.rotated(i * TAU / 4 + 0.4) * 150.0)
	_drive = true
	await _wait(1.5)
	# se arma la sinergia: cartel "ENLACE ESTABLECIDO"
	_keep_closing = false
	GameData.activated_synergies.erase("snowman")
	var equip = player.get_node("Equipment")
	_equip_items(equip, "snowman")
	await _wait(5.0)
	for c in get_tree().root.get_children():
		if c.scene_file_path.ends_with("synergy_activation.tscn"): c.queue_free()
	get_tree().paused = false
	_keep_closing = true
	await _wait(7.0)

func _clip_boss(level: int, path: String, length: float) -> void:
	_loadout(level, "shotgun", "maze", "lanzallamas", true)
	await _load_room(path)
	await _wait(5.5) # cinemática de entrada
	_drive = true
	await _wait(length - 5.5)

func _clip_omnia() -> void:
	_loadout(1, "pistol", "daga", "", false)
	GameData.scrap = 4800
	await _load_room("res://Scenes/Rooms/lab_room.tscn")
	await _wait(0.8)
	var menu = OmniaMenu.new()
	get_tree().root.add_child(menu)
	await _wait(1.2)
	for step in ["d", "d", "r", "tab", "d", "r", "tab", "r", "d", "tab", "r", "d"]:
		_pad(step)
		await _wait(0.75)
	await _wait(1.0)

# --- Armado ---

func _loadout(level: int, primary: String, melee: String, syn: String, mark_seen: bool) -> void:
	GameData.current_level = level
	GameData.current_run_room = 2
	GameData.rooms_before_boss = 7
	GameData.chosen_primary_weapon = primary
	GameData.chosen_melee_weapon = melee
	GameData.unlock_all_synergies()
	for slot in GameData.equipment_slots:
		GameData.equipment_slots[slot] = null
	if syn != "":
		_equip_items(null, syn)
		if mark_seen and not GameData.activated_synergies.has(syn):
			GameData.activated_synergies.append(syn)
	for s in ["lanzallamas", "holy_fire", "hombre_lobo"]:
		if mark_seen and not GameData.activated_synergies.has(s): GameData.activated_synergies.append(s)

func _equip_items(equip, syn: String) -> void:
	for s in TERMINAL.TEST_SYNERGIES:
		if s.id != syn: continue
		var main = s.weapon_type == "primary"
		var slots = [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3] if main else [ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]
		for i in s.items.size():
			GameData.equipment_slots[slots[i]] = load(s.items[i])
	if equip:
		equip.equipment_changed.emit()

var center_player := false

# Centro del piso de la sala (la capa de tiles más grande).
func _room_center() -> Vector2:
	var best := Rect2()
	for layer in room.find_children("*", "TileMapLayer", true, false):
		var used = layer.get_used_rect()
		var ts = Vector2(layer.tile_set.tile_size) * layer.global_scale
		var r = Rect2(layer.global_position + Vector2(used.position) * ts, Vector2(used.size) * ts)
		if r.get_area() > best.get_area(): best = r
	return best.get_center()

func _load_room(path: String) -> void:
	room = load(path).instantiate()
	# la sala pasa a ser la escena actual (el cartel de la sala y los enemigos la usan)
	get_tree().root.add_child(room)
	get_tree().current_scene = room
	for i in 30:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
		if player: break
	await _wait(0.4)
	InputMode.instance()._set_gamepad(true)
	if center_player and player:
		player.global_position = _room_center()

func _spawn(path: String, offset: Vector2) -> void:
	if not ResourceLoader.exists(path) or not player: return
	var e = load(path).instantiate()
	room.add_child(e)
	e.global_position = player.global_position + offset
	if e.has_method("alert_to_player"): e.alert_to_player()

# --- Jugador "automático" ---

func _physics_process(delta: float) -> void:
	_t += delta
	if _keep_closing:
		for c in get_tree().root.get_children():
			if c is UIWindow or c.scene_file_path.ends_with("synergy_activation.tscn"):
				c.queue_free()
				get_tree().paused = false
	if not _drive or not is_instance_valid(player): return
	InputMode.instance()._set_gamepad(true)
	var target = _nearest_enemy()
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	if not target:
		Input.action_release("shoot")
		return
	var to = target.global_position - player.global_position
	InputMode.instance().aim_dir = to.normalized()
	InputMode.instance()._has_aimed = true
	Input.action_press("shoot")
	# se mueve en círculo alrededor del enemigo, acercándose o alejándose
	var want = 70.0 if _melee else 170.0
	var move = to.normalized().orthogonal() * (1.0 if sin(_t * 0.7) > 0 else -1.0)
	if to.length() > want + 40.0: move += to.normalized() * 1.2
	elif to.length() < want - 40.0: move -= to.normalized() * 1.2
	_press_dir(move.normalized())
	if _melee:
		_melee_t -= delta
		if _melee_t <= 0.0:
			_melee_t = 0.45
			Input.action_press("attack_melee")
		else:
			Input.action_release("attack_melee")

func _press_dir(d: Vector2) -> void:
	if d.x > 0.2: Input.action_press("move_right", d.x)
	if d.x < -0.2: Input.action_press("move_left", -d.x)
	if d.y > 0.2: Input.action_press("move_down", d.y)
	if d.y < -0.2: Input.action_press("move_up", -d.y)

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d = INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(e) or not e is Node2D or e.get("is_dying") == true: continue
		var d = e.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _pad(step: String) -> void:
	var buttons = {"d": JOY_BUTTON_DPAD_DOWN, "r": JOY_BUTTON_DPAD_RIGHT, "tab": JOY_BUTTON_RIGHT_SHOULDER}
	for pressed in [true, false]:
		var ev = InputEventJoypadButton.new()
		ev.button_index = buttons[step]
		ev.pressed = pressed
		Input.parse_input_event(ev)

func _wait(s: float) -> void:
	await get_tree().create_timer(s, true).timeout
