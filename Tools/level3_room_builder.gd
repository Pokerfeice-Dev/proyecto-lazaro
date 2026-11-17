@tool
extends RefCounted
# Salas chicas del Núcleo (zona 3, Level3_Room5 a Level3_Room14). Duplica Level3_Room2 (con todo lo
# que trae: script de sala, fondo animado, puerta, Area_entered, Spawns y barriles) y le pone el piso,
# las paredes y los obstáculos que salen de Tools/level3_rooms.json.
#
# El JSON lo genera Tools/room_gen/build.py (Python con Pillow y SciPy). Ahí se definen las formas de
# cada sala: plataformas con el mismo marco que tu Level3_Room3 (borde superior de festones, acantilado
# de raíces, puente entre cámaras), pasillos angostos, fosos, pisos de tres tipos y props del atlas.
# Para cambiar una sala se edita Tools/room_gen/build.py, se corre
#     python Tools/room_gen/build.py --preview tmp/salas
# (deja una imagen por sala en esa carpeta) y después se regeneran las escenas desde el editor:
#     load("res://Tools/level3_room_builder.gd").build_all(true)
#
# Capas: "Floor" lleva el piso y los bordes (frenan cuerpos pero no balas, ver combat_room.gd);
# "Walls" lleva las paredes de verdad (borde superior, acantilados y un anillo de colisión casi
# invisible alrededor de todo el mapa), que sí frenan balas; "Tile_Objects" lleva fosos y props.

const TEMPLATE := "res://Scenes/Rooms/Level3_Room2.tscn"
const OUT_DIR := "res://Scenes/Rooms/"
const DATA := "res://Tools/level3_rooms.json"
const ORIGIN := Vector2i(5, 6)          # celda de arriba a la izquierda (como la sala 2)
const CELL := 32.0                      # 16 px * escala 2 del TileMapLayer

# Tienda de Ygor (las entradas del JSON con "kind": "shop"). Los hologramas van a los mismos desfases
# de Ygor que en la tienda de la cripta; las 3 máquinas las pone ygor.gd solas (Ygor + (-88|0|88, 184)).
const YGOR_SCENE := "res://Scenes/Ygor/ygor.tscn"
const HOLOGRAM_SCENE := "res://Scenes/Ygor/hologram_ygor_store.tscn"
const YGOR_MUSIC := "res://Audio/Music/Ygor_Shop.ogg"
const HOLOGRAM_OFFSETS := [Vector2(-112, 96), Vector2(112, 96), Vector2(144, 256), Vector2(-144, 256)]

static func cell_center(local: Array) -> Vector2:
	var c := ORIGIN + Vector2i(int(local[0]), int(local[1]))
	return Vector2((c.x + 0.5) * CELL, (c.y + 0.5) * CELL)

static func load_specs() -> Array:
	var f := FileAccess.open(DATA, FileAccess.READ)
	if f == null: return []
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Array else []

static func paint(layer: TileMapLayer, cells: Array) -> void:
	layer.clear()
	for c in cells:
		layer.set_cell(ORIGIN + Vector2i(int(c[0]), int(c[1])), 0, Vector2i(int(c[2]), int(c[3])))

static func build_room(spec: Dictionary, overwrite := false) -> String:
	var room_name: String = spec["name"]
	var path := OUT_DIR + room_name + ".tscn"
	if ResourceLoader.exists(path) and not overwrite:
		return room_name + ": ya existe, no se toca"
	var root: Node = (load(TEMPLATE) as PackedScene).instantiate()
	# escena independiente (no heredada de la sala 2): si se toca la sala 2, estas no cambian
	root.scene_file_path = ""
	root.name = "Room_Ygor3" if spec.get("kind", "") == "shop" else room_name.replace("Level3_Room", "Room_")
	# Las capas se reemplazan por capas nuevas con las mismas propiedades: si se borran las
	# celdas de una capa que vino de otra escena, quedan guardadas como "borradas" en el archivo.
	var ground := fresh_layer(root, "Floor")
	var objects := fresh_layer(root, "Tile_Objects")
	var walls := fresh_layer(root, "Walls")
	# la plantilla trae Walls corrida 48 px; aqui las paredes se dibujan en la misma grilla que el piso
	walls.position = Vector2.ZERO
	paint(ground, spec["floor"])
	paint(objects, spec["objects"])
	paint(walls, spec["walls"])
	var spawn_pos := cell_center(spec["player"])
	var player_spawn := root.get_node("player_spawn") as Node2D
	var area := root.get_node("Area_entered") as Node2D
	var area_offset := area.position - player_spawn.position
	player_spawn.position = spawn_pos
	(root.get_node("Door") as Node2D).position = cell_center(spec["door"])
	if spec.get("kind", "") == "shop":
		return _finish_shop(root, spec, path)
	area.position = spawn_pos + area_offset
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
	return room_name + (": guardada (%s)" % spec["title"] if err == OK else ": error al guardar " + str(err))

# Tienda: sin enemigos ni disparador de inicio (se borran Area_entered, Spawns y Barrels de la plantilla),
# con Ygor, sus 4 hologramas y su música, igual que las tiendas de las zonas 1 y 2.
static func _finish_shop(root: Node, spec: Dictionary, path: String) -> String:
	for extra_name in ["Area_entered", "Spawns", "Barrels"]:
		var extra := root.get_node_or_null(extra_name)
		if extra:
			root.remove_child(extra)
			extra.free()
	var ygor_pos := cell_center(spec["ygor"])
	var ygor := (load(YGOR_SCENE) as PackedScene).instantiate() as Node2D
	ygor.name = "Ygor"
	root.add_child(ygor)
	ygor.owner = root
	ygor.position = ygor_pos
	for i in HOLOGRAM_OFFSETS.size():
		var holo := (load(HOLOGRAM_SCENE) as PackedScene).instantiate() as Node2D
		holo.name = "Hologram_Ygor_Store" + ("" if i == 0 else str(i + 1))
		root.add_child(holo)
		holo.owner = root
		holo.position = ygor_pos + HOLOGRAM_OFFSETS[i]
	var music := AudioStreamPlayer.new()
	music.name = "Ygor_music"
	music.stream = load(YGOR_MUSIC)
	music.volume_db = -3.0
	music.autoplay = true
	root.add_child(music)
	music.owner = root
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK: return spec["name"] + ": error al empaquetar " + str(err)
	err = ResourceSaver.save(packed, path)
	return spec["name"] + (": tienda guardada (%s)" % spec["title"] if err == OK else ": error al guardar " + str(err))

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
	var specs := load_specs()
	if specs.is_empty(): return ["No se pudo leer " + DATA]
	for spec in specs:
		out.append(build_room(spec, overwrite))
	return out
