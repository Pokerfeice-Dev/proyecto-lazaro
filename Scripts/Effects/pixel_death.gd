extends Node2D

## Fragmentos del frame real: conservan textura, orientación y escala.
## Un nodo por sprite, sin cuerpos físicos ni una escena por píxel.
const DURATION := 0.85
var texture: Texture2D
var pieces: Array[Dictionary] = []
var elapsed := 0.0

static func spawn_from(body: Node2D) -> void:
	if not body or not body.is_visible_in_tree(): return
	if body is Sprite2D or body is AnimatedSprite2D:
		_spawn_sprite(body)
	for child in body.get_children():
		if child is Node2D:
			spawn_from(child)

static func _spawn_sprite(sprite: Node2D) -> void:
	var tex: Texture2D
	var region: Rect2
	if sprite is AnimatedSprite2D:
		if not sprite.sprite_frames: return
		tex = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if tex: region = Rect2(Vector2.ZERO, tex.get_size())
	elif sprite is Sprite2D:
		tex = sprite.texture
		if tex:
			region = sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, tex.get_size())
			region.size /= Vector2(sprite.hframes, sprite.vframes)
			region.position += Vector2(sprite.frame_coords) * region.size
	if not tex: return
	var fx = new()
	fx.texture = tex
	fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fx.process_mode = Node.PROCESS_MODE_PAUSABLE
	sprite.get_tree().current_scene.add_child(fx)
	fx.global_transform = sprite.global_transform
	fx.z_index = sprite.z_index + 1
	var origin: Vector2 = sprite.offset
	if sprite.centered: origin -= region.size * 0.5
	# Limita el costo incluso con sprites grandes.
	var step := maxi(2, ceili(maxf(region.size.x, region.size.y) / 16.0))
	for y in range(0, int(region.size.y), step):
		for x in range(0, int(region.size.x), step):
			var size := Vector2(minf(step, region.size.x - x), minf(step, region.size.y - y))
			var pos := Vector2(x, y)
			var dest := pos + origin
			if sprite.flip_h: dest.x = -dest.x - size.x
			if sprite.flip_v: dest.y = -dest.y - size.y
			fx.pieces.append({
				"source": Rect2(region.position + pos, size),
				"dest": Rect2(dest, size),
				"velocity": Vector2(randf_range(-28, 28), randf_range(-65, -20)),
				"delay": randf_range(0.0, 0.18),
				"flip": Vector2(-1 if sprite.flip_h else 1, -1 if sprite.flip_v else 1),
			})

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	for piece in pieces:
		var age := maxf(0.0, elapsed - float(piece.delay))
		var progress := clampf(age / (DURATION - float(piece.delay)), 0.0, 1.0)
		var rect: Rect2 = piece.dest
		rect.position += (piece.velocity * age + Vector2(0, -25) * age * age).round()
		var shrink := 1.0 - progress * 0.8
		rect.position += rect.size * (1.0 - shrink) * 0.5
		rect.size *= shrink
		if piece.flip.x < 0: rect.size.x = -rect.size.x
		if piece.flip.y < 0: rect.size.y = -rect.size.y
		var tint := Color.WHITE.lerp(Color(0.45, 1.0, 0.85), progress * 0.55)
		tint.a = 1.0 - smoothstep(0.25, 1.0, progress)
		draw_texture_rect_region(texture, rect, piece.source, tint)
