extends Node2D

var destination := ""

func _ready() -> void:
	var packed = load(destination) as PackedScene
	if not packed: return
	# No se ejecutan scripts de la sala: sólo se copian sus capas visuales.
	var source = packed.instantiate()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(160, 160)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var scenery := Node2D.new()
	viewport.add_child(scenery)
	_copy_tiles(source, scenery, Transform2D.IDENTITY)
	var camera := Camera2D.new()
	var spawn = source.get_node_or_null("player_spawn") as Node2D
	camera.position = spawn.position if spawn else Vector2.ZERO
	camera.zoom = Vector2(0.45, 0.45)
	viewport.add_child(camera)
	source.free()
	var picture := Sprite2D.new()
	picture.texture = viewport.get_texture()
	picture.scale = Vector2(0.42, 0.55)
	picture.position = Vector2(0, -25)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://Art/Effects/portal_surface.gdshader")
	picture.material = mat
	add_child(picture)

func _copy_tiles(node: Node, target: Node2D, parent_transform: Transform2D) -> void:
	var transform_here := parent_transform
	if node is Node2D: transform_here = parent_transform * node.transform
	if node is TileMapLayer:
		var copy := TileMapLayer.new()
		copy.tile_set = node.tile_set
		copy.tile_map_data = node.tile_map_data
		copy.transform = transform_here
		copy.collision_enabled = false
		copy.navigation_enabled = false
		target.add_child(copy)
	for child in node.get_children():
		_copy_tiles(child, target, transform_here)
