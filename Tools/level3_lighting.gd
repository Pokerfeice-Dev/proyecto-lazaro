extends RefCounted
class_name Level3Lighting

## Iluminación del Área 3 (Tierra Maldita), igual que en las zonas 1 y 2:
##  - CanvasModulate oscuro de la sala (el ambiente).
##  - Nodo "Iluminacion" con instancias de Glow_decor (sin colisión):
##      * luces sobre los objetos brillantes que ya están pintados en Tile_Objects
##        (vainas amarillas, corales rosados), y
##      * vainas/corales nuevos cerca de las paredes, repartidos a distancia pareja.
## Edita el .tscn como texto (no re-empaqueta la sala, así no se pierde nada).
## Se puede volver a correr: borra lo que generó antes y lo vuelve a hacer.
## Salas que ya tienen CanvasModulate (p. ej. la de prueba de Prometeo) se saltan.
## Uso desde el editor: print(Level3Lighting.run())

const ROOMS_DIR := "res://Scenes/Rooms/"
const GLOW_SCENE := "res://Scenes/World/Glow_decor.tscn"
const EXT_ID := "glow_decor_1"
const AMBIENT := Color(0.24, 0.17, 0.25)
const MARKER_NODE := "[node name=\"CanvasModulate\" type=\"CanvasModulate\" parent=\".\"]"

# Celdas del atlas de Cursed Land que brillan (cuando están pintadas en Tile_Objects).
const EMITTERS := [
	{"rect": Rect2i(0, 76, 3, 3), "kind": "luz_ambar"}, # vaina amarilla chica
	{"rect": Rect2i(28, 74, 9, 3), "kind": "luz_ambar"}, # vainas amarillas grandes
	{"rect": Rect2i(3, 76, 4, 2), "kind": "luz_rosa"}, # corales rosados chicos
	{"rect": Rect2i(33, 55, 3, 6), "kind": "luz_rosa"}, # coral rosado grande
]
const DECOR_KINDS := [["pod", 0.55], ["coral", 0.30], ["coral_chico", 0.15]]
const MIN_SPACING := 224.0 # px entre luces (el radio de cada una es ~175)
const DOOR_CLEARANCE := 160.0
const SPAWN_CLEARANCE := 64.0

static func run(only: String = "") -> String:
	var report: Array[String] = []
	var files: Array[String] = []
	for f in DirAccess.open(ROOMS_DIR).get_files():
		if f.begins_with("Level3_") and f.ends_with(".tscn") and not f.contains("Prueba"):
			if only == "" or f == only:
				files.append(f)
	files.sort()
	for f in files:
		report.append(_process_room(f))
	return "\n".join(report)

static func _process_room(file: String) -> String:
	var path := ROOMS_DIR + file
	var text := FileAccess.get_file_as_string(path)
	if text.contains(GLOW_SCENE):
		text = _strip_generated(text)
	elif text.contains("CanvasModulate"):
		return file + ": ya tiene CanvasModulate, se omite"

	var packed: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	var room: Node = packed.instantiate()
	var floor_l: TileMapLayer = room.get_node_or_null("Floor")
	var walls_l: TileMapLayer = room.get_node_or_null("Walls")
	var objs_l: TileMapLayer = room.get_node_or_null("Tile_Objects")
	if floor_l == null:
		room.free()
		return file + ": sin capa Floor, se omite"

	var floor_cells := {}
	for c in floor_l.get_used_cells():
		floor_cells[c] = true
	var wall_cells := {}
	if walls_l:
		for c in walls_l.get_used_cells():
			wall_cells[_to_floor_cell(walls_l, c, floor_l)] = true

	# 1) Luces sobre los objetos brillantes ya pintados.
	var taken: Array[Vector2] = []
	var tile_lights: Array = [] # [posición, kind]
	var object_cells := {}
	if objs_l:
		var emit := {} # kind -> {celda: true}
		for c in objs_l.get_used_cells():
			object_cells[_to_floor_cell(objs_l, c, floor_l)] = true
			var ac := objs_l.get_cell_atlas_coords(c)
			for e in EMITTERS:
				if (e["rect"] as Rect2i).has_point(ac):
					if not emit.has(e["kind"]):
						emit[e["kind"]] = {}
					emit[e["kind"]][c] = true
		for kind in emit.keys():
			for cluster in _clusters(emit[kind]):
				var sum := Vector2.ZERO
				for c in cluster:
					sum += _world(objs_l, c)
				var pos: Vector2 = sum / cluster.size()
				tile_lights.append([pos, kind])
				taken.append(pos)

	# 2) Vainas/corales nuevos cerca de las paredes.
	var avoid: Array = [] # [posición, radio]
	for child in room.get_children():
		if child.name.begins_with("Door") and child is Node2D:
			avoid.append([(child as Node2D).position, DOOR_CLEARANCE])
		elif child.name == "player_spawn" and child is Node2D:
			avoid.append([(child as Node2D).position, DOOR_CLEARANCE])
		elif child.name == "Spawns" or child.name == "Barrels":
			for m in child.get_children():
				if m is Node2D:
					avoid.append([(m as Node2D).position, SPAWN_CLEARANCE])

	var blocked := {}
	for c in wall_cells.keys():
		blocked[c] = true
	for c in object_cells.keys():
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				blocked[c + Vector2i(dx, dy)] = true

	var near: Array[Vector2] = []
	var far: Array[Vector2] = []
	for c in floor_cells.keys():
		if blocked.has(c):
			continue
		var d := _edge_distance(c, floor_cells, wall_cells)
		if d != 2 and d != 3:
			continue
		var pos := _world(floor_l, c) + Vector2(0.0, 10.0)
		var ok := true
		for a in avoid:
			if pos.distance_to(a[0]) < float(a[1]):
				ok = false
				break
		if ok:
			(near if d == 2 else far).append(pos)

	var rng := RandomNumberGenerator.new()
	rng.seed = file.hash()
	var count: int = floor_cells.size()
	var target: int = clampi(roundi(count / 45.0), 3, 8)
	if count > 1000:
		target = clampi(roundi(count / 110.0), 8, 16)
	var wanted: int = maxi(target - tile_lights.size(), 2)

	var candidates: Array[Vector2] = near.duplicate()
	if candidates.size() < wanted * 3:
		candidates.append_array(far)
	_shuffle(candidates, rng)

	var decor: Array = [] # [posición, kind]
	for i in wanted:
		var best := Vector2.INF
		var best_score := -1.0
		for cand in candidates:
			var min_d := INF
			for t in taken:
				min_d = minf(min_d, cand.distance_to(t))
			if min_d < MIN_SPACING:
				continue
			if min_d > best_score:
				best_score = min_d
				best = cand
		if best == Vector2.INF:
			break
		taken.append(best)
		decor.append([best, _pick_kind(rng)])

	room.free()

	# 3) Escribir el .tscn.
	var block := MARKER_NODE + "\ncolor = Color(%.3f, %.3f, %.3f, 1)\n\n" % [AMBIENT.r, AMBIENT.g, AMBIENT.b]
	block += "[node name=\"Iluminacion\" type=\"Node2D\" parent=\".\"]\n\n"
	var n := 1
	for tl in tile_lights:
		block += _node_text("Glow_tile_%d" % n, tl[0], tl[1])
		n += 1
	n = 1
	for dc in decor:
		block += _node_text("Glow_%d" % n, dc[0], dc[1])
		n += 1

	var lines := text.split("\n")
	lines.insert(1, "[ext_resource type=\"PackedScene\" path=\"%s\" id=\"%s\"]" % [GLOW_SCENE, EXT_ID])
	var out := "\n".join(lines).strip_edges(false, true) + "\n\n" + block
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(out)
	f.close()
	return "%s: suelo=%d, luces en objetos=%d, vainas/corales nuevos=%d" % [file, count, tile_lights.size(), decor.size()]

static func _node_text(node_name: String, pos: Vector2, kind: String) -> String:
	var s := "[node name=\"%s\" parent=\"Iluminacion\" instance=ExtResource(\"%s\")]\n" % [node_name, EXT_ID]
	s += "position = Vector2(%d, %d)\n" % [roundi(pos.x), roundi(pos.y)]
	if kind != "pod":
		s += "kind = \"%s\"\n" % kind
	return s + "\n"

static func _strip_generated(text: String) -> String:
	var idx := text.find(MARKER_NODE)
	if idx >= 0:
		text = text.substr(0, idx)
	var kept := PackedStringArray()
	for l in text.split("\n"):
		if not l.contains(GLOW_SCENE):
			kept.append(l)
	return "\n".join(kept).strip_edges(false, true) + "\n"

static func _world(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	return layer.transform * layer.map_to_local(cell)

static func _to_floor_cell(layer: TileMapLayer, cell: Vector2i, floor_l: TileMapLayer) -> Vector2i:
	return floor_l.local_to_map(floor_l.transform.affine_inverse() * _world(layer, cell))

# Distancia (en celdas, hasta 3) al borde: una celda sin suelo o con pared.
static func _edge_distance(c: Vector2i, floor_cells: Dictionary, wall_cells: Dictionary) -> int:
	for r in range(1, 4):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var o := c + Vector2i(dx, dy)
				if not floor_cells.has(o) or wall_cells.has(o):
					return r
	return 99

# Grupos de celdas vecinas (8 direcciones).
static func _clusters(cells: Dictionary) -> Array:
	var seen := {}
	var result: Array = []
	for start in cells.keys():
		if seen.has(start):
			continue
		var group: Array[Vector2i] = []
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var cur: Vector2i = stack.pop_back()
			group.append(cur)
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var o := cur + Vector2i(dx, dy)
					if cells.has(o) and not seen.has(o):
						seen[o] = true
						stack.append(o)
		result.append(group)
	return result

static func _pick_kind(rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	var acc := 0.0
	for entry in DECOR_KINDS:
		acc += float(entry[1])
		if r <= acc:
			return entry[0]
	return "pod"

static func _shuffle(arr: Array[Vector2], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
