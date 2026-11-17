class_name CastShadow
extends Node2D
# Sombra proyectada de un personaje: una copia oscura de su cuadro actual, "acostada" en el piso
# y estirada hacia el lado contrario de la lámpara (PointLight2D) más cercana. Cuanto más lejos
# de la luz, más larga y más tenue; fuera del alcance de la luz desaparece.
# La crea CharacterLook; se apaga con Opciones > Efectos > "Sombras proyectadas".
#
# Rendimiento: un sprite extra por personaje (mismo material y textura que el resto, así que el
# motor lo agrupa) y una búsqueda de la luz más cercana entre las registradas. Las luces se
# registran solas al entrar al árbol (no se recorre la escena cada cuadro).

const MAX_ALPHA := 0.42
const MIN_LENGTH := 0.35        # largo de la sombra (escala vertical) pegado a la luz
const MAX_LENGTH := 1.0         # largo en el borde del alcance de la luz
const RANGE_FACTOR := 0.9       # parte del radio de la luz donde todavía se ve la sombra
const RECHECK_FRAMES := 2       # cada cuántos cuadros se recalcula la luz más cercana

static var _lights: Array[PointLight2D] = []
static var _tree_hooked: SceneTree = null
# Fila de los pies (última fila con píxeles) de cada cuadro, para que la sombra salga de los pies
# y no del borde de la celda. Se calcula una sola vez por cuadro y queda guardada.
static var _foot_rows: Dictionary = {}
static var _atlas_images: Dictionary = {}

var source: CanvasItem              # sprite del personaje (AnimatedSprite2D o Sprite2D)
var _mirror: Node2D
var _frame_counter := 0
var _height := 0.0                  # alto del cuadro (para poner el pivote en los pies)

static func _hook_tree(tree: SceneTree) -> void:
	if _tree_hooked == tree: return
	_tree_hooked = tree
	_lights.clear()
	tree.node_added.connect(_on_node_added)
	tree.node_removed.connect(_on_node_removed)
	var stack: Array[Node] = [tree.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is PointLight2D: _register(n)
		stack.append_array(n.get_children())

static func _on_node_added(n: Node) -> void:
	if n is PointLight2D: _register(n)

static func _on_node_removed(n: Node) -> void:
	if n is PointLight2D: _lights.erase(n)

static func _register(light: PointLight2D) -> void:
	if _lights.has(light): return
	# luces del HUD (están dentro de un CanvasLayer) no proyectan sombras en el piso
	var p := light.get_parent()
	while p:
		if p is CanvasLayer: return
		p = p.get_parent()
	_lights.append(light)

func setup(sprite: CanvasItem) -> void:
	source = sprite

func _ready() -> void:
	_hook_tree(get_tree())
	show_behind_parent = true
	z_index = 0
	light_mask = 0
	if source is AnimatedSprite2D:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = (source as AnimatedSprite2D).sprite_frames
		a.centered = true
		_mirror = a
		(source as AnimatedSprite2D).frame_changed.connect(_sync_frame)
		(source as AnimatedSprite2D).animation_changed.connect(_sync_frame)
	elif source is Sprite2D:
		var s := Sprite2D.new()
		s.texture = (source as Sprite2D).texture
		s.hframes = (source as Sprite2D).hframes
		s.vframes = (source as Sprite2D).vframes
		s.region_enabled = (source as Sprite2D).region_enabled
		s.region_rect = (source as Sprite2D).region_rect
		_mirror = s
	else:
		queue_free()
		return
	_mirror.light_mask = 0
	_mirror.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_mirror)
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	_sync_frame()

func _sync_frame() -> void:
	if not is_instance_valid(source) or _mirror == null: return
	var size := Vector2.ZERO
	if source is AnimatedSprite2D:
		var src := source as AnimatedSprite2D
		var m := _mirror as AnimatedSprite2D
		if m.sprite_frames != src.sprite_frames: m.sprite_frames = src.sprite_frames
		if m.animation != src.animation: m.animation = src.animation
		m.frame = src.frame
		m.flip_h = src.flip_h
		var tex := src.sprite_frames.get_frame_texture(src.animation, src.frame) if src.sprite_frames else null
		if tex: size = tex.get_size()
	else:
		var src2 := source as Sprite2D
		var m2 := _mirror as Sprite2D
		m2.texture = src2.texture
		m2.frame = src2.frame
		m2.flip_h = src2.flip_h
		m2.region_rect = src2.region_rect
		if src2.texture:
			size = src2.region_rect.size if src2.region_enabled else src2.texture.get_size() / Vector2(src2.hframes, src2.vframes)
	_height = size.y
	var foot := _height
	if source is AnimatedSprite2D:
		var src3 := source as AnimatedSprite2D
		if src3.sprite_frames:
			foot = _foot_row(src3.sprite_frames.get_frame_texture(src3.animation, src3.frame), _height)
	# pivote en los pies: el cuadro va encima del origen de este nodo, con la fila de los pies
	# (no el borde de la celda) sobre el pivote
	# (el desplazamiento del sprite, si tiene, va en el pivote y no en la copia)
	var sc := (source as Node2D).scale
	var off: Vector2 = source.get("offset") if source.get("offset") is Vector2 else Vector2.ZERO
	_mirror.scale = sc
	var below_center := (foot - _height * 0.5) * sc.y
	_mirror.position = Vector2(0.0, -below_center)
	position = (source as Node2D).position + off * sc + Vector2(0.0, below_center)

func _process(_delta: float) -> void:
	if not is_instance_valid(source):
		queue_free()
		return
	_frame_counter += 1
	if _frame_counter % RECHECK_FRAMES != 0: return
	if source is AnimatedSprite2D:
		_mirror.flip_h = (source as AnimatedSprite2D).flip_h
	var light := _nearest_light()
	var src_visible := source.is_visible_in_tree() and source.modulate.a > 0.05
	if light == null or not src_visible:
		modulate.a = 0.0
		return
	var feet := global_position
	var to_feet := feet - light.global_position
	var dist := to_feet.length()
	var reach := _light_reach(light) * RANGE_FACTOR
	if dist >= reach or reach <= 0.0:
		modulate.a = 0.0
		return
	var t := dist / reach
	var away := to_feet / maxf(dist, 0.001)
	# el "arriba" del sprite (-Y) apunta hacia afuera de la luz
	global_rotation = atan2(away.x, -away.y)
	scale = Vector2(1.0, lerpf(MIN_LENGTH, MAX_LENGTH, t))
	var strength := clampf(light.energy, 0.3, 1.2)
	modulate = Color(0.0, 0.0, 0.0, MAX_ALPHA * strength * pow(1.0 - t, 1.3) * source.modulate.a)

static func _foot_row(tex: Texture2D, fallback: float) -> float:
	if not (tex is AtlasTexture) or (tex as AtlasTexture).atlas == null: return fallback
	var key := tex.get_instance_id()
	if _foot_rows.has(key): return _foot_rows[key]
	var at := tex as AtlasTexture
	var akey := at.atlas.get_instance_id()
	if not _atlas_images.has(akey):
		_atlas_images[akey] = at.atlas.get_image()
	var img: Image = _atlas_images[akey]
	var r := Rect2i(at.region)
	var row := float(r.size.y)
	if img and not img.is_empty():
		var found := false
		for y in range(r.size.y - 1, -1, -1):
			for x in range(r.size.x):
				var px := Vector2i(r.position.x + x, r.position.y + y)
				if px.x < img.get_width() and px.y < img.get_height() and img.get_pixelv(px).a > 0.5:
					row = float(y + 1)
					found = true
					break
			if found: break
	_foot_rows[key] = row
	return row

static func _light_reach(light: PointLight2D) -> float:
	if light.texture == null: return 0.0
	return light.texture.get_width() * 0.5 * light.texture_scale * maxf(light.global_scale.x, 0.01)

func _nearest_light() -> PointLight2D:
	var best: PointLight2D = null
	var best_d := INF
	var here := global_position
	var owner_node := get_parent()
	for l in _lights:
		if not is_instance_valid(l) or not l.enabled or not l.is_visible_in_tree(): continue
		if owner_node and owner_node.is_ancestor_of(l): continue   # su propia luz no le hace sombra
		var d := here.distance_squared_to(l.global_position)
		if d < best_d:
			best_d = d
			best = l
	return best
