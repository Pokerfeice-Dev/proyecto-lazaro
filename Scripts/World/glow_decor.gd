@tool
extends Node2D
class_name GlowDecor

## Decoración que brilla del Área 3 (Tierra Maldita), sin colisión.
## Hace lo mismo que las velas/antorchas de las otras zonas pero con los bichos del tileset:
## vainas amarillas y corales rosados, con una luz anaranjada o rosada que "respira".
## Los kinds "luz_*" son solo la luz (sin sprite), para poner sobre objetos que ya están
## pintados en el TileMapLayer "Tile_Objects".
## Va dentro del nodo "Iluminacion" de la sala (QualityManager lo cuenta como luz de ambiente).

const KINDS := {
	"pod": {"region": Rect2(8, 1227, 30, 28), "color": Color(1.0, 0.64, 0.28), "energy": 0.9, "scale": 2.2},
	"coral": {"region": Rect2(54, 1220, 20, 25), "color": Color(1.0, 0.52, 0.55), "energy": 0.72, "scale": 2.0},
	"coral_chico": {"region": Rect2(88, 1223, 17, 20), "color": Color(1.0, 0.52, 0.55), "energy": 0.55, "scale": 1.6},
	"luz_ambar": {"color": Color(1.0, 0.66, 0.3), "energy": 0.75, "scale": 1.9},
	"luz_rosa": {"color": Color(1.0, 0.52, 0.55), "energy": 0.62, "scale": 1.8},
	"luz_espora": {"color": Color(0.72, 1.0, 0.5), "energy": 0.55, "scale": 1.8},
}

const PULSE := 0.07 # cuánto sube y baja el brillo (7 %)
const PULSE_SPEED := 1.9
const UPDATE_INTERVAL := 0.08

@export_enum("pod", "coral", "coral_chico", "luz_ambar", "luz_rosa", "luz_espora") var kind: String = "pod":
	set(value):
		kind = value
		if is_node_ready():
			_apply_look()

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

var _base_energy := 0.9
var _phase := 0.0
var _accum := 0.0

func _ready() -> void:
	_phase = randf_range(0.0, TAU)
	_apply_look()
	set_process(not Engine.is_editor_hint())

func _apply_look() -> void:
	var data: Dictionary = KINDS.get(kind, KINDS["pod"])
	var light_height := 0.0
	sprite.visible = data.has("region")
	if sprite.visible:
		var region: Rect2 = data["region"]
		sprite.region_rect = region
		sprite.offset = Vector2(0.0, -region.size.y / 2.0) # la base del sprite queda en el origen
		light_height = region.size.y # el sprite se dibuja a escala 2: su centro queda a -size.y
	light.position = Vector2(0.0, -light_height)
	light.color = data["color"]
	light.energy = data["energy"]
	var s: float = data["scale"]
	light.scale = Vector2(s, s)
	_base_energy = light.energy

func _process(delta: float) -> void:
	if not FlickeringLight.is_globally_enabled:
		return
	_accum += delta
	if _accum < UPDATE_INTERVAL:
		return
	_accum = 0.0
	var t := Time.get_ticks_msec() / 1000.0
	light.energy = _base_energy * (1.0 + sin(t * PULSE_SPEED + _phase) * PULSE)
