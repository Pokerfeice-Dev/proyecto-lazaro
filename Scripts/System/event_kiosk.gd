extends CanvasLayer
class_name EventKiosk

## Modo stand del evento (solo en el build "Buenos Aires Game Dev"):
## si nadie toca el teclado, el mouse ni el joystick por un rato, avisa arriba
## con una cuenta regresiva de 5 segundos y vuelve al menú principal para el
## próximo jugador. El aviso no frena el juego ni toma el foco: cualquier
## botón lo cancela.
## También registra la run como "cerrado" si se cierra la ventana a mitad de run.
## GameData lo crea al arrancar: EventKiosk.install(self)

const MAIN_MENU := "res://Scenes/UI/MainMenu.tscn"
## Segundos sin tocar nada antes de que aparezca la cuenta regresiva.
const IDLE_SECONDS := 75.0
## En las pantallas del final (QR) se da más tiempo: la gente escanea con el celular.
const IDLE_SECONDS_OUTRO := 150.0
const COUNTDOWN := 5.0
const STICK_DEADZONE := 0.35
## Escenas donde no hace falta reiniciar (ya es el inicio).
const IDLE_FREE_SCENES := ["MainMenu", "IntroCinematic"]

var _idle := 0.0
var _toast: PanelContainer
var _count_label: Label
var _resetting := false

static func install(parent: Node) -> EventKiosk:
	var kiosk = EventKiosk.new()
	kiosk.name = "EventKiosk"
	parent.add_child.call_deferred(kiosk)
	return kiosk

func _init() -> void:
	layer = 250
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_build_toast()

func _input(event: InputEvent) -> void:
	if _is_activity(event):
		_idle = 0.0
		if _toast.visible:
			_hide_toast()

func _process(delta: float) -> void:
	if _resetting or not _idle_matters():
		_idle = 0.0
		if _toast.visible: _hide_toast()
		return
	_idle += delta
	var limit = IDLE_SECONDS_OUTRO if EventOutro.is_showing() else IDLE_SECONDS
	var left = limit + COUNTDOWN - _idle
	if left <= COUNTDOWN:
		_show_toast(ceili(left))
	if left <= 0.0:
		_reset_to_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		RunLog.finish("cerrado")

# --- Actividad ---

func _is_activity(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.is_pressed()
	if event is InputEventJoypadMotion:
		return absf(event.axis_value) > STICK_DEADZONE
	if event is InputEventMouseMotion:
		return event.relative.length() > 2.0
	return false

func _idle_matters() -> bool:
	var scene = get_tree().current_scene
	return scene != null and not IDLE_FREE_SCENES.has(scene.name)

# --- Volver al menú ---

func _reset_to_menu() -> void:
	_resetting = true
	_hide_toast()
	RunLog.finish("inactividad")
	_close_overlays()
	get_tree().paused = false
	Engine.time_scale = 1.0
	if GameData.is_event_demo():
		GameData.end_event_demo()
	SceneTransition.change_scene(MAIN_MENU)
	await get_tree().create_timer(1.5, true).timeout
	_idle = 0.0
	_resetting = false

# Ventanas que viven en la raíz (popups, pantalla de fin, carteles...) no se
# van solas al cambiar de escena: se cierran a mano. Los autoloads y los nodos
# de sistema (InputMode) quedan.
func _close_overlays() -> void:
	var tree = get_tree()
	for c in tree.root.get_children():
		if c == tree.current_scene or _is_autoload(c) or c is InputMode: continue
		if c is CanvasLayer or c is Control:
			c.queue_free()
	if OptionsMenu.get("is_open") == true:
		OptionsMenu.close()

func _is_autoload(node: Node) -> bool:
	return ProjectSettings.has_setting("autoload/" + node.name)

# --- Aviso ---

func _build_toast() -> void:
	_toast = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.position.y = 24
	_toast.visible = false
	add_child(_toast)
	var m = UIStyle.padded(16)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(m)
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	m.add_child(row)
	_count_label = UIStyle.label("5", 40, UIStyle.COLOR_GOLD)
	_count_label.custom_minimum_size.x = 36
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_count_label)
	var texts = VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	texts.add_child(UIStyle.label("¿SIGUES AHÍ?", 20, UIStyle.COLOR_TEXT))
	texts.add_child(UIStyle.label("Volvemos al menú para el próximo jugador. Toca cualquier botón para seguir.", 15, UIStyle.COLOR_MUTED))
	for c in _toast.find_children("*", "Control", true, false):
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_toast(seconds: int) -> void:
	_count_label.text = str(maxi(seconds, 0))
	if _toast.visible: return
	_toast.visible = true
	_toast.modulate.a = 0.0
	_toast.position.y = 0
	var t = _toast.create_tween().set_parallel(true)
	t.tween_property(_toast, "modulate:a", 1.0, 0.2)
	t.tween_property(_toast, "position:y", 24.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_toast() -> void:
	_toast.visible = false
