extends Node

const BASES := {
	"pistol": "Revolver", "uzi": "uzi", "shotgun": "shotgun",
	"daga": "dagger", "maze": "mace", "hacha": "axe"
}
const NAMES := {"pistol": "Pistola", "uzi": "UZI", "shotgun": "Escopeta", "daga": "Daga", "maze": "Maza", "hacha": "Hacha"}
var items: Dictionary = {}
var results: Array = []
var seconds := 30.0
var repeats := 3

func _ready() -> void:
	_run.call_deferred()

func _scan_items(path: String) -> void:
	for dir in DirAccess.get_directories_at(path): _scan_items(path + "/" + dir)
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".tres"): continue
		var item = load(path + "/" + file)
		if item is ItemData: items[item.id] = item

func _run() -> void:
	GameData.event_demo_active = true # save_game no escribe partidas en este modo.
	GameData.active_protocol = ""
	GameData.chosen_primary_weapon = "pistol"
	GameData.chosen_melee_weapon = "daga"
	for id in SynergyManager.SYNERGIES:
		if not GameData.unlocked_synergies.has(id): GameData.unlocked_synergies.append(id)
	AudioServer.set_bus_mute(0, true)
	_scan_items("res://Art/Items")
	if OS.has_environment("BENCH_SECONDS"): seconds = float(OS.get_environment("BENCH_SECONDS"))
	if OS.has_environment("BENCH_REPEATS"): repeats = int(OS.get_environment("BENCH_REPEATS"))
	var cases: Array = []
	for id in BASES:
		cases.append({"name": NAMES[id], "base": id, "synergy": "", "mode": "ranged" if id in ["pistol", "uzi", "shotgun"] else "melee"})
	cases.append({"name": "Escopeta (cerca)", "base": "shotgun", "synergy": "", "mode": "ranged", "distance": 70})
	for id in SynergyManager.SYNERGIES:
		var def: Dictionary = SynergyManager.SYNERGIES[id]
		var base: String = def.get("required_weapon", "pistol")
		var mode := "ranged" if base in ["pistol", "uzi", "shotgun"] else "melee"
		if id == "bestia_de_caza":
			base = "daga"
			mode = "dual"
		cases.append({"name": def.name, "base": base, "synergy": id, "mode": mode})
		if id == "daga_del_odio":
			for health in [0.5, 0.1]:
				cases.append({"name": def.name + " (%d%% HP)" % int(health * 100), "base": base, "synergy": id, "mode": mode, "health": health})
		if id == "alto_octanaje":
			cases.append({"name": def.name + " + pistola", "base": base, "synergy": id, "mode": "combo"})
		if id == "bestia_de_caza":
			cases.append({"name": def.name + " (furia sostenida)", "base": base, "synergy": id, "mode": mode, "fury": true})
		if id == "trituradora_biomecanica":
			cases.append({"name": def.name + " (onda cargada)", "base": base, "synergy": id, "mode": "burst", "distance": 100})
	# Escena adicional existente, sin receta activa; no confundir con Cerberus.
	cases.append({"name": "Flamethrower (escena alternativa)", "base": "pistol", "synergy": "", "mode": "ranged", "scene": "Flamethrower"})
	for config in cases:
		if OS.has_environment("BENCH_FILTER") and not config.name.contains(OS.get_environment("BENCH_FILTER")): continue
		for repetition in repeats:
			await _measure(config, repetition)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Reports"))
	var file := FileAccess.open("res://Reports/dps_benchmark.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"seconds": seconds, "repeats": repeats, "physics_fps": Engine.physics_ticks_per_second, "results": results}, "\t"))
	print("DPS_BENCHMARK_COMPLETE runs=", results.size())
	get_tree().quit()

func _measure(config: Dictionary, repetition: int) -> void:
	seed(271828 + repetition)
	GameData.equipment_slots = {}
	var main: bool = config.base in ["pistol", "uzi", "shotgun"]
	if config.synergy != "":
		var def: Dictionary = SynergyManager.SYNERGIES[config.synergy]
		var weapon_slots := [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3] if main else [ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]
		for i in def.required_items.size():
			var item: ItemData = items[def.required_items[i]]
			var slot = weapon_slots[i] if item.type == ItemData.ItemType.WEAPON else item.slot
			GameData.equipment_slots[slot] = item
	var arena := Node2D.new()
	arena.name = "DPSArena"
	get_tree().root.add_child(arena)
	get_tree().current_scene = arena
	var player = preload("res://Scenes/Player/Player.tscn").instantiate()
	player.set_script(preload("res://Tests/dps_benchmark_player.gd"))
	player.stats = PlayerStats.new()
	arena.add_child(player)
	player.last_dir = "right"
	player.anim_sprite.play("idle_right")
	player.active_weapon.switch_weapon(load("res://Scenes/Weapon/" + (config.get("scene", BASES[config.base]) if main else "Revolver") + ".tscn"))
	player.second_weapon.switch_weapon(load("res://Scenes/Weapon/" + ("dagger" if main else BASES[config.base]) + ".tscn"))
	player._apply_synergy_weapon_override()
	player.stats.current_health = maxi(1, int(player.stats.max_health * config.get("health", 1.0)))
	if config.mode == "dual": player._init_left_melee_weapon()
	var dummy = preload("res://Scenes/Enemies/dummy.tscn").instantiate()
	dummy.set_script(preload("res://Tests/dps_benchmark_dummy.gd"))
	dummy.position = Vector2(160 if config.mode == "ranged" else 45, 0)
	if config.synergy == "lanzallamas": dummy.position.x = 110
	if config.has("distance"): dummy.position.x = config.distance
	arena.add_child(dummy)
	player.aim_target = dummy.position
	player.update_glock()
	await get_tree().physics_frame
	await get_tree().physics_frame
	if config.get("fury", false): player.is_furia_active = true
	var stats_start := _stats(player, main)
	dummy.measuring = true
	if config.mode in ["ranged", "combo"]: Input.action_press("shoot")
	var damage_at_five := 0
	for frame in int(seconds * 60):
		if frame == 0 and config.mode == "burst": player._trigger_trituradora_shockwave()
		if config.get("fury", false): player.is_furia_active = true
		player.benchmark_step(1.0 / 60.0, config.mode)
		await get_tree().physics_frame
		if frame == 299: damage_at_five = dummy.total_damage
	dummy.measuring = false
	Input.action_release("shoot")
	var record := config.duplicate()
	record.merge({"repetition": repetition + 1, "seconds": seconds, "distance": dummy.position.x, "damage": dummy.total_damage, "dps": dummy.total_damage / seconds, "hits": dummy.hits, "critical_hits": dummy.critical_hits, "sources": dummy.sources.duplicate(), "hit_damage_counts": dummy.hit_damage_counts.duplicate(), "dps_after_5s": (dummy.total_damage - damage_at_five) / maxf(1.0, seconds - 5.0), "stats_start": stats_start, "stats_end": _stats(player, main)})
	results.append(record)
	print("DPS_RESULT ", JSON.stringify(record))
	player._force_stop_flame_stream()
	get_tree().current_scene = self
	arena.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

func _stats(player: Player, main: bool) -> Dictionary:
	var weapon = player.active_weapon.current_weapon if main else player.second_weapon.current_weapon
	var out := {"scene": weapon.scene_file_path, "base_damage": weapon.damage, "base_rate": weapon.attack_speed}
	for key in ["damage", "damage_multiplier", "attack_speed", "crit_chance", "crit_damage", "bullet_count", "piercing", "attack_range", "attack_range_percent", "move_speed_percent", "armor", "max_health_percent", "dash_cooldown_percent", "burn_chance", "stun_chance", "slow_chance"]:
		out["bonus_" + key] = player._get_equip_stat(key, main)
	out["effective_damage"] = (weapon.damage + out.bonus_damage) * ((weapon.damage_multiplier if main else 1.0) + out.bonus_damage_multiplier)
	out["normal_hit_damage"] = int(out.effective_damage) if main else roundi((weapon.damage + int(out.bonus_damage)) * (1.0 + out.bonus_damage_multiplier))
	out["attacks_per_second"] = weapon.attack_speed * (1.0 + out.bonus_attack_speed)
	out["crit_chance"] = (weapon.crit_chance if main else 0.0) + out.bonus_crit_chance
	out["crit_multiplier"] = (weapon.crit_damage if main else 2.0) + out.bonus_crit_damage
	if main:
		var projectile: PackedScene = weapon.projectile_scene
		var active := SynergyManager.get_active_synergies(player.get_node("Equipment"), player.get_active_ranged_weapon_id(), true)
		for id in active:
			var def: Dictionary = SynergyManager.SYNERGIES[id]
			if def.has("projectile_override") and not def.has("projectile_override_chance"):
				projectile = load(def.projectile_override)
		out["pellets"] = player._calculate_final_bullet_count(weapon.bullet_count + int(out.bonus_bullet_count), projectile, player.get_active_ranged_weapon_id())
		out["projectile_speed"] = weapon.projectile_speed + player._get_equip_stat("projectile_speed", true)
		out["spread"] = player._calculate_final_spread(weapon.cone_spread_angle + player._get_equip_stat("cone_spread_angle", true), projectile, player.get_active_ranged_weapon_id())
		out["projectile_lifetime"] = weapon.lifetime + player._get_equip_stat("lifetime", true)
		out["piercing"] = weapon.piercing + int(out.bonus_piercing)
	else:
		out["range_scale"] = (weapon.attack_range + out.bonus_attack_range) * (1.0 + out.bonus_attack_range_percent)
	return out
