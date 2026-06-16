extends Node2D

@export var default_weapon_scene: PackedScene = preload("res://Scenes/Weapon/dagger.tscn")
@export var dagger_scene: PackedScene = preload("res://Scenes/Weapon/dagger.tscn")
@export var mace_scene: PackedScene = preload("res://Scenes/Weapon/mace.tscn")
@export var axe_scene: PackedScene = preload("res://Scenes/Weapon/axe.tscn")

var current_weapon: Node2D = null
var active_scene: PackedScene = null

const DEFAULT_BASE: Dictionary = {
	"damage": 30.0,
	"attack_speed": 1.0,
	"attack_range": 1.0,
	"knockback_force": 0.0
}

var _base_stats: Dictionary = {
	"damage": 15.0,
	"attack_speed": 1.0,
	"attack_range": 1.0,
	"knockback_force": 150.0
}

var _upgrades: Dictionary = {
	"damage": 0.0,
	"attack_speed": 0.0,
	"attack_range": 0.0,
	"knockback_force": 0.0
}

var damage: int:
	get: return int(_get_melee_property("damage"))
	set(val): _set_melee_upgrade("damage", val)

var attack_speed: float:
	get: return _get_melee_property("attack_speed")
	set(val): _set_melee_upgrade("attack_speed", val)

var attack_range: float:
	get: return _get_melee_property("attack_range")
	set(val): 
		_set_melee_upgrade("attack_range", val)
		scale = Vector2(_get_melee_property("attack_range"), _get_melee_property("attack_range"))

var knockback_force: float:
	get: return _get_melee_property("knockback_force")
	set(val): _set_melee_upgrade("knockback_force", val)

func _ready() -> void:
	_load_default_weapon()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	if not event.pressed: return
	_handle_melee_switch_keys(event.keycode)

func _handle_melee_switch_keys(keycode: int) -> void:
	if keycode == KEY_4:
		switch_weapon(dagger_scene)
	elif keycode == KEY_5:
		switch_weapon(mace_scene)
	elif keycode == KEY_6:
		switch_weapon(axe_scene)

func _load_default_weapon() -> void:
	if default_weapon_scene:
		switch_weapon(default_weapon_scene)

func switch_weapon(new_scene: PackedScene) -> void:
	if not new_scene: return
	active_scene = new_scene
	_unlock_codex(new_scene)
	_remove_current_weapon()
	_instantiate_weapon(new_scene)
	_align_weapon_mark()
	_cache_base_stats()
	_apply_current_upgrades_to_weapon()

func _unlock_codex(scene: PackedScene) -> void:
	if not GameData.has_method("unlock_codex_entry"): return
	var path = scene.resource_path.to_lower()
	_perform_codex_unlock(path)

func _perform_codex_unlock(path: String) -> void:
	if "dagger" in path:
		GameData.unlock_codex_entry("weapons", "daga")
		return
	if "mace" in path:
		GameData.unlock_codex_entry("weapons", "maze")
		return
	if "axe" in path:
		GameData.unlock_codex_entry("weapons", "hacha")

func _remove_current_weapon() -> void:
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null

func _instantiate_weapon(new_scene: PackedScene) -> void:
	current_weapon = new_scene.instantiate()
	add_child(current_weapon)

func _cache_base_stats() -> void:
	if not current_weapon: return
	_base_stats["damage"] = current_weapon.get("damage") if "damage" in current_weapon else 15.0
	_base_stats["attack_speed"] = current_weapon.get("attack_speed") if "attack_speed" in current_weapon else 1.0
	_base_stats["attack_range"] = current_weapon.get("attack_range") if "attack_range" in current_weapon else 1.0
	_base_stats["knockback_force"] = current_weapon.get("knockback_force") if "knockback_force" in current_weapon else 150.0

func _apply_current_upgrades_to_weapon() -> void:
	if not current_weapon: return
	_safe_set_property(current_weapon, "damage", int(_base_stats["damage"] + _upgrades["damage"]))
	_safe_set_property(current_weapon, "attack_speed", _base_stats["attack_speed"] + _upgrades["attack_speed"])
	_safe_set_property(current_weapon, "attack_range", _base_stats["attack_range"] + _upgrades["attack_range"])
	_safe_set_property(current_weapon, "knockback_force", _base_stats["knockback_force"] + _upgrades["knockback_force"])

func _safe_set_property(target: Object, prop_name: String, value: Variant) -> void:
	if prop_name in target:
		target.set(prop_name, value)

func _get_melee_property(prop_name: String) -> Variant:
	if current_weapon and prop_name in current_weapon:
		return current_weapon.get(prop_name)
	return _base_stats.get(prop_name) + _upgrades.get(prop_name)

func _set_melee_upgrade(prop_name: String, absolute_val: Variant) -> void:
	var base_val = DEFAULT_BASE[prop_name]
	var upgrade_val = absolute_val - base_val
	_upgrades[prop_name] = upgrade_val
	if current_weapon:
		_safe_set_property(current_weapon, prop_name, _base_stats[prop_name] + upgrade_val)

func attack() -> void:
	if not current_weapon: return
	if not current_weapon.has_method("attack"): return
	current_weapon.attack()

func is_attacking() -> bool:
	if not current_weapon: return false
	if not current_weapon.has_method("is_attacking"): return false
	return current_weapon.is_attacking()

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
