extends Node

const SYNERGIES = {
	"pistola_mente_colmena": {
		"name": "Mente Colmena",
		"description": "Balas teledirigidas (abejas mecánicas). Dispara 3 abejas que buscan en abanico con vuelo ondulado orgánico y cazan agresivamente al objetivo.",
		"required_weapon": "pistol",
		"required_items": ["colmena", "cerebro", "cabeza_humana"],
		"stat_modifiers": {
			"bullet_count": 1.0,
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
	},
	"bestia_de_caza": {
		"name": "Instinto Canino",
		"description": "Instinto Salvaje: Reemplaza el arma a rango por una segunda arma cuerpo a cuerpo. Otorga +15% daño, +20% vel. ataque, +20% vel. movimiento, pero reduce la defensa en -2 (más arriesgado). Dash activa furia por 3s.",
		"required_items": ["torso_espinado", "brazo_armado", "piernas_caninas"],
		"stat_modifiers": {
			"damage_multiplier": 0.15,
			"attack_speed": 0.20,
			"move_speed_percent": 0.20,
			"armor": -2.0
		}
	},
	"trituradora_biomecanica": {
		"name": "Impulso Ligero",
		"description": "Carga Cinética: Acumulás energía al moverte rápidamente. Al máximo, tu próximo dash genera una onda de choque (daño y empuje en área) y otorga 0.5s de invulnerabilidad. Otorga +10% vel. movimiento y -15% cooldown de dash.",
		"required_items": ["torso_ligero", "piernas_rodantes", "brazo_ligero"],
		"stat_modifiers": {
			"move_speed_percent": 0.10,
			"dash_cooldown_percent": -0.15
		}
	},
	"acorazado_muscular": {
		"name": "Set Musculoso",
		"description": "Poder Descomunal: Incrementa el daño base en +20%, el empuje en +15%, la vida máxima en +25% y la defensa en +3, a cambio de reducir la velocidad de movimiento en -5%.",
		"required_items": ["torso_blindado", "brazo_reforzado", "piernas_bionicas"],
		"stat_modifiers": {
			"damage_multiplier": 0.20,
			"knockback_percent": 0.15,
			"max_health_percent": 0.25,
			"armor": 3.0,
			"move_speed_percent": -0.05
		}
	},
	"minigun": {
		"name": "Minigun",
		"description": "La UZI es reemplazada por una ametralladora biomecánica alimentada por chatarra viva. Mantener presionado el disparo aumenta progresivamente las RPM y el daño.",
		"required_weapon": "uzi",
		"required_items": ["mezcladora", "motocicleta", "sierra_circular"],
		"weapon_scene_override": "res://Scenes/Weapon/Minigun.tscn"
	},
	"lanzallamas": {
		"name": "Lanzallamas",
		"description": "Reemplaza la escopeta por un lanzallamas de alcance corto. Quema al impactar (daño en el tiempo) y el alcance aumenta rápido mientras mantenés presionado el disparo.",
		"required_weapon": "shotgun",
		"required_items": ["cabeza_de_perro", "cabeza_de_perro", "cabeza_de_perro"],
		"stat_modifiers": {},
		"weapon_scene_override": "res://Scenes/Weapon/Flamethrower.tscn"
	},
	"hombre_lobo": {
		"name": "Hombre Lobo",
		"description": "Aparece un enemigo marcado en la sala. El hacha hace muchísimo más daño al enemigo marcado y, al golpearlo, la marca explota dañando a los enemigos cercanos y aparece en otro enemigo.",
		"required_weapon": "hacha",
		"required_items": ["cabeza_humana", "cabeza_de_perro", "aguijon_mecanico"],
		"stat_modifiers": {}
	},
	"daga_del_odio": {
		"name": "Daga del Odio",
		"description": "Mientras menos vida tenés, más letal se vuelve la daga: gana muchísimo daño, velocidad de ataque, alcance y probabilidad/daño crítico a medida que baja tu salud. El filo se tiñe de rojo.",
		"required_weapon": "daga",
		"required_items": ["pulmones", "cabeza_humana", "sierra_circular"],
		"stat_modifiers": {}
	},
	"arrogancia": {
		"name": "Arrogancia",
		"description": "Mientras atacás con la maza, cualquier bala enemiga que te toque durante el golpe rebota devuelta (con daño reducido) hacia los enemigos, en vez de pegarte a vos.",
		"required_weapon": "maze",
		"required_items": ["mezcladora", "cabeza_humana", "colmena"],
		"stat_modifiers": {}
	},
	"relampago": {
		"name": "Relámpago",
		"description": "La UZI dispara normal, pero cada bala tiene chance de salir como bala relámpago: electrifica al enemigo que impacta, lo aturde de forma notoria y contagia la marca en cadena a los enemigos cercanos.",
		"required_weapon": "uzi",
		"required_items": ["cerebro", "aguijon_mecanico", "motocicleta"],
		"stat_modifiers": {},
		"projectile_override": "res://Scenes/Projectiles/ElectroProjectile.tscn",
		"projectile_override_chance": 0.35
	}
}

func get_active_synergies(equipment: Object, active_weapon_id: String, is_main: bool = true) -> Array[String]:
	var active: Array[String] = []
	for syn_id in SYNERGIES.keys():
		_check_and_add_synergy(active, syn_id, equipment, active_weapon_id, is_main)
	return active

func _check_and_add_synergy(active: Array[String], syn_id: String, equipment: Object, active_weapon_id: String, is_main: bool = true) -> void:
	if not GameData.is_synergy_unlocked(syn_id):
		return
	var def = SYNERGIES[syn_id]
	var weapon_sat = _is_weapon_satisfied(def, active_weapon_id)
	var items_sat = _are_items_satisfied(def, equipment, is_main)
	if weapon_sat and items_sat:
		active.append(syn_id)

func _is_synergy_active(syn_id: String, equipment: Object, active_weapon_id: String, is_main: bool = true) -> bool:
	if not GameData.is_synergy_unlocked(syn_id):
		return false
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
	var needed_counts = {}
	for req_item_id in req_items:
		var key = req_item_id.to_lower()
		needed_counts[key] = needed_counts.get(key, 0) + 1
	for item_id in needed_counts.keys():
		var needed = needed_counts[item_id]
		var have = _count_item_equipped(equipment, item_id, is_main)
		if have < needed:
			return false
	return true

func _count_item_equipped(equipment: Object, item_id: String, is_main: bool = true) -> int:
	if not equipment:
		return 0
	var count = 0
	for slot in equipment.slots.keys():
		if is_main and (slot == ItemData.ItemSlot.SEC_W1 or slot == ItemData.ItemSlot.SEC_W2 or slot == ItemData.ItemSlot.SEC_W3):
			continue
		if not is_main and (slot == ItemData.ItemSlot.MAIN_W1 or slot == ItemData.ItemSlot.MAIN_W2 or slot == ItemData.ItemSlot.MAIN_W3):
			continue
		if _check_item_id_in_slot(equipment, slot, item_id):
			count += 1
	return count

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
	# Algunas sinergias (ej: Relampago) no reemplazan TODAS las balas, solo
	# tienen una probabilidad de que la bala disparada sea la especial.
	var chance = float(def.get("projectile_override_chance", 1.0))
	if chance < 1.0 and randf() > chance:
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

# ── Helpers de Consulta y Afinidad para UI ──────────────────────────────────

func get_item_display_name(item_id: String) -> String:
	var item_entry = CodexData.DATA.get("items", {}).get(item_id.to_lower(), {})
	if not item_entry.is_empty():
		return item_entry.get("name", item_id.capitalize())
	return item_id.capitalize()

func get_weapon_display_name(weapon_id: String) -> String:
	if weapon_id == "":
		return "Set Biomecánico"
	var weapon_entry = CodexData.DATA.get("weapons", {}).get(weapon_id.to_lower(), {})
	if not weapon_entry.is_empty():
		return weapon_entry.get("name", weapon_id.capitalize())
	return weapon_id.capitalize()

func get_item_synergy_info(item_id: String, active_weapon_id: String, active_melee_id: String, equipment: Object) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var target_id = item_id.to_lower()
	for syn_id in SYNERGIES.keys():
		var info = _build_single_item_synergy_info(syn_id, target_id, active_weapon_id, active_melee_id, equipment)
		if not info.is_empty():
			results.append(info)
	return results

func _build_single_item_synergy_info(syn_id: String, target_item_id: String, active_weapon_id: String, active_melee_id: String, equipment: Object) -> Dictionary:
	var def = SYNERGIES[syn_id]
	var req_items: Array = def.get("required_items", [])
	if not _list_has_item(req_items, target_item_id):
		return {}
	
	var req_weapon: String = def.get("required_weapon", "")
	var is_active = _is_synergy_weapon_matching(req_weapon, active_weapon_id, active_melee_id)
	var equipped_count = _count_equipped_synergy_items(req_items, equipment, req_weapon, active_weapon_id)
	
	return {
		"id": syn_id,
		"name": def.get("name", syn_id),
		"required_weapon": req_weapon,
		"required_items": req_items,
		"matches_active_weapon": is_active,
		"equipped_count": equipped_count,
		"total_required": req_items.size(),
		"is_unlocked": GameData.is_synergy_unlocked(syn_id)
	}

func _list_has_item(items: Array, target_id: String) -> bool:
	for it in items:
		if str(it).to_lower() == target_id:
			return true
	return false

func _is_synergy_weapon_matching(req_weapon: String, active_main: String, active_melee: String) -> bool:
	if req_weapon == "":
		return true
	var r_w = req_weapon.to_lower()
	if r_w == active_main.to_lower():
		return true
	if r_w == active_melee.to_lower():
		return true
	return false

func _count_equipped_synergy_items(req_items: Array, equipment: Object, req_weapon: String, active_main: String) -> int:
	if not equipment:
		return 0
	var is_main = req_weapon.to_lower() == active_main.to_lower()
	var needed_counts = _calculate_needed_counts(req_items)
	var count = 0
	for it_id in needed_counts.keys():
		var have = _count_item_equipped(equipment, it_id, is_main)
		var needed = needed_counts[it_id]
		count += mini(have, needed)
	return count

func _calculate_needed_counts(req_items: Array) -> Dictionary:
	var dict = {}
	for it in req_items:
		var k = str(it).to_lower()
		dict[k] = dict.get(k, 0) + 1
	return dict

func get_weapon_synergies_info(weapon_id: String, equipment: Object) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var target_w = weapon_id.to_lower()
	for syn_id in SYNERGIES.keys():
		var info = _build_single_weapon_synergy_info(syn_id, target_w, equipment)
		if not info.is_empty():
			results.append(info)
	return results

func _build_single_weapon_synergy_info(syn_id: String, target_weapon: String, equipment: Object) -> Dictionary:
	var def = SYNERGIES[syn_id]
	var req_w = def.get("required_weapon", "").to_lower()
	if req_w != target_weapon:
		return {}
	var req_items: Array = def.get("required_items", [])
	var equipped_count = _count_equipped_synergy_items(req_items, equipment, req_w, target_weapon)
	return {
		"id": syn_id,
		"name": def.get("name", syn_id),
		"required_items": req_items,
		"equipped_count": equipped_count,
		"total_required": req_items.size(),
		"is_unlocked": GameData.is_synergy_unlocked(syn_id)
	}

func get_synergy_recipe_string(syn_id: String) -> String:
	var def = SYNERGIES.get(syn_id, {})
	if def.is_empty():
		return ""
	var weapon = get_weapon_display_name(def.get("required_weapon", ""))
	var item_names: Array[String] = []
	for it in def.get("required_items", []):
		item_names.append(get_item_display_name(str(it)))
	return "%s + %s" % [weapon, ", ".join(item_names)]
