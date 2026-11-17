@tool
extends RefCounted
# Bocetos de salas chicas del Núcleo (zona 3). Duplica Level3_Room2 (con todo lo que trae:
# script de sala, fondo animado, puerta, Area_entered, Spawns y barriles) y le arma un piso nuevo,
# del tamaño de las salas de la zona 1, con obstáculos del mismo tileset.
#
# Se usa desde el editor (por ejemplo con el MCP o un EditorScript):
#     load("res://Tools/level3_room_builder.gd").build_all()
# No pisa salas que ya existan (pasar overwrite = true para regenerarlas a propósito).
#
# Las salas nuevas son BOCETOS: el piso es un rectángulo con el borde de acantilado del tileset y
# los obstáculos son bloques copiados de las salas 1 y 2. Se terminan a mano en el editor.

const TEMPLATE := "res://Scenes/Rooms/Level3_Room2.tscn"
const OUT_DIR := "res://Scenes/Rooms/"
const ORIGIN := Vector2i(5, 6)          # celda de arriba a la izquierda (como la sala 2)
const CELL := 32.0                      # 16 px * escala 2 del TileMapLayer
const INTERIOR := Vector2i(30, 25)

# Borde del piso (mismo esquema que Level3_Room2)
const LEFT := [Vector2i(38, 12), Vector2i(39, 12)]
const RIGHT := [Vector2i(36, 12), Vector2i(37, 12)]
const TOP := [Vector2i(36, 21), Vector2i(37, 21)]
const BOTTOM_1 := [Vector2i(31, 22), Vector2i(32, 22)]
const BOTTOM_2 := [Vector2i(31, 23), Vector2i(32, 23)]

# Bloques de Tile_Objects (origen en el atlas, tamaño en celdas), sacados de las salas 1 y 2
const BLOCKS := {
	"pilar_alto": [Vector2i(0, 40), Vector2i(2, 4)],
	"pilar": [Vector2i(0, 40), Vector2i(2, 2)],
	"maquina": [Vector2i(40, 43), Vector2i(4, 4)],
	"raices": [Vector2i(23, 47), Vector2i(4, 4)],
	"roca": [Vector2i(7, 52), Vector2i(3, 3)],
	"tronco": [Vector2i(16, 41), Vector2i(2, 2)],
	"columna": [Vector2i(45, 55), Vector2i(2, 3)],
	"altar": [Vector2i(0, 76), Vector2i(3, 3)],
}

# Salas: tamaño (con el borde), obstáculos [bloque, columna, fila], spawns y barriles (celdas
# locales). El jugador aparece arriba al centro y la puerta va abajo al centro.
const ROOMS := {
	"Level3_Room5": {"size": Vector2i(18, 14), "nombre": "Pilares",
		"blocks": [["pilar", 4, 4], ["pilar", 12, 4], ["pilar", 4, 8], ["pilar", 12, 8]],
		"spawns": [Vector2i(3, 10), Vector2i(14, 10), Vector2i(9, 6), Vector2i(14, 2)],
		"barrels": [Vector2i(3, 2), Vector2i(14, 6)]},
	"Level3_Room6": {"size": Vector2i(22, 12), "nombre": "Pasillo ancho",
		"blocks": [["altar", 9, 4], ["columna", 4, 3], ["columna", 16, 3]],
		"spawns": [Vector2i(4, 8), Vector2i(17, 8), Vector2i(3, 2), Vector2i(18, 2)],
		"barrels": [Vector2i(2, 5), Vector2i(19, 5)]},
	"Level3_Room7": {"size": Vector2i(14, 18), "nombre": "Zigzag",
		"blocks": [["tronco", 3, 5], ["tronco", 8, 8], ["tronco", 3, 11]],
		"spawns": [Vector2i(10, 5), Vector2i(4, 9), Vector2i(10, 12), Vector2i(5, 14)],
		"barrels": [Vector2i(10, 2), Vector2i(2, 8)]},
	"Level3_Room8": {"size": Vector2i(16, 16), "nombre": "Altar",
		"blocks": [["maquina", 6, 6]],
		"spawns": [Vector2i(3, 4), Vector2i(12, 4), Vector2i(3, 11), Vector2i(12, 11)],
		"barrels": [Vector2i(3, 8), Vector2i(12, 8)]},
	"Level3_Room9": {"size": Vector2i(24, 12), "nombre": "Galería",
		"blocks": [["pilar", 5, 4], ["pilar", 10, 6], ["pilar", 14, 4], ["pilar", 18, 6]],
		"spawns": [Vector2i(3, 8), Vector2i(21, 8), Vector2i(8, 2), Vector2i(17, 2)],
		"barrels": [Vector2i(3, 2), Vector2i(21, 2)]},
	"Level3_Room10": {"size": Vector2i(18, 18), "nombre": "Cuatro rocas",
		"blocks": [["roca", 3, 3], ["roca", 12, 3], ["roca", 3, 11], ["roca", 12, 11]],
		"spawns": [Vector2i(8, 8), Vector2i(4, 8), Vector2i(14, 8), Vector2i(9, 11)],
		"barrels": [Vector2i(6, 6), Vector2i(11, 10)]},
	"Level3_Room11": {"size": Vector2i(20, 14), "nombre": "Carriles",
		"blocks": [["tronco", 5, 4], ["tronco", 13, 4], ["tronco", 9, 7]],
		"spawns": [Vector2i(3, 10), Vector2i(16, 10), Vector2i(16, 2), Vector2i(3, 2)],
		"barrels": [Vector2i(16, 6), Vector2i(3, 6)]},
	"Level3_Room12": {"size": Vector2i(16, 12), "nombre": "Cámara chica",
		"blocks": [["raices", 9, 3]],
		"spawns": [Vector2i(3, 6), Vector2i(4, 9), Vector2i(12, 8)],
		"barrels": [Vector2i(3, 3)]},
	"Level3_Room13": {"size": Vector2i(26, 14), "nombre": "Escombros",
		"blocks": [["altar", 4, 4], ["columna", 19, 3], ["tronco", 10, 7], ["tronco", 16, 8], ["pilar", 22, 8]],
		"spawns": [Vector2i(3, 9), Vector2i(23, 2), Vector2i(8, 10), Vector2i(18, 10), Vector2i(12, 5)],
		"barrels": [Vector2i(2, 2), Vector2i(23, 5)]},
	"Level3_Room14": {"size": Vector2i(20, 16), "nombre": "Encrucijada",
		"blocks": [["pilar_alto", 4, 6], ["pilar_alto", 14, 6], ["maquina", 8, 7]],
		"spawns": [Vector2i(3, 3), Vector2i(16, 3), Vector2i(3, 12), Vector2i(16, 12)],
		"barrels": [Vector2i(6, 4), Vector2i(13, 4)]},
}

static func cell_center(local: Vector2i) -> Vector2:
	var c := ORIGIN + local
	return Vector2((c.x + 0.5) * CELL, (c.y + 0.5) * CELL)

static func paint_floor(ground: TileMapLayer, size: Vector2i) -> void:
	ground.clear()
	var w := size.x
	var h := size.y
	for y in range(h):
		for x in range(w):
			var atlas := Vector2i(-1, -1)
			if y == 0:
				if x >= 1 and x <= w - 2: atlas = TOP[x % 2]
			elif y == h - 2:
				if x >= 1 and x <= w - 2: atlas = BOTTOM_1[x % 2]
			elif y == h - 1:
				if x >= 1 and x <= w - 2: atlas = BOTTOM_2[x % 2]
			elif x == 0: atlas = LEFT[0]
			elif x == 1: atlas = LEFT[1]
			elif x == w - 2: atlas = RIGHT[0]
			elif x == w - 1: atlas = RIGHT[1]
			else: atlas = INTERIOR
			if atlas.x >= 0:
				ground.set_cell(ORIGIN + Vector2i(x, y), 0, atlas)

static func place_block(layer: TileMapLayer, block: String, at: Vector2i) -> void:
	var b: Array = BLOCKS[block]
	var origin: Vector2i = b[0]
	var bsize: Vector2i = b[1]
	for j in range(bsize.y):
		for i in range(bsize.x):
			layer.set_cell(ORIGIN + at + Vector2i(i, j), 0, origin + Vector2i(i, j))

static func build_room(room_name: String, spec: Dictionary, overwrite := false) -> String:
	var path := OUT_DIR + room_name + ".tscn"
	if ResourceLoader.exists(path) and not overwrite:
		return room_name + ": ya existe, no se toca"
	var root: Node = (load(TEMPLATE) as PackedScene).instantiate()
	# escena independiente (no heredada de la sala 2): si se toca la sala 2, estas no cambian
	root.scene_file_path = ""
	root.name = room_name.replace("Level3_Room", "Room_")
	var size: Vector2i = spec["size"]
	# Las capas se reemplazan por capas nuevas con las mismas propiedades: si se borran las
	# celdas de una capa que vino de otra escena, quedan guardadas como "borradas" en el archivo.
	var ground := fresh_layer(root, "Floor")
	var objects := fresh_layer(root, "Tile_Objects")
	fresh_layer(root, "Walls")
	paint_floor(ground, size)
	for b in spec["blocks"]:
		place_block(objects, b[0], Vector2i(b[1], b[2]))
	var spawn_pos := cell_center(Vector2i(size.x / 2, 2))
	var player_spawn := root.get_node("player_spawn") as Node2D
	var area := root.get_node("Area_entered") as Node2D
	var area_offset := area.position - player_spawn.position
	player_spawn.position = spawn_pos
	area.position = spawn_pos + area_offset
	var door := root.get_node("Door") as Node2D
	door.position = cell_center(Vector2i(size.x / 2, size.y - 4))
	# Spawns: se reusan los marcadores de la plantilla y se agregan los que falten
	var spawns := root.get_node("Spawns")
	var wanted: Array = spec["spawns"]
	while spawns.get_child_count() < wanted.size():
		var m := Marker2D.new()
		m.name = "Spawn%d" % (spawns.get_child_count() + 1)
		spawns.add_child(m)
		m.owner = root
	while spawns.get_child_count() > wanted.size():
		var last := spawns.get_child(spawns.get_child_count() - 1)
		spawns.remove_child(last)
		last.free()
	for i in wanted.size():
		(spawns.get_child(i) as Node2D).position = cell_center(wanted[i])
	var barrels := root.get_node("Barrels")
	var bw: Array = spec["barrels"]
	while barrels.get_child_count() > bw.size():
		var lastb := barrels.get_child(barrels.get_child_count() - 1)
		barrels.remove_child(lastb)
		lastb.free()
	for i in barrels.get_child_count():
		(barrels.get_child(i) as Node2D).position = cell_center(bw[i])
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK: return room_name + ": error al empaquetar " + str(err)
	err = ResourceSaver.save(packed, path)
	return room_name + (": guardada (%s, %dx%d)" % [spec["nombre"], size.x, size.y] if err == OK else ": error al guardar " + str(err))

static func fresh_layer(root: Node, layer_name: String) -> TileMapLayer:
	var old := root.get_node_or_null(layer_name) as TileMapLayer
	if old == null: return null
	var layer := TileMapLayer.new()
	for p in old.get_property_list():
		if not (p.usage & PROPERTY_USAGE_STORAGE): continue
		if p.name in ["tile_map_data", "script", "name", "owner", "scene_file_path", "unique_name_in_owner"]: continue
		layer.set(p.name, old.get(p.name))
	layer.name = layer_name
	var idx := old.get_index()
	root.remove_child(old)
	old.free()
	root.add_child(layer)
	root.move_child(layer, idx)
	layer.owner = root
	return layer

static func build_all(overwrite := false) -> Array:
	var out := []
	for room_name in ROOMS.keys():
		out.append(build_room(room_name, ROOMS[room_name], overwrite))
	return out
