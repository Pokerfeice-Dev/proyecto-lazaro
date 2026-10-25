extends Node2D
class_name PlayerMarker

## Anillo celeste a los pies de Lázaro para encontrarlo rápido entre los
## enemigos (en el evento varios lo perdían de vista). Late suave y se dibuja
## detrás del personaje, sobre su sombra.
## Se apaga desde Opciones > Juego ("Marca debajo de Lázaro").

const COLOR := Color("#52D8C6")
const RADIUS := Vector2(19.0, 8.0)
const OFFSET := Vector2(0.0, 15.0)

var _time := 0.0

func _ready() -> void:
	show_behind_parent = true
	z_index = 0
	position = OFFSET
	visible = FxSettings.on("marcador_lazaro")
	var gs = FxSettings.instance()
	if gs: gs.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(_section: String, key: String, value: Variant) -> void:
	if key == "marcador_lazaro":
		visible = bool(value)

func _process(delta: float) -> void:
	if not visible: return
	_time += delta
	queue_redraw()

func _draw() -> void:
	var pulse = 0.5 + 0.5 * sin(_time * 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, RADIUS.y / RADIUS.x))
	draw_arc(Vector2.ZERO, RADIUS.x, 0.0, TAU, 40, Color(COLOR, 0.55 + 0.25 * pulse), 2.0, true)
	draw_arc(Vector2.ZERO, RADIUS.x + 3.0, 0.0, TAU, 40, Color(COLOR, 0.12 + 0.12 * pulse), 3.0, true)
