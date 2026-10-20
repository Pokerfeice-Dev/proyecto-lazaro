class_name RunLog
extends RefCounted

## Registro de cada run en un CSV, para revisar después del evento cómo jugó la
## gente: cuánto duró, hasta dónde llegó, qué la mató, qué armas eligió y qué
## sinergias armó.
## Se escribe una fila cuando la run termina (muerte, victoria, abandono,
## inactividad o se cerró el juego).
## Archivo: user://registro_runs.csv. En el ejecutable también se copia la fila
## al lado del .exe (registro_runs.csv), así es fácil de encontrar.
## Uso:
##   RunLog.begin()                 al empezar la run
##   RunLog.note_synergy(id)        al activarse una sinergia
##   RunLog.finish("muerte")        al terminar

const FILE_NAME := "registro_runs.csv"
const SEP := ";" # Excel en español separa columnas con punto y coma
const COLUMNS := [
	"fecha", "hora_inicio", "duracion_seg", "duracion", "modo", "resultado",
	"zona", "sala", "escena", "causa", "enemigos", "chatarra",
	"arma_principal", "arma_secundaria", "sinergias", "piezas_equipadas", "control",
]

static var _active := false
static var _start_msec := 0
static var _start_time := ""
static var _synergies: Array[String] = []

static func is_active() -> bool:
	return _active

static func begin() -> void:
	if _active:
		finish("abandonada")
	_active = true
	_start_msec = Time.get_ticks_msec()
	_start_time = Time.get_time_string_from_system()
	_synergies.clear()

static func note_synergy(syn_id: String) -> void:
	if _active and not _synergies.has(syn_id):
		_synergies.append(syn_id)

## resultado: "muerte", "victoria", "abandonada", "inactividad" o "cerrado".
static func finish(result: String) -> void:
	if not _active: return
	_active = false
	var line = SEP.join(_row(result).map(_clean))
	_append("user://" + FILE_NAME, line)
	if not OS.has_feature("editor"):
		_append(OS.get_executable_path().get_base_dir().path_join(FILE_NAME), line)

## Ruta completa del registro principal (para mostrarla o abrir la carpeta).
static func file_path() -> String:
	return ProjectSettings.globalize_path("user://" + FILE_NAME)

# --- Armado de la fila ---

static func _row(result: String) -> Array:
	var seconds = int((Time.get_ticks_msec() - _start_msec) / 1000.0)
	var scene = Engine.get_main_loop().current_scene
	return [
		Time.get_date_string_from_system(), _start_time, seconds,
		"%d:%02d" % [seconds / 60, seconds % 60],
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
	]

# "Sala 4" o "Jefe" (cuando ya pasó todas las salas de la zona).
static func _room_label() -> String:
	if GameData.current_run_room > GameData.rooms_before_boss:
		return "Jefe"
	return "Sala %d" % GameData.current_run_room

static func _synergy_name(syn_id: String) -> String:
	return SynergyManager.SYNERGIES.get(syn_id, {}).get("name", syn_id)

static func _equipped_names() -> Array:
	var names = []
	for slot in GameData.equipment_slots:
		var item = GameData.equipment_slots[slot]
		if item:
			names.append(item.item_name)
	return names

# Sin separadores ni saltos de línea dentro de una celda.
static func _clean(value) -> String:
	return str(value).replace(SEP, ",").replace("\n", " ").replace("\r", " ")

static func _append(path: String, line: String) -> void:
	var is_new = not FileAccess.file_exists(path)
	var f = FileAccess.open(path, FileAccess.READ_WRITE if not is_new else FileAccess.WRITE)
	if not f: return
	if is_new:
		f.store_string("﻿" + SEP.join(COLUMNS) + "\n") # BOM: Excel lee bien los acentos
	f.seek_end()
	f.store_string(line + "\n")
	f.close()
