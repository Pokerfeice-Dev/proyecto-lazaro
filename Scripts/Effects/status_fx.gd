class_name StatusFx
extends RefCounted

## Sprites de estado sobre los enemigos (arte de turco):
## - fuego: en loop mientras dura la quemadura (IgniteEffect)
## - hielo: costra en los pies que crece y se queda en el último cuadro mientras
##   el enemigo está congelado (EnemyBase.freeze_enemy)
## Uso: StatusFx.show_fire(enemigo) / hide_fire(enemigo), show_freeze / hide_freeze.

const FIRE_TEX := preload("res://Art/Effects/StatusEffects/statuseffect_fire17x28.png")
const FREEZE_TEX := preload("res://Art/Effects/StatusEffects/statuseffect_freeze23x14.png")
const FIRE_NODE := "StatusFire"
const FREEZE_NODE := "StatusFreeze"
const ART_SCALE := 1.3 # misma escala que los personajes

static func show_fire(target: Node) -> void:
	if not (target is Node2D) or target.get_node_or_null(FIRE_NODE): return
	var fx = _make(FIRE_TEX, Vector2i(17, 28), 4, 10.0, true)
	fx.name = FIRE_NODE
	var rect = _body_rect(target)
	fx.position = rect.get_center() + Vector2(0, -rect.size.y * 0.1)
	target.add_child(fx)

static func hide_fire(target: Node) -> void:
	_remove(target, FIRE_NODE)

static func show_freeze(target: Node) -> void:
	if not (target is Node2D): return
	_remove(target, FREEZE_NODE)
	var fx = _make(FREEZE_TEX, Vector2i(23, 14), 4, 12.0, false)
	fx.name = FREEZE_NODE
	var rect = _body_rect(target)
	# la costra se apoya en los pies
	fx.position = Vector2(rect.get_center().x, rect.end.y - 14.0 * ART_SCALE * 0.5)
	target.add_child(fx)

static func hide_freeze(target: Node) -> void:
	_remove(target, FREEZE_NODE)

static func _remove(target: Node, node_name: String) -> void:
	if not is_instance_valid(target): return
	var fx = target.get_node_or_null(node_name)
	if fx:
		target.remove_child(fx)
		fx.queue_free()

# Hoja horizontal de cuadros -> AnimatedSprite2D que se reproduce solo.
static func _make(tex: Texture2D, frame: Vector2i, count: int, fps: float, loop: bool) -> AnimatedSprite2D:
	var frames = SpriteFrames.new()
	frames.set_animation_loop("default", loop)
	frames.set_animation_speed("default", fps)
	for i in count:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame.x, 0, frame.x, frame.y)
		frames.add_frame("default", atlas)
	var fx = AnimatedSprite2D.new()
	fx.sprite_frames = frames
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.scale = Vector2(ART_SCALE, ART_SCALE)
	fx.z_index = 1 # encima del sprite del enemigo
	fx.play("default") # el hielo se queda solo en el último cuadro (sin loop)
	return fx

# Rectángulo del cuerpo en coordenadas del enemigo, a partir de su sprite.
static func _body_rect(target: Node) -> Rect2:
	var sprite: Node2D = target._get_sprite() if target.has_method("_get_sprite") else null
	var size := Vector2(24, 32)
	var center := Vector2.ZERO
	if sprite is AnimatedSprite2D and sprite.sprite_frames:
		var anim = sprite.animation
		if sprite.sprite_frames.has_animation(anim) and sprite.sprite_frames.get_frame_count(anim) > 0:
			var t = sprite.sprite_frames.get_frame_texture(anim, 0)
			if t: size = t.get_size() * sprite.scale.abs()
		center = sprite.position + sprite.offset * sprite.scale
	elif sprite is Sprite2D and sprite.texture:
		size = sprite.texture.get_size() / Vector2(sprite.hframes, sprite.vframes) * sprite.scale.abs()
		center = sprite.position + sprite.offset * sprite.scale
	# los cuadros suelen tener aire alrededor: se achica un poco
	size *= 0.8
	return Rect2(center - size / 2.0, size)
