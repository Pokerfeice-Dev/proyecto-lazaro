extends Node2D
class_name ArenaGenerator

@export var obstacle_scene: PackedScene = preload("res://Scenes/World/Obstacle.tscn")
@export var wall_scene: PackedScene = preload("res://Scenes/World/Wall.tscn")

var tile_size: int = 64
var grid_size: Vector2 = Vector2(20, 15) # Default square size
var active_obstacles: Array = []
var spawn_points: Array = []

func _ready():
	add_to_group("arena_generator")

func generate_arena(type: String):
	_clear_arena()
	
	spawn_points.clear()
	
	match type:
		"square": grid_size = Vector2(20, 20)
		"rectangle": grid_size = Vector2(30, 15)
		"cross": _generate_cross()
		"irregular": _generate_irregular()
		_: grid_size = Vector2(20, 20)
		
	if type in ["square", "rectangle"]:
		_generate_walls(Vector2.ZERO, grid_size)
		_generate_obstacles(Vector2.ZERO, grid_size)
		_find_spawn_points(Vector2.ZERO, grid_size)

func _clear_arena():
	for o in active_obstacles:
		o.queue_free()
	active_obstacles.clear()

func _generate_walls(start: Vector2, end: Vector2):
	if not wall_scene: return
	
	for x in range(start.x - 1, end.x + 1):
		for y in range(start.y - 1, end.y + 1):
			if x == start.x - 1 or x == end.x or y == start.y - 1 or y == end.y:
				var wall = wall_scene.instantiate()
				add_child(wall)
				wall.global_position = Vector2(x * tile_size, y * tile_size)
				active_obstacles.append(wall)

func _generate_obstacles(start: Vector2, end: Vector2):
	if not obstacle_scene: return
	
	var obstacle_count = randi() % int(((end.x - start.x) * (end.y - start.y)) * 0.1) # 10% coverage
	for i in range(obstacle_count):
		var rx = randf_range(start.x + 2, end.x - 2)
		var ry = randf_range(start.y + 2, end.y - 2)
		var obs = obstacle_scene.instantiate()
		add_child(obs)
		obs.global_position = Vector2(rx * tile_size, ry * tile_size)
		active_obstacles.append(obs)

func _find_spawn_points(start: Vector2, end: Vector2):
	for i in range(10): # 10 potential spawn points
		var sx = randf_range(start.x + 1, end.x - 1)
		var sy = randf_range(start.y + 1, end.y - 1)
		spawn_points.append(Vector2(sx * tile_size, sy * tile_size))

func _generate_cross():
	pass # Complex generation logic here, using combined rects
	
func _generate_irregular():
	pass # Cellular automata or drunkard's walk
