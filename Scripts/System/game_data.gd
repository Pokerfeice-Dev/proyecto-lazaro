extends Node
## GameData – Autoload singleton.
## Persists scrap and weapon upgrade levels across scene transitions and deaths.

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
var unlocked_protocols: Array[String] = []
var active_protocol: String = ""
var has_died_once: bool = false
var chosen_primary_weapon: String = "pistol"
var chosen_melee_weapon: String = "daga"
var temporary_damage_multiplier: float = 1.0
var vampiric_kills_counter: int = 0

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

func unlock_codex_entry(category: String, entry_id: String) -> void:
	if not codex_unlocks.has(category): return
	if not codex_unlocks[category].has(entry_id):
		codex_unlocks[category].append(entry_id)
		print("Codex unlocked: ", category, " -> ", entry_id)

func is_codex_unlocked(category: String, entry_id: String) -> bool:
	if not codex_unlocks.has(category): return false
	return codex_unlocks[category].has(entry_id)

func _ready() -> void:
	_load_level1_rooms()
	for slot in ItemData.ItemSlot.values():
		equipment_slots[slot] = null
	unlock_codex_entry("levels", "level_1")
	unlock_codex_entry("weapons", "pistol")
	unlock_codex_entry("weapons", "daga")

func _process(delta: float) -> void:
	if get_tree().paused: return
	if not get_tree().current_scene: return
	var scene_name = get_tree().current_scene.name.to_lower()
	if scene_name != "mainmenu" and scene_name != "newgame":
		play_time += delta

# ── Run Management ────────────────────────────────────────────────────────────
var current_run_room: int = 0
var run_enemies_killed: int = 0:
	set(val):
		var diff = val - run_enemies_killed
		run_enemies_killed = val
		if diff > 0:
			_on_enemy_killed_protocol_check(diff)

func _on_enemy_killed_protocol_check(diff: int) -> void:
	if active_protocol == "nucleo_vampirico":
		vampiric_kills_counter += diff
		while vampiric_kills_counter >= 25:
			vampiric_kills_counter -= 25
			var player = get_tree().get_first_node_in_group("player")
			if player and "stats" in player and player.stats.has_method("heal"):
				player.stats.heal(2)
var run_scrap_collected: int = 0
var last_killer: String = "Infección Lázaro"
var rooms_pool: Array[String] = []
var last_room_path: String = ""
var rooms_before_boss: int = 7

func _load_level1_rooms() -> void:
	var path: String = "res://Scenes/Rooms/"
	var dir = DirAccess.open(path)
	if not dir: return
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		_add_room_if_valid(file_name, path)
		file_name = dir.get_next()

func _add_room_if_valid(file_name: String, path: String) -> void:
	if not file_name.begins_with("Level1_Room"): return
	var clean_name = file_name.trim_suffix(".remap")
	if not clean_name.ends_with(".tscn"): return
	if "bossfight" in clean_name.to_lower() or "ygor" in clean_name.to_lower(): return
	rooms_pool.append(path + clean_name)

func start_new_run() -> String:
	total_deployments += 1
	current_run_room = 1
	if current_run_room > max_reached_room:
		max_reached_room = current_run_room
	rooms_before_boss = randi_range(7, 10)
	run_enemies_killed = 0
	run_scrap_collected = 0
	last_killer = "Infección Lázaro"
	save_game()
	return get_random_room_from_pool()

func get_next_room() -> String:
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
	return "res://Scenes/Rooms/Level1_Room15-BossFight.tscn"

func check_for_ygor_room() -> String:
	var is_multiple_of_three: bool = (current_run_room % 3 == 0)
	if not is_multiple_of_three:
		return get_random_room_from_pool()
	return roll_for_ygor_room()

func roll_for_ygor_room() -> String:
	var roll: float = randf()
	if roll < 0.5:
		return "res://Scenes/Rooms/Level1_Room12(Ygor1).tscn"
	return get_random_room_from_pool()

func get_random_room_from_pool() -> String:
	if rooms_pool.is_empty():
		return "res://Scenes/Rooms/lab_room.tscn"
	
	if rooms_pool.size() == 1:
		last_room_path = rooms_pool[0]
		return rooms_pool[0]
		
	var next_room = rooms_pool.pick_random()
	while next_room == last_room_path:
		next_room = rooms_pool.pick_random()
		
	last_room_path = next_room
	return next_room

func get_room_config() -> Dictionary:
	var config: Dictionary = _create_base_config()
	_apply_room_scaling(config, current_run_room)
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
	
	config.allowed_enemies = ["follower", "shooter", "tank"]
	_add_turret_to_allowed_enemies_if_level_4(config, room)
	_add_summoner_to_allowed_enemies_if_level_5(config, room)

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
		"label": "⚔ Daño",
		"desc": "Aumenta el daño base del arma",
		"cost": 1,
		"step": 5.0
	},
	{
		"key": "fire_rate",
		"label": "🔥 Cadencia",
		"desc": "Dispara más rápido",
		"cost": 1,
		"step": 0.2
	},
	{
		"key": "bullet_count",
		"label": "🔫 Balas",
		"desc": "Dispara más balas por vez",
		"cost": 1,
		"step": 1
	},
	{
		"key": "bullet_speed",
		"label": "💨 Velocidad de bala",
		"desc": "Las balas viajan más rápido",
		"cost": 1,
		"step": 80.0
	},
	{
		"key": "spread",
		"label": "🎯 Precisión",
		"desc": "Reduce la dispersión del cono",
		"cost": 1,
		"step": -3.0
	},
	{
		"key": "damage_multiplier",
		"label": "💣 Multiplicador de daño",
		"desc": "Cada bala hace aún más daño",
		"cost": 1,
		"step": 0.25
	},
	{
		"key": "crit_chance",
		"label": "💥 Críticos",
		"desc": "Probabilidad de golpe crítico (x2 daño)",
		"cost": 1,
		"step": 0.1
	},
	{
		"key": "piercing",
		"label": "🗡 Penetración",
		"desc": "Las balas atraviesan enemigos adicionales",
		"cost": 1,
		"step": 1
	},
	{
		"key": "melee_damage",
		"label": "🔪 Daño Melee",
		"desc": "Aumenta el daño del ataque cuerpo a cuerpo",
		"cost": 1,
		"step": 10.0
	},
	{
		"key": "melee_speed",
		"label": "⚡ Velocidad Melee",
		"desc": "Ataca más rápido cuerpo a cuerpo",
		"cost": 1,
		"step": 0.2
	},
	{
		"key": "melee_range",
		"label": "📏 Alcance Melee",
		"desc": "Aumenta el rango y tamaño del ataque",
		"cost": 1,
		"step": 0.15
	},
	{
		"key": "melee_knockback",
		"label": "💨 Empuje Melee",
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
	if syn_id == "minigun":
		return true
	return unlocked_synergies.has(syn_id)

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
		"unlocked_protocols": unlocked_protocols,
		"active_protocol": active_protocol,
		"has_died_once": has_died_once,
		"chosen_primary_weapon": chosen_primary_weapon,
		"chosen_melee_weapon": chosen_melee_weapon,
		"weapons_unlocked": codex_unlocks["weapons"],
		"max_reached_level": max_reached_level,
		"max_reached_room": max_reached_room,
		"total_deployments": total_deployments,
		"last_save_time": last_save_time
	}
	var file = FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	
	_save_global_settings(slot)

func load_game(slot: int) -> bool:
	if not FileAccess.file_exists(get_save_path(slot)):
		return false
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if not file: return false
	
	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) != TYPE_DICTIONARY: return false
	
	current_slot = slot
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
	
	var raw_protos = json.get("unlocked_protocols", [])
	unlocked_protocols.clear()
	for p in raw_protos: unlocked_protocols.append(str(p))
	
	active_protocol = str(json.get("active_protocol", ""))
	has_died_once = bool(json.get("has_died_once", false))
	chosen_primary_weapon = str(json.get("chosen_primary_weapon", "pistol"))
	chosen_melee_weapon = str(json.get("chosen_melee_weapon", "daga"))
	
	var raw_weapons = json.get("weapons_unlocked", ["pistol", "daga"])
	codex_unlocks["weapons"].clear()
	for w in raw_weapons:
		codex_unlocks["weapons"].append(str(w))
	
	scrap_changed.emit(scrap)
	_save_global_settings(slot)
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

func reset_data() -> void:
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
	unlocked_protocols.clear()
	active_protocol = ""
	has_died_once = false
	chosen_primary_weapon = "pistol"
	chosen_melee_weapon = "daga"
	codex_unlocks["weapons"] = ["pistol", "daga"]
	
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

func format_time(time: float) -> String:
	var total_secs = int(time)
	var hours = int(total_secs / 3600.0)
	var minutes = int((total_secs % 3600) / 60.0)
	var seconds = total_secs % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
