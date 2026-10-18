extends Node
class_name PadFocusable

## Botones que con mouse no toman foco (FOCUS_NONE, para que Espacio o Enter
## no los apreten sin querer) pero que con joystick tienen que poder
## recorrerse con la cruceta. Se cuelga del control y le cambia el modo de
## foco según lo que se esté usando.
## Uso: PadFocusable.attach(boton)

var _target: Control
var _keyboard_mode: Control.FocusMode

static func attach(control: Control) -> void:
	if control.has_node("PadFocusable"): return
	var f = PadFocusable.new()
	f.name = "PadFocusable"
	f._target = control
	f._keyboard_mode = control.focus_mode
	control.add_child(f)

func _ready() -> void:
	InputMode.instance().mode_changed.connect(_apply)
	_apply(InputMode.is_gamepad())

func _apply(gamepad: bool) -> void:
	if not is_instance_valid(_target): return
	# los botones deshabilitados (armas bloqueadas, etc.) se saltan
	var skip = _target is BaseButton and _target.disabled
	_target.focus_mode = Control.FOCUS_ALL if gamepad and not skip else _keyboard_mode
	if not gamepad and _target.has_focus():
		_target.release_focus()
