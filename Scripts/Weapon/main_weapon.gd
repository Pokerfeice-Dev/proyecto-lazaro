extends Node2D

@export var default_weapon_scene: PackedScene = preload("res://Scenes/Weapon/shotgun.tscn")
@export var pistol_scene: PackedScene = preload("res://Scenes/Weapon/pistol.tscn")
@export var uzi_scene: PackedScene = preload("res://Scenes/Weapon/uzi.tscn")
@export var shotgun_scene: PackedScene = preload("res://Scenes/Weapon/shotgun.tscn")

var current_weapon: Node2D = null
var _base_weapon_scene: PackedScene = null
var _current_override_path: String = ""

const PISTOL_BASE: Dictionary = {
	"damage": 10.0,
	"projectile_speed": 400.0,
	"bullet_count": 1,
	"cone_spread_angle": 15.0,
	"piercing": 0,
	"crit_chance": 0.0,
	"crit_damage": 2.0,
	"lifetime": 3.0,
	"attack_speed": 1.0,
	"damage_multiplier": 1.0
}

var _base_stats: Dictionary = PISTOL_BASE.duplicate()

var _upgrades: Dictionary = {
	"damage": 0.0,
	"projectile_speed": 0.0,
	"bullet_count": 0,
	"cone_spread_angle": 0.0,
	"piercing": 0,
	"crit_chance": 0.0,
	"crit_damage": 0.0,
	"lifetime": 0.0,
	"attack_speed": 0.0,
	"damage_multiplier": 0.0
}

var damage: float:
	get: return _get_weapon_property("damage")
	set(val): _set_weapon_upgrade("damage", val)

var projectile_speed: float:
	get: return _get_weapon_property("projectile_speed")
	set(val): _set_weapon_upgrade("projectile_speed", val)

var bullet_count: int:
	get: return _get_weapon_property("bullet_count")
	set(val): _set_weapon_upgrade("bullet_count", val)

var cone_spread_angle: float:
	get: return _get_weapon_property("cone_spread_angle")
	set(val): _set_weapon_upgrade("cone_spread_angle", val)

var piercing: int:
	get: return _get_weapon_property("piercing")
	set(val): _set_weapon_upgrade("piercing", val)

var crit_chance: float:
	get: return _get_weapon_property("crit_chance")
	set(val): _set_weapon_upgrade("crit_chance", val)

var crit_damage: float:
	get: return _get_weapon_property("crit_damage")
	set(val): _set_weapon_upgrade("crit_damage", val)

var lifetime: float:
	get: return _get_weapon_property("lifetime")
	set(val): _set_weapon_upgrade("lifetime", val)

var attack_speed: float:
	get: return _get_weapon_property("attack_speed")
	set(val): _set_weapon_upgrade("attack_speed", val)

var damage_multiplier: float:
	get: return _get_weapon_property("damage_multiplier")
	set(val): _set_weapon_upgrade("damage_multiplier", val)

func _ready() -> void:
	_load_default_weapon()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed:
		return
	_handle_weapon_switch_keys(event.keycode)

func _handle_weapon_switch_keys(keycode: int) -> void:
	if keycode == KEY_1:
		switch_weapon(pistol_scene)
	elif keycode == KEY_2:
		switch_weapon(uzi_scene)
	elif keycode == KEY_3:
		switch_weapon(shotgun_scene)

func _load_default_weapon() -> void:
	if default_weapon_scene:
		switch_weapon(default_weapon_scene)

func switch_weapon(new_weapon_scene: PackedScene) -> void:
	if not new_weapon_scene:
		return
	_base_weapon_scene = new_weapon_scene
	_current_override_path = ""
	_unlock_weapon_codex(new_weapon_scene)
	_remove_current_weapon()
	_instantiate_and_add_weapon(new_weapon_scene)
	_align_weapon_mark()
	_cache_base_stats()
	_apply_current_upgrades_to_weapon()
	_check_and_apply_initial_synergy_override()

func _check_and_apply_initial_synergy_override() -> void:
	var player = get_parent()
	if not player:
		return
	var equip = player.get_node_or_null("Equipment")
	if not equip:
		return
	var active_weapon_id = player.get_active_ranged_weapon_id()
	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, true)
	var override_path = SynergyManager.get_synergies_weapon_override(active_syns)
	if override_path != "":
		apply_synergy_weapon_override(override_path)

func apply_synergy_weapon_override(override_path: String) -> void:
	if _current_override_path == override_path:
		return
	_current_override_path = override_path
	_apply_synergy_weapon_override_scene(override_path)

func _apply_synergy_weapon_override_scene(override_path: String) -> void:
	if override_path != "":
		_instantiate_override(override_path)
		return
	_restore_base_weapon()

func _instantiate_override(override_path: String) -> void:
	var override_scene = load(override_path) as PackedScene
	if override_scene:
		_remove_current_weapon()
		_instantiate_and_add_weapon(override_scene)
		_align_weapon_mark()
		_cache_base_stats()
		_apply_current_upgrades_to_weapon()

func _restore_base_weapon() -> void:
	if _base_weapon_scene:
		_remove_current_weapon()
		_instantiate_and_add_weapon(_base_weapon_scene)
		_align_weapon_mark()
		_cache_base_stats()
		_apply_current_upgrades_to_weapon()

func _unlock_weapon_codex(scene: PackedScene) -> void:
	if not GameData.has_method("unlock_codex_entry"): return
	var path = scene.resource_path.to_lower()
	if "pistol" in path:
		GameData.unlock_codex_entry("weapons", "pistol")
	elif "uzi" in path:
		GameData.unlock_codex_entry("weapons", "uzi")
	elif "shotgun" in path:
		GameData.unlock_codex_entry("weapons", "shotgun")

func _remove_current_weapon() -> void:
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null

func _instantiate_and_add_weapon(new_weapon_scene: PackedScene) -> void:
	current_weapon = new_weapon_scene.instantiate()
	add_child(current_weapon)

func _cache_base_stats() -> void:
	if not current_weapon:
		return
	_base_stats["damage"] = current_weapon.get("damage") if "damage" in current_weapon else PISTOL_BASE["damage"]
	_base_stats["projectile_speed"] = current_weapon.get("projectile_speed") if "projectile_speed" in current_weapon else PISTOL_BASE["projectile_speed"]
	_base_stats["bullet_count"] = current_weapon.get("bullet_count") if "bullet_count" in current_weapon else PISTOL_BASE["bullet_count"]
	_base_stats["cone_spread_angle"] = current_weapon.get("cone_spread_angle") if "cone_spread_angle" in current_weapon else PISTOL_BASE["cone_spread_angle"]
	_base_stats["piercing"] = current_weapon.get("piercing") if "piercing" in current_weapon else PISTOL_BASE["piercing"]
	_base_stats["crit_chance"] = current_weapon.get("crit_chance") if "crit_chance" in current_weapon else PISTOL_BASE["crit_chance"]
	_base_stats["crit_damage"] = current_weapon.get("crit_damage") if "crit_damage" in current_weapon else PISTOL_BASE["crit_damage"]
	_base_stats["lifetime"] = current_weapon.get("lifetime") if "lifetime" in current_weapon else PISTOL_BASE["lifetime"]
	_base_stats["attack_speed"] = current_weapon.get("attack_speed") if "attack_speed" in current_weapon else PISTOL_BASE["attack_speed"]
	_base_stats["damage_multiplier"] = current_weapon.get("damage_multiplier") if "damage_multiplier" in current_weapon else PISTOL_BASE["damage_multiplier"]

func _apply_current_upgrades_to_weapon() -> void:
	if not current_weapon:
		return
	_safe_set_property(current_weapon, "damage", _base_stats["damage"] + _upgrades["damage"])
	_safe_set_property(current_weapon, "projectile_speed", _base_stats["projectile_speed"] + _upgrades["projectile_speed"])
	_safe_set_property(current_weapon, "bullet_count", _base_stats["bullet_count"] + _upgrades["bullet_count"])
	_safe_set_property(current_weapon, "cone_spread_angle", _base_stats["cone_spread_angle"] + _upgrades["cone_spread_angle"])
	_safe_set_property(current_weapon, "piercing", _base_stats["piercing"] + _upgrades["piercing"])
	_safe_set_property(current_weapon, "crit_chance", _base_stats["crit_chance"] + _upgrades["crit_chance"])
	_safe_set_property(current_weapon, "crit_damage", _base_stats["crit_damage"] + _upgrades["crit_damage"])
	_safe_set_property(current_weapon, "lifetime", _base_stats["lifetime"] + _upgrades["lifetime"])
	_safe_set_property(current_weapon, "attack_speed", _base_stats["attack_speed"] + _upgrades["attack_speed"])
	_safe_set_property(current_weapon, "damage_multiplier", _base_stats["damage_multiplier"] + _upgrades["damage_multiplier"])

func _safe_set_property(target: Object, prop_name: String, value: Variant) -> void:
	if prop_name in target:
		target.set(prop_name, value)

func _get_weapon_property(prop_name: String) -> Variant:
	if current_weapon and prop_name in current_weapon:
		return current_weapon.get(prop_name)
	return _base_stats.get(prop_name) + _upgrades.get(prop_name)

func _set_weapon_upgrade(prop_name: String, absolute_val: Variant) -> void:
	var base_val = PISTOL_BASE[prop_name]
	var upgrade_val = absolute_val - base_val
	_upgrades[prop_name] = upgrade_val
	if current_weapon:
		_safe_set_property(current_weapon, prop_name, _base_stats[prop_name] + upgrade_val)

# ── WeaponBase Methods Delegation ──────────────────────────────────────────

func get_projectile_scene() -> PackedScene:
	if current_weapon and current_weapon.has_method("get_projectile_scene"):
		return current_weapon.get_projectile_scene()
	return null

func get_damage() -> float:
	if current_weapon and current_weapon.has_method("get_damage"):
		return current_weapon.get_damage()
	return _base_stats["damage"] + _upgrades["damage"]

func get_projectile_speed() -> float:
	if current_weapon and current_weapon.has_method("get_projectile_speed"):
		return current_weapon.get_projectile_speed()
	return _base_stats["projectile_speed"] + _upgrades["projectile_speed"]

func get_bullet_count() -> int:
	if current_weapon and current_weapon.has_method("get_bullet_count"):
		return current_weapon.get_bullet_count()
	return _base_stats["bullet_count"] + _upgrades["bullet_count"]

func get_spread_angle() -> float:
	if current_weapon and current_weapon.has_method("get_spread_angle"):
		return current_weapon.get_spread_angle()
	return _base_stats["cone_spread_angle"] + _upgrades["cone_spread_angle"]

func get_piercing() -> int:
	if current_weapon and current_weapon.has_method("get_piercing"):
		return current_weapon.get_piercing()
	return _base_stats["piercing"] + _upgrades["piercing"]

func get_crit_chance() -> float:
	if current_weapon and current_weapon.has_method("get_crit_chance"):
		return current_weapon.get_crit_chance()
	return _base_stats["crit_chance"] + _upgrades["crit_chance"]

func get_crit_damage() -> float:
	if current_weapon and current_weapon.has_method("get_crit_damage"):
		return current_weapon.get_crit_damage()
	return _base_stats["crit_damage"] + _upgrades["crit_damage"]

func get_lifetime() -> float:
	if current_weapon and current_weapon.has_method("get_lifetime"):
		return current_weapon.get_lifetime()
	return _base_stats["lifetime"] + _upgrades["lifetime"]

func get_attack_speed() -> float:
	if current_weapon and current_weapon.has_method("get_attack_speed"):
		return current_weapon.get_attack_speed()
	return _base_stats["attack_speed"] + _upgrades["attack_speed"]

func get_damage_multiplier() -> float:
	if current_weapon and current_weapon.has_method("get_damage_multiplier"):
		return current_weapon.get_damage_multiplier()
	return _base_stats["damage_multiplier"] + _upgrades["damage_multiplier"]

func play_shoot_effects() -> void:
	if not current_weapon:
		return
	_play_current_weapon_effects()

func _play_current_weapon_effects() -> void:
	var anim = current_weapon.get_node_or_null("Weapon_Sprites")
	if anim and anim.has_method("play"):
		anim.stop()
		anim.play("shoot")
	var sound = current_weapon.get_node_or_null("Bullet_sound")
	if sound and sound.has_method("play"):
		sound.play()

func get_bullet_spawn_pos(fallback: Vector2) -> Vector2:
	if not current_weapon:
		return fallback
	return _get_current_weapon_spawn_pos(fallback)

func _get_current_weapon_spawn_pos(fallback: Vector2) -> Vector2:
	var mark = current_weapon.get_node_or_null("Bullet_mark_right")
	if mark:
		return mark.global_position
	return fallback

func _align_weapon_mark() -> void:
	if not current_weapon:
		return
	var mark = current_weapon.find_child("Weapon_mark", true, false)
	if not mark:
		return
	_shift_weapon_components(mark)

func _shift_weapon_components(mark: Node2D) -> void:
	var local_pos = current_weapon.to_local(mark.global_position)
	for child in current_weapon.get_children():
		_shift_child_node(child, local_pos)
	current_weapon.position = Vector2.ZERO

func _shift_child_node(child: Node, offset: Vector2) -> void:
	var node_2d = child as Node2D
	if node_2d:
		node_2d.position -= offset

func get_base_weapon_id() -> String:
	if _base_weapon_scene:
		var path = _base_weapon_scene.resource_path.to_lower()
		if "pistol" in path:
			return "pistol"
		if "uzi" in path:
			return "uzi"
		if "shotgun" in path:
			return "shotgun"
	if current_weapon and "id" in current_weapon:
		return current_weapon.id
	return ""
