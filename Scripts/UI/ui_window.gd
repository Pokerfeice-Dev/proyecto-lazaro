extends CanvasLayer
class_name UIWindow

## Ventana genérica con el estilo de la UI del juego: pestaña de título con
## ícono, panel principal, cuerpo, divisor y pie con botones y teclas.
## Pausa el juego mientras está abierta (si se pide), ESC (B) cierra y Enter
## (A) presiona el botón principal.
## Uso:
##   var w = UIWindow.open("  O.M.N.I.A.", ICON_INFO)
##   w.body.add_child(...)
##   w.add_button("ENTENDIDO", true, "E", w.close)

signal closed

const OPEN_SOUND := "res://Audio/Sfx/Piano_Ui (2).wav"
const CLOSE_SOUND := "res://Audio/Sfx/UI_cancelar.wav"

var body: VBoxContainer
var footer: HBoxContainer
var _window: VBoxContainer
var _tab: Button
var _primary: Button
var _paused_by_me := false
var _closing := false

static func open(title: String, icon: Texture2D = null, width: float = 600.0, pause := true) -> UIWindow:
	var window = UIWindow.new()
	window._build(title, icon, width)
	Engine.get_main_loop().root.add_child(window)
	if pause and not window.get_tree().paused:
		window.get_tree().paused = true
		window._paused_by_me = true
	return window

func _init() -> void:
	layer = 230
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_play(OPEN_SOUND)
	_animate_in()
	_focus_primary.call_deferred()

# Ventana modal: con joystick el foco arranca en el botón principal y no se
# va a lo de atrás. Los botones se agregan después de abrirla, por eso es diferido.
func _focus_primary() -> void:
	PadFocus.push_modal(self, _primary if is_instance_valid(_primary) else null)

func _input(event: InputEvent) -> void:
	if _closing: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_play(CLOSE_SOUND)
		close()
	elif _primary and _is_confirm(event) and not _pad_on_button(event):
		get_viewport().set_input_as_handled()
		_primary.pressed.emit()

# Con joystick, A aprieta el botón enfocado (el que eligió con la cruceta).
func _pad_on_button(event: InputEvent) -> bool:
	return event is InputEventJoypadButton and get_viewport().gui_get_focus_owner() is BaseButton

# Enter, E o el botón A del joystick.
func _is_confirm(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E

## Botón del pie. "key" muestra la tecla al lado (por ejemplo "E" o "ESC").
## El primer botón principal también se activa con Enter o E.
func add_button(text: String, primary: bool, key: String, callback: Callable) -> Button:
	var spacer_needed = footer.get_child_count() == 0 and primary
	if spacer_needed:
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer.add_child(spacer)
	if key != "":
		# el principal se confirma con A en el joystick; el resto según la tecla
		footer.add_child(UIStyle.keycap(key, "A" if primary and not _primary else ""))
	var btn = UIStyle.button(text, primary, Vector2(0, 46), 18)
	btn.custom_minimum_size.x = 190
	btn.pressed.connect(callback)
	footer.add_child(btn)
	if primary and not _primary:
		_primary = btn
	return btn

## Espacio que empuja los botones siguientes a la derecha.
func add_footer_spacer() -> void:
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

func close() -> void:
	if _closing: return
	_closing = true
	var t = create_tween().set_parallel(true)
	t.tween_property(_window, "modulate:a", 0.0, 0.15)
	t.tween_property(_window, "scale", Vector2(0.96, 0.96), 0.15)
	t.chain().tween_callback(_finish_close)

func _finish_close() -> void:
	if _paused_by_me and is_inside_tree():
		get_tree().paused = false
	closed.emit()
	queue_free()

# --- Armado ---

func _build(title: String, icon: Texture2D, width: float) -> void:
	var backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0, 0, 0, 0.62)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_window = VBoxContainer.new()
	_window.add_theme_constant_override("separation", 0)
	_window.custom_minimum_size.x = width
	center.add_child(_window)
	_tab = UIStyle.title_tab(title)
	_tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	if icon:
		_tab.icon = icon
		_tab.expand_icon = false
		_tab.add_theme_color_override("icon_normal_color", UIStyle.COLOR_GOLD)
		_tab.add_theme_constant_override("icon_max_width", 22)
	_window.add_child(_tab)
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	_window.add_child(panel)
	var m = UIStyle.padded(26)
	panel.add_child(m)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	m.add_child(col)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	col.add_child(body)
	col.add_child(UIStyle.divider())
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(footer)

func _animate_in() -> void:
	var backdrop = get_node("Backdrop") as ColorRect
	backdrop.modulate.a = 0.0
	_window.modulate.a = 0.0
	backdrop.create_tween().tween_property(backdrop, "modulate:a", 1.0, 0.18)
	await get_tree().process_frame
	_window.pivot_offset = _window.size / 2.0
	_window.scale = Vector2(0.92, 0.92)
	var t = _window.create_tween().set_parallel(true)
	t.tween_property(_window, "modulate:a", 1.0, 0.18)
	t.tween_property(_window, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play(path: String) -> void:
	if not ResourceLoader.exists(path): return
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load(path)
	sfx.bus = "SFX"
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
