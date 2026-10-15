extends Sprite2D
class_name StationSprite

## Sprite de las estaciones de la sala de entrenamiento (armería, incubadora).
## Anima sus cuadros en loop si tiene varios, y se ilumina cuando el jugador
## está cerca (cuadro "glow_frame" o un brillo suave si no tiene ese cuadro).

@export var animated := false
@export var fps := 5.0
@export var glow_frame := -1

var _time := 0.0
var _highlight := false

func set_highlight(on: bool) -> void:
	_highlight = on
	if glow_frame >= 0 and not animated:
		frame = glow_frame if on else 0

func _process(delta: float) -> void:
	_time += delta
	if animated and hframes > 1:
		frame = int(_time * fps) % hframes
	var pulse = 0.5 + 0.5 * sin(_time * 4.0)
	var target = Color(1.15 + 0.1 * pulse, 1.15 + 0.1 * pulse, 1.15 + 0.1 * pulse) if _highlight else Color.WHITE
	self_modulate = self_modulate.lerp(target, minf(1.0, delta * 10.0))
