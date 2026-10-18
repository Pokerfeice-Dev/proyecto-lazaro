extends Node
class_name KeycapSwitch

## Cambia lo que se muestra según se juegue con teclado/mouse o con joystick.
## - attach(tecla, label, "A"): la tecla dibujada (UIStyle.keycap) pasa a ser
##   el botón del joystick (pad_text vacío = el que corresponda a la tecla;
##   si no tiene equivalente, queda la tecla).
## - swap_icon(icono, "A"): un ícono (por ejemplo el del mouse) se cambia por
##   el botón, en el mismo lugar.
## - swap(con_teclado, con_joystick): muestra uno u otro (cualquiera puede ser null).
## - only_on_pad(control): el control solo se ve con joystick.
## - add_tab_hints(fila): LB / RB a los costados de una fila de pestañas.

var _cap: Control
var _kb_node: Control
var _glyph: Control
var _key_style: StyleBox

static func attach(cap: PanelContainer, label: Label, pad_text: String = "") -> void:
	var pad = pad_text if pad_text != "" else InputMode.pad_label(label.text)
	if pad == label.text: return # sin equivalente: queda la tecla
	var glyph = PadGlyph.create(pad, cap.custom_minimum_size.y)
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cap.add_child(glyph)
	_make(cap, label, glyph, cap.get_theme_stylebox("panel"))

static func swap_icon(icon: Control, pad_text: String) -> PadGlyph:
	var glyph = PadGlyph.create(pad_text, maxf(icon.custom_minimum_size.y, 26.0))
	icon.add_sibling(glyph)
	swap(icon, glyph)
	return glyph

static func swap(kb_node: Control, pad_node: Control) -> void:
	_make(kb_node if kb_node else pad_node, kb_node, pad_node, null)

static func only_on_pad(control: Control) -> void:
	swap(null, control)

## LB al principio y RB al final de una fila de pestañas (solo con joystick).
## Para las categorías del códice se usan LT / RT.
static func add_tab_hints(bar: Control, glyph_size: float = 36.0, left: String = "LB", right: String = "RB") -> void:
	var lb = PadGlyph.create(left, glyph_size)
	bar.add_child(lb)
	bar.move_child(lb, 0)
	only_on_pad(lb)
	var rb = PadGlyph.create(right, glyph_size)
	bar.add_child(rb)
	only_on_pad(rb)

static func _make(holder: Control, kb_node: Control, glyph: Control, style: StyleBox) -> void:
	var sw = KeycapSwitch.new()
	sw.name = "KeycapSwitch"
	sw._cap = holder if style else null
	sw._kb_node = kb_node
	sw._glyph = glyph
	sw._key_style = style
	holder.add_child(sw)

func _ready() -> void:
	InputMode.instance().mode_changed.connect(_apply)
	_apply(InputMode.is_gamepad())

func _apply(gamepad: bool) -> void:
	if is_instance_valid(_kb_node):
		_kb_node.visible = not gamepad
	if not is_instance_valid(_glyph): return
	_glyph.visible = gamepad
	if not _cap or not _glyph is PadGlyph: return
	# acompaña el tamaño de la tecla (hay teclas agrandadas después de crearlas)
	var h = maxf(_cap.custom_minimum_size.y, 24.0)
	_glyph.custom_minimum_size = Vector2(h * PadGlyph.aspect(_glyph.button), h)
	_cap.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if gamepad else _key_style)
