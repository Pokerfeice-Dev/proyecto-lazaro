extends RefCounted
class_name OmniaCatalog

## Qué se vende en O.M.N.I.A. (la terminal de mejoras permanentes del Lab):
## categorías, precios, íconos y las reglas de cada compra. La ventana
## (OmniaMenu) solo lo muestra. Los nombres y descripciones largas de las
## sinergias salen de SynergyManager, para que coincidan con lo que se ve en
## la run.

const RESEARCH = preload("res://Art/Ui/synergy_research_settings.tres")

const CATEGORIES := ["ESTRUCTURA", "RECURSOS", "ARSENAL", "SINERGIAS", "PROTOCOLOS"]
const CATEGORY_INFO := {
	"ESTRUCTURA": "Mejoras permanentes del cuerpo de Lázaro.",
	"RECURSOS": "Mejoras para conseguir más chatarra, carne y objetos.",
	"ARSENAL": "Armas nuevas para elegir al empezar cada run.",
	"SINERGIAS": "Combinaciones de arma y piezas que transforman tu equipo.",
	"PROTOCOLOS": "Un protocolo activo por run, con un efecto especial.",
}

const UPGRADE_COST_STEP := 50
const ICON_DIR := "res://Art/Ui/svg/"

const ESTRUCTURA := [
	{"key": "integridad_estructural", "name": "Integridad Estructural", "desc": "Aumenta la salud máxima permanentemente (+2 HP por nivel).", "max": 10, "step": 2.0, "value_desc": "+%d HP", "icon": "icon_health"},
	{"key": "servomotores", "name": "Servomotores", "desc": "Aumenta la velocidad de movimiento permanentemente (+1% por nivel).", "max": 10, "step": 1.0, "value_desc": "+%d%% velocidad", "icon": "icon_energy"},
	{"key": "blindaje_compuesto", "name": "Blindaje Compuesto", "desc": "Aumenta la defensa básica permanentemente (+0.2 de defensa por nivel).", "max": 10, "step": 0.2, "value_desc": "+%.1f defensa", "icon": "icon_armor"},
	{"key": "sistema_ataque", "name": "Sistema de Ataque", "desc": "Aumenta permanentemente el daño de todas las armas (+1% por nivel).", "max": 20, "step": 1.0, "value_desc": "+%d%% daño", "icon": "icon_damage"},
	{"key": "sinapsis_acelerada", "name": "Sinapsis Acelerada", "desc": "Aumenta permanentemente la velocidad de ataque (+1% por nivel).", "max": 20, "step": 1.0, "value_desc": "+%d%% vel. de ataque", "icon": "icon_fire_rate"},
	{"key": "balistica_predictiva", "name": "Balística Predictiva", "desc": "Aumenta permanentemente la probabilidad de crítico (+0.5% por nivel).", "max": 10, "step": 0.5, "value_desc": "+%.1f%% crítico", "icon": "icon_critical"},
]

const RECURSOS := [
	{"key": "compactador", "name": "Compactador", "desc": "Aumenta la chatarra obtenida en combate (+2% por nivel).", "max": 20, "step": 2.0, "value_desc": "+%d%% chatarra", "icon": "res://Art/Scrap/scrap_icon.png"},
	{"key": "biomasa_eficiente", "name": "Biomasa Eficiente", "desc": "Aumenta la carne obtenida al derrotar enemigos (+2% por nivel).", "max": 20, "step": 2.0, "value_desc": "+%d%% carne", "icon": "icon_torso"},
	{"key": "imanes_industriales", "name": "Imanes Industriales", "desc": "Aumenta el radio de atracción de chatarra y carne (+5% por nivel).", "max": 10, "step": 5.0, "value_desc": "+%d%% radio", "icon": "icon_range"},
	{"key": "recuperacion_restos", "name": "Recuperación de Restos", "desc": "Aumenta la probabilidad de que caigan objetos y carne (+1% por nivel).", "max": 15, "step": 1.0, "value_desc": "+%d%% drop", "icon": "icon_plus"},
	{"key": "escaner_objetivos", "name": "Escáner de Objetivos", "desc": "Aumenta la probabilidad de que aparezcan enemigos élite (+1% por nivel).", "max": 10, "step": 1.0, "value_desc": "+%d%% élites", "icon": "icon_search"},
]

const ARSENAL := [
	{"id": "hacha", "name": "Hacha de Mano", "desc": "Arma cuerpo a cuerpo: tajos amplios y poderosos.", "cost": 300},
	{"id": "maze", "name": "Maza Pesada", "desc": "Arma cuerpo a cuerpo: golpes contundentes de gran alcance y empuje.", "cost": 300},
	{"id": "uzi", "name": "Uzi", "desc": "Arma a distancia: ráfagas de alta cadencia a corta distancia.", "cost": 500},
	{"id": "shotgun", "name": "Escopeta", "desc": "Arma a distancia: disparo devastador con dispersión en cono.", "cost": 500},
]

## icon: sprite de la sinergia. Si no hay, se usa el arma que pide o la primera pieza.
## tint (opcional): color para diferenciar las que usan un sprite prestado.
const SINERGIAS := [
	{"id": "pistola_mente_colmena", "cost": 300, "icon": "res://Art/Weapons/Distance/Pistol/HiveMindPistol/synergy_hivemind_sprite.png"},
	{"id": "roadkill", "cost": 300, "icon": "res://Art/Weapons/Distance/Pistol/Roadkill/synergy_roadkill_sprite.png"},
	{"id": "minigun", "cost": 300, "icon": "res://Art/Weapons/Distance/Uzi/synergy_heavymetal_sprite.png"},
	{"id": "lanzallamas", "cost": 300, "icon": "res://Art/Weapons/Distance/Shotgun/synergy_cerberus_sprite.png"},
	{"id": "relampago", "cost": 300, "icon": "res://Art/Weapons/Distance/Uzi/synergy_thebride_sprite.png"},
	{"id": "daga_del_odio", "cost": 300, "icon": "res://Art/Weapons/Melee/Dagger/synergy_nemesis_sprite.png"},
	{"id": "hombre_lobo", "cost": 300, "icon": "res://Art/Weapons/Melee/Axe/synergy_wolfsbane_sprite.png"},
	{"id": "arrogancia", "cost": 300, "icon": "res://Art/Weapons/Melee/Mace/synergy_arrogance_sprite.png"},
	{"id": "speed_demon", "cost": 300, "icon": "res://Art/Weapons/Melee/Dagger/synergy_speeddemon_icon.tres"},
	{"id": "snowman", "cost": 300, "icon": "res://Art/Weapons/Distance/Shotgun/synergy_avalanche_sprite.png"},
	{"id": "bestia_de_caza", "cost": 500, "icon": "", "advanced": true},
	{"id": "trituradora_biomecanica", "cost": 500, "icon": "", "advanced": true},
	{"id": "acorazado_muscular", "cost": 500, "icon": "", "advanced": true},
]
## Las sinergias avanzadas (sets de cuerpo) piden tener estas dos primero.
const ADVANCED_REQUIRES := ["pistola_mente_colmena", "roadkill"]

const PROTOCOLOS := [
	{"id": "circuito_emergencia", "name": "Circuito de Emergencia", "desc": "El primer golpe de cada sala hace un 30% menos de daño.", "cost": 400, "icon": "icon_armor"},
	{"id": "reparacion_autonoma", "name": "Reparación Autónoma", "desc": "Al limpiar una sala: +1 HP.", "cost": 500, "icon": "icon_health"},
	{"id": "nucleo_vampirico", "name": "Núcleo Vampírico", "desc": "Cada 25 enemigos derrotados: +2 HP.", "cost": 600, "icon": "icon_health"},
	{"id": "sobrecarga", "name": "Sobrecarga", "desc": "Al entrar a una sala: +10% de daño durante 5 segundos.", "cost": 700, "icon": "icon_energy"},
	{"id": "reflejo_sintetico", "name": "Reflejo Sintético", "desc": "Después de un dash dejas una copia holográfica que dispara una vez.", "cost": 800, "icon": "icon_compare"},
	{"id": "enjambre_residual", "name": "Enjambre Residual", "desc": "Empiezas cada run con una abeja mecánica aliada.", "cost": 900, "icon": "icon_projectiles"},
	{"id": "blindaje_reactivo", "name": "Blindaje Reactivo", "desc": "Al recibir daño ganas +2 de defensa durante 3 segundos.", "cost": 900, "icon": "icon_armor"},
	{"id": "furia_de_titanio", "name": "Furia de Titanio", "desc": "Con menos del 30% de vida: +25% de velocidad de ataque.", "cost": 1000, "icon": "icon_fire_rate"},
	{"id": "reciclaje_instantaneo", "name": "Reciclaje Instantáneo", "desc": "Cada jefe derrotado te da 50 de chatarra extra.", "cost": 1200, "icon": "res://Art/Scrap/scrap_icon.png"},
]

# --- Entradas listas para mostrar ---
# Cada entrada es un Dictionary con: id, name, desc, icon (Texture2D), kind,
# state ("disponible", "comprado", "bloqueado", "maximo", "activo"), cost,
# action (texto del botón) y extras según el tipo.

static func entries(category: String) -> Array:
	match category:
		"ESTRUCTURA": return _leveled_entries(ESTRUCTURA)
		"RECURSOS": return _leveled_entries(RECURSOS)
		"ARSENAL": return _weapon_entries()
		"SINERGIAS": return _synergy_entries()
		"PROTOCOLOS": return _protocol_entries()
	return []

static func progress(category: String) -> Vector2i:
	var done = 0
	var total = 0
	for e in entries(category):
		if e.kind == "upgrade":
			done += e.level
			total += e.max
		else:
			total += 1
			if e.state in ["comprado", "activo"]:
				done += 1
	return Vector2i(done, total)

static func _leveled_entries(list: Array) -> Array:
	var result = []
	for up in list:
		var lvl = int(GameData.core_upgrades.get(up.key, 0))
		var maxed = lvl >= up.max
		result.append({
			"id": up.key, "name": up.name, "desc": up.desc, "kind": "upgrade",
			"icon": load_icon(up.icon), "level": lvl, "max": up.max,
			"bonus": _bonus_text(up, lvl),
			"cost": 0 if maxed else (lvl + 1) * UPGRADE_COST_STEP,
			"state": "maximo" if maxed else "disponible",
			"action": "MÁXIMO" if maxed else "MEJORAR",
		})
	return result

static func _bonus_text(up: Dictionary, lvl: int) -> String:
	var value = lvl * up.step
	if "%d" in up.value_desc:
		return up.value_desc % int(round(value))
	return up.value_desc % value

static func _weapon_entries() -> Array:
	var result = []
	for w in ARSENAL:
		var owned = GameData.is_codex_unlocked("weapons", w.id)
		result.append({
			"id": w.id, "name": w.name, "desc": w.desc, "kind": "weapon",
			"icon": _codex_icon("weapons", w.id), "cost": w.cost,
			"state": "comprado" if owned else "disponible",
			"action": "DESBLOQUEADA" if owned else "DESBLOQUEAR",
		})
	return result

static func _synergy_entries() -> Array:
	var advanced_ready = true
	for req in ADVANCED_REQUIRES:
		advanced_ready = advanced_ready and GameData.is_synergy_unlocked(req)
	var result = []
	for s in SINERGIAS:
		var def: Dictionary = SynergyManager.SYNERGIES.get(s.id, {})
		var owned = GameData.is_synergy_unlocked(s.id)
		var discovered = GameData.is_synergy_discovered(s.id)
		var blocked = s.get("advanced", false) and not advanced_ready and not owned
		var state = "comprado" if owned else ("bloqueado" if blocked else "disponible")
		result.append({
			"id": s.id, "name": def.get("name", s.id) if discovered else "Investigación %02d" % (result.size() + 1),
			"desc": def.get("description", "") if discovered else RESEARCH.clues.get(s.id, "Experimentá con componentes para descubrir esta combinación."),
			"kind": "synergy", "icon": _synergy_icon(s, def) if discovered else load_icon("icon_lock"), "cost": s.cost,
			"tint": s.get("tint", Color.WHITE),
			"recipe": _recipe(def), "recipe_text": SynergyManager.get_synergy_recipe_string(s.id),
			"requirement": "Requiere desbloquear las investigaciones 01 y 02." if blocked else "",
			"state": state,
			"action": {"comprado": "DESBLOQUEADA", "bloqueado": "BLOQUEADA"}.get(state, "DESBLOQUEAR"),
		})
	return result

static func _protocol_entries() -> Array:
	var result = []
	for p in PROTOCOLOS:
		var owned = GameData.unlocked_protocols.has(p.id)
		var active = GameData.active_protocol == p.id
		var state = "activo" if active else ("comprado" if owned else "disponible")
		result.append({
			"id": p.id, "name": p.name, "desc": p.desc, "kind": "protocol",
			"icon": load_icon(p.icon), "cost": p.cost, "state": state,
			"action": {"activo": "DESACTIVAR", "comprado": "EQUIPAR"}.get(state, "DESBLOQUEAR"),
		})
	return result

# --- Para otras pantallas (el códice) ---

static func synergy_ids() -> Array:
	var ids = []
	for s in SINERGIAS:
		ids.append(s.id)
	return ids

static func synergy_icon(id: String) -> Texture2D:
	for s in SINERGIAS:
		if s.id == id:
			return _synergy_icon(s, SynergyManager.SYNERGIES.get(id, {}))
	return null

static func synergy_tint(id: String) -> Color:
	for s in SINERGIAS:
		if s.id == id:
			return s.get("tint", Color.WHITE)
	return Color.WHITE

static func synergy_recipe(id: String) -> Array:
	return _recipe(SynergyManager.SYNERGIES.get(id, {}))

## Arma y piezas que pide una sinergia: [{name, icon}].
static func _recipe(def: Dictionary) -> Array:
	var parts = []
	var weapon = def.get("required_weapon", "")
	if weapon != "":
		parts.append({"name": SynergyManager.get_weapon_display_name(weapon), "icon": _codex_icon("weapons", weapon)})
	for item in def.get("required_items", []):
		parts.append({"name": SynergyManager.get_item_display_name(str(item)), "icon": _codex_icon("items", str(item))})
	return parts

static func _synergy_icon(s: Dictionary, def: Dictionary) -> Texture2D:
	if s.icon != "" and ResourceLoader.exists(s.icon):
		return load(s.icon)
	var weapon = def.get("required_weapon", "")
	if weapon != "":
		return _codex_icon("weapons", weapon)
	var items = def.get("required_items", [])
	return _codex_icon("items", str(items[0])) if items.size() > 0 else null

static func _codex_icon(category: String, id: String) -> Texture2D:
	var cat: Dictionary = CodexData.DATA.get(category, {})
	return cat.get(id, {}).get("icon", null)

## "icon_health" -> SVG de la UI; una ruta completa -> esa textura.
static func load_icon(name: String) -> Texture2D:
	var path = name if name.begins_with("res://") else ICON_DIR + name + ".svg"
	return load(path) if ResourceLoader.exists(path) else null

# --- Compras (devuelven true si se hizo) ---

static func purchase(entry: Dictionary) -> bool:
	match entry.kind:
		"upgrade":
			if entry.state != "disponible" or not GameData.spend_scrap(entry.cost): return false
			GameData.core_upgrades[entry.id] = int(GameData.core_upgrades.get(entry.id, 0)) + 1
		"weapon":
			if entry.state != "disponible" or not GameData.spend_scrap(entry.cost): return false
			GameData.unlock_codex_entry("weapons", entry.id)
		"synergy":
			if entry.state != "disponible" or not GameData.spend_scrap(entry.cost): return false
			if not GameData.unlocked_synergies.has(entry.id):
				GameData.unlocked_synergies.append(entry.id)
		"protocol":
			return _use_protocol(entry)
	GameData.save_game()
	return true

static func _use_protocol(entry: Dictionary) -> bool:
	match entry.state:
		"activo":
			GameData.active_protocol = ""
		"comprado":
			GameData.active_protocol = entry.id
		_:
			if not GameData.spend_scrap(entry.cost): return false
			if not GameData.unlocked_protocols.has(entry.id):
				GameData.unlocked_protocols.append(entry.id)
	GameData.save_game()
	return true

## ¿El botón de la entrada se puede apretar?
static func can_act(entry: Dictionary) -> bool:
	if entry.kind == "protocol" and entry.state in ["activo", "comprado"]:
		return true
	return entry.state == "disponible" and GameData.scrap >= entry.cost

## Precio a mostrar (0 = no se muestra).
static func shown_cost(entry: Dictionary) -> int:
	if entry.state != "disponible":
		return 0
	return entry.cost

## Los índices distinguen componentes repetidos de una misma receta.
static func is_ingredient_revealed(id: String, index: int) -> bool:
	if not GameData.is_synergy_unlocked(id): return false
	return GameData.is_synergy_discovered(id) or index == 0 or GameData.synergy_item_hints.get(id, []).has(index)

static func hint_cost(index: int) -> int:
	return RESEARCH.second_item_cost if index == 1 else RESEARCH.third_item_cost

static func purchase_hint(id: String, index: int) -> bool:
	var items: Array = SynergyManager.SYNERGIES.get(id, {}).get("required_items", [])
	if index < 1 or index > 2 or index >= items.size(): return false
	if not GameData.is_synergy_unlocked(id) or is_ingredient_revealed(id, index): return false
	if not GameData.spend_scrap(maxi(0, hint_cost(index))): return false
	var hints: Array = GameData.synergy_item_hints.get(id, []).duplicate()
	hints.append(index)
	GameData.synergy_item_hints[id] = hints
	GameData.save_game()
	return true

static func synergy_ingredients(id: String) -> Array:
	var definition: Dictionary = SynergyManager.SYNERGIES.get(id, {}).duplicate()
	definition["required_weapon"] = ""
	return _recipe(definition)
