class_name InventoryHealthBar
extends VBoxContainer
# Barra de vida que va debajo del retrato de Lázaro en el inventario.
#
#  - set_health(): vida actual y máxima en tiempo real (la barra se desliza hacia el valor nuevo).
#  - set_preview(): cómo quedaría la vida si sueltas la pieza que llevas sobre el casillero.
#      verde  = vida que se gana (cura al instalar una pieza nueva, o capacidad máxima nueva)
#      ámbar  = vida que se pierde (la pieza quitada o reemplazada daba vida máxima)
#    Con vista previa, la escala de la barra es la del máximo mayor, así se ven los dos largos.
#  - clear_preview(): vuelve a la vida real.

const COLOR_FILL := Color("#D9524E")
const COLOR_TRACK := Color("#10181C")
const COLOR_TRACK_CAPACITY := Color("#1E2A30")
const COLOR_BORDER := Color("#4A6772")
const COLOR_GAIN := Color("#6FE08A")
const COLOR_LOSS := Color("#EDB35B")
const COLOR_TICK := Color(0.0, 0.0, 0.0, 0.35)
const TICK_EVERY := 25            # una marca cada tantos puntos de vida
const TRACK_HEIGHT := 22.0
const SLIDE_SPEED := 1.4          # vidas máximas por segundo que recorre la barra al cambiar

var _current: int = 0
var _max: int = 1
var _shown: float = 0.0
var _initialized: bool = false
var _has_preview: bool = false
var _prev_current: int = 0
var _prev_max: int = 1

var _value_label: Label
var _delta_label: Label
var _track: Control

func _ready() -> void:
	name = "InventoryHealthBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var title := _make_label("VIDA", 18, UIStyle.COLOR_MUTED)
	row.add_child(title)
	_value_label = _make_label("", 20, UIStyle.COLOR_TEXT)
	row.add_child(_value_label)
	_delta_label = _make_label("", 18, COLOR_GAIN)
	_delta_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_delta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(_delta_label)
	# El título y el valor se reparten el lado izquierdo; el cambio va a la derecha.
	_value_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 10)
	_track = Control.new()
	_track.custom_minimum_size = Vector2(0, TRACK_HEIGHT)
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.draw.connect(_draw_track)
	add_child(_track)
	_refresh_texts()

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func set_health(current: int, max_health: int) -> void:
	max_health = maxi(max_health, 1)
	current = clampi(current, 0, max_health)
	if current == _current and max_health == _max and _initialized: return
	_current = current
	_max = max_health
	if not _initialized:
		_shown = float(current)
		_initialized = true
	_shown = minf(_shown, float(_max))
	_refresh_texts()
	if _track != null: _track.queue_redraw()

func set_preview(new_current: int, new_max: int) -> void:
	new_max = maxi(new_max, 1)
	new_current = clampi(new_current, 0, new_max)
	if new_current == _current and new_max == _max:
		clear_preview()
		return
	_has_preview = true
	_prev_current = new_current
	_prev_max = new_max
	_refresh_texts()
	if _track != null: _track.queue_redraw()

func clear_preview() -> void:
	if not _has_preview: return
	_has_preview = false
	_refresh_texts()
	if _track != null: _track.queue_redraw()

func _process(delta: float) -> void:
	if _track == null or not is_visible_in_tree(): return
	if not is_equal_approx(_shown, float(_current)):
		_shown = move_toward(_shown, float(_current), float(_max) * SLIDE_SPEED * delta)
		_track.queue_redraw()
	elif _has_preview:
		_track.queue_redraw() # latido de la vista previa

func _refresh_texts() -> void:
	if _value_label == null: return
	_value_label.text = "%d / %d" % [_current, _max]
	if not _has_preview:
		_delta_label.text = ""
		return
	var parts: Array[String] = []
	var d_cur := _prev_current - _current
	var d_max := _prev_max - _max
	if d_cur != 0: parts.append("%+d vida" % d_cur)
	if d_max != 0: parts.append("%+d máx." % d_max)
	_delta_label.text = "  ·  ".join(parts)
	var gain := d_cur > 0 or d_max > 0
	var loss := d_cur < 0 or d_max < 0
	var color := COLOR_GAIN
	if loss and not gain: color = UIStyle.COLOR_DANGER
	elif loss and gain: color = COLOR_LOSS
	_delta_label.add_theme_color_override("font_color", color)

func _draw_track() -> void:
	var track_size := _track.size
	var scale_max := float(_max)
	if _has_preview: scale_max = float(maxi(_max, _prev_max))
	if scale_max <= 0.0 or track_size.x <= 0.0: return
	var per_point := track_size.x / scale_max
	var h := track_size.y
	var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 1000.0 * 6.0)

	# fondo y capacidad actual
	_track.draw_rect(Rect2(0, 0, track_size.x, h), COLOR_TRACK)
	_track.draw_rect(Rect2(0, 0, _max * per_point, h), COLOR_TRACK_CAPACITY)

	# capacidad que se gana o se pierde
	if _has_preview and _prev_max > _max:
		var c := COLOR_GAIN
		c.a = 0.28 * pulse
		_track.draw_rect(Rect2(_max * per_point, 0, (_prev_max - _max) * per_point, h), c)
	elif _has_preview and _prev_max < _max:
		var c := COLOR_LOSS
		c.a = 0.28 * pulse
		_track.draw_rect(Rect2(_prev_max * per_point, 0, (_max - _prev_max) * per_point, h), c)

	# vida actual (lo que no cambia con la vista previa)
	var keep := _shown
	if _has_preview: keep = minf(_shown, float(_prev_current))
	_track.draw_rect(Rect2(0, 0, keep * per_point, h), COLOR_FILL)
	if _has_preview and _shown > keep:
		var c := COLOR_LOSS
		c.a = pulse
		_track.draw_rect(Rect2(keep * per_point, 0, (_shown - keep) * per_point, h), c)
	elif _has_preview and float(_prev_current) > _shown:
		var c := COLOR_GAIN
		c.a = pulse
		_track.draw_rect(Rect2(_shown * per_point, 0, (float(_prev_current) - _shown) * per_point, h), c)

	# marcas y borde
	var tick := TICK_EVERY
	while tick < int(scale_max):
		var x := tick * per_point
		_track.draw_line(Vector2(x, 0), Vector2(x, h), COLOR_TICK, 1.0)
		tick += TICK_EVERY
	_track.draw_rect(Rect2(0, 0, track_size.x, h), COLOR_BORDER, false, 2.0)
