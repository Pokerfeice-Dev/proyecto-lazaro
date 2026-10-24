extends Node2D

const Navigator = preload("res://Scripts/World/enemy_navigation.gd")
var navigator: RefCounted
var failures := 0

class Walker extends EnemyBase:
	func _ready() -> void:
		add_to_group("enemy")
		has_detected_player = true
		move_speed = 140
	func _physics_process(_delta: float) -> void:
		if target and global_position.distance_to(target.global_position) > 18:
			velocity = get_nav_direction_to_target() * move_speed
		else: velocity = Vector2.ZERO
		move_and_slide()

func get_nav_path(start: Vector2, finish: Vector2, radius: float) -> PackedVector2Array:
	return navigator.get_path(start, finish, radius)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("NAV_FAILED: " + message)

func wall(position_value: Vector2, size: Vector2, layer: int) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = position_value
	body.collision_layer = layer
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true
	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(32, 32)
	var source := TileSetAtlasSource.new()
	var bitmap := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	bitmap.fill(Color("18232d"))
	source.texture = ImageTexture.create_from_image(bitmap)
	source.texture_region_size = Vector2i(32, 32)
	source.create_tile(Vector2i.ZERO)
	tiles.add_source(source, 0)
	floor_layer.tile_set = tiles
	for x in 20:
		for y in 15: floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	add_child(floor_layer)
	navigator = Navigator.new(self)
	# Obstáculo cóncavo: la salida requiere alejarse inicialmente del jugador.
	wall(Vector2(300, 240), Vector2(32, 240), 1)
	wall(Vector2(220, 120), Vector2(192, 32), 4)
	wall(Vector2(220, 360), Vector2(192, 32), 4)
	var barrel := wall(Vector2(410, 240), Vector2(40, 50), 4)
	var target := Node2D.new()
	target.position = Vector2(540, 240)
	add_child(target)
	var walkers: Array[Walker] = []
	for i in 3:
		var walker := Walker.new()
		walker.collision_layer = 2
		walker.collision_mask = 7
		walker.position = Vector2(210, 190 + i * 45)
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 8 + i * 2
		collision.shape = shape
		walker.add_child(collision)
		walker.target = target
		add_child(walker)
		walker.set_physics_process(false)
		walkers.append(walker)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var started := Time.get_ticks_msec()
	var path := get_nav_path(walkers[0].position, target.position, 10)
	print("NAV_BUILD_MS: ", Time.get_ticks_msec() - started, " WAYPOINTS: ", path.size())
	check(path.size() > 3, "Ruta alrededor de obstáculo cóncavo")
	check(not walkers[0]._can_walk_segment(Vector2(360, 240), Vector2(470, 240)), "Detecta barril capa 4")
	for walker in walkers: walker.set_physics_process(true)
	for frame in 720: await get_tree().physics_frame
	for walker in walkers:
		check(walker.position.distance_to(target.position) < 65, "Enemigo rodea obstáculo: " + str(walker.position))
	barrel.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(walkers[0]._can_walk_segment(Vector2(360, 240), Vector2(470, 240)), "Paso abierto tras destruir barril")
	for walker in walkers: walker.set_physics_process(false)
	await _check_room_geometry("res://Scenes/Rooms/Level1_Room2.tscn")
	await _check_room_geometry("res://Scenes/Rooms/Level2_Room2.tscn")
	if failures == 0: print("ENEMY_NAVIGATION_OK")
	get_tree().quit(failures)

func _check_room_geometry(path: String) -> void:
	var source = load(path).instantiate()
	var geometry := Node2D.new()
	geometry.position = Vector2(5000, 5000)
	add_child(geometry)
	for child in source.get_children():
		if child is TileMapLayer:
			child.owner = null
			source.remove_child(child)
			geometry.add_child(child)
	source.free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nav := Navigator.new(geometry)
	var floor_layer := geometry.get_node("Floor") as TileMapLayer
	var cells := floor_layer.get_used_cells()
	var begin := Time.get_ticks_msec()
	nav.get_path(floor_layer.to_global(floor_layer.map_to_local(cells[0])), floor_layer.to_global(floor_layer.map_to_local(cells[-1])), 12)
	var graph: AStar2D = nav.caches[12.0].graph
	print("NAV_REAL_ROOM: ", path.get_file(), " points=", graph.get_point_count(), " build_ms=", Time.get_ticks_msec() - begin)
	check(graph.get_point_count() > 50, "Geometría real tiene espacio navegable")
	geometry.queue_free()
	await get_tree().physics_frame
