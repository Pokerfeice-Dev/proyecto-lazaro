extends Node

const SYNERGIES = {
	"pistola_mente_colmena": {
		"name": "Pistola Mente Colmena",
		"description": "Balas teledirigidas (abejas mecánicas) que buscan enemigos. Aumenta proyectiles, daño, rango y velocidad de ataque, pero reduce la velocidad de bala.",
		"required_weapon": "pistol",
		"required_items": ["colmena", "cerebro", "cabeza_humana"],
		"stat_modifiers": {
			"bullet_count": 2.0,
			"damage": 3.0,
			"lifetime": 4.0,
			"projectile_speed": -200.0,
			"attack_speed": 1.5
		},
		"projectile_override": "res://Scenes/Projectiles/BeeProjectile.tscn",
		"weapon_scene_override": "res://Scenes/Weapon/HivemindPistol.tscn"
	},
	"roadkill": {
		"name": "Roadkill",
		"description": "Dispara un proyectil que rebota en las paredes hasta 3 veces o hasta que impacta sobre 3 enemigos. Aumenta el daño, velocidad de proyectil, velocidad de ataque y piercing.",
		"required_weapon": "pistol",
		"required_items": ["motocicleta", "sierra_circular", "pulmones"],
		"stat_modifiers": {
			"damage": 5.0,
			"projectile_speed": 150.0,
			"attack_speed": 1.0,
			"piercing": 3.0
		},
		"projectile_override": "res://Scenes/Projectiles/RoadkillProjectile.tscn",
		"weapon_scene_override": "res://Scenes/Weapon/RoadkillPistol.tscn"
	}
}

func get_active_synergies(equipment: Object, active_weapon_id: String, is_main: bool = true) -> Array[String]:
	var active: Array[String] = []
	for syn_id in SYNERGIES.keys():
		_check_and_add_synergy(active, syn_id, equipment, active_weapon_id, is_main)
	return active

func _check_and_add_synergy(active: Array[String], syn_id: String, equipment: Object, active_weapon_id: String, is_main: bool = true) -> void:
	var def = SYNERGIES[syn_id]
	var weapon_sat = _is_weapon_satisfied(def, active_weapon_id)
	var items_sat = _are_items_satisfied(def, equipment, is_main)
	print("[SynergyManager] Checking: ", syn_id, " | Active Weapon: '", active_weapon_id, "' (Sat: ", weapon_sat, ") | Items (Sat: ", items_sat, ")")
	if weapon_sat and items_sat:
		active.append(syn_id)

func _is_synergy_active(syn_id: String, equipment: Object, active_weapon_id: String, is_main: bool = true) -> bool:
	var def = SYNERGIES[syn_id]
	if not _is_weapon_satisfied(def, active_weapon_id):
		return false
	if not _are_items_satisfied(def, equipment, is_main):
		return false
	return true

func _is_weapon_satisfied(def: Dictionary, active_weapon_id: String) -> bool:
	var req_weapon = def.get("required_weapon", "")
	if req_weapon == "":
		return true
	return req_weapon.to_lower() == active_weapon_id.to_lower()

func _are_items_satisfied(def: Dictionary, equipment: Object, is_main: bool = true) -> bool:
	var req_items = def.get("required_items", [])
	for req_item_id in req_items:
		var is_eq = _is_item_equipped(equipment, req_item_id, is_main)
		print("  - Checking item: ", req_item_id, " | Equipped: ", is_eq)
		if not is_eq:
			return false
	return true

func _is_item_equipped(equipment: Object, item_id: String, is_main: bool = true) -> bool:
	if not equipment:
		return false
	for slot in equipment.slots.keys():
		if is_main and (slot == ItemData.ItemSlot.SEC_W1 or slot == ItemData.ItemSlot.SEC_W2 or slot == ItemData.ItemSlot.SEC_W3):
			continue
		if not is_main and (slot == ItemData.ItemSlot.MAIN_W1 or slot == ItemData.ItemSlot.MAIN_W2 or slot == ItemData.ItemSlot.MAIN_W3):
			continue
		if _check_item_id_in_slot(equipment, slot, item_id):
			return true
	return false

func _check_item_id_in_slot(equipment: Object, slot: Variant, item_id: String) -> bool:
	var item = equipment.slots[slot]
	if not item:
		return false
	return item.id.to_lower() == item_id.to_lower()

func get_synergies_stat_modifier(active_syn_ids: Array[String], stat_name: String) -> float:
	var total = 0.0
	for syn_id in active_syn_ids:
		total += _get_single_synergy_stat_modifier(syn_id, stat_name)
	return total

func _get_single_synergy_stat_modifier(syn_id: String, stat_name: String) -> float:
	var def = SYNERGIES[syn_id]
	var modifiers = def.get("stat_modifiers", {})
	return float(modifiers.get(stat_name, 0.0))

func get_synergies_projectile_override(active_syn_ids: Array[String]) -> PackedScene:
	for syn_id in active_syn_ids:
		var scene = _get_single_synergy_projectile_override(syn_id)
		if scene:
			return scene
	return null

func _get_single_synergy_projectile_override(syn_id: String) -> PackedScene:
	var def = SYNERGIES[syn_id]
	var path = def.get("projectile_override", "")
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as PackedScene

func get_synergies_weapon_override(active_syn_ids: Array[String]) -> String:
	for syn_id in active_syn_ids:
		var path = _get_single_synergy_weapon_override(syn_id)
		if path != "":
			return path
	return ""

func _get_single_synergy_weapon_override(syn_id: String) -> String:
	var def = SYNERGIES[syn_id]
	var path = def.get("weapon_scene_override", "")
	if path == "":
		return ""
	if not ResourceLoader.exists(path):
		return ""
	return path
