extends CPUParticles2D
class_name AmbientDust

static var is_globally_enabled: bool = true

@export var base_amount: int = 55
@export var base_lifetime: float = 5.5
@export var base_alpha: float = 0.26

var floor_layer: TileMapLayer = null
var time_since_update: float = 0.0
var update_interval: float = 0.75
var last_update_pos: Vector2 = Vector2.INF

func _ready() -> void:
	add_to_group("ambient_dust")
	if not is_globally_enabled:
		visible = false
		emitting = false
		return
		
	top_level = true
	global_position = Vector2.ZERO
	_configure_core_settings()
	_configure_motion_dynamics()
	_configure_scale_curve()
	_configure_color_gradient()
	_configure_render_material()
	_apply_biome_ambient_tint()
	_find_floor_layer()
	_update_visible_tile_points()
	emitting = true

func _process(delta: float) -> void:
	if not is_globally_enabled: return
	time_since_update += delta
	var current_center = _get_camera_or_player_center()
	var dist_moved = current_center.distance_to(last_update_pos)
	if dist_moved > 90.0 or time_since_update >= update_interval:
		time_since_update = 0.0
		_update_visible_tile_points()

func _find_floor_layer() -> void:
	if not get_tree() or not get_tree().current_scene: return
	var scene = get_tree().current_scene
	var floor_node = scene.find_child("Floor", true, false) as TileMapLayer
	if floor_node:
		floor_layer = floor_node
		return
	var nodes = scene.find_children("*", "TileMapLayer", true, false)
	for node in nodes:
		if "floor" in node.name.to_lower():
			floor_layer = node as TileMapLayer
			return

func _get_camera_or_player_center() -> Vector2:
	var viewport = get_viewport()
	if viewport:
		var camera = viewport.get_camera_2d()
		if camera: return camera.global_position
	var parent_2d = get_parent() as Node2D
	if parent_2d: return parent_2d.global_position
	return global_position

func _update_visible_tile_points() -> void:
	if not floor_layer or not is_instance_valid(floor_layer):
		_find_floor_layer()
	if not floor_layer or not is_instance_valid(floor_layer):
		return
		
	var center = _get_camera_or_player_center()
	last_update_pos = center
	var half_view = Vector2(490.0, 290.0)
	var view_rect = Rect2(center - half_view, half_view * 2.0)
	var new_points = _collect_valid_floor_points(view_rect)
	_apply_emission_points(new_points)

func _collect_valid_floor_points(view_rect: Rect2) -> PackedVector2Array:
	var points = PackedVector2Array()
	var min_cell = floor_layer.local_to_map(floor_layer.to_local(view_rect.position))
	var max_cell = floor_layer.local_to_map(floor_layer.to_local(view_rect.end))
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var pt = _get_point_if_tile_valid(Vector2i(x, y))
			if pt != Vector2.INF:
				points.append(pt)
	return points

func _get_point_if_tile_valid(cell: Vector2i) -> Vector2:
	if floor_layer.get_cell_source_id(cell) == -1:
		return Vector2.INF
	var tile_world = floor_layer.to_global(floor_layer.map_to_local(cell))
	var jitter = Vector2(randf_range(-9.0, 9.0), randf_range(-9.0, 9.0))
	return tile_world + jitter

func _apply_emission_points(points: PackedVector2Array) -> void:
	if points.is_empty():
		emitting = false
		return
	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	emission_points = points
	emitting = true

func _configure_core_settings() -> void:
	amount = base_amount
	lifetime = base_lifetime
	preprocess = base_lifetime
	local_coords = false
	z_index = 20
	z_as_relative = false

func _configure_motion_dynamics() -> void:
	direction = Vector2(0.2, -0.6)
	spread = 55.0
	gravity = Vector2(0.0, -1.8)
	initial_velocity_min = 3.0
	initial_velocity_max = 10.0
	damping_min = 1.0
	damping_max = 3.0
	scale_amount_min = 0.8
	scale_amount_max = 2.2

func _configure_scale_curve() -> void:
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.2, 1.0))
	curve.add_point(Vector2(0.75, 0.9))
	curve.add_point(Vector2(1.0, 0.0))
	scale_amount_curve = curve

func _configure_color_gradient() -> void:
	var col = _get_ambient_dust_color()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(col.r, col.g, col.b, 0.0))
	gradient.add_point(0.2, Color(col.r, col.g, col.b, base_alpha))
	gradient.add_point(0.7, Color(col.r * 0.95, col.g * 0.95, col.b * 0.95, base_alpha * 0.8))
	gradient.set_color(1, Color(col.r * 0.9, col.g * 0.9, col.b * 0.9, 0.0))
	color_ramp = gradient

func _configure_render_material() -> void:
	var mat = CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

func _get_ambient_dust_color() -> Color:
	var scene_name = _get_current_scene_name().to_lower()
	if "level2" in scene_name:
		return Color(0.72, 0.95, 0.82)
	if "room16" in scene_name or "space" in scene_name:
		return Color(0.85, 0.89, 1.0)
	if "boss2" in scene_name:
		return Color(0.88, 0.96, 0.65)
	if "shop" in scene_name or "treasure" in scene_name:
		return Color(1.0, 0.92, 0.72)
	if "hub" in scene_name:
		return Color(0.92, 0.92, 0.96)
	return Color(0.96, 0.92, 0.84)

func _get_current_scene_name() -> String:
	if not get_tree(): return ""
	if not get_tree().current_scene: return ""
	return get_tree().current_scene.name

func _apply_biome_ambient_tint() -> void:
	var col = _get_ambient_dust_color()
	modulate = Color(col.r, col.g, col.b, 1.0)

func set_dust_enabled(enabled: bool) -> void:
	visible = enabled
	emitting = enabled

static func toggle_global_dust(tree: SceneTree) -> bool:
	is_globally_enabled = not is_globally_enabled
	_update_all_dust_nodes_in_tree(tree, is_globally_enabled)
	return is_globally_enabled

static func _update_all_dust_nodes_in_tree(tree: SceneTree, enabled: bool) -> void:
	if not tree: return
	var nodes = tree.get_nodes_in_group("ambient_dust")
	for node in nodes:
		var dust = node as AmbientDust
		if not dust: continue
		dust.set_dust_enabled(enabled)
