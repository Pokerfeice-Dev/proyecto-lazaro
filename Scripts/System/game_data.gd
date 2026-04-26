extends Node
## GameData – Autoload singleton.
## Persists scrap and weapon upgrade levels across scene transitions and deaths.

# ── Scrap ───────────────────────────────────────────────────────────────────
var scrap: int = 0
signal scrap_changed(new_amount: int)

# ── Metadata ───────────────────────────────────────────────────────────────────
var play_time: float = 0.0
var current_slot: int = 1

func _process(delta: float) -> void:
	if get_tree().paused: return
	if not get_tree().current_scene: return
	var scene_name = get_tree().current_scene.name.to_lower()
	if scene_name != "mainmenu" and scene_name != "newgame":
		play_time += delta

# ── Weapon upgrades ─────────────────────────────────────────────────────────
var weapon_damage: float = 10.0
var weapon_fire_rate: float = 0.5      # seconds between shots (lower = faster)
var weapon_bullet_count: int = 1
var weapon_bullet_speed: float = 400.0
var weapon_spread: float = 15.0
var weapon_damage_multiplier: float = 1.0
var weapon_crit_chance: float = 0.0     # 0‒1
var weapon_piercing: int = 0            # bullets pierce N extra enemies

var melee_damage: float = 30.0
var melee_speed: float = 1.0
var melee_range: float = 1.0

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
		"step": -0.05
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
]

# ── Helpers ──────────────────────────────────────────────────────────────────
func add_scrap(amount: int) -> void:
	scrap += amount
	scrap_changed.emit(scrap)

func spend_scrap(amount: int) -> bool:
	if scrap < amount:
		return false
	scrap -= amount
	scrap_changed.emit(scrap)
	return true

func get_upgrade_level(key: String) -> float:
	match key:
		"damage":            return weapon_damage
		"fire_rate":         return weapon_fire_rate
		"bullet_count":      return weapon_bullet_count
		"bullet_speed":      return weapon_bullet_speed
		"spread":            return weapon_spread
		"damage_multiplier": return weapon_damage_multiplier
		"crit_chance":       return weapon_crit_chance
		"piercing":          return weapon_piercing
		"melee_damage":      return melee_damage
		"melee_speed":       return melee_speed
		"melee_range":       return melee_range
	return 0.0

func apply_upgrade(key: String, step: float) -> void:
	match key:
		"damage":
			weapon_damage = maxf(1.0, weapon_damage + step)
		"fire_rate":
			weapon_fire_rate = maxf(0.05, weapon_fire_rate + step)
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
		"piercing":
			weapon_piercing = max(0, weapon_piercing + int(step))
		"melee_damage":
			melee_damage = maxf(1.0, melee_damage + step)
		"melee_speed":
			melee_speed = maxf(0.1, melee_speed + step)
		"melee_range":
			melee_range = maxf(0.1, melee_range + step)

func apply_to_weapon(weapon: WeaponBase) -> void:
	if not weapon:
		return
	weapon.damage            = weapon_damage
	weapon.projectile_speed  = weapon_bullet_speed
	weapon.bullet_count      = weapon_bullet_count
	weapon.cone_spread_angle = weapon_spread
	weapon.piercing          = weapon_piercing
	weapon.crit_chance       = weapon_crit_chance

func apply_to_melee(melee: Node2D) -> void:
	if not melee: return
	if "damage" in melee: melee.damage = int(melee_damage)
	if "attack_speed" in melee: melee.attack_speed = melee_speed
	if "attack_range" in melee: melee.attack_range = melee_range
	if melee.has_method("_ready"):
		melee.scale = Vector2(melee_range, melee_range)

func apply_to_player_stats(stats: PlayerStats) -> void:
	if not stats:
		return
	stats.fire_rate         = weapon_fire_rate
	stats.damage_multiplier = weapon_damage_multiplier

# ── Save System ──────────────────────────────────────────────────────────────
func get_save_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func get_global_path() -> String:
	return "user://global_settings.json"

func save_game(slot: int = -1) -> void:
	if slot == -1: slot = current_slot
	var data = {
		"scrap": scrap,
		"weapon_damage": weapon_damage,
		"weapon_fire_rate": weapon_fire_rate,
		"weapon_bullet_count": weapon_bullet_count,
		"weapon_bullet_speed": weapon_bullet_speed,
		"weapon_spread": weapon_spread,
		"weapon_damage_multiplier": weapon_damage_multiplier,
		"weapon_crit_chance": weapon_crit_chance,
		"weapon_piercing": weapon_piercing,
		"melee_damage": melee_damage,
		"melee_speed": melee_speed,
		"melee_range": melee_range,
		"play_time": play_time
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
	weapon_fire_rate = float(json.get("weapon_fire_rate", 0.5))
	weapon_bullet_count = int(json.get("weapon_bullet_count", 1))
	weapon_bullet_speed = float(json.get("weapon_bullet_speed", 400.0))
	weapon_spread = float(json.get("weapon_spread", 15.0))
	weapon_damage_multiplier = float(json.get("weapon_damage_multiplier", 1.0))
	weapon_crit_chance = float(json.get("weapon_crit_chance", 0.0))
	weapon_piercing = int(json.get("weapon_piercing", 0))
	melee_damage = float(json.get("melee_damage", 30.0))
	melee_speed = float(json.get("melee_speed", 1.0))
	melee_range = float(json.get("melee_range", 1.0))
	play_time = float(json.get("play_time", 0.0))
	
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

func reset_data() -> void:
	scrap = 0
	weapon_damage = 10.0
	weapon_fire_rate = 0.5
	weapon_bullet_count = 1
	weapon_bullet_speed = 400.0
	weapon_spread = 15.0
	weapon_damage_multiplier = 1.0
	weapon_crit_chance = 0.0
	weapon_piercing = 0
	melee_damage = 30.0
	melee_speed = 1.0
	melee_range = 1.0
	play_time = 0.0
	scrap_changed.emit(scrap)

func get_slot_info(slot: int) -> Dictionary:
	if not FileAccess.file_exists(get_save_path(slot)):
		return {"exists": false}
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if typeof(json) == TYPE_DICTIONARY:
		return {
			"exists": true,
			"play_time": float(json.get("play_time", 0.0)),
			"scrap": int(json.get("scrap", 0))
		}
	return {"exists": false}

func format_time(time: float) -> String:
	var total_secs = int(time)
	var hours = total_secs / 3600
	var minutes = (total_secs % 3600) / 60
	var seconds = total_secs % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
