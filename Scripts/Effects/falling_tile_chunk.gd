extends Node2D
class_name FallingTileChunk

## Una "pieza" chiquita del tileset (un puñado de tiles agrupados) que cae
## desde arriba y aterriza exactamente donde va, para el efecto de lluvia de
## piezas al entrar a una sala (ver tile_rain_reveal.gd). Dibuja copias
## exactas de los tiles reales (mismo atlas/región/flip) así que al aterrizar
## es indistinguible del tile real -- que en ese momento se restaura debajo.

var _draws: Array = []

func add_tile(offset: Vector2, texture: Texture2D, region: Rect2, size: Vector2, flip_h: bool = false, flip_v: bool = false) -> void:
	_draws.append({
		"offset": offset,
		"texture": texture,
		"region": region,
		"size": size,
		"flip_h": flip_h,
		"flip_v": flip_v,
	})

func _draw() -> void:
	for d in _draws:
		var rect = Rect2(d.offset - d.size * 0.5, d.size)
		var region: Rect2 = d.region
		if d.flip_h:
			region = Rect2(region.position.x + region.size.x, region.position.y, -region.size.x, region.size.y)
		if d.flip_v:
			region = Rect2(region.position.x, region.position.y + region.size.y, region.size.x, -region.size.y)
		draw_texture_rect_region(d.texture, rect, region)

## Programa la caída: espera "delay", recién ahí limpia las celdas reales de
## "layer" (quedan invisibles/sin colisión un instante breve) y larga la
## caída visual; al aterrizar restaura esas celdas y se autodestruye.
func fall_and_restore(layer: TileMapLayer, saved_cells: Array, delay: float, fall_height: float, duration: float) -> void:
	if _draws.is_empty():
		queue_free()
		return
	queue_redraw()
	var target_pos = global_position
	global_position = target_pos + Vector2(randf_range(-4.0, 4.0), -fall_height)
	rotation = randf_range(-0.03, 0.03)
	z_as_relative = false
	z_index = 100
	visible = false

	get_tree().create_timer(delay).timeout.connect(_start_fall.bind(layer, saved_cells, target_pos, duration))

func _start_fall(layer: TileMapLayer, saved_cells: Array, target_pos: Vector2, duration: float) -> void:
	if not is_instance_valid(self):
		return
	if is_instance_valid(layer):
		for sc in saved_cells:
			layer.set_cell(sc.coords, -1)
	visible = true
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(self, "rotation", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(_land.bind(layer, saved_cells))

func _land(layer: TileMapLayer, saved_cells: Array) -> void:
	if is_instance_valid(layer):
		for sc in saved_cells:
			layer.set_cell(sc.coords, sc.source_id, sc.atlas_coords, sc.alt)
	var t = create_tween()
	t.tween_property(self, "scale", Vector2(1.02, 1.02), 0.03)
	t.chain().tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.chain().tween_callback(queue_free)
