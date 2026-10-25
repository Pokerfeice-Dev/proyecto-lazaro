extends Node
## GameData – Autoload singleton.
## Persists scrap y niveles de mejora de armas entre cambios de escena y muertes.

# ── Scrap ───────────────────────────────────────────────────────────────────
var scrap: int = 0
signal scrap_changed(new_amount: int)

# ── Flesh ───────────────────────────────────────────────────────────────────
var flesh: int = 0
signal flesh_changed(new_amount: int)

# ── Metadata ───────────────────────────────────────────────────────────────────
var play_time: float = 0.0
var current_slot: int = 1
var previous_scene_path: String = ""
var debug_god_mode: bool = false

var max_reached_level: int = 1
var max_reached_room: int = 1
var total_deployments: int = 0
var last_save_time: String = ""

# ── Core Upgrades & Runs ──────────────────────────────────────────────────────
var core_upgrades: Dictionary = {
	"integridad_estructural": 0,
	"servomotores": 0,
	"blindaje_compuesto": 0,
	"sistema_ataque": 0,
	"sinapsis_acelerada": 0,
	"balistica_predictiva": 0,
	"compactador": 0,
	"biomasa_eficiente": 0,
	"imanes_industriales": 0,
	"recuperacion_restos": 0,
	"escaner_objetivos": 0
}

var unlocked_synergies: Array[String] = []
var activated_synergies: Array[String] = []
var synergy_item_hints: Dictionary = {}
var unlocked_protocols: Array[String] = []
var active_protocol: String = ""
var has_died_once: bool = false
var has_shown_inventory_tutorial: bool = false
## Pantalla de título ("Presiona cualquier botón") al abrir el juego y cuando
## el modo stand vuelve al menú para la próxima persona.
var show_title_screen := true
var has_completed_tutorial: bool = false # la sala de entrenamiento ya no repite los pasos
var last_room_name: String = "" # nombre de la última sala de la que salimos, usado para elegir el spawn correcto
var chosen_primary_weapon: String = "pistol"
var chosen_melee_weapon: String = "daga"
var temporary_damage_multiplier: float = 1.0

## Los temporizadores de efectos pueden sobrevivir a un cambio de escena.
## Esta restauración vive en el autoload para no capturar jugadores liberados.
func clear_temporary_damage_multiplier() -> void:
	temporary_damage_multiplier = 1.0
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()
var vampiric_kills_counter: int = 0
var protocol_recycled_levels: Array[int] = []
var protocol_run_stats: Dictionary = {}

func reset_protocol_run() -> void:
	vampiric_kills_counter = 0
	temporary_damage_multiplier = 1.0
	protocol_recycled_levels.clear()
	protocol_run_stats.clear()

func record_protocol(metric: String, amount: float) -> void:
	if active_protocol.is_empty() or amount <= 0.0: return
	protocol_run_stats[metric] = float(protocol_run_stats.get(metric, 0.0)) + amount

func protocol_enemy_defeated(enemy: Node2D) -> void:
	if enemy.get("is_clone") == true: return
	if active_protocol == "nucleo_vampirico":
		vampiric_kills_counter += 1
		if vampiric_kills_counter >= 10:
			vampiric_kills_counter -= 10
			var clot = preload("res://Scripts/Effects/protocol_clot.gd").new()
			clot.position = get_tree().current_scene.to_local(enemy.global_position) if get_tree().current_scene is Node2D else enemy.global_position
			get_tree().current_scene.add_child.call_deferred(clot)
	if active_protocol == "reciclaje_instantaneo" and enemy.get_script().resource_path.get_file() in ["boss1.gd", "boss2.gd", "boss3_prometeo.gd"]:
		var before := scrap
		add_scrap(50)
		record_protocol("scrap", scrap - before)

func can_recycle_protocol(item: ItemData, inventory: Inventory) -> bool:
	var scene := get_tree().current_scene
	return active_protocol == "reciclaje_instantaneo" and scene != null and scene.is_in_group("combat_room") and current_run_room > 0 and not protocol_recycled_levels.has(current_level) and item != null and inventory != null and inventory.items.has(item)

func recycle_protocol_item(item: ItemData, inventory: Inventory) -> bool:
	if not can_recycle_protocol(item, inventory): return false
	# Marcar antes de emitir inventory_updated para que el botón se refresque bloqueado.
	protocol_recycled_levels.append(current_level)
	inventory.remove_item(item)
	var before := scrap
	add_scrap(40)
	record_protocol("scrap", scrap - before)
	return true

func protocol_summary() -> String:
	match active_protocol:
		"circuito_emergencia", "blindaje_reactivo": return "%d daño evitado" % int(protocol_run_stats.get("blocked", 0))
		"reparacion_autonoma", "nucleo_vampirico": return "%d HP recuperados" % int(protocol_run_stats.get("healed", 0))
		"sobrecarga": return "%d daño extra" % int(protocol_run_stats.get("overload_damage", 0))
		"reflejo_sintetico": return "%d daño de ecos" % int(protocol_run_stats.get("echo_damage", 0))
		"enjambre_residual": return "%d daño de abeja" % int(protocol_run_stats.get("bee_damage", 0))
		"furia_de_titanio": return "%d s en furia" % int(protocol_run_stats.get("furia_seconds", 0))
		"reciclaje_instantaneo": return "%d chatarra extra" % int(protocol_run_stats.get("scrap", 0))
	return ""

# ── Level Progression: zona 1 -> boss 1 -> zona 2 -> boss 2 -> zona 3 -> Prometeo -> gana la run ──
const MAX_LEVEL_FOR_NOW: int = 3
const BOSS_ROOMS := {
	1: "res://Scenes/Rooms/Level1_Room15-BossFight.tscn",
	2: "res://Scenes/Rooms/Level2_Room14BossFight.tscn",
	3: "res://Scenes/Rooms/Level3_Room4BossFight.tscn",
}
## Nombre de cada zona (cartel de inicio de sala). El códice usa los mismos.
const ZONE_NAMES := {
	1: "Distrito Asphodel",
	2: "La Cripta",
	3: "El Núcleo",
}
## Tiendas de Ygor por zona. La zona 3 todavía no tiene la suya, así que ahí no aparece.
const YGOR_ROOMS := {
	1: "res://Scenes/Rooms/Level1_Room12(Ygor1).tscn",
	2: "res://Scenes/Rooms/Level2_Room13(Ygor1).tscn",
}
var current_level: int = 1
var just_won_run: bool = false

# ── Modo evento ──────────────────────────────────────────────────────────────
# Se habilita solo en el preset de Buenos Aires Game Dev. Usa el sandbox para
# que ningún avance, gasto o desbloqueo de la demo llegue a los slots normales.
const EVENT_DEMO_ROOMS_BEFORE_BOSS := 6
const EVENT_OMNIA_LEVEL := 3 # 50% de 5 redondeado a un nivel entero jugable.
var event_demo_active := false
## Interruptor para probar el modo evento sin exportar: Proyecto > Configuración
## del proyecto > (Avanzado) frankengun/modo_evento. Después del evento se apaga.
const EVENT_SETTING := "frankengun/modo_evento"

## true en el build "Buenos Aires Game Dev" o con el interruptor prendido
## (editor y cualquier exportación).
func is_event_build() -> bool:
	return OS.has_feature("event_demo") or bool(ProjectSettings.get_setting(EVENT_SETTING, false))
## Cheats (menú U / T, teclas F1-F12, "ç" para limpiar la sala, cambio de
## armas con 1-6): apagados salvo que se prenda frankengun/cheats en la
## configuración del proyecto. En el build del evento quedan prendidos
## (ahí está la pestaña Registro).
const CHEATS_SETTING := "frankengun/cheats"

func cheats_enabled() -> bool:
	return is_event_build() or bool(ProjectSettings.get_setting(CHEATS_SETTING, false))

var demo_completed_pending := false

func finish_first_boss_demo() -> void:
	if not is_event_build() and not is_event_demo():
		return
	if demo_completed_pending:
		return
	demo_completed_pending = true
	just_won_run = false
	RunLog.finish("victoria")
	save_game()
	if event_demo_active:
		end_event_demo()
	get_tree().current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer(0.9).timeout
	SceneTransition.change_scene("res://Scenes/Rooms/lab_room.tscn")

# ── Boss Fight State ─────────────────────────────────────────────────────────
var boss_fight_phase: int = 1
var boss_persisted_health: int = 0
var boss_persisted_max_health: int = 1000

func reset_boss_state() -> void:
	boss_fight_phase = 1
	boss_persisted_health = 0
	boss_persisted_max_health = 1000

# ── Items & Inventory ────────────────────────────────────────────────────────
var inventory_items: Array[ItemData] = []
var equipment_slots: Dictionary = {}

var codex_unlocks: Dictionary = {
	"enemies": [],
	"weapons": [],
	"items": [],
	"npcs": [],
	"levels": []
}

# show_toast=false para los desbloqueos iniciales (no tiene sentido un popup al arrancar el juego)
func unlock_codex_entry(category: String, entry_id: String, show_toast: bool = true) -> void:
	if not codex_unlocks.has(category): return
	if not codex_unlocks[category].has(entry_id):
		codex_unlocks[category].append(entry_id)
		print("Codex unlocked: ", category, " -> ", entry_id)
		if show_toast:
			_queue_codex_toast(category, entry_id)

func is_codex_unlocked(category: String, entry_id: String) -> bool:
	if not codex_unlocks.has(category): return false
	return codex_unlocks[category].has(entry_id)

# ── Codex Toast (aviso de descubrimiento estilo logro) ───────────────────────
# cola para que dos desbloqueos casi simultáneos no se pisen entre sí
var _codex_toast_queue: Array = []
var _codex_toast_active: bool = false

func _queue_codex_toast(category: String, entry_id: String) -> void:
	_codex_toast_queue.append({"category": category, "entry_id": entry_id})
	if not _codex_toast_active:
		_show_next_codex_toast()

func _show_next_codex_toast() -> void:
	if _codex_toast_queue.is_empty():
		_codex_toast_active = false
		return
	_codex_toast_active = true
	var entry: Dictionary = _codex_toast_queue.pop_front()
	var toast: CodexToast = CodexToast.new()
	toast.category = entry["category"]
	toast.entry_id = entry["entry_id"]
	toast.finished.connect(_on_codex_toast_finished)
	add_child(toast)

func _on_codex_toast_finished() -> void:
	_show_next_codex_toast()

func _ready() -> void:
	InputMode.instance() # joystick: botones y detección desde el arranque
	if is_event_build():
		EventKiosk.install(self) # stand: vuelve al menú si nadie juega
	_load_level1_rooms()
	for slot in ItemData.ItemSlot.values():
		equipment_slots[slot] = null
	unlock_codex_entry("levels", "distrito_1", false)
	unlock_codex_entry("weapons", "pistol", false)
	unlock_codex_entry("weapons", "daga", false)
	_apply_event_unlocks()

func _process(delta: float) -> void:
	if get_tree().paused: return
	if not get_tree().current_scene: return
	var scene_name = get_tree().current_scene.name.to_lower()
	if scene_name != "mainmenu" and scene_name != "newgame":
		play_time += delta

# ── Run Management ────────────────────────────────────────────────────────────
var current_run_room: int = 0
var run_start_time_msec: int = 0 # para calcular el tiempo sobrevivido en la pantalla de muerte
var run_enemies_killed: int = 0:
	set(val):
		run_enemies_killed = val
var run_scrap_collected: int = 0
var last_killer: String = "Infección Lázaro"
var rooms_pool: Array[String] = []
var rooms_pool_level2: Array[String] = []
var rooms_pool_level3: Array[String] = []
var last_room_path: String = ""
var rooms_before_boss: int = 7

func _load_level1_rooms() -> void:
	rooms_pool = _scan_rooms_with_prefix("Level1_Room")
	rooms_pool_level2 = _scan_rooms_with_prefix("Level2_Room")
	rooms_pool_level3 = _scan_rooms_with_prefix("Level3_Room")

func _scan_rooms_with_prefix(prefix: String) -> Array[String]:
	var result: Array[String] = []
	var path: String = "res://Scenes/Rooms/"
	var dir = DirAccess.open(path)
	if not dir: return result
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		_add_room_if_valid(file_name, path, prefix, result)
		file_name = dir.get_next()
	return result

func _add_room_if_valid(file_name: String, path: String, prefix: String, result: Array[String]) -> void:
	if not file_name.begins_with(prefix): return
	var clean_name = file_name.trim_suffix(".remap")
	if not clean_name.ends_with(".tscn"): return
	if "bossfight" in clean_name.to_lower() or "ygor" in clean_name.to_lower(): return
	result.append(path + clean_name)

func start_new_run() -> String:
	RunLog.begin()
	reset_protocol_run()
	# El build de Buenos Aires Game Dev conserva el flujo normal de inicio;
	# cambia sólo la configuración de la run al confirmarla.
	if is_event_build():
		return start_event_demo()
	total_deployments += 1
	current_level = 1
	current_run_room = 1
	if current_run_room > max_reached_room:
		max_reached_room = current_run_room
	rooms_before_boss = randi_range(7, 10)
	run_enemies_killed = 0
	run_scrap_collected = 0
	run_start_time_msec = Time.get_ticks_msec()
	last_killer = "Infección Lázaro"
	last_room_path = ""
	reset_boss_state()
	save_game()
	return get_random_room_from_pool()

func start_event_demo() -> String:
	if event_demo_active:
		end_event_demo()
	begin_sandbox()
	event_demo_active = true
	# las armas que eligió en el laboratorio se mantienen
	var primary = chosen_primary_weapon
	var melee = chosen_melee_weapon
	reset_data()
	chosen_primary_weapon = primary
	chosen_melee_weapon = melee
	current_level = 1
	current_run_room = 1
	rooms_before_boss = EVENT_DEMO_ROOMS_BEFORE_BOSS
	run_enemies_killed = 0
	run_scrap_collected = 0
	run_start_time_msec = Time.get_ticks_msec()
	last_killer = "Infección Lázaro"
	last_room_path = ""
	reset_boss_state()
	for key in core_upgrades.keys():
		core_upgrades[key] = EVENT_OMNIA_LEVEL
	unlock_all_synergies()
	# La demo usa el mismo inventario y enemigos de nivel 1; sólo abre las
	# recetas para que las combinaciones obtenidas durante la run funcionen.
	return get_random_room_from_pool()

func end_event_demo() -> void:
	if not event_demo_active: return
	event_demo_active = false
	just_won_run = false
	end_sandbox()

func is_event_demo() -> bool:
	return event_demo_active

func get_next_room() -> String:
	RunLog.note_room()
	current_run_room += 1
	if current_run_room > max_reached_room:
		max_reached_room = current_run_room
		save_game()
	return determine_next_room()

func determine_next_room() -> String:
	if current_run_room > rooms_before_boss:
		return get_boss_room()
	return check_for_ygor_room()

func get_boss_room() -> String:
	return BOSS_ROOMS.get(clampi(current_level, 1, MAX_LEVEL_FOR_NOW), BOSS_ROOMS[1])

# Se llama cuando el jugador cruza la puerta de salida del boss.
# Zonas 1 y 2 completas -> arranca la zona siguiente. Zona 3 completa -> gana la run y vuelve al Lab.
func get_post_boss_scene() -> String:
	if event_demo_active:
		just_won_run = true
		return "res://Scenes/Rooms/lab_room.tscn"
	if current_level < MAX_LEVEL_FOR_NOW:
		current_level += 1
		current_run_room = 1
		rooms_before_boss = randi_range(7, 10)
		last_room_path = ""
		if current_level > max_reached_level:
			max_reached_level = current_level
		# Zona nueva alcanzada: dispara el aviso de descubrimiento en el códice.
		unlock_codex_entry("levels", "distrito_%d" % current_level)
		save_game()
		return get_random_room_from_pool()
	return win_run()

## Run ganada (cayó el jefe final): guarda y devuelve el laboratorio, a donde se vuelve.
func win_run() -> String:
	just_won_run = true
	save_game()
	return "res://Scenes/Rooms/lab_room.tscn"

func check_for_ygor_room() -> String:
	var is_multiple_of_three: bool = (current_run_room % 3 == 0)
	if not is_multiple_of_three or not YGOR_ROOMS.has(current_level):
		return get_random_room_from_pool()
	return roll_for_ygor_room()

func roll_for_ygor_room() -> String:
	var roll: float = randf()
	if roll < 0.5:
		return _remember_room(get_ygor_room_for_current_level())
	return get_random_room_from_pool()

func get_zone_name(level: int) -> String:
	return ZONE_NAMES.get(level, ZONE_NAMES[1])

func get_ygor_room_for_current_level() -> String:
	return YGOR_ROOMS.get(current_level, YGOR_ROOMS[1])

func _get_current_pool() -> Array[String]:
	match current_level:
		2: return rooms_pool_level2
		3: return rooms_pool_level3
	return rooms_pool

func get_random_room_from_pool() -> String:
	var pool: Array[String] = _get_current_pool()
	if pool.is_empty():
		return "res://Scenes/Rooms/lab_room.tscn"
	var candidates := _get_valid_room_candidates(pool)
	if candidates.is_empty():
		candidates = pool.duplicate()
	return _remember_room(candidates.pick_random())

func _get_valid_room_candidates(pool: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for room_path in pool:
		if room_path == last_room_path:
			continue
		if _is_treasure_room(room_path) and _is_special_reward_room(last_room_path):
			continue
		result.append(room_path)
	return result

func _is_treasure_room(room_path: String) -> bool:
	return "treasure" in room_path.to_lower()

func _is_special_reward_room(room_path: String) -> bool:
	var name_lower = room_path.to_lower()
	return "treasure" in name_lower or "ygor" in name_lower

func _remember_room(room_path: String) -> String:
	last_room_path = room_path
	return room_path

func get_room_config() -> Dictionary:
	var config: Dictionary = _create_base_config()
	_apply_room_scaling(config, current_run_room)
	if current_level == 2:
		config.allowed_enemies = ["crypt_gargoyle", "crypt_ghoul", "crypt_centipede", "crypt_death_squad", "crypt_laser_eye", "crypt_dead_beekeeper", "crypt_bell_keeper"]
	return config

func _create_base_config() -> Dictionary:
	return {
		"total_enemies": 4,
		"max_concurrent": 3,
		"spawn_interval": 1.5,
		"allowed_enemies": ["follower"]
	}

func _apply_room_scaling(config: Dictionary, room: int) -> void:
	if room <= 1:
		_set_room_1_config(config)
		return
	if room == 2:
		_set_room_2_config(config)
		return
	_set_room_n_config(config, room)

func _set_room_1_config(config: Dictionary) -> void:
	config.total_enemies = 4
	config.max_concurrent = 3
	config.spawn_interval = 1.5
	config.allowed_enemies = ["follower"]

func _set_room_2_config(config: Dictionary) -> void:
	config.total_enemies = 7
	config.max_concurrent = 4
	config.spawn_interval = 1.3
	config.allowed_enemies = ["follower", "shooter"]

func _set_room_n_config(config: Dictionary, room: int) -> void:
	var extra_rooms = room - 3
	config.total_enemies = 11 + (extra_rooms * 4)
	config.max_concurrent = 5 + int(extra_rooms / 2.0)
	
	var new_interval = 1.1 - (extra_rooms * 0.05)
	config.spawn_interval = maxf(0.3, new_interval)
	
	config.allowed_enemies = ["follower", "shooter"]
	_add_tank_to_allowed_enemies(config, room)
	_add_turret_to_allowed_enemies_if_level_4(config, room)
	_add_summoner_to_allowed_enemies_if_level_5(config, room)

func _add_tank_to_allowed_enemies(config: Dictionary, room: int) -> void:
	if current_level <= 1 and room < 4:
		return
	config.allowed_enemies.append("tank")

func _add_turret_to_allowed_enemies_if_level_4(config: Dictionary, room: int) -> void:
	if room < 4: return
	config.allowed_enemies.append("turret")

func _add_summoner_to_allowed_enemies_if_level_5(config: Dictionary, room: int) -> void:
	if room < 5: return
	config.allowed_enemies.append("summoner")

# ── Weapon upgrades ─────────────────────────────────────────────────────────
var weapon_damage: float = 10.0
var weapon_fire_rate: float = 1.0      # attacks per second (APS)
var weapon_bullet_count: int = 1
var weapon_bullet_speed: float = 400.0
var weapon_spread: float = 15.0
var weapon_damage_multiplier: float = 1.0
var weapon_crit_chance: float = 0.0     # 0‒1
var weapon_crit_damage: float = 2.0     # 2x multiplier by default
var weapon_piercing: int = 0            # bullets pierce N extra enemies

var melee_damage: float = 30.0
var melee_speed: float = 1.0
var melee_range: float = 1.0
var melee_knockback: float = 0.0

# Upgrade costs (scrap) and step sizes ───────────────────────────────────────
const UPGRADE_DEFS: Array[Dictionary] = [
	{
		"key": "damage",
		"label": "Daño",
		"desc": "Aumenta el daño base del arma",
		"cost": 1,
		"step": 5.0
	},
	{
		"key": "fire_rate",
		"label": "Cadencia",
		"desc": "Dispara más rápido",
		"cost": 1,
		"step": 0.2
	},
	{
		"key": "bullet_count",
		"label": "Balas",
		"desc": "Dispara más balas por vez",
		"cost": 1,
		"step": 1
	},
	{
		"key": "bullet_speed",
		"label": "Velocidad de bala",
		"desc": "Las balas viajan más rápido",
		"cost": 1,
		"step": 80.0
	},
	{
		"key": "spread",
		"label": "Precisión",
		"desc": "Reduce la dispersión del cono",
		"cost": 1,
		"step": -3.0
	},
	{
		"key": "damage_multiplier",
		"label": "Multiplicador de daño",
		"desc": "Cada bala hace aún más daño",
		"cost": 1,
		"step": 0.25
	},
	{
		"key": "crit_chance",
		"label": "Críticos",
		"desc": "Probabilidad de golpe crítico (x2 daño)",
		"cost": 1,
		"step": 0.1
	},
	{
		"key": "piercing",
		"label": "Penetración",
		"desc": "Las balas atraviesan enemigos adicionales",
		"cost": 1,
		"step": 1
	},
	{
		"key": "melee_damage",
		"label": "Daño Melee",
		"desc": "Aumenta el daño del ataque cuerpo a cuerpo",
		"cost": 1,
		"step": 10.0
	},
	{
		"key": "melee_speed",
		"label": "Velocidad Melee",
		"desc": "Ataca más rápido cuerpo a cuerpo",
		"cost": 1,
		"step": 0.2
	},
	{
		"key": "melee_range",
		"label": "Alcance Melee",
		"desc": "Aumenta el rango y tamaño del ataque",
		"cost": 1,
		"step": 0.15
	},
	{
		"key": "melee_knockback",
		"label": "Empuje Melee",
		"desc": "Empuja a los enemigos al golpearlos",
		"cost": 1,
		"step": 250.0
	},
]

# ── Helpers ──────────────────────────────────────────────────────────────────
func add_scrap(amount: int) -> void:
	var level = core_upgrades.get("compactador", 0)
	var multiplier = 1.0 + (level * 0.02)
	var extra_scrap = int(round(amount * multiplier))
	scrap += extra_scrap
	run_scrap_collected += extra_scrap
	scrap_changed.emit(scrap)

func spend_scrap(amount: int) -> bool:
	if scrap < amount:
		return false
	scrap -= amount
	scrap_changed.emit(scrap)
	return true

func add_flesh(amount: int) -> void:
	var level = core_upgrades.get("biomasa_eficiente", 0)
	var multiplier = 1.0 + (level * 0.02)
	var extra_flesh = int(round(amount * multiplier))
	flesh += extra_flesh
	flesh_changed.emit(flesh)

func spend_flesh(amount: int) -> bool:
	if flesh < amount:
		return false
	flesh -= amount
	flesh_changed.emit(flesh)
	return true

func get_active_protocol() -> String:
	return active_protocol

func is_synergy_unlocked(syn_id: String) -> bool:
	return unlocked_synergies.has(syn_id)

## Comprar una sinergia habilita su combinación y revela el primer componente.
## Su sprite recién se ve cuando se arma por primera vez en una run (aparece la
## animación de "nueva sinergia" y queda en activated_synergies).
func is_synergy_discovered(syn_id: String) -> bool:
	return activated_synergies.has(syn_id)

# ── Sala de entrenamiento: todo lo que se desbloquea ahí es de prueba ─────────
## Al entrar se guarda una copia del progreso; mientras dure, save_game escribe
## esa copia; al salir se vuelve a ella. Así las sinergias, piezas y mejoras de
## la sala de entrenamiento no quedan en la partida.
const SANDBOX_KEYS: Array[String] = [
	"scrap", "flesh", "core_upgrades", "unlocked_synergies", "activated_synergies", "synergy_item_hints",
	"unlocked_protocols", "active_protocol", "chosen_primary_weapon", "chosen_melee_weapon",
	"codex_unlocks", "inventory_items", "equipment_slots",
	"weapon_damage", "weapon_fire_rate", "weapon_bullet_count", "weapon_bullet_speed",
	"weapon_spread", "weapon_damage_multiplier", "weapon_crit_chance", "weapon_crit_damage",
	"weapon_piercing", "melee_damage", "melee_speed", "melee_range", "melee_knockback",
]
var sandbox_active: bool = false
var _sandbox_snapshot: Dictionary = {}

func begin_sandbox() -> void:
	if sandbox_active: return
	_sandbox_snapshot.clear()
	for key in SANDBOX_KEYS:
		_sandbox_snapshot[key] = _copy_value(get(key))
	sandbox_active = true

func end_sandbox() -> void:
	if not sandbox_active: return
	sandbox_active = false
	for key in SANDBOX_KEYS:
		_restore_value(key, _sandbox_snapshot[key])
	_sandbox_snapshot.clear()
	scrap_changed.emit(scrap)
	flesh_changed.emit(flesh)

func _copy_value(value):
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value

# Arrays y diccionarios se restauran "en el lugar": el inventario y el equipo
# del jugador apuntan a los mismos objetos de GameData.
func _restore_value(key: String, saved) -> void:
	var current = get(key)
	if current is Array:
		current.clear()
		current.append_array(saved)
	elif current is Dictionary:
		current.clear()
		current.merge(saved.duplicate(true), true)
	else:
		set(key, saved)

func unlock_synergy(syn_id: String) -> void:
	if not unlocked_synergies.has(syn_id):
		unlocked_synergies.append(syn_id)

func unlock_all_synergies() -> void:
	var all_ids: Array[String] = [
		"pistola_mente_colmena",
		"roadkill",
		"bestia_de_caza",
		"trituradora_biomecanica",
		"acorazado_muscular",
		"minigun",
		"lanzallamas",
		"daga_del_odio",
		"arrogancia",
		"hombre_lobo",
		"relampago",
		"speed_demon",
		"snowman",
		"holy_fire",
		"alto_octanaje"
	]
	for syn_id in all_ids:
		unlock_synergy(syn_id)


func get_upgrade_level(key: String) -> float:
	match key:
		"damage":            return weapon_damage
		"fire_rate":         return weapon_fire_rate
		"bullet_count":      return weapon_bullet_count
		"bullet_speed":      return weapon_bullet_speed
		"spread":            return weapon_spread
		"damage_multiplier": return weapon_damage_multiplier
		"crit_chance":       return weapon_crit_chance
		"crit_damage":       return weapon_crit_damage
		"piercing":          return weapon_piercing
		"melee_damage":      return melee_damage
		"melee_speed":       return melee_speed
		"melee_range":       return melee_range
		"melee_knockback":   return melee_knockback
	return 0.0

func apply_upgrade(key: String, step: float) -> void:
	match key:
		"damage":
			weapon_damage = maxf(1.0, weapon_damage + step)
		"fire_rate":
			weapon_fire_rate = maxf(0.1, weapon_fire_rate + step)
		"bullet_count":
			weapon_bullet_count = max(1, weapon_bullet_count + int(step))
		"bullet_speed":
			weapon_bullet_speed = maxf(100.0, weapon_bullet_speed + step)
		"spread":
			weapon_spread = clampf(weapon_spread + step, 0.0, 90.0)
		"damage_multiplier":
			weapon_damage_multiplier = maxf(1.0, weapon_damage_multiplier + step)
		"crit_chance":
			weapon_crit_chance = clampf(weapon_crit_chance + step, 0.0, 1.0)
		"crit_damage":
			weapon_crit_damage = maxf(1.0, weapon_crit_damage + step)
		"piercing":
			weapon_piercing = max(0, weapon_piercing + int(step))
		"melee_damage":
			melee_damage = maxf(1.0, melee_damage + step)
		"melee_speed":
			melee_speed = maxf(0.1, melee_speed + step)
		"melee_range":
			melee_range = maxf(0.1, melee_range + step)
		"melee_knockback":
			melee_knockback += step

func apply_to_weapon(weapon) -> void:
	if not weapon:
		return
	if "damage" in weapon: weapon.damage = weapon_damage
	if "projectile_speed" in weapon: weapon.projectile_speed = weapon_bullet_speed
	if "bullet_count" in weapon: weapon.bullet_count = weapon_bullet_count
	if "cone_spread_angle" in weapon: weapon.cone_spread_angle = weapon_spread
	if "piercing" in weapon: weapon.piercing = weapon_piercing
	if "crit_chance" in weapon: weapon.crit_chance = weapon_crit_chance
	if "crit_damage" in weapon:
		weapon.crit_damage = weapon_crit_damage
	if "attack_speed" in weapon:
		weapon.attack_speed = weapon_fire_rate
	if "damage_multiplier" in weapon:
		weapon.damage_multiplier = weapon_damage_multiplier

func apply_to_melee(melee) -> void:
	if not melee: return
	if "damage" in melee: melee.damage = int(melee_damage)
	if "attack_speed" in melee: melee.attack_speed = melee_speed
	if "attack_range" in melee: melee.attack_range = melee_range
	if "knockback_force" in melee: melee.knockback_force = melee_knockback
	if melee.has_method("_ready"):
		melee.scale = Vector2(melee_range, melee_range)

# ── Save System ──────────────────────────────────────────────────────────────
func get_save_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func get_global_path() -> String:
	return "user://global_settings.json"

func save_game(slot: int = -1) -> void:
	# El ejecutable del evento no escribe slots ni configuración de progreso.
	if event_demo_active: return
	if slot == -1: slot = current_slot
	last_save_time = get_formatted_system_time()
	var data = {
		"scrap": scrap,
		"weapon_damage": weapon_damage,
		"weapon_fire_rate": weapon_fire_rate,
		"weapon_bullet_count": weapon_bullet_count,
		"weapon_bullet_speed": weapon_bullet_speed,
		"weapon_spread": weapon_spread,
		"weapon_damage_multiplier": weapon_damage_multiplier,
		"weapon_crit_chance": weapon_crit_chance,
		"weapon_crit_damage": weapon_crit_damage,
		"weapon_piercing": weapon_piercing,
		"melee_damage": melee_damage,
		"melee_speed": melee_speed,
		"melee_range": melee_range,
		"melee_knockback": melee_knockback,
		"play_time": play_time,
		"core_upgrades": core_upgrades,
		"unlocked_synergies": unlocked_synergies,
		"activated_synergies": activated_synergies,
		"synergy_item_hints": synergy_item_hints,
		"unlocked_protocols": unlocked_protocols,
		"active_protocol": active_protocol,
		"has_died_once": has_died_once,
		"has_shown_inventory_tutorial": has_shown_inventory_tutorial,
		"has_completed_tutorial": has_completed_tutorial,
		"chosen_primary_weapon": chosen_primary_weapon,
		"chosen_melee_weapon": chosen_melee_weapon,
		"weapons_unlocked": codex_unlocks["weapons"],
		"codex_unlocks": codex_unlocks,
		"max_reached_level": max_reached_level,
		"max_reached_room": max_reached_room,
		"total_deployments": total_deployments,
		"last_save_time": last_save_time
	}
	if sandbox_active:
		_use_sandbox_snapshot(data)
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	
	_save_global_settings(slot)

# Guardando desde la sala de entrenamiento: se escribe el progreso de antes de entrar.
func _use_sandbox_snapshot(data: Dictionary) -> void:
	for key in _sandbox_snapshot:
		if data.has(key):
			data[key] = _sandbox_snapshot[key]
	data["weapons_unlocked"] = _sandbox_snapshot["codex_unlocks"].get("weapons", [])

func load_game(slot: int) -> bool:
	if not FileAccess.file_exists(get_save_path(slot)):
		return false
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file: return false
	
	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) != TYPE_DICTIONARY: return false
	
	current_slot = slot
	run_start_time_msec = Time.get_ticks_msec() # arranca a contar desde que se retoma la partida
	scrap = int(json.get("scrap", 0))
	weapon_damage = float(json.get("weapon_damage", 10.0))
	weapon_fire_rate = float(json.get("weapon_fire_rate", 1.0))
	weapon_bullet_count = int(json.get("weapon_bullet_count", 1))
	weapon_bullet_speed = float(json.get("weapon_bullet_speed", 400.0))
	weapon_spread = float(json.get("weapon_spread", 15.0))
	weapon_damage_multiplier = float(json.get("weapon_damage_multiplier", 1.0))
	weapon_crit_chance = float(json.get("weapon_crit_chance", 0.0))
	weapon_crit_damage = float(json.get("weapon_crit_damage", 2.0))
	weapon_piercing = int(json.get("weapon_piercing", 0))
	melee_damage = float(json.get("melee_damage", 30.0))
	melee_speed = float(json.get("melee_speed", 1.0))
	melee_range = float(json.get("melee_range", 1.0))
	melee_knockback = float(json.get("melee_knockback", 0.0))
	play_time = float(json.get("play_time", 0.0))
	
	max_reached_level = int(json.get("max_reached_level", 1))
	max_reached_room = int(json.get("max_reached_room", 1))
	total_deployments = int(json.get("total_deployments", 0))
	last_save_time = str(json.get("last_save_time", ""))
	
	core_upgrades = json.get("core_upgrades", {
		"integridad_estructural": 0,
		"servomotores": 0,
		"blindaje_compuesto": 0,
		"sistema_ataque": 0,
		"sinapsis_acelerada": 0,
		"balistica_predictiva": 0,
		"compactador": 0,
		"biomasa_eficiente": 0,
		"imanes_industriales": 0,
		"recuperacion_restos": 0,
		"escaner_objetivos": 0
	})
	
	var raw_syns = json.get("unlocked_synergies", [])
	unlocked_synergies.clear()
	for s in raw_syns: unlocked_synergies.append(str(s))
	
	var raw_hints = json.get("synergy_item_hints", {})
	synergy_item_hints.clear()
	if raw_hints is Dictionary:
		for id in raw_hints:
			if not raw_hints[id] is Array: continue
			var indices: Array = []
			for index in raw_hints[id]:
				if (index is float or index is int) and int(index) in [1, 2]:
					if not indices.has(int(index)): indices.append(int(index))
			synergy_item_hints[str(id)] = indices
	var raw_act_syns = json.get("activated_synergies", [])
	activated_synergies.clear()
	for s in raw_act_syns: activated_synergies.append(str(s))
	
	var raw_protos = json.get("unlocked_protocols", [])
	unlocked_protocols.clear()
	for p in raw_protos: unlocked_protocols.append(str(p))
	
	active_protocol = str(json.get("active_protocol", ""))
	has_died_once = bool(json.get("has_died_once", false))
	has_shown_inventory_tutorial = bool(json.get("has_shown_inventory_tutorial", false))
	has_completed_tutorial = bool(json.get("has_completed_tutorial", false))
	chosen_primary_weapon = str(json.get("chosen_primary_weapon", "pistol"))
	chosen_melee_weapon = str(json.get("chosen_melee_weapon", "daga"))
	
	# códice: restauramos todas las categorías (enemigos, armas, ítems, npcs, zonas)
	var raw_codex: Dictionary = json.get("codex_unlocks", {})
	for cat in codex_unlocks.keys():
		var raw_list: Array = raw_codex.get(cat, [])
		codex_unlocks[cat].clear()
		for entry_id in raw_list:
			codex_unlocks[cat].append(str(entry_id))
	
	# compatibilidad con guardados viejos que solo tenían el códice de armas
	if not raw_codex.has("weapons"):
		var raw_weapons = json.get("weapons_unlocked", ["pistol", "daga"])
		codex_unlocks["weapons"].clear()
		for w in raw_weapons:
			codex_unlocks["weapons"].append(str(w))
	
	scrap_changed.emit(scrap)
	_save_global_settings(slot)
	_apply_event_unlocks()
	return true

func _save_global_settings(last_slot: int) -> void:
	var file = FileAccess.open(get_global_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"last_played_slot": last_slot}))

func get_last_played_slot() -> int:
	if not FileAccess.file_exists(get_global_path()): return 1
	var file = FileAccess.open(get_global_path(), FileAccess.READ)
	if not file: return 1
	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) == TYPE_DICTIONARY:
		return int(json.get("last_played_slot", 1))
	return 1

func delete_save(slot: int) -> void:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func clear_items() -> void:
	inventory_items.clear()
	for k in equipment_slots.keys():
		equipment_slots[k] = null
	flesh = 0
	flesh_changed.emit(flesh)

## Build del evento: todas las armas se pueden elegir desde el principio y
## todas las sinergias están habilitadas (no descubiertas: su sprite y su nombre
## se revelan recién al armarlas).
const EVENT_WEAPONS: Array[String] = ["pistol", "uzi", "shotgun", "daga", "hacha", "maze"]

func _apply_event_unlocks() -> void:
	if not is_event_build(): return
	for id in EVENT_WEAPONS:
		unlock_codex_entry("weapons", id, false)
	unlock_all_synergies()

func reset_data() -> void:
	reset_protocol_run()
	scrap = 0
	flesh = 0
	weapon_damage = 10.0
	weapon_fire_rate = 1.0
	weapon_bullet_count = 1
	weapon_bullet_speed = 400.0
	weapon_spread = 15.0
	weapon_damage_multiplier = 1.0
	weapon_crit_chance = 0.0
	weapon_crit_damage = 2.0
	weapon_piercing = 0
	melee_damage = 30.0
	melee_speed = 1.0
	melee_range = 1.0
	melee_knockback = 0.0
	play_time = 0.0
	inventory_items.clear()
	for k in equipment_slots.keys():
		equipment_slots[k] = null
	max_reached_level = 1
	max_reached_room = 1
	total_deployments = 0
	last_save_time = ""
	
	core_upgrades = {
		"integridad_estructural": 0,
		"servomotores": 0,
		"blindaje_compuesto": 0,
		"sistema_ataque": 0,
		"sinapsis_acelerada": 0,
		"balistica_predictiva": 0,
		"compactador": 0,
		"biomasa_eficiente": 0,
		"imanes_industriales": 0,
		"recuperacion_restos": 0,
		"escaner_objetivos": 0
	}
	unlocked_synergies.clear()
	activated_synergies.clear()
	synergy_item_hints.clear()
	unlocked_protocols.clear()
	active_protocol = ""
	has_died_once = false
	has_shown_inventory_tutorial = false
	has_completed_tutorial = false
	chosen_primary_weapon = "pistol"
	chosen_melee_weapon = "daga"
	codex_unlocks["weapons"] = ["pistol", "daga"]
	_apply_event_unlocks()
	
	scrap_changed.emit(scrap)
	flesh_changed.emit(flesh)

func get_slot_info(slot: int) -> Dictionary:
	if not FileAccess.file_exists(get_save_path(slot)):
		return {"exists": false}
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) == TYPE_DICTIONARY:
		return {
			"exists": true,
			"play_time": float(json.get("play_time", 0.0)),
			"max_reached_level": int(json.get("max_reached_level", 1)),
			"max_reached_room": int(json.get("max_reached_room", 1)),
			"total_deployments": int(json.get("total_deployments", 0)),
			"last_save_time": str(json.get("last_save_time", ""))
		}
	return {"exists": false}

func get_formatted_system_time() -> String:
	var dt = Time.get_datetime_dict_from_system()
	var day = dt.get("day", 1)
	var month = dt.get("month", 1)
	var year = dt.get("year", 2026)
	var hour = dt.get("hour", 0)
	var minute = dt.get("minute", 0)
	
	var am_pm = "am"
	var display_hour = hour
	if hour >= 12:
		am_pm = "pm"
		if hour > 12:
			display_hour = hour - 12
	elif hour == 0:
		display_hour = 12
		
	return "%02d/%02d/%04d a las %d:%02d %s" % [day, month, year, display_hour, minute, am_pm]

# segundos transcurridos desde que arrancó la run actual, para el resumen de muerte
func get_run_elapsed_seconds() -> float:
	return (Time.get_ticks_msec() - run_start_time_msec) / 1000.0

func format_time(time: float) -> String:
	var total_secs = int(time)
	var hours = int(total_secs / 3600.0)
	var minutes = int((total_secs % 3600) / 60.0)
	var seconds = total_secs % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func unlock_all_omnia() -> void:
	has_died_once = true
	scrap += 10000
	flesh += 10000
	
	for key in core_upgrades.keys():
		core_upgrades[key] = 5
		
	var all_syns = ["minigun", "bestia_de_caza", "trituradora_biomecanica"]
	for s in all_syns:
		if not unlocked_synergies.has(s):
			unlocked_synergies.append(s)
			
	var all_protos = ["circuito_emergencia", "reparacion_autonoma", "nucleo_vampirico", "sobrecarga", "reflejo_sintetico", "enjambre_residual", "blindaje_reactivo", "furia_de_titanio", "reciclaje_instantaneo"]
	for p in all_protos:
		if not unlocked_protocols.has(p):
			unlocked_protocols.append(p)
			
	codex_unlocks["weapons"] = ["pistol", "uzi", "shotgun", "daga", "maze", "hacha"]
	codex_unlocks["levels"] = ["distrito_1", "distrito_2", "distrito_3"]
	
	scrap_changed.emit(scrap)
	flesh_changed.emit(flesh)
	save_game()
