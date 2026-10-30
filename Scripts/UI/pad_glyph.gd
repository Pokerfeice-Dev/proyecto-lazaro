extends Control
class_name PadGlyph

## Botón de joystick (Xbox) dibujado a mano, para mostrar en la UI en lugar de
## la tecla cuando se juega con joystick.
## Botones: A B X Y (círculos de color), LB RB (bumpers), LT RT (gatillos),
## START (menú), BACK (vista), LS RS (analógicos) y DPAD (cruceta).
## Uso:  PadGlyph.create("A", 32)  o  PadGlyph.draw_button(canvas, rect, "RT", presionado)

const FACE_COLORS := {
	"A": Color("#6DBE45"), "B": Color("#E5484D"),
	"X": Color("#3E8EDE"), "Y": Color("#F2C230"),
}
const BODY := Color("#1B262B")
const BODY_PRESSED := Color("#3E6A68")
const OUTLINE := Color("#D9E4E4")

var button := "A"
var pressed := 0.0

static func create(p_button: String, glyph_size: float = 32.0) -> PadGlyph:
	var g = PadGlyph.new()
	g.button = p_button
	g.custom_minimum_size = Vector2(glyph_size, glyph_size) * Vector2(aspect(p_button), 1.0)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return g

## Proporción ancho/alto que conviene para cada botón.
static func aspect(p_button: String) -> float:
	match p_button:
		"LB", "RB", "START", "BACK": return 1.5
	return 1.0

func _process(_delta: float) -> void:
	if button == "LS" or button == "RS":
		queue_redraw() # el analógico se mueve un poquito

func _draw() -> void:
	draw_button(self, Rect2(Vector2.ZERO, size), button, pressed)

## Dibuja el botón dentro de rect. pressed (0..1) lo hunde y aclara.
static func draw_button(ci: CanvasItem, rect: Rect2, p_button: String, p_pressed: float = 0.0) -> void:
	var font = (ci as Control).get_theme_default_font() if ci is Control else ThemeDB.fallback_font
	match p_button:
		"A", "B", "X", "Y": _draw_face(ci, rect, p_button, p_pressed, font)
		"LB", "RB": _draw_bumper(ci, rect, p_button, p_pressed, font)
		"LT", "RT": _draw_trigger(ci, rect, p_button, p_pressed, font)
		"START": _draw_menu(ci, rect, p_pressed, true)
		"BACK": _draw_menu(ci, rect, p_pressed, false)
		"LS", "RS": _draw_stick(ci, rect, p_button, p_pressed, font)
		"DPAD": _draw_dpad(ci, rect, p_pressed)
		"DPAD_UP": _draw_dpad(ci, rect, p_pressed, true) # cruceta con la flecha de arriba marcada
		_: _draw_bumper(ci, rect, p_button, p_pressed, font)

# Botón redondo de color con la letra.
static func _draw_face(ci: CanvasItem, rect: Rect2, letter: String, p: float, font: Font) -> void:
	var r = minf(rect.size.x, rect.size.y) / 2.0
	var c = rect.get_center()
	var col = FACE_COLORS[letter]
	ci.draw_circle(c + Vector2(0, r * 0.12), r * 0.96, Color(0, 0, 0, 0.45))
	var face_c = c + Vector2(0, r * 0.1 * p)
	ci.draw_circle(face_c, r * 0.92, BODY.lerp(BODY_PRESSED, p))
	ci.draw_arc(face_c, r * 0.86, 0.0, TAU, 32, col.lightened(0.25 * p), maxf(2.0, r * 0.14), true)
	_center_text(ci, font, letter, face_c, int(r * 1.05), col.lightened(0.2 + 0.3 * p))

# Bumper: pastilla con esquinas redondeadas y "LB"/"RB".
static func _draw_bumper(ci: CanvasItem, rect: Rect2, text: String, p: float, font: Font) -> void:
	var box = _box(rect, p)
	box.set_corner_radius_all(int(rect.size.y * 0.35))
	ci.draw_style_box(box, rect.grow(-rect.size.y * 0.08))
	_center_text(ci, font, text, rect.get_center(), int(rect.size.y * 0.42), OUTLINE)

# Gatillo: forma de gatillo (más alto arriba) con "LT"/"RT".
static func _draw_trigger(ci: CanvasItem, rect: Rect2, text: String, p: float, font: Font) -> void:
	var box = _box(rect, p)
	var rad = int(rect.size.x * 0.4)
	box.corner_radius_top_left = rad
	box.corner_radius_top_right = rad
	box.corner_radius_bottom_left = int(rad * 0.3)
	box.corner_radius_bottom_right = int(rad * 0.3)
	var inner = Rect2(rect.position + Vector2(rect.size.x * 0.12, rect.size.y * (0.04 + 0.08 * p)), Vector2(rect.size.x * 0.76, rect.size.y * 0.9))
	ci.draw_style_box(box, inner)
	_center_text(ci, font, text, inner.get_center() + Vector2(0, rect.size.y * 0.05), int(rect.size.y * 0.36), OUTLINE)

# START (tres rayitas) o BACK (dos cuadraditos), como en el joystick de Xbox.
static func _draw_menu(ci: CanvasItem, rect: Rect2, p: float, start: bool) -> void:
	var box = _box(rect, p)
	box.set_corner_radius_all(int(rect.size.y * 0.5))
	ci.draw_style_box(box, rect.grow(-rect.size.y * 0.08))
	var c = rect.get_center()
	var u = rect.size.y * 0.13
	if start:
		for i in 3:
			var y = c.y + (i - 1) * u * 1.4
			ci.draw_line(Vector2(c.x - u * 1.7, y), Vector2(c.x + u * 1.7, y), OUTLINE, maxf(1.5, u * 0.55))
	else:
		ci.draw_rect(Rect2(c + Vector2(-u * 1.6, -u * 1.4), Vector2(u * 2.0, u * 2.0)), OUTLINE, false, maxf(1.5, u * 0.45))
		ci.draw_rect(Rect2(c + Vector2(-u * 0.5, -u * 0.4), Vector2(u * 2.0, u * 2.0)), OUTLINE, true)

# Analógico: círculo con anillo y la letra adentro.
static func _draw_stick(ci: CanvasItem, rect: Rect2, text: String, p: float, font: Font) -> void:
	var r = minf(rect.size.x, rect.size.y) / 2.0
	var c = rect.get_center()
	ci.draw_circle(c, r * 0.96, Color(0, 0, 0, 0.45))
	ci.draw_circle(c, r * 0.9, BODY)
	var top = c + Vector2(sin(Time.get_ticks_msec() * 0.004) * r * 0.12 * (1.0 - p), 0)
	ci.draw_circle(top, r * 0.62, BODY.lerp(BODY_PRESSED, 0.5 + 0.5 * p))
	ci.draw_arc(top, r * 0.62, 0.0, TAU, 28, OUTLINE, maxf(1.5, r * 0.08), true)
	ci.draw_arc(c, r * 0.9, 0.0, TAU, 32, Color(OUTLINE, 0.55), maxf(1.5, r * 0.06), true)
	_center_text(ci, font, text, top, int(r * 0.62), OUTLINE)

# Cruceta.
static func _draw_dpad(ci: CanvasItem, rect: Rect2, p: float, up_only := false) -> void:
	var s = minf(rect.size.x, rect.size.y)
	var c = rect.get_center()
	var w = s * 0.32
	var col = BODY.lerp(BODY_PRESSED, p)
	ci.draw_rect(Rect2(c - Vector2(w / 2.0, s * 0.45), Vector2(w, s * 0.9)), col)
	ci.draw_rect(Rect2(c - Vector2(s * 0.45, w / 2.0), Vector2(s * 0.9, w)), col)
	ci.draw_rect(Rect2(c - Vector2(w / 2.0, s * 0.45), Vector2(w, s * 0.9)), OUTLINE, false, 1.5)
	ci.draw_rect(Rect2(c - Vector2(s * 0.45, w / 2.0), Vector2(s * 0.9, w)), OUTLINE, false, 1.5)
	if up_only:
		# brazo de arriba relleno y con su flechita, para que se lea "arriba"
		ci.draw_rect(Rect2(c - Vector2(w / 2.0, s * 0.45), Vector2(w, s * 0.45 - w / 2.0)), OUTLINE)
		var tip = c - Vector2(0, s * 0.38)
		ci.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-w * 0.32, w * 0.4), tip + Vector2(w * 0.32, w * 0.4)]), BODY)

static func _box(rect: Rect2, p: float) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = BODY.lerp(BODY_PRESSED, p)
	box.border_color = UIStyle.COLOR_GOLD if p > 0.0 else OUTLINE
	box.set_border_width_all(maxi(2, int(rect.size.y * 0.06)))
	box.shadow_color = Color(0, 0, 0, 0.4)
	box.shadow_size = 2
	return box

static func _center_text(ci: CanvasItem, font: Font, text: String, center: Vector2, font_size: int, color: Color) -> void:
	font_size = maxi(font_size, 8)
	var ts = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent = font.get_ascent(font_size)
	var descent = font.get_descent(font_size)
	var pos = Vector2(center.x - ts.x / 2.0, center.y + (ascent - descent) / 2.0)
	ci.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
