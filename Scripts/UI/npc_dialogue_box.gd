extends CanvasLayer
class_name NpcDialogueBox

## Cuadro de diálogo inferior de los NPC (el de Ygor): nombre con rombo, rol,
## texto que se escribe solo y pie "E Siguiente" (X con joystick). Opcionalmente muestra el
## retrato del NPC a la izquierda. Se cierra solo después de unos segundos.
## Uso:
##   _box = NpcDialogueBox.create(self, "YGOR", "Mercader de Prótesis y Órganos", color, retrato)
##   _box.say("Hola")

signal closed

const FONT := preload("res://Art/Fonts/Dekatron-SemiBold.otf")
const AUTO_CLOSE := 4.5

var speaker: String
var role: String
var accent: Color = Color(0.25, 0.85, 1.0)
var portrait: Texture2D
var active := false
var _panel: PanelContainer
var _text: Label
var _typewriter: Tween
var _auto_close: Tween

static func create(owner_node: Node, p_speaker: String, p_role: String, p_accent: Color, p_portrait: Texture2D = null) -> NpcDialogueBox:
	var box = NpcDialogueBox.new()
	box.speaker = p_speaker
	box.role = p_role
	box.accent = p_accent
	box.portrait = p_portrait
	owner_node.add_child(box)
	return box

func _ready() -> void:
	layer = 110
	_build()

## Muestra una línea (con efecto de máquina de escribir) y reinicia el cierre automático.
func say(line: String) -> void:
	active = true
	_cancel_tweens()
	_panel.visible = true
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_text.text = line
	_text.visible_ratio = 0.0
	_typewriter = create_tween()
	_typewriter.tween_property(_text, "visible_ratio", 1.0, clampf(line.length() * 0.02, 0.4, 1.4))
	_auto_close = create_tween()
	_auto_close.tween_interval(AUTO_CLOSE + line.length() * 0.02)
	_auto_close.tween_callback(close)

func close() -> void:
	if not active: return
	active = false
	_cancel_tweens()
	var t = create_tween()
	t.tween_property(_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_finish_close)

func _finish_close() -> void:
	if is_instance_valid(_panel):
		_panel.visible = false
	closed.emit()

func _cancel_tweens() -> void:
	for tw in [_typewriter, _auto_close]:
		if tw and tw.is_valid(): tw.kill()

# --- Armado (mismo diseño que tenía Ygor) ---

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 180
	_panel.offset_right = -180
	_panel.offset_bottom = -30
	_panel.offset_top = -180
	_panel.modulate.a = 0.0
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _style())
	add_child(_panel)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	_panel.add_child(row)
	if portrait:
		row.add_child(_portrait())
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(vbox)
	vbox.add_child(_header())
	_text = _label("", 20, Color(0.95, 0.95, 0.95))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text)
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 8)
	var key = UIStyle.keycap("E") # con joystick muestra la X
	footer.add_child(key)
	footer.add_child(_label("Siguiente", 14, Color(accent, 0.75)))
	vbox.add_child(footer)

func _style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.95)
	sb.border_color = Color(accent, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb

func _header() -> Control:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.add_child(_label("◆ " + speaker, 20, accent))
	if role != "":
		header.add_child(_label("|  " + role, 14, Color(0.6, 0.7, 0.8, 0.7)))
	return header

# Retrato en un marco de slot, como en el inventario.
func _portrait() -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped"])
	frame.custom_minimum_size = Vector2(104, 104)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pic = UIStyle.icon(portrait, 88)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	frame.add_child(pic)
	return frame

func _label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
