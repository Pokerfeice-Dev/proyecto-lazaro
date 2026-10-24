extends RefCounted
## Rutas compartidas por tamaño de enemigo, calculadas con colisiones reales.
const OBSTACLE_MASK := 5
var room: Node2D
var caches: Dictionary = {}
var _obstacle_check_at := 0
var _obstacle_signature := 0

func _init(owner_room: Node2D) -> void:
	room = owner_room
	for child in room.get_children():
		if child is TileMapLayer:
			child.changed.connect(_invalidate)

func _invalidate() -> void:
	caches.clear()

func _refresh_obstacles() -> void:
	var now := Time.get_ticks_msec()
	if now < _obstacle_check_at: return
	_obstacle_check_at = now + 700
	var state: Array = []
	for body in room.find_children("*", "CollisionObject2D", true, false):
		if body is Area2D or body.is_in_group("player") or body.is_in_group("enemy"): continue
		if body.collision_layer & OBSTACLE_MASK == 0: continue
		state.append([body.get_instance_id(), body.global_transform, body.collision_layer])
		for shape in body.get_children():
			if shape is CollisionShape2D:
				state.append([shape.transform, shape.disabled, shape.shape])
	var signature := hash(state)
	if signature != _obstacle_signature:
		_obstacle_signature = signature
		_invalidate()

static func actor_exclusions(tree: SceneTree) -> Array[RID]:
	var excluded: Array[RID] = []
	for group in ["player", "enemy"]:
		for actor in tree.get_nodes_in_group(group):
			if actor is CollisionObject2D: excluded.append(actor.get_rid())
	return excluded

static func query_for(radius: float, excluded: Array[RID]) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.collision_mask = OBSTACLE_MASK
	query.exclude = excluded
	return query

static func clear_segment(space: PhysicsDirectSpaceState2D, query: PhysicsShapeQueryParameters2D, start: Vector2, finish: Vector2) -> bool:
	query.transform = Transform2D(0, start)
	query.motion = Vector2.ZERO
	if not space.intersect_shape(query, 1).is_empty(): return false
	query.motion = finish - start
	return space.cast_motion(query)[0] >= 0.999

func get_path(start: Vector2, finish: Vector2, radius: float) -> PackedVector2Array:
	var floor_layer := room.get_node_or_null("Floor") as TileMapLayer
	if not floor_layer: return PackedVector2Array()
	var bucket := ceilf(radius / 2.0) * 2.0
	_refresh_obstacles()
	var query := query_for(bucket, actor_exclusions(room.get_tree()))
	var space := room.get_world_2d().direct_space_state
	if not caches.has(bucket):
		caches[bucket] = {"graph": _build_graph(floor_layer, space, query)}
	var graph: AStar2D = caches[bucket].graph
	if graph.get_point_count() == 0: return PackedVector2Array()
	var start_id := _reachable_point(graph, start, space, query)
	var end_id := _reachable_point(graph, finish, space, query)
	if start_id < 0: return PackedVector2Array()
	if end_id < 0: end_id = graph.get_closest_point(finish)
	var path := graph.get_point_path(start_id, end_id)
	if not path.is_empty() and clear_segment(space, query, path[-1], finish): path.append(finish)
	return path

func _reachable_point(graph: AStar2D, position: Vector2, space: PhysicsDirectSpaceState2D, query: PhysicsShapeQueryParameters2D) -> int:
	var nearest := graph.get_closest_point(position)
	if clear_segment(space, query, position, graph.get_point_position(nearest)): return nearest
	var best := -1
	var distance := INF
	for id in graph.get_point_ids():
		var point := graph.get_point_position(id)
		var dist := point.distance_squared_to(position)
		if dist < distance and dist < 128 * 128 and clear_segment(space, query, position, point):
			best = id
			distance = dist
	return best

func _build_graph(floor_layer: TileMapLayer, space: PhysicsDirectSpaceState2D, query: PhysicsShapeQueryParameters2D) -> AStar2D:
	var graph := AStar2D.new()
	var ids: Dictionary = {}
	var tile_size := Vector2(floor_layer.tile_set.tile_size)
	# Cuatro muestras por tile permiten rodear props sin eliminar tiles enteros.
	for cell in floor_layer.get_used_cells():
		for x in 2:
			for y in 2:
				var key := cell * 2 + Vector2i(x, y)
				var point := floor_layer.to_global(floor_layer.map_to_local(cell) + Vector2(x - 0.5, y - 0.5) * tile_size * 0.5)
				query.transform = Transform2D(0, point)
				query.motion = Vector2.ZERO
				if not space.intersect_shape(query, 1).is_empty(): continue
				var id := graph.get_available_point_id()
				graph.add_point(id, point)
				ids[key] = id
	for cell: Vector2i in ids:
		for offset in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1)]:
			var next: Vector2i = cell + offset
			if not ids.has(next): continue
			if offset.x != 0 and offset.y != 0:
				if not ids.has(cell + Vector2i(offset.x, 0)) or not ids.has(cell + Vector2i(0, offset.y)): continue
			if clear_segment(space, query, graph.get_point_position(ids[cell]), graph.get_point_position(ids[next])):
				graph.connect_points(ids[cell], ids[next])
	return graph
