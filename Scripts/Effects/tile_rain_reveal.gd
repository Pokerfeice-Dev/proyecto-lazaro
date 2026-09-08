extends Node
class_name TileRainReveal

## Efecto de "lluvia de tileset": agrupa los tiles usados de un TileMapLayer
## en piezas chicas (chunk_size x chunk_size tiles) y las hace caer del cielo
## una por una, en ola desde "origin" (normalmente player_spawn), igual que
## RoomReveal hace con los props sueltos. Pensado para Floor/Tile_Objects/
## Walls -- no toca TileMapLayers vacíos ni rompe autotile (restaura cada
## celda con su source/atlas/alt exactos, no le pide a Godot que recalcule
## nada).
##
## Ojo: mientras una pieza está en el aire, esa porción de la capa está
## limpia (sin tile, sin colisión) -- la ventana es corta (dura lo mismo que
## el delay + la caída de esa pieza puntual, no toda la sala junta), pero si
## alguien camina justo ahí durante ese instante podría, en teoría, cruzar
## una pared todavía no aterrizada. En la práctica el jugador recién está
## entrando a la sala, así que no debería notarse.

const DEFAULT_CHUNK_SIZE: int = 2
const DEFAULT_WAVE_SPEED: float = 900.0
const DEFAULT_FALL_HEIGHT: float = 90.0
const DEFAULT_FALL_DURATION: float = 0.22

static func reveal_tilemap_layer(layer: TileMapLayer, origin: Vector2, chunk_size: int = DEFAULT_CHUNK_SIZE, wave_speed: float = DEFAULT_WAVE_SPEED, fall_height: float = DEFAULT_FALL_HEIGHT, fall_duration: float = DEFAULT_FALL_DURATION) -> void:
	if not layer or not is_instance_valid(layer): return
	var tile_set = layer.tile_set
	if not tile_set: return
	var cells = layer.get_used_cells()
	if cells.is_empty(): return

	var size = maxi(1, chunk_size)
	var chunks: Dictionary = {}
	for c in cells:
		var key = Vector2i(floori(float(c.x) / size), floori(float(c.y) / size))
		if not chunks.has(key):
			chunks[key] = []
		chunks[key].append(c)

	var parent_for_pieces = layer.get_parent() if layer.get_parent() else layer

	for key in chunks.keys():
		_spawn_chunk(layer, tile_set, chunks[key], origin, wave_speed, fall_height, fall_duration, parent_for_pieces)

static func _spawn_chunk(layer: TileMapLayer, tile_set: TileSet, chunk_cells: Array, origin: Vector2, wave_speed: float, fall_height: float, fall_duration: float, parent_for_pieces: Node) -> void:
	var world_positions: Array = []
	for c in chunk_cells:
		world_positions.append(layer.to_global(layer.map_to_local(c)))

	var center = Vector2.ZERO
	for p in world_positions:
		center += p
	center /= world_positions.size()

	var tile_world_size: Vector2 = Vector2(tile_set.tile_size) * layer.scale

	var chunk = FallingTileChunk.new()
	var saved_cells: Array = []
	for i in range(chunk_cells.size()):
		var coords: Vector2i = chunk_cells[i]
		var source_id = layer.get_cell_source_id(coords)
		if source_id == -1: continue
		var atlas_coords = layer.get_cell_atlas_coords(coords)
		var alt = layer.get_cell_alternative_tile(coords)
		var source = tile_set.get_source(source_id)
		if not (source is TileSetAtlasSource): continue

		var region: Rect2 = Rect2((source as TileSetAtlasSource).get_tile_texture_region(atlas_coords))
		var flip_h = layer.is_cell_flipped_h(coords)
		var flip_v = layer.is_cell_flipped_v(coords)
		var offset = world_positions[i] - center
		chunk.add_tile(offset, (source as TileSetAtlasSource).texture, region, tile_world_size, flip_h, flip_v)
		saved_cells.append({"coords": coords, "source_id": source_id, "atlas_coords": atlas_coords, "alt": alt})

	if saved_cells.is_empty():
		chunk.queue_free()
		return

	parent_for_pieces.add_child(chunk)
	chunk.global_position = center
	chunk.modulate = layer.modulate

	var delay = RoomReveal.delay_from_origin(center, origin, wave_speed)
	chunk.fall_and_restore(layer, saved_cells, delay, fall_height, fall_duration)
