class_name RunLog
extends RefCounted

## Registro de cada run en un CSV, para revisar después del evento cómo jugó la
## gente: cuánto duró, hasta dónde llegó, qué la mató, cuánto tardó en cada
## sala, qué armas y objetos agarró, si encontró el inventario, etc.
## Se escribe una fila cuando la run termina (muerte, victoria, abandono,
## inactividad o se cerró el juego).
## Archivo: user://registro_runs.csv. En el ejecutable también se copia la fila
## al lado del .exe (registro_runs.csv), así es fácil de encontrar.
## Se prende y se apaga desde el menú de cheats (U / T), pestaña "Registro":
## así solo cuentan las runs de los jugadores y no nuestras pruebas. Queda
## guardado aunque se cierre el juego (user://registro_runs.cfg).
## Uso:
##   RunLog.begin()                 al empezar la run
##   RunLog.note_synergy(id)        al activarse una sinergia
##   RunLog.note_room()             al pasar a la sala siguiente
##   RunLog.note_damage(n, fuente)  cuando el jugador recibe daño
##   RunLog.note_heal(n)            cuando se cura
##   RunLog.note_item(item)         al agarrar un objeto (piso, cofre, tienda)
##   RunLog.note("dashes")          contadores sueltos (dashes, inventario)
##   RunLog.new_player()            el modo stand volvió al menú: viene otra persona
##   RunLog.finish("muerte")        al terminar
##   RunLog.screen("Resultado")     se abrió una pantalla final (resultado, QR, video)
##   RunLog.screens_done()          se cerró la última pantalla final: se escribe la fila
## Con muerte o victoria la fila espera a que se cierren las pantallas finales,
## para anotar cuáles vio y cuánto se quedó en cada una.

const FILE_NAME := "registro_runs.csv"
const CONFIG := "user://registro_runs.cfg"
const SEP := ";" # Excel en español separa columnas con punto y coma
const COLUMNS := [
	"fecha", "hora_inicio", "duracion_seg", "duracion", "modo", "resultado",
	"zona", "sala", "escena", "causa", "enemigos", "chatarra",
	"arma_principal", "arma_secundaria", "sinergias", "piezas_equipadas", "control",
	"jugador", "run_del_jugador", "salas_completadas", "tiempos_por_sala",
	"golpes_recibidos", "dano_recibido", "dano_por_fuente", "curacion", "vida_final",
	"jefe_vida_restante", "dashes", "objetos_recogidos", "objetos",
	"veces_inventario", "primera_sinergia", "fps_promedio",
	"tutorial_completado", "cambio_armas", "primer_dash",
	"pantallas_finales", "seg_pantallas_finales",
]
const DEFAULT_WEAPONS := ["pistol", "daga"]

static var _active := false
static var _start_msec := 0
static var _start_time := ""
static var _start_frames := 0
static var _room_msec := 0
static var _synergies: Array[String] = []
static var _first_synergy := ""
static var _room_times: Array[String] = []
static var _damage_by_source := {}
static var _hits := 0
static var _healed := 0
static var _items: Array[String] = []
static var _counters := {}
static var _new_player := true
static var _player := 0
static var _player_runs := 0
static var _first_dash := ""
static var _pending: Array = [] # fila terminada esperando las pantallas finales
static var _screens: Array[String] = []
static var _screen_name := ""
static var _screen_msec := 0
static var _screens_msec := 0

static func is_active() -> bool:
	return _active

static func begin() -> void:
	if _active:
		finish("abandonada")
	_flush("")
	if not is_enabled(): return
	_active = true
	_start_msec = Time.get_ticks_msec()
	_room_msec = _start_msec
	_start_time = Time.get_time_string_from_system()
	_start_frames = Engine.get_frames_drawn()
	_synergies.clear()
	_first_synergy = ""
	_room_times.clear()
	_damage_by_source.clear()
	_hits = 0
	_healed = 0
	_items.clear()
	_counters.clear()
	_first_dash = ""
	if _new_player:
		_new_player = false
		_player = _next_player_number()
		_player_runs = 0
	_player_runs += 1

## El modo stand volvió al menú por inactividad: la próxima run es de otra persona.
static func new_player() -> void:
	_flush("inactividad")
	_new_player = true

static func note_synergy(syn_id: String) -> void:
	if not _active or _synergies.has(syn_id): return
	_synergies.append(syn_id)
	if _first_synergy == "":
		_first_synergy = "%s (%s)" % [_synergy_name(syn_id), _clock(_elapsed())]

## Se terminó una sala y se pasa a la siguiente: queda anotado cuánto tardó.
static func note_room() -> void:
	if not _active: return
	var now = Time.get_ticks_msec()
	_room_times.append("S%d %s" % [GameData.current_run_room, _clock(int((now - _room_msec) / 1000.0))])
	_room_msec = now

static func note_damage(amount: int, source: String) -> void:
	if not _active: return
	_hits += 1
	_damage_by_source[source] = _damage_by_source.get(source, 0) + amount

static func note_heal(amount: int) -> void:
	if _active and amount > 0:
		_healed += amount

static func note_item(item) -> void:
	if not _active or item == null: return
	var item_name = item.get("item_name")
	_items.append(str(item_name) if item_name else "?")

static func note(counter: String) -> void:
	if not _active: return
	if counter == "dashes" and not _counters.has("dashes"):
		_first_dash = _clock(_elapsed())
	_counters[counter] = _counters.get(counter, 0) + 1

## resultado: "muerte", "victoria", "abandonada", "inactividad" o "cerrado".
static func finish(result: String) -> void:
	_flush(result) # si quedaba una fila esperando (se cerró el juego en la pantalla final)
	if not _active: return
	_active = false
	_pending = _row(result)
	_screens.clear()
	_screen_name = ""
	_screens_msec = Time.get_ticks_msec()
	# sin pantalla final (abandono, inactividad, cierre): se escribe ya
	if not result in ["muerte", "victoria"]:
		_flush("")

## Se abrió una pantalla final; la anterior queda anotada con su tiempo.
static func screen(screen_name: String) -> void:
	if _pending.is_empty(): return
	_close_screen("")
	_screen_name = screen_name
	_screen_msec = Time.get_ticks_msec()

## El jugador cerró la última pantalla final: se escribe la fila.
static func screens_done() -> void:
	_flush("")

static func _close_screen(reason: String) -> void:
	if _screen_name == "": return
	var secs = int((Time.get_ticks_msec() - _screen_msec) / 1000.0)
	_screens.append("%s %s%s" % [_screen_name, _clock(secs), " (%s)" % reason if reason != "" else ""])
	_screen_name = ""

# reason: por qué se cortó la pantalla abierta ("" = la cerró el jugador)
static func _flush(reason: String) -> void:
	if _pending.is_empty(): return
	_close_screen(reason)
	var row = _pending
	_pending = []
	row.append(" | ".join(_screens))
	row.append(int((Time.get_ticks_msec() - _screens_msec) / 1000.0) if not _screens.is_empty() else 0)
	var line = SEP.join(row.map(_clean))
	_append("user://" + FILE_NAME, line)
	if not OS.has_feature("editor"):
		_append(OS.get_executable_path().get_base_dir().path_join(FILE_NAME), line)

## Ruta completa del registro principal (para mostrarla o abrir la carpeta).
static func file_path() -> String:
	return ProjectSettings.globalize_path("user://" + FILE_NAME)

## Si el registro está prendido (por defecto, apagado).
static func is_enabled() -> bool:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG) != OK: return false
	return cfg.get_value("registro", "activo", false)

## Prender o apagar el registro. Al apagarlo, la run en curso no se anota.
static func set_enabled(on: bool) -> void:
	var cfg = ConfigFile.new()
	cfg.load(CONFIG)
	cfg.set_value("registro", "activo", on)
	cfg.save(CONFIG)
	if not on:
		_active = false
		_pending = []

## Guarda el registro actual con la fecha en el nombre y deja uno vacío,
## para empezar a contar desde cero. No borra nada. Devuelve el nombre nuevo.
static func archive() -> String:
	var new_name = _archived_name("")
	var paths = [ProjectSettings.globalize_path("user://")]
	if not OS.has_feature("editor"):
		paths.append(OS.get_executable_path().get_base_dir())
	var moved = ""
	for dir in paths:
		var from = dir.path_join(FILE_NAME)
		if FileAccess.file_exists(from) and DirAccess.rename_absolute(from, dir.path_join(new_name)) == OK:
			moved = new_name
	# la numeración de jugadores también vuelve a empezar
	var cfg = ConfigFile.new()
	cfg.load(CONFIG)
	cfg.set_value("registro", "jugadores", 0)
	cfg.save(CONFIG)
	_new_player = true
	return moved

## Carpeta donde queda el registro (para abrirla desde el menú de cheats).
static func folder_path() -> String:
	return file_path().get_base_dir()

## Lee el registro guardado: una lista de filas {columna: valor}, la más vieja primero.
static func read_rows() -> Array:
	var rows := []
	var path = "user://" + FILE_NAME
	if not FileAccess.file_exists(path): return rows
	var lines = FileAccess.get_file_as_string(path).replace("\r", "").split("\n", false)
	if lines.is_empty(): return rows
	var header = lines[0].trim_prefix("﻿").split(SEP)
	for i in range(1, lines.size()):
		var cells = lines[i].split(SEP)
		var row := {}
		for c in header.size():
			row[header[c]] = cells[c] if c < cells.size() else ""
		rows.append(row)
	return rows

# --- Armado de la fila ---

static func _row(result: String) -> Array:
	var seconds = _elapsed()
	var tree = Engine.get_main_loop() as SceneTree
	var scene = tree.current_scene
	var player = tree.get_first_node_in_group("player")
	var rooms = _room_times.duplicate()
	rooms.append("%s %s (sin terminar)" % [_room_label(), _clock(int((Time.get_ticks_msec() - _room_msec) / 1000.0))])
	return [
		Time.get_date_string_from_system(), _start_time, seconds, _clock(seconds),
		"evento" if GameData.is_event_demo() or GameData.is_event_build() else "normal",
		result,
		GameData.get_zone_name(GameData.current_level), _room_label(),
		scene.name if scene else "",
		GameData.last_killer if result == "muerte" else "",
		GameData.run_enemies_killed, GameData.run_scrap_collected,
		SynergyManager.get_weapon_display_name(GameData.chosen_primary_weapon),
		SynergyManager.get_weapon_display_name(GameData.chosen_melee_weapon),
		", ".join(_synergies.map(_synergy_name)),
		", ".join(_equipped_names()),
		"joystick" if InputMode.is_gamepad() else "teclado y mouse",
		_player, _player_runs, _room_times.size(), " | ".join(rooms),
		_hits, _sum(_damage_by_source), _damage_text(), _healed,
		_health_text(player), _boss_health_text(scene),
		_counters.get("dashes", 0), _items.size(), ", ".join(_items),
		_counters.get("inventario", 0), _first_synergy,
		roundi((Engine.get_frames_drawn() - _start_frames) / maxf(seconds, 1.0)),
		"sí" if GameData.has_completed_tutorial else "no",
		_weapons_changed_text(), _first_dash,
	]

# "no" si siguió con Pistola + Daga; si no, qué cambió.
static func _weapons_changed_text() -> String:
	var changed = []
	if GameData.chosen_primary_weapon != DEFAULT_WEAPONS[0]: changed.append("principal")
	if GameData.chosen_melee_weapon != DEFAULT_WEAPONS[1]: changed.append("cuerpo a cuerpo")
	return "no" if changed.is_empty() else "sí (%s)" % ", ".join(changed)

# "Sala 4" o "Jefe" (cuando ya pasó todas las salas de la zona).
static func _room_label() -> String:
	if GameData.current_run_room > GameData.rooms_before_boss:
		return "Jefe"
	return "Sala %d" % GameData.current_run_room

static func _elapsed() -> int:
	return int((Time.get_ticks_msec() - _start_msec) / 1000.0)

static func _clock(seconds: int) -> String:
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]

static func _synergy_name(syn_id: String) -> String:
	return SynergyManager.SYNERGIES.get(syn_id, {}).get("name", syn_id)

static func _equipped_names() -> Array:
	var names = []
	for slot in GameData.equipment_slots:
		var item = GameData.equipment_slots[slot]
		if item:
			names.append(item.item_name)
	return names

static func _sum(d: Dictionary) -> int:
	var total = 0
	for k in d:
		total += d[k]
	return total

# "Mecha 30, Abeja Mutante 12": de dónde vino el daño, de mayor a menor.
static func _damage_text() -> String:
	var keys = _damage_by_source.keys()
	keys.sort_custom(func(a, b): return _damage_by_source[a] > _damage_by_source[b])
	return ", ".join(keys.map(func(k): return "%s %d" % [k, _damage_by_source[k]]))

static func _health_text(player: Node) -> String:
	if not player or player.get("stats") == null: return ""
	return "%d/%d" % [player.stats.current_health, player.stats.max_health]

# Si la run terminó en la sala del jefe: cuánta vida le quedaba (en %).
static func _boss_health_text(scene: Node) -> String:
	if not scene or _room_label() != "Jefe": return ""
	for n in scene.find_children("*", "", true, false):
		var script = n.get_script()
		if n is Node2D and script and script.resource_path.get_file().begins_with("boss") and n.get("max_health"):
			var hp = maxf(float(n.get("current_health")), 0.0)
			return "%d%%" % roundi(hp / float(n.max_health) * 100.0)
	return ""

static func _next_player_number() -> int:
	var cfg = ConfigFile.new()
	cfg.load(CONFIG)
	var n = int(cfg.get_value("registro", "jugadores", 0)) + 1
	cfg.set_value("registro", "jugadores", n)
	cfg.save(CONFIG)
	return n

static func _archived_name(tag: String) -> String:
	var stamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	return FILE_NAME.get_basename() + tag + "_" + stamp + ".csv"

# Sin separadores ni saltos de línea dentro de una celda.
static func _clean(value) -> String:
	return str(value).replace(SEP, ",").replace("\n", " ").replace("\r", " ")

static func _append(path: String, line: String) -> void:
	# si el archivo es de una versión con otras columnas, se guarda aparte y se empieza uno nuevo
	if FileAccess.file_exists(path):
		var old = FileAccess.open(path, FileAccess.READ)
		var header = old.get_line().trim_prefix("﻿") if old else ""
		old = null
		if header != SEP.join(COLUMNS):
			DirAccess.rename_absolute(path, path.get_base_dir().path_join(_archived_name("_viejo")))
	var is_new = not FileAccess.file_exists(path)
	var f = FileAccess.open(path, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if not f: return
	if is_new:
		f.store_string("﻿" + SEP.join(COLUMNS) + "\n") # BOM: Excel lee bien los acentos
	f.seek_end()
	f.store_string(line + "\n")
	f.close()
