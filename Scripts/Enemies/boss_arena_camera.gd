extends Camera2D

## Vista fija de la sala: el jugador y el apuntado no desplazan el encuadre.
var arena_bounds := Rect2()
var maximum_zoom := 1.8

static func begin(previous: Camera2D, boss: Node2D, duration: float) -> void:
	if not is_instance_valid(previous) or not is_instance_valid(boss): return
	var room := boss.get_tree().current_scene
	var floor_layer := room.get_node_or_null("Floor") as TileMapLayer
	if not floor_layer or not floor_layer.tile_set: return
	var cells := floor_layer.get_used_rect()
	if not cells.has_area(): return
	var tile_size := Vector2(floor_layer.tile_set.tile_size)
	var bounds := floor_layer.global_transform * Rect2(Vector2(cells.position) * tile_size, Vector2(cells.size) * tile_size)
	# Margen para el cuerpo del jefe, saltos, sacudidas y la barra de vida.
	bounds = bounds.grow(96.0)
	var camera := new()
	camera.name = "BossArenaCamera"
	camera.arena_bounds = bounds
	camera.maximum_zoom = minf(previous.zoom.x / 1.3 * 0.8, 1.8)
	room.add_child(camera)
	camera.global_position = previous.get_screen_center_position()
	camera.zoom = previous.zoom
	camera.make_current()
	var transition := camera.create_tween().set_parallel(true)
	transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(camera, "global_position", bounds.get_center(), duration)
	transition.tween_property(camera, "zoom", camera.fitted_zoom(), duration)
	transition.chain().tween_callback(func(): camera.get_viewport().size_changed.connect(camera.refit))

func fitted_zoom() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var fit := minf(viewport_size.x / arena_bounds.size.x, viewport_size.y / arena_bounds.size.y)
	return Vector2.ONE * minf(fit, maximum_zoom)

func refit() -> void:
	zoom = fitted_zoom()
