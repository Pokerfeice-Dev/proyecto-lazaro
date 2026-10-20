extends CanvasLayer
class_name TutorialHud

## Tarjeta del paso actual del tutorial, con el estilo de la UI del juego:
## pestaña "ENTRENAMIENTO · PASO X/Y", las teclas o el mouse dibujados en
## grande (se presionan solos para mostrar qué hacer), el texto corto, un
## contador y los puntitos de progreso. Si el objetivo del paso queda fuera
## de la pantalla, aparece una flecha con la manito en el borde apuntando hacia él.

const HAND := preload("res://Art/Props/Training/tutorial_hand.png")
const ICON_CHECK := preload("res://Art/Ui/svg/icon_check.svg")
const STEP_SOUND := "res://Audio/Sfx/Equipar_items.wav"
const EDGE_MARGIN := 70.0

var _tab: Button
var _card: VBoxContainer
var _content: HBoxContainer
var _inputs_box: HBoxContainer
var _text: Label
var _counter: Label
var _pips: HBoxContainer
var _edge: Control
var _edge_arrow: Polygon2D
var _target: Node2D
var _time := 0.0
var _inputs: Array = []

func _ready() -> void:
	layer = 95
	_build()
	InputMode.instance().mode_changed.connect(_on_input_mode_changed)

# Teclado <-> joystick: vuelve a dibujar las teclas o los botones.
func _on_input_mode_changed(_gamepad: bool) -> void:
	_fill_inputs(_inputs)

## Cambia de paso. inputs: teclas ("W", "ESPACIO", "E") o "MOUSE_L" / "MOUSE_R".
func set_step(index: int, total: int, text: String, inputs: Array = [], counter := "") -> void:
	_tab.text = "  ENTRENAMIENTO · PASO %d/%d" % [index + 1, total]
	_fill_inputs(inputs)
	_text.text = text
	set_counter(counter)
	_refresh_pips(index, total)
	_pulse_card()
	_play(STEP_SOUND)

func set_counter(counter: String) -> void:
	_counter.text = counter
	_counter.visible = counter != ""

## Recordatorio visual cuando el jugador permanece varios segundos en un paso.
func nudge() -> void:
	_pulse_card()

## Objetivo del paso: si sale de la pantalla, la flecha del borde lo señala.
func track(target: Node2D) -> void:
	_target = target

func hide_card() -> void:
	var t = create_tween()
	t.tween_property(_card, "modulate:a", 0.0, 0.25)
	_target = null

func _process(delta: float) -> void:
	_time += delta
	_update_edge_arrow()

# --- Armado ---

func _build() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_card = VBoxContainer.new()
	_card.add_theme_constant_override("separation", 0)
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card.offset_bottom = -28
	_card.custom_minimum_size.x = 760
	_card.offset_left = -380
	_card.offset_right = 380
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_card)
	_tab = UIStyle.title_tab("  ENTRENAMIENTO")
	_tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tab.add_theme_font_size_override("font_size", 16)
	_tab.custom_minimum_size = Vector2(0, 36)
	_card.add_child(_tab)
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(panel)
	var m = UIStyle.padded(18)
	panel.add_child(m)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	m.add_child(col)
	_content = HBoxContainer.new()
	_content.add_theme_constant_override("separation", 22)
	col.add_child(_content)
	_inputs_box = HBoxContainer.new()
	_inputs_box.add_theme_constant_override("separation", 6)
	_inputs_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_inputs_box.custom_minimum_size = Vector2(170, 64)
	_content.add_child(_inputs_box)
	_text = UIStyle.label("", 24, UIStyle.COLOR_TEXT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_text)
	_counter = UIStyle.label("", 30, UIStyle.COLOR_GOLD)
	_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_content.add_child(_counter)
	_pips = HBoxContainer.new()
	_pips.alignment = BoxContainer.ALIGNMENT_CENTER
	_pips.add_theme_constant_override("separation", 8)
	col.add_child(_pips)
	_build_edge_arrow(root)

func _fill_inputs(inputs: Array) -> void:
	_inputs = inputs
	for c in _inputs_box.get_children():
		_inputs_box.remove_child(c)
		c.queue_free()
	var shown = TutorialInputIcon.for_mode(inputs)
	_inputs_box.visible = not shown.is_empty()
	for i in shown.size():
		_inputs_box.add_child(TutorialInputIcon.create(shown[i], 1.0, i * 0.35))

func _refresh_pips(index: int, total: int) -> void:
	for c in _pips.get_children():
		_pips.remove_child(c)
		c.queue_free()
	for i in total:
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(26 if i == index else 12, 6)
		pip.color = UIStyle.COLOR_GOLD if i == index else (UIStyle.COLOR_TEAL if i < index else Color(UIStyle.COLOR_MUTED, 0.3))
		_pips.add_child(pip)

func _pulse_card() -> void:
	await get_tree().process_frame
	_card.pivot_offset = Vector2(_card.size.x / 2.0, _card.size.y)
	_card.modulate = Color(1.6, 1.6, 1.6, 0.0)
	_card.scale = Vector2(0.96, 0.96)
	var t = create_tween().set_parallel(true)
	t.tween_property(_card, "modulate", Color.WHITE, 0.3)
	t.tween_property(_card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# --- Flecha del borde ---

func _build_edge_arrow(root: Control) -> void:
	_edge = Control.new()
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edge.visible = false
	root.add_child(_edge)
	_edge_arrow = Polygon2D.new()
	_edge_arrow.polygon = PackedVector2Array([Vector2(30, 0), Vector2(-14, -20), Vector2(-6, 0), Vector2(-14, 20)])
	_edge_arrow.color = UIStyle.COLOR_GOLD
	_edge.add_child(_edge_arrow)
	var hand = TextureRect.new()
	hand.texture = HAND
	hand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hand.size = Vector2(48, 56)
	hand.position = Vector2(-24, -86)
	hand.flip_v = true
	_edge.add_child(hand)

func _update_edge_arrow() -> void:
	if not _target or not is_instance_valid(_target) or not _target.is_inside_tree():
		_edge.visible = false
		return
	var vp = get_viewport().get_visible_rect().size
	var screen_pos = get_viewport().get_canvas_transform() * _target.global_position
	var inside = Rect2(Vector2.ZERO, vp).grow(-EDGE_MARGIN).has_point(screen_pos)
	_edge.visible = not inside
	if inside: return
	var center = vp / 2.0
	var dir = (screen_pos - center).normalized()
	var limit = vp / 2.0 - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var k = minf(absf(limit.x / dir.x) if dir.x != 0.0 else INF, absf(limit.y / dir.y) if dir.y != 0.0 else INF)
	_edge.position = center + dir * k
	_edge_arrow.rotation = dir.angle()
	_edge.modulate.a = 0.75 + 0.25 * sin(_time * 8.0)

func _play(path: String) -> void:
	if not ResourceLoader.exists(path): return
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load(path)
	sfx.bus = "SFX"
	sfx.volume_db = -6.0
	add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
