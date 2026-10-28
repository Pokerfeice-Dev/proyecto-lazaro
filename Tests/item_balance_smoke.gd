extends Node2D
class Pilot extends Node2D:
	func _get_equip_stat(key: String, _main: bool = true) -> float:
		return {"damage": 2.0, "damage_multiplier": 0.2}.get(key, 0.0)
class Victim extends Node2D:
	var current_health := 100
	var is_dying := false
	var status := ""
	func take_damage(amount: int, _crit: bool = false) -> void: current_health -= amount
	func apply_status_effect(effect: String) -> void: status = effect
var failures := 0
var count := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func scan(path: String) -> void:
	for directory in DirAccess.get_directories_at(path): scan(path + "/" + directory)
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".tres"): continue
		var item = load(path + "/" + file) as ItemData
		if not item: continue
		count += 1
		check(not item.stats.is_empty(), "Empty stats: " + item.id)
		if item.type == ItemData.ItemType.WEAPON:
			var damage := (10.0 + float(item.stats.get("damage", 0))) * (1 + float(item.stats.get("damage_multiplier", 0)))
			var rate := 1 + float(item.stats.get("attack_speed", 0))
			var crit := 1 + float(item.stats.get("crit_chance", 0)) * (1 + float(item.stats.get("crit_damage", 0)))
			check(damage * rate * crit >= 10 and damage * rate * crit < 15, "Outlier module: " + item.id)
			if item.stats.has("crit_damage"): check(item.stats.get("crit_chance", 0) > 0, "Critical item needs another module: " + item.id)
func run() -> void:
	GameData.event_demo_active = true
	scan("res://Art/Items")
	var pilot := Pilot.new()
	add_child(pilot)
	var melee := MeleeWeaponBase.new()
	melee.damage = 15
	pilot.add_child(melee)
	var victim := Victim.new()
	add_child(victim)
	melee._apply_damage_to_enemy(victim)
	check(victim.current_health == 80, "Melee multiplier not applied")
	var player = load("res://Scripts/Player/player.gd").new()
	var equipment := Equipment.new()
	equipment.name = "Equipment"
	player.add_child(equipment)
	var module := ItemData.new()
	module.stats = {"burn_chance": 1.0}
	equipment.slots = {ItemData.ItemSlot.SEC_W1: module}
	player.apply_melee_item_status(victim)
	check(victim.status == "burn", "Secondary proc not applied")
	check(player._roll_bullet_status_effect(true) == "", "Secondary proc leaked into primary")
	player.free()
	print("ITEM_BALANCE_SMOKE items=", count, " failures=", failures)
	get_tree().quit(failures)
