extends Node2D
class_name ObstacleOutline

## Contorno claro alrededor de los obstáculos con colisión de una capa de
## tiles (zona 2: con la niebla de la Cripta no se veía con qué cosa chocabas).
## Se cuelga como hijo de la capa, así usa sus mismas coordenadas y escala.
## Uso: ObstacleOutline.attach(tile_objects_layer)

const LINE_COLOR := Color(0.72, 0.96, 1.0, 0.55)
const FILL_COLOR := Color(0.72, 0.96, 1.0, 0.07)
const LINE_WIDTH := 1.0 # en pixeles del tile (la capa está escalada x2)

var layer: TileMapLayer
var _edges: Array = [] # pares de puntos de los bordes que dan al piso libre
var _cells: Array[Rect2] = []

static func attach(tile_layer: TileMapLayer) -> ObstacleOutline:
	if not tile_layer or tile_layer.get_node_or_null("ObstacleOutline"): return null
	var outline = ObstacleOutline.new()
	outline.name = "ObstacleOutline"
	outline.layer = tile_layer
	tile_layer.add_child(outline)
	return outline

func _ready() -> void:
	z_index = 1 # encima de los tiles, debajo de personajes y balas
	_build()
	queue_redraw()

func _build() -> void:
	var solid := {}
	for cell in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		if data and data.get_collision_polygons_count(0) > 0:
			solid[cell] = true
	var size := Vector2(layer.tile_set.tile_size)
	for cell in solid:
		var origin := layer.map_to_local(cell) - size / 2.0
		_cells.append(Rect2(origin, size))
		# solo los lados que dan a una celda sin obstáculo
		var sides = [
			[Vector2i.UP, origin, origin + Vector2(size.x, 0)],
			[Vector2i.DOWN, origin + Vector2(0, size.y), origin + size],
			[Vector2i.LEFT, origin, origin + Vector2(0, size.y)],
			[Vector2i.RIGHT, origin + Vector2(size.x, 0), origin + size],
		]
		for side in sides:
			if not solid.has(cell + side[0]):
				_edges.append([side[1], side[2]])

func _draw() -> void:
	for rect in _cells:
		draw_rect(rect, FILL_COLOR)
	for edge in _edges:
		draw_line(edge[0], edge[1], LINE_COLOR, LINE_WIDTH)
