@tool
extends Sprite2D
class_name DropShadow

## Textura radial elíptica compartida para todas las sombras del juego
static var _shared_texture: Texture2D = null

@export var shadow_size: Vector2 = Vector2(26.0, 12.0):
	set(val):
		shadow_size = val
		_update_base_scale()

@export var shadow_offset: Vector2 = Vector2(0.0, 14.0):
	set(val):
		shadow_offset = val
		position = shadow_offset

@export var shadow_alpha: float = 0.38:
	set(val):
		shadow_alpha = val
		_update_color()

var _base_scale: Vector2 = Vector2.ONE
var _current_height: float = 0.0
var _fade_tween: Tween = null

func _ready() -> void:
	_init_shadow_visuals()

func _init_shadow_visuals() -> void:
	texture = _get_or_create_shared_texture()
	show_behind_parent = true
	z_index = 0
	_sync_offset_and_position()
	_update_color()
	_update_base_scale()

func _sync_offset_and_position() -> void:
	if position != Vector2.ZERO:
		shadow_offset = position
		return
	position = shadow_offset

func _update_color() -> void:
	modulate = Color(0.0, 0.0, 0.0, shadow_alpha)

static func _get_or_create_shared_texture() -> Texture2D:
	if _shared_texture:
		return _shared_texture
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.85),
		Color(1.0, 1.0, 1.0, 0.4),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.45, 0.75, 1.0])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 32
	_shared_texture = tex
	return _shared_texture

func _update_base_scale() -> void:
	_base_scale = Vector2(shadow_size.x / 64.0, shadow_size.y / 32.0)
	scale = _base_scale

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	_keep_horizontal()

func _keep_horizontal() -> void:
	if global_rotation == 0.0: return
	global_rotation = 0.0

func set_shadow_size(new_size: Vector2) -> void:
	shadow_size = new_size
	_update_base_scale()

func set_shadow_offset(new_offset: Vector2) -> void:
	shadow_offset = new_offset
	position = shadow_offset

func set_height_offset(height: float) -> void:
	_current_height = maxf(0.0, height)
	position.y = shadow_offset.y + _current_height
	var height_ratio = 1.0 / (1.0 + _current_height * 0.015)
	scale = _base_scale * height_ratio
	modulate.a = shadow_alpha * (1.0 / (1.0 + _current_height * 0.02))

func fade_out(duration: float = 0.25) -> void:
	_kill_active_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fade_tween.finished.connect(queue_free)

func fade_in(duration: float = 0.2) -> void:
	_kill_active_tween()
	modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", shadow_alpha, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _kill_active_tween() -> void:
	if not _fade_tween: return
	if not _fade_tween.is_valid(): return
	_fade_tween.kill()

static func attach_to(target: Node2D, size: Vector2 = Vector2(26.0, 12.0), new_offset: Vector2 = Vector2(0.0, 14.0), alpha: float = 0.38) -> DropShadow:
	if not target or not is_instance_valid(target): return null
	var existing = target.get_node_or_null("DropShadow") as DropShadow
	if existing: return existing
	var shadow = DropShadow.new()
	shadow.name = "DropShadow"
	shadow.shadow_size = size
	shadow.shadow_offset = new_offset
	shadow.shadow_alpha = alpha
	target.add_child(shadow)
	return shadow
