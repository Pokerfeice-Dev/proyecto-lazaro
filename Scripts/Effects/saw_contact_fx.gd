extends Node2D
## Un efecto breve por enemigo; los pulsos sucesivos lo refrescan.
var age := 0.0
var direction := Vector2.RIGHT
var target_ref: WeakRef
var target_offset := Vector2.ZERO
var texture: Texture2D
var samples: Array[Rect2] = []
var pulse := 0

static func spawn(body: Node2D, contact_point: Vector2, forward: Vector2) -> void:
	var existing: Variant = body.get_meta("saw_contact_fx") if body.has_meta("saw_contact_fx") else null
	var fx: Node2D = existing.get_ref() if existing is WeakRef else null
	if not is_instance_valid(fx):
		if body.get_tree().get_nodes_in_group("saw_contact_fx").size() >= 24: return
		fx = new()
		body.get_tree().current_scene.add_child(fx)
		fx.add_to_group("saw_contact_fx")
		body.set_meta("saw_contact_fx", weakref(fx))
	fx.global_position = contact_point
	fx.target_ref = weakref(body)
	fx.target_offset = contact_point - body.global_position
	fx.direction = forward.normalized()
	fx.age = 0
	fx.pulse += 1
	fx.capture_sprite(body)

func _ready() -> void:
	z_index = 30
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

func capture_sprite(body: Node2D) -> void:
	var sprite: Node2D = body._get_sprite() if body.has_method("_get_sprite") else body.get_node_or_null("AnimatedSprite2D")
	var region := Rect2()
	texture = null
	if sprite is AnimatedSprite2D and sprite.sprite_frames:
		texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		if texture: region = Rect2(Vector2.ZERO, texture.get_size())
	elif sprite is Sprite2D and sprite.texture:
		texture = sprite.texture
		region = sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, texture.get_size())
		region.size /= Vector2(sprite.hframes, sprite.vframes)
		region.position += Vector2(sprite.frame_coords) * region.size
	samples.clear()
	if not texture: return
	var size := Vector2.ONE * clampf(minf(region.size.x, region.size.y) / 8, 2, 6)
	for i in 8:
		var uv := Vector2(0.2 + fposmod(i * 0.37 + pulse * 0.13, 0.6), 0.2 + fposmod(i * 0.23, 0.6))
		samples.append(Rect2(region.position + ((region.size - size) * uv).floor(), size))

func _process(delta: float) -> void:
	age += delta
	if age > 0.42:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := age / 0.42
	var fade := 1 - t
	var side := direction.orthogonal()
	var center := Vector2.ZERO
	var target: Node2D = target_ref.get_ref() if target_ref else null
	if is_instance_valid(target): center = to_local(target.global_position + target_offset)
	# Tres surcos paralelos: destello corto sobre el punto mordido por los dientes.
	var bite := maxf(0, 1 - age / 0.16)
	for i in 3:
		var mid := center + direction * (i - 1) * 4
		var edge := side * (7 + i * 2)
		draw_line((mid - edge).round(), (mid + edge + direction * 3).round(), Color(0.28, 0.04, 0.08, bite * 0.85), 4)
		draw_line((mid - edge).round(), (mid + edge + direction * 3).round(), Color(1, 0.84, 0.48, bite), 1)
	# La sierra expulsa fragmentos y chispas hacia ambos lados de la hoja.
	var count := 10 if OS.has_feature("web") else 16
	for i in count:
		var sign_side := 1.0 if i % 2 == 0 else -1.0
		var velocity := side * sign_side * (45 + i * 5) - direction * (15 + fposmod(i * 13.7, 45))
		var pos := velocity * age + Vector2(0, 130 * age * age)
		var tint := Color("ffe6a6") if i % 3 == 0 else Color("ff763c")
		draw_line(pos.round(), (pos - velocity.normalized() * 9 * fade).round(), Color(tint, fade), 2)
		if texture and i < samples.size():
			draw_texture_rect_region(texture, Rect2(pos.round(), Vector2.ONE * (3 + i % 3) * fade), samples[i], Color(1, 1, 1, fade))
		else:
			draw_rect(Rect2(pos.round(), Vector2(2, 2)), Color(tint, fade))
