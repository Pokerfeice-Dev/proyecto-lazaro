extends Node2D
class_name TutorialPointer

## Indicadores del tutorial dentro del mundo:
##  - point_at(objetivos): círculo que late en el suelo y una manito que rebota
##    encima de cada objetivo (el maniquí, el enemigo, las piezas del suelo).
##  - show_inputs(teclas): un cartelito sobre la cabeza del jugador con las
##    teclas que hay que tocar, presionándose solas, y la manito tocándolas.
## Nadie lee el texto: esto muestra dónde ir y qué tocar.

const HAND := preload("res://Art/Props/Training/tutorial_hand.png")
const RING_COLOR := Color("#F4C45E")
const HAND_SCALE := 2.0
const INPUT_SCALE := 0.36

var _targets: Array = []
var _hand_height := 44.0
var _hands: Array[Sprite2D] = []
var _inputs_holder: Node2D
var _inputs_row: HBoxContainer
var _input_hand: Sprite2D
var _time := 0.0
var _inputs: Array = []

func _ready() -> void:
	z_as_relative = false
	z_index = 40
	_inputs_holder = Node2D.new()
	_inputs_holder.visible = false
	add_child(_inputs_holder)
	var plate = PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _plate_style())
	plate.scale = Vector2(INPUT_SCALE, INPUT_SCALE)
	_inputs_holder.add_child(plate)
	_inputs_row = HBoxContainer.new()
	_inputs_row.add_theme_constant_override("separation", 8)
	plate.add_child(_inputs_row)
	_input_hand = _make_hand()
	_inputs_holder.add_child(_input_hand)
	InputMode.instance().mode_changed.connect(_on_input_mode_changed)

# Teclado <-> joystick: vuelve a dibujar las teclas o los botones.
func _on_input_mode_changed(_gamepad: bool) -> void:
	show_inputs(_inputs)

## Señala uno o más objetivos (Node2D). Lista vacía = nada.
## hand_height: qué tan arriba del objetivo flota la manito (menos para objetos chicos).
func point_at(targets: Array, hand_height := 44.0) -> void:
	_hand_height = hand_height
	for hand in _hands: hand.queue_free()
	_hands.clear()
	_targets = targets.filter(func(t): return is_instance_valid(t))
	for t in _targets:
		var hand = _make_hand()
		add_child(hand)
		_hands.append(hand)

## Teclas sobre la cabeza del jugador ("W", "ESPACIO", "MOUSE_L"...). Vacío = nada.
func show_inputs(inputs: Array) -> void:
	_inputs = inputs
	for c in _inputs_row.get_children():
		_inputs_row.remove_child(c)
		c.queue_free()
	var shown = TutorialInputIcon.for_mode(inputs)
	_inputs_holder.visible = not shown.is_empty()
	for i in shown.size():
		_inputs_row.add_child(TutorialInputIcon.create(shown[i], 1.0, i * 0.35))
	(_inputs_holder.get_child(0) as Control).reset_size() # la placa se ajusta a las teclas nuevas

func clear() -> void:
	point_at([])
	show_inputs([])

func _process(delta: float) -> void:
	_time += delta
	_follow_targets()
	_follow_player()
	queue_redraw()

func _follow_targets() -> void:
	for i in range(_targets.size() - 1, -1, -1):
		var t = _targets[i]
		if not is_instance_valid(t):
			_targets.remove_at(i)
			_hands[i].queue_free()
			_hands.remove_at(i)
			continue
		# recién creado (se agrega diferido): todavía no tiene posición real
		_hands[i].visible = t.is_inside_tree()
		if not t.is_inside_tree(): continue
		var bounce = absf(sin(_time * 4.0 + i)) * 8.0
		_hands[i].global_position = t.global_position + Vector2(0, -_hand_height - bounce)

func _follow_player() -> void:
	if not _inputs_holder.visible: return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if not player: return
	var plate = _inputs_holder.get_child(0) as Control
	var plate_size = plate.size * INPUT_SCALE
	_inputs_holder.global_position = player.global_position + Vector2(-plate_size.x / 2.0, -34 - plate_size.y + sin(_time * 3.0) * 2.0)
	# la manito baja sobre la primera tecla cada vez que se "presiona"
	var t = fmod(_time + TutorialInputIcon.PRESS_EVERY, TutorialInputIcon.PRESS_EVERY)
	var dip = 5.0 if t < 0.22 else 0.0
	_input_hand.position = Vector2(14, -14 + dip)

# Círculo en el suelo debajo de cada objetivo.
func _draw() -> void:
	for t in _targets:
		if not is_instance_valid(t) or not t.is_inside_tree(): continue
		var center = to_local(t.global_position) + Vector2(0, 14)
		var k = fmod(_time * 1.2, 1.0)
		# Baliza vertical: se entiende incluso antes de leer la tarjeta inferior.
		var beam_top = center + Vector2(0, -82.0 - sin(_time * 3.0) * 6.0)
		draw_line(center + Vector2(0, -6), beam_top, Color(RING_COLOR, 0.18), 10.0)
		draw_line(center + Vector2(0, -6), beam_top, Color(RING_COLOR, 0.65), 2.0)
		var arrow_y = center.y - 52.0 + sin(_time * 4.0) * 4.0
		draw_colored_polygon(PackedVector2Array([Vector2(center.x, arrow_y + 13), Vector2(center.x - 10, arrow_y), Vector2(center.x + 10, arrow_y)]), RING_COLOR)
		draw_set_transform(center, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(RING_COLOR, 0.9), 3.0)
		draw_arc(Vector2.ZERO, 22.0 + k * 22.0, 0.0, TAU, 32, Color(RING_COLOR, 0.8 * (1.0 - k)), 2.0)
		draw_set_transform(Vector2.ZERO)

func _make_hand() -> Sprite2D:
	var hand = Sprite2D.new()
	hand.texture = HAND
	hand.flip_v = true
	hand.scale = Vector2(HAND_SCALE, HAND_SCALE)
	hand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return hand

func _plate_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.08, 0.1, 0.88)
	s.border_color = Color(UIStyle.COLOR_TEAL, 0.7)
	s.set_border_width_all(2)
	s.set_corner_radius_all(6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
