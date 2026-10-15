extends Control
class_name TutorialInputIcon

## Una tecla o el mouse dibujados como en la UI, que se "presionan" solos en
## loop para mostrar qué hay que tocar. El mouse ilumina el botón que corresponde.
## Uso: TutorialInputIcon.create("W"), create("MOUSE_L"), create("ESPACIO")

const PRESS_EVERY := 1.4

var key := ""
var press_delay := 0.0
var _time := 0.0
var _pressed := 0.0

static func create(p_key: String, size_scale: float = 1.0, delay: float = 0.0) -> TutorialInputIcon:
	var icon = TutorialInputIcon.new()
	icon.key = p_key
	icon.press_delay = delay
	var base = Vector2(44, 58) if p_key.begins_with("MOUSE") else Vector2(maxf(48.0, 16.0 + p_key.length() * 16.0), 48)
	icon.custom_minimum_size = base * size_scale
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

func _process(delta: float) -> void:
	_time += delta
	var t = fmod(_time + PRESS_EVERY - press_delay, PRESS_EVERY)
	_pressed = 1.0 if t < 0.22 else 0.0
	queue_redraw()

func _draw() -> void:
	if key.begins_with("MOUSE"):
		_draw_mouse(key == "MOUSE_L")
	else:
		_draw_key()

func _draw_key() -> void:
	var r = Rect2(Vector2.ZERO, size)
	var depth = 6.0 * (1.0 - _pressed * 0.7)
	var face = Rect2(r.position + Vector2(0, 6.0 - depth), Vector2(r.size.x, r.size.y - 6.0))
	draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, r.size.y - 6)), Color("#0B1215"))
	var box = StyleBoxFlat.new()
	box.bg_color = Color("#23353B").lerp(Color("#3E6A68"), _pressed)
	box.border_color = UIStyle.COLOR_GOLD if _pressed > 0.0 else UIStyle.COLOR_TEAL
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	draw_style_box(box, face)
	var font = get_theme_default_font()
	var font_size = int(clampf(size.y * 0.42, 12, 26))
	var text_size = font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, face.get_center() + Vector2(-text_size.x / 2.0, text_size.y * 0.32), key, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UIStyle.COLOR_TEXT)

func _draw_mouse(left: bool) -> void:
	var w = size.x
	var h = size.y
	var body = StyleBoxFlat.new()
	body.bg_color = Color("#23353B")
	body.border_color = UIStyle.COLOR_TEAL
	body.set_border_width_all(2)
	body.set_corner_radius_all(int(w * 0.45))
	draw_style_box(body, Rect2(Vector2.ZERO, size))
	# botón que hay que tocar
	var button = Rect2(Vector2(3.0 if left else w / 2.0, 3.0), Vector2(w / 2.0 - 3.0, h * 0.42))
	var glow = UIStyle.COLOR_GOLD.lerp(Color.WHITE, _pressed * 0.6)
	var b = StyleBoxFlat.new()
	b.bg_color = Color(glow, 0.55 + 0.45 * _pressed)
	b.corner_radius_top_left = int(w * 0.4) if left else 0
	b.corner_radius_top_right = 0 if left else int(w * 0.4)
	draw_style_box(b, button)
	draw_line(Vector2(w / 2.0, 3), Vector2(w / 2.0, h * 0.45), UIStyle.COLOR_TEAL, 2.0)
	draw_line(Vector2(4, h * 0.45), Vector2(w - 4, h * 0.45), UIStyle.COLOR_TEAL, 2.0)
	# ondita cuando "hace clic"
	if _pressed > 0.0:
		var c = button.get_center()
		draw_arc(c, 14.0, 0.0, TAU, 20, Color(UIStyle.COLOR_GOLD, 0.7), 2.0)
