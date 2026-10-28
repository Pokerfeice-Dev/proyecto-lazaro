extends RefCounted
## One spatial snapshot per physics frame, shared by every enemy.
const CELL_SIZE := 96.0
static var _frame := -1
static var _tree_id := 0
static var _cells: Dictionary = {}

static func neighbors(actor: Node2D) -> Array:
	var tree := actor.get_tree()
	var frame := Engine.get_physics_frames()
	if frame != _frame or _tree_id != tree.get_instance_id():
		_frame = frame
		_tree_id = tree.get_instance_id()
		_cells.clear()
		for enemy in tree.get_nodes_in_group("enemy"):
			if not is_instance_valid(enemy) or not enemy is CharacterBody2D: continue
			if enemy.get("is_dying") == true or enemy.get("is_spawning") == true: continue
			# Delivery is deliberately passable, not an avoidance obstacle.
			if enemy is Delivery: continue
			var key := Vector2i((enemy.global_position / CELL_SIZE).floor())
			if not _cells.has(key): _cells[key] = []
			_cells[key].append({"body": enemy, "position": enemy.global_position, "velocity": enemy.velocity})
	var center := Vector2i((actor.global_position / CELL_SIZE).floor())
	var result: Array = []
	for x in range(-1, 2):
		for y in range(-1, 2):
			for sample in _cells.get(center + Vector2i(x, y), []):
				if is_instance_valid(sample.body) and sample.body != actor:
					result.append(sample)
	result.sort_custom(func(a, b): return actor.global_position.distance_squared_to(a.position) < actor.global_position.distance_squared_to(b.position))
	if result.size() > 12: result.resize(12)
	return result
