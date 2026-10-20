extends Control
class_name SynergyHalo

## Halo de luz detrás del sprite de una sinergia, como el de la ventana
## "ENLACE ESTABLECIDO": un brillo radial que respira y dos anillos con arcos
## que giran en sentidos opuestos. Apagado (sinergia sin descubrir) queda
## tenue y casi quieto.
## Uso: marco.add_child(SynergyHalo.create(color, true))

const GLOW_STEPS := 7

var color := Color.WHITE
var active := true
var _time := 0.0

static func create(halo_color: Color, is_active: bool) -> SynergyHalo:
	var h = SynergyHalo.new()
	h.color = halo_color
	h.active = is_active
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h._time = randf() * 10.0
	return h

func _process(delta: float) -> void:
	_time += delta * (1.0 if active else 0.25)
	queue_redraw()

func _draw() -> void:
	var c = size / 2.0
	var r = minf(size.x, size.y) * 0.5
	var strength = (0.55 + 0.15 * sin(_time * 2.0)) if active else 0.25
	# brillo radial: discos concéntricos cada vez más transparentes
	for i in GLOW_STEPS:
		var k = 1.0 - float(i) / GLOW_STEPS
		draw_circle(c, r * (0.25 + 0.65 * k), Color(color, 0.05 * strength))
	# anillos con arcos que giran
	var ring = Color(color, 0.55 * strength)
	draw_arc(c, r * 0.86, 0.0, TAU, 48, Color(color, 0.18 * strength), 1.0, true)
	draw_arc(c, r * 0.86, _time * 0.8, _time * 0.8 + 1.6, 24, ring, 2.0, true)
	draw_arc(c, r * 0.86, _time * 0.8 + PI, _time * 0.8 + PI + 0.7, 12, ring, 2.0, true)
	draw_arc(c, r * 0.66, -_time * 1.3, -_time * 1.3 + 1.1, 16, Color(color, 0.4 * strength), 1.5, true)
	if active:
		# chispa que recorre el anillo de afuera
		var a = _time * 0.8 + 1.6
		draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.86, 2.5, Color(color.lightened(0.4), 0.9 * strength))
