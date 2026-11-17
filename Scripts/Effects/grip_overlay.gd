class_name GripOverlay
extends AnimatedSprite2D
# Animación que se dibuja SOBRE el jugador mientras un enemigo lo tiene agarrado: el brazo errante
# enroscado en su cintura y el pecho, o la caja torácica del torso hueco cerrándose.
# Hoja de 48x48 por cuadro: fila 0 = entrada (4 cuadros, una vez), fila 1 = apretando (6 cuadros,
# en bucle). Sigue al jugador y se borra con release(), o sola si el jugador desaparece.

const CELL := 48
const INTRO_FRAMES := 4
const HOLD_FRAMES := 6

static var _cache: Dictionary = {}

var _target: Node2D
var _shake: float = 0.6
var _flash_tween: Tween

## Crea la animación sobre target. Devuelve null si la hoja no existe.
static func attach(target: Node2D, sheet_path: String, fps: float = 12.0, shake: float = 0.6) -> GripOverlay:
	if not is_instance_valid(target) or not target.is_inside_tree(): return null
	var frames := _frames_for(sheet_path, fps)
	if frames == null: return null
	var o := GripOverlay.new()
	o._target = target
	o._shake = shake
	o.sprite_frames = frames
	o.top_level = true
	o.z_as_relative = false
	o.z_index = 8                      # el jugador está en 5
	o.scale = Vector2(1.3, 1.3)        # igual que el sprite del jugador
	o.global_position = target.global_position + Vector2(0, -1)
	target.get_tree().current_scene.add_child(o)
	return o

static func _frames_for(path: String, fps: float) -> SpriteFrames:
	if _cache.has(path): return _cache[path]
	var tex := load(path) as Texture2D
	if tex == null: return null
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	sf.add_animation("intro")
	sf.set_animation_loop("intro", false)
	sf.set_animation_speed("intro", fps)
	sf.add_animation("hold")
	sf.set_animation_loop("hold", true)
	sf.set_animation_speed("hold", fps)
	for i in INTRO_FRAMES: sf.add_frame("intro", _cell(tex, i, 0))
	for i in HOLD_FRAMES: sf.add_frame("hold", _cell(tex, i, 1))
	_cache[path] = sf
	return sf

static func _cell(tex: Texture2D, col: int, row: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(col * CELL, row * CELL, CELL, CELL)
	return a

func _ready() -> void:
	play("intro")
	animation_finished.connect(func(): if animation == "intro": play("hold"))

func _process(_delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_inside_tree():
		queue_free()
		return
	var jitter := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) if animation == "hold" else Vector2.ZERO
	global_position = _target.global_position + Vector2(0, -1) + jitter

## Destello blanco cuando le pegas al enemigo que te tiene agarrado.
func flash() -> void:
	if _flash_tween and _flash_tween.is_valid(): _flash_tween.kill()
	modulate = Color(2.2, 2.2, 2.2, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.12)

func release() -> void:
	queue_free()
