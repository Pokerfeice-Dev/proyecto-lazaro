extends Control
class_name TitlePrompt

## Cartel de la pantalla de título ("PRESIONA CUALQUIER BOTÓN") con el estilo de la
## UI del juego: placa con borde, rombos dorados, barrido de luz y un zumbido
## eléctrico que cada tanto se vuelve glitch. Entra como una pantalla que se prende
## y sale con un destello. Lo crea main_menu.gd.

signal salio

const TEXTO := "PRESIONA CUALQUIER BOTÓN"
const JITTER_CADA := 0.06 # segundos entre un temblor y otro (se ve como zumbido, sin gastar)
const GLITCH_CADA := Vector2(2.2, 4.0)

var _placa: PanelContainer
var _brillo: Control # barrido de luz y arco eléctrico (recortado a la placa)
var _tiempo := 0.0
var _sig_jitter := 0.0
var _sig_glitch := 2.0
var _glitch_resta := 0.0
var _saliendo := false
var _entro := false
var _arco := PackedVector2Array()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placa = PanelContainer.new()
	_placa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placa.add_theme_stylebox_override("panel", _estilo())
	add_child(_placa)
	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placa.add_child(fila)
	fila.add_child(_rombo())
	var texto = UIStyle.label(TEXTO, 24, UIStyle.COLOR_GOLD)
	texto.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	texto.add_theme_constant_override("outline_size", 5)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_child(texto)
	fila.add_child(_rombo())
	_brillo = Control.new()
	_brillo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brillo.clip_contents = true
	_brillo.draw.connect(_dibujar_brillo)
	_placa.add_child(_brillo)
	_brillo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placa.resized.connect(_on_placa_resized)
	await get_tree().process_frame
	_placa.reset_size()
	custom_minimum_size = _placa.size
	size = _placa.size
	_placa.pivot_offset = _placa.size / 2.0
	_entrar()

func _on_placa_resized() -> void:
	_placa.pivot_offset = _placa.size / 2.0

func _rombo() -> Label:
	var l = UIStyle.label("◆", 18, UIStyle.COLOR_TEAL)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _estilo() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.07, 0.09, 0.82)
	s.border_color = Color(UIStyle.COLOR_GOLD, 0.9)
	s.set_border_width_all(2)
	s.border_width_bottom = 4
	s.set_corner_radius_all(6)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.shadow_color = Color(UIStyle.COLOR_GOLD, 0.22)
	s.shadow_size = 12
	return s

# Entrada: se prende como una pantalla (línea fina que se abre) con un destello.
func _entrar() -> void:
	_placa.scale = Vector2(1.18, 0.04)
	_placa.modulate = Color(2.2, 2.2, 2.2, 0.0)
	var t = create_tween().set_parallel(true)
	t.tween_property(_placa, "modulate:a", 1.0, 0.12)
	t.tween_property(_placa, "scale:x", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_placa, "scale:y", 1.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.1)
	t.tween_property(_placa, "modulate", Color.WHITE, 0.4).set_delay(0.1)
	t.chain().tween_callback(_terminar_entrada)

func _terminar_entrada() -> void:
	_entro = true

func _process(delta: float) -> void:
	if _placa == null or _saliendo: return
	_tiempo += delta
	_sig_glitch -= delta
	if _sig_glitch <= 0.0:
		_sig_glitch = randf_range(GLITCH_CADA.x, GLITCH_CADA.y)
		_glitch_resta = 0.28
	_glitch_resta = maxf(0.0, _glitch_resta - delta)
	if not _entro: return
	# respiración lenta de la placa y de su resplandor
	var latido = 0.5 + 0.5 * sin(_tiempo * 2.6)
	var s = 1.0 + 0.018 * latido
	_sig_jitter -= delta
	if _sig_jitter <= 0.0:
		_sig_jitter = JITTER_CADA
		var fuerza = 0.7 if _glitch_resta <= 0.0 else 4.5
		_placa.position = Vector2(randf_range(-fuerza, fuerza), randf_range(-fuerza, fuerza) * 0.5)
		_placa.rotation_degrees = randf_range(-0.12, 0.12) if _glitch_resta <= 0.0 else randf_range(-0.8, 0.8)
		var tinte = Color.WHITE.lerp(Color(1.5, 1.4, 1.1), latido * 0.4)
		if _glitch_resta > 0.0:
			tinte = Color(1.8, 1.6, 1.2) if randf() < 0.5 else Color(0.6, 1.2, 1.3)
		_placa.modulate = tinte
		_generar_arco()
	_placa.scale = Vector2(s, s)
	_brillo.queue_redraw() # el barrido de luz avanza cada cuadro

# Línea quebrada tipo chispazo sobre el borde de abajo; solo se ve durante el glitch.
func _generar_arco() -> void:
	_arco.clear()
	if _glitch_resta <= 0.0: return
	var w = _brillo.size.x
	var y = _brillo.size.y - 2.0
	var x = 0.0
	while x < w:
		_arco.append(Vector2(x, y + randf_range(-6.0, 6.0)))
		x += randf_range(10.0, 26.0)
	_arco.append(Vector2(w, y))

func _dibujar_brillo() -> void:
	var tam = _brillo.size
	# barrido de luz: una franja inclinada que cruza la placa cada par de segundos
	var ciclo = fposmod(_tiempo, 2.8) / 1.6
	if ciclo <= 1.0:
		var x = lerpf(-60.0, tam.x + 60.0, ciclo)
		var ancho = 46.0
		var c0 = Color(1, 0.95, 0.75, 0.0)
		var c1 = Color(1, 0.95, 0.75, 0.22)
		var pts = PackedVector2Array([Vector2(x - ancho, tam.y), Vector2(x - ancho + 22.0, 0), Vector2(x + 22.0, 0), Vector2(x, tam.y)])
		var cols = PackedColorArray([c0, c0, c1, c1])
		draw_polygon(pts, cols)
	if _arco.size() > 1:
		draw_polyline(_arco, Color(0.75, 1.0, 0.95, 0.9), 2.0)

# Salida: destello, la placa se aplasta en una línea y desaparece. Avisa con "salio".
func salir() -> void:
	if _saliendo: return
	_saliendo = true
	_placa.position = Vector2.ZERO
	_placa.rotation = 0.0
	var t = create_tween()
	t.tween_property(_placa, "modulate", Color(3.0, 3.0, 2.6, 1.0), 0.06)
	t.set_parallel(true)
	t.tween_property(_placa, "scale", Vector2(1.2, 0.04), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.06)
	t.tween_property(_placa, "modulate:a", 0.0, 0.14).set_delay(0.16)
	t.chain().tween_callback(_terminar_salida)

func _terminar_salida() -> void:
	salio.emit()
	queue_free()
