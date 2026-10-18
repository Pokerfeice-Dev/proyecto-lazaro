extends Node
class_name InputMode

## Soporte de joystick (pensado para uno de Xbox). Se usa con funciones
## estáticas (InputMode.is_gamepad(), etc.); la primera llamada crea un nodo
## en la raíz que escucha el input, así no hace falta registrar un autoload.
## - Agrega los botones del joystick a las acciones del juego al arrancar.
## - Detecta solo qué se está usando: apenas tocas un botón o mueves un
##   analógico pasa a modo joystick; con teclado o mouse vuelve a teclado.
##   Avisa con la señal mode_changed para que la UI cambie teclas por botones.
## - Apuntado con el analógico derecho (con una ayuda suave hacia el enemigo
##   más alineado) para el jugador.
##
## Controles (Xbox):
##   Analógico izq: moverse · Analógico der: apuntar · RT: disparar · LT: melee
##   A: dash · X: interactuar · Y o Select (View): inventario · Start (Menu): pausa
##   En menús: analógico o cruceta para moverse, A aceptar, B volver,
##   LB / RB cambiar de pestaña, LT / RT cambiar de categoría (códice),
##   X equipar o desequipar, clic del analógico der. comparar,
##   analógico der. desplazar listas.

signal mode_changed(gamepad: bool)

const STICK_DEADZONE := 0.25
const AIM_DEADZONE := 0.3
const SWITCH_THRESHOLD := 0.45
const MOUSE_SWITCH_DISTANCE := 6.0
const AIM_DISTANCE := 140.0
const AIM_ASSIST_ANGLE := deg_to_rad(16.0)
const AIM_ASSIST_RANGE := 520.0
const TRIGGER_ON := 0.6 # gatillo apretado (en menús)
const TRIGGER_OFF := 0.3 # gatillo suelto: más bajo que ON para que no rebote

static var _node: InputMode

var gamepad := false
var aim_dir := Vector2.RIGHT
var _has_aimed := false
var _trigger_down := {} # eje del gatillo -> apretado
var _memo_event: InputEvent
var _memo_tap := false

## Etiqueta de botón por tecla de teclado (lo que muestran los carteles).
const PAD_FOR_KEY := {
	"E": "X", "ESC": "B", "ESCAPE": "B", "ENTER": "A", "INTRO": "A",
	"I": "Y", "ESPACIO": "A", "SPACE": "A", "SHIFT": "X", "TAB": "Y",
	"MOUSE_L": "RT", "MOUSE_R": "LT", "Q": "LB", "R": "RB",
	"W": "LS", "A": "LS", "S": "LS", "D": "LS", "P": "START",
	"MOUSE": "A",
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_gamepad()
	add_child(PadFocus.new()) # marco de foco y navegación de menús
	add_child(PadCrosshair.new()) # mira donde apunta el analógico derecho

## Nodo único (lo crea la primera vez). Para escuchar mode_changed.
static func instance() -> InputMode:
	if not is_instance_valid(_node):
		_node = InputMode.new()
		_node.name = "InputMode"
		var tree = Engine.get_main_loop() as SceneTree
		tree.root.add_child.call_deferred(_node)
	return _node

static func is_gamepad() -> bool:
	return instance().gamepad

## Tecla E o botón X: interactuar (puertas, cofres, carteles, NPC, objetos).
static func is_interact(event: InputEvent) -> bool:
	instance()
	return event.is_action_pressed("interact") and not event.is_echo()

## Texto del botón que corresponde a una tecla (para los carteles).
static func pad_label(key_text: String) -> String:
	return PAD_FOR_KEY.get(key_text.to_upper(), key_text)

## Gatillo LT/RT recién apretado: true una sola vez por pulsación (los
## gatillos son analógicos y mandan muchos eventos mientras se aprietan).
## Para los menús; jugando, disparar sigue usando la acción normal.
static func trigger_tap(event: InputEvent) -> bool:
	return instance()._trigger_tap(event)

func _trigger_tap(event: InputEvent) -> bool:
	if not event is InputEventJoypadMotion: return false
	if event.axis != JOY_AXIS_TRIGGER_LEFT and event.axis != JOY_AXIS_TRIGGER_RIGHT: return false
	if event == _memo_event: return _memo_tap # mismo evento leído por varios menús
	var was = _trigger_down.get(event.axis, false)
	var down = event.axis_value > (TRIGGER_OFF if was else TRIGGER_ON)
	_trigger_down[event.axis] = down
	_memo_event = event
	_memo_tap = down and not was
	return _memo_tap

# --- Detección automática ---

func _input(event: InputEvent) -> void:
	_trigger_tap(event) # mantiene al día el estado de los gatillos aunque ningún menú lo pida
	if event is InputEventJoypadButton and event.pressed:
		_set_gamepad(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > SWITCH_THRESHOLD:
		_set_gamepad(true)
	elif event is InputEventKey and event.pressed:
		_set_gamepad(false)
	elif event is InputEventMouseButton and event.pressed:
		_set_gamepad(false)
	elif event is InputEventMouseMotion and event.relative.length() > MOUSE_SWITCH_DISTANCE:
		_set_gamepad(false)

func _set_gamepad(on: bool) -> void:
	if gamepad == on: return
	gamepad = on
	mode_changed.emit(on)

# --- Apuntado ---

func _process(_delta: float) -> void:
	if not gamepad: return
	var stick = Vector2(Input.get_joy_axis(_pad(), JOY_AXIS_RIGHT_X), Input.get_joy_axis(_pad(), JOY_AXIS_RIGHT_Y))
	if stick.length() > AIM_DEADZONE:
		aim_dir = stick.normalized()
		_has_aimed = true

## Punto al que apunta el jugador con el joystick.
static func aim_point(from: Vector2, move_dir: Vector2 = Vector2.ZERO) -> Vector2:
	return instance()._aim_point(from, move_dir)

func _aim_point(from: Vector2, move_dir: Vector2) -> Vector2:
	var dir = aim_dir
	if not _has_aimed and move_dir.length() > 0.1:
		dir = move_dir.normalized()
	var target = _assist_target(from, dir)
	if target:
		return target.global_position
	return from + dir * AIM_DISTANCE

# Ayuda suave: si hay un enemigo casi en la línea del analógico, apunta a él.
# Se puede apagar en Opciones > Juego > Asistencia de apuntado.
func _assist_target(from: Vector2, dir: Vector2) -> Node2D:
	if not FxSettings.on("asistencia_apuntado"): return null
	var best: Node2D = null
	var best_angle := AIM_ASSIST_ANGLE
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy is Node2D: continue
		if enemy.get("is_dying") == true: continue
		var to = enemy.global_position - from
		if to.length() > AIM_ASSIST_RANGE or to.length() < 1.0: continue
		var angle = absf(dir.angle_to(to))
		if angle < best_angle:
			best_angle = angle
			best = enemy
	return best

func _pad() -> int:
	var pads = Input.get_connected_joypads()
	return pads[0] if not pads.is_empty() else 0

# --- Botones en las acciones ---

func _bind_gamepad() -> void:
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		if InputMap.has_action(action):
			InputMap.action_set_deadzone(action, STICK_DEADZONE)
	_axis("shoot", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_axis("attack_melee", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_button("dash", JOY_BUTTON_A)
	_button("interact", JOY_BUTTON_X)
	_button("toggle_inventory", JOY_BUTTON_Y)
	_button("toggle_inventory", JOY_BUTTON_BACK)
	_button("pause", JOY_BUTTON_START)
	# menús (por si el proyecto no trae los botones por defecto)
	_button("ui_accept", JOY_BUTTON_A)
	_button("ui_cancel", JOY_BUTTON_B)
	_button("ui_up", JOY_BUTTON_DPAD_UP)
	_button("ui_down", JOY_BUTTON_DPAD_DOWN)
	_button("ui_left", JOY_BUTTON_DPAD_LEFT)
	_button("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_axis("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("ui_down", JOY_AXIS_LEFT_Y, 1.0)
	_axis("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_action("ui_tab_prev")
	_ensure_action("ui_tab_next")
	_button("ui_tab_prev", JOY_BUTTON_LEFT_SHOULDER)
	_button("ui_tab_next", JOY_BUTTON_RIGHT_SHOULDER)
	_ensure_action("ui_equip")
	_button("ui_equip", JOY_BUTTON_X)
	_ensure_action("ui_compare")
	_button("ui_compare", JOY_BUTTON_RIGHT_STICK)
	_ensure_action("ui_page_prev")
	_ensure_action("ui_page_next")
	_axis("ui_page_prev", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_axis("ui_page_next", JOY_AXIS_TRIGGER_RIGHT, 1.0)

func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)

func _button(action: String, button: JoyButton) -> void:
	_ensure_action(action)
	var ev = InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1
	_add_event(action, ev)

func _axis(action: String, axis: JoyAxis, value: float) -> void:
	_ensure_action(action)
	var ev = InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	ev.device = -1
	_add_event(action, ev)

# No repite un botón que la acción ya tenga.
func _add_event(action: String, ev: InputEvent) -> void:
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)
