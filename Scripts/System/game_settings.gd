extends Node
class_name FxSettings

# Opciones del juego (Video, Audio, Efectos, Juego). Autoload "GameSettings".
# Se guardan en user://opciones.cfg y se aplican al arrancar el juego.
#
# Para sumar una opcion nueva:
#   1. agregar la clave con su valor por defecto en DEFAULTS (en la seccion que corresponda)
#   2. agregar la fila en ROWS de options_screen.gd (texto, descripcion, tipo de control)
#   3. donde se use, preguntar con FxSettings.on("clave") (devuelve true/false)
#      o escuchar GameSettings.setting_changed si tiene que reaccionar en vivo.

signal setting_changed(section: String, key: String, value: Variant)

const SETTINGS_PATH := "user://opciones.cfg"
const WINDOWED_SIZE := Vector2i(1600, 900)

const DEFAULTS := {
	"video": {
		"modo_pantalla": 0,      # 0 pantalla completa, 1 ventana, 2 ventana sin bordes
		"vsync": true,
		"fps_max": 0,            # 0 = sin limite
		"mostrar_fps": false,
	},
	"audio": {
		"general": 100.0,
		"music": 100.0,
		"sfx": 100.0,
		"silenciar_sin_foco": false,
	},
	"fx": {
		"polvo_ambiente": true,
		"luces_parpadeantes": true,
		"vineta": true,
		"sombras": true,
		"polvo_pasos": true,
		"sacudida_camara": true,
		"animacion_salas": true,
		"particulas_menu": true,
		"fondo_animado_menu": true,
	},
	"juego": {
		"brujula_enemigos": true,
		"indicador_danio": true,
	},
}

var _values: Dictionary = {}
var _save_pending: bool = false
var _fps_layer: CanvasLayer = null
var _fps_label: Label = null
var _fps_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_apply_all()

# ---- acceso desde cualquier script ----

# FxSettings.on("sombras") -> si la opcion esta activada. Si no hay autoload (editor) devuelve true.
static func on(key: String) -> bool:
	var gs = instance()
	if not gs: return true
	return bool(gs.get_flag(key))

static func instance() -> Node:
	var loop = Engine.get_main_loop()
	if not (loop is SceneTree): return null
	return (loop as SceneTree).root.get_node_or_null("GameSettings")

func get_flag(key: String) -> Variant:
	for section in _values:
		if _values[section].has(key):
			return _values[section][key]
	return true

func get_value(section: String, key: String) -> Variant:
	if _values.has(section) and _values[section].has(key):
		return _values[section][key]
	return DEFAULTS.get(section, {}).get(key)

func set_value(section: String, key: String, value: Variant) -> void:
	if not _values.has(section): return
	_values[section][key] = value
	_apply(key, value)
	_queue_save()
	setting_changed.emit(section, key, value)

func reset_section(section: String) -> void:
	if not DEFAULTS.has(section): return
	for key in DEFAULTS[section]:
		set_value(section, key, DEFAULTS[section][key])

# ---- guardar / cargar ----

func _load_settings() -> void:
	_values = DEFAULTS.duplicate(true)
	var cfg = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK: return
	for section in DEFAULTS:
		for key in DEFAULTS[section]:
			_values[section][key] = cfg.get_value(section, key, DEFAULTS[section][key])

# guardado diferido: mover un slider no escribe el archivo 60 veces por segundo
func _queue_save() -> void:
	if _save_pending: return
	_save_pending = true
	get_tree().create_timer(0.4, true).timeout.connect(_save_settings)

func _save_settings() -> void:
	_save_pending = false
	var cfg = ConfigFile.new()
	cfg.load(SETTINGS_PATH) # conserva otras claves que pueda haber
	for section in _values:
		for key in _values[section]:
			cfg.set_value(section, key, _values[section][key])
	cfg.save(SETTINGS_PATH)

# ---- aplicar ----

func _apply_all() -> void:
	for section in _values:
		for key in _values[section]:
			_apply(key, _values[section][key])

func _apply(key: String, value: Variant) -> void:
	match key:
		"modo_pantalla": _apply_window_mode(int(value))
		"vsync": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED)
		"fps_max": Engine.max_fps = int(value)
		"mostrar_fps": _set_fps_visible(bool(value))
		"general": _apply_bus_volume("Master", float(value))
		"music": _apply_bus_volume("Music", float(value))
		"sfx": _apply_bus_volume("SFX", float(value))
		"polvo_ambiente": _apply_ambient_dust(bool(value))
		"luces_parpadeantes": _apply_flicker(bool(value))
		"vineta": _apply_vignette(bool(value))
		"sombras": _set_group_visible("drop_shadows", bool(value))
		"brujula_enemigos": _set_group_visible("enemy_compass", bool(value))

# El proyecto arranca en ventana (1600x900, Project Settings) y desde aca se pasa a pantalla
# completa. Si arrancara en pantalla completa, Windows guardaria el tamaño de la pantalla
# como "tamaño de ventana" y al volver a modo ventana la dejaba en pantalla completa exclusiva.
func _apply_window_mode(mode: int) -> void:
	if mode == 0:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, mode == 2)
	# al salir de pantalla completa Windows tarda un par de cuadros en soltar la ventana;
	# si se le cambia el tamaño en ese mismo cuadro lo ignora
	await get_tree().process_frame
	await get_tree().process_frame
	if int(get_value("video", "modo_pantalla")) != mode: return # se cambio de nuevo mientras tanto
	_resize_window(mode)

func _resize_window(mode: int) -> void:
	var screen = DisplayServer.window_get_current_screen()
	if mode == 2:
		DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
		DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
		return
	DisplayServer.window_set_size(WINDOWED_SIZE)
	_center_window()

func _center_window() -> void:
	var screen = DisplayServer.window_get_current_screen()
	var screen_pos = DisplayServer.screen_get_position(screen)
	var screen_size = DisplayServer.screen_get_size(screen)
	DisplayServer.window_set_position(screen_pos + Vector2i(Vector2(screen_size - WINDOWED_SIZE) * 0.5))

# misma curva que el menu de pausa: el 50% suena realmente a la mitad
func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	if value <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		return
	AudioServer.set_bus_mute(bus_index, false)
	var t = value / 100.0
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(t * t))

func _apply_ambient_dust(enabled: bool) -> void:
	AmbientDust.is_globally_enabled = enabled
	if not enabled: # al activarlo vuelve en la proxima sala (se configura al crearse)
		AmbientDust._update_all_dust_nodes_in_tree(get_tree(), false)

func _apply_flicker(enabled: bool) -> void:
	FlickeringLight.is_globally_enabled = enabled
	FlickeringLight._update_all_lights_in_tree(get_tree(), enabled)

func _apply_vignette(enabled: bool) -> void:
	CinematicVignette.is_globally_enabled = enabled
	CinematicVignette._update_all_vignettes_in_tree(get_tree(), enabled)

func _set_group_visible(group: String, enabled: bool) -> void:
	for node in get_tree().get_nodes_in_group(group):
		if node is CanvasItem:
			node.visible = enabled

# ---- contador de FPS ----

func _set_fps_visible(enabled: bool) -> void:
	if enabled and not _fps_layer:
		_create_fps_label()
	if _fps_layer:
		_fps_layer.visible = enabled

func _create_fps_label() -> void:
	_fps_layer = CanvasLayer.new()
	_fps_layer.layer = 128
	add_child(_fps_layer)
	_fps_label = Label.new()
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.position = Vector2(-150, 12)
	_fps_label.size = Vector2(138, 30)
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.add_theme_font_size_override("font_size", 20)
	_fps_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.9))
	_fps_label.add_theme_constant_override("outline_size", 6)
	_fps_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_fps_layer.add_child(_fps_label)

func _process(delta: float) -> void:
	if not _fps_layer or not _fps_layer.visible: return
	_fps_timer -= delta
	if _fps_timer > 0.0: return
	_fps_timer = 0.5
	_fps_label.text = "%d FPS" % Engine.get_frames_per_second()

# ---- silenciar cuando la ventana pierde el foco ----

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and get_value("audio", "silenciar_sin_foco"):
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, float(get_value("audio", "general")) <= 0.0)
