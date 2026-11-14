class_name BodyLayers
extends Node
# Cuerpo de Lázaro por capas: torso, brazo derecho, brazo izquierdo, pierna derecha y pierna izquierda.
# Cada capa es un AnimatedSprite2D hijo del sprite principal que reproduce las mismas animaciones
# y cuadros, pero con la hoja de esa pieza sola. Según el set de la pieza equipada en cada slot
# (Musculoso, Ligero, Canino, Gordo) la capa usa la hoja pintada de ese set; sin set, usa la
# original. El sprite completo sigue existiendo (Art/Player_art/*.png): se usa para el dash y para
# cualquier animación que no esté partida en capas, y es el que leen los efectos (fantasma de dash,
# muerte, llegada). No hay shaders ni tintes: son hojas de arte distintas.
#
# Hojas: res://Art/Player_art/layers/<hoja>/<capa>[_<set>].png, con la misma disposición que la
# hoja completa. Si un día hay arte final por set, se reemplazan esos PNG y no hace falta tocar código.

const LAYER_DIR := "res://Art/Player_art/layers/"
const SETS: Array = ["musculoso", "ligero", "canino", "gordo"]
## Hoja completa -> carpeta de capas. Las hojas de dash no están partidas (se usa el sprite completo).
const SHEET_FOLDERS := {
	"lazaro_idle_spritesheet.png": "idle",
	"lazaro_idle_spritesheet_invert.png": "idle_invert",
	"lazaro_walk_spritesheet.png": "walk",
	"lazaro_walk_spritesheet_invert.png": "walk_invert",
}
## Capa -> slot del que sale su set. Si en el juego se ve el brazo cambiado de lado, intercambia
## ARM_R y ARM_L aquí.
const LAYER_SLOTS := {
	"torso": ItemData.ItemSlot.TORSO,
	"arm_r": ItemData.ItemSlot.ARM_R,
	"arm_l": ItemData.ItemSlot.ARM_L,
	"leg_r": ItemData.ItemSlot.LEG_R,
	"leg_l": ItemData.ItemSlot.LEG_L,
}

## Capas sin slot: no cambian con el equipo (la cabeza siempre se ve original).
const FIXED_LAYERS: Array = ["head"]
## Orden de dibujo: cuerpo primero, extremidades encima.
const LAYER_ORDER: Array = ["torso", "head", "arm_r", "arm_l", "leg_r", "leg_l"]

var _sprite: AnimatedSprite2D
var _equipment: Equipment
var _layers: Dictionary = {}          # capa -> AnimatedSprite2D
var _layer_sets: Dictionary = {}      # capa -> set actual ("" = original)
var _frames_cache: Dictionary = {}    # "capa/set" -> SpriteFrames
var _layered_anims: Dictionary = {}   # animación -> true si todos sus cuadros salen de una hoja partida
var _base_self_modulate: Color = Color.WHITE
var _layers_active: bool = false
# Estado de la última sincronización: si nada cambió, _sync no toca las capas (ahorra setters que redibujan).
var _dirty: bool = true
var _last_anim: StringName = &""
var _last_frame: int = -1
var _last_flip_h: bool = false
var _last_flip_v: bool = false
var _last_offset: Vector2 = Vector2.INF
var _last_centered: bool = true
# Medición temporal (la lee PerfProbe).
static var sync_usec: int = 0
static var sync_calls: int = 0

func _ready() -> void:
	var player := get_parent()
	_sprite = player.get("anim_sprite") as AnimatedSprite2D
	_equipment = player.get_node_or_null("Equipment") as Equipment
	if _sprite == null or _sprite.sprite_frames == null: return
	process_priority = 100
	_base_self_modulate = _sprite.self_modulate
	_scan_layered_animations()
	for layer in LAYER_ORDER:
		var s := AnimatedSprite2D.new()
		s.name = "Layer_" + layer
		s.use_parent_material = true
		s.visible = false
		_sprite.add_child(s)
		_layers[layer] = s
		_layer_sets[layer] = "<sin asignar>"
		if FIXED_LAYERS.has(layer):
			_layer_sets[layer] = ""
			s.sprite_frames = _get_frames(layer, "")
	_sprite.frame_changed.connect(_sync)
	_sprite.animation_changed.connect(_sync)
	if _equipment != null:
		_equipment.equipment_changed.connect(refresh)
	refresh()

func _process(_delta: float) -> void:
	_sync()

# Nombre del set de una pieza, o "" si no pertenece a ninguno.
# Sale de la última palabra del nombre ("Torso Musculoso" -> musculoso, "Piernas Ligeras" -> ligero).
static func get_set_name(item: ItemData) -> String:
	if item == null: return ""
	var words := item.item_name.strip_edges().to_lower().split(" ", false)
	if words.is_empty(): return ""
	var last: String = words[words.size() - 1]
	# Las piernas van en plural femenino ("Piernas Ligeras"): se normaliza a "ligero".
	if last.ends_with("as") or last.ends_with("os"):
		last = last.substr(0, last.length() - 2) + "o"
	return last if SETS.has(last) else ""

func refresh() -> void:
	if _layers.is_empty(): return
	for layer in LAYER_SLOTS:
		var item: ItemData = null
		if _equipment != null:
			item = _equipment.slots.get(LAYER_SLOTS[layer]) as ItemData
		var set_id := get_set_name(item)
		if _layer_sets[layer] == set_id: continue
		_layer_sets[layer] = set_id
		var s: AnimatedSprite2D = _layers[layer]
		s.sprite_frames = _get_frames(layer, set_id)
		_dirty = true
	_sync()

# Recorre las animaciones del sprite principal y anota cuáles salen de hojas partidas en capas.
func _scan_layered_animations() -> void:
	var src := _sprite.sprite_frames
	for anim in src.get_animation_names():
		var ok := src.get_frame_count(anim) > 0
		for i in src.get_frame_count(anim):
			if _folder_of(src.get_frame_texture(anim, i)) == "":
				ok = false
				break
		if ok: _layered_anims[anim] = true

static func _folder_of(tex: Texture2D) -> String:
	var atlas := tex as AtlasTexture
	if atlas == null or atlas.atlas == null: return ""
	return SHEET_FOLDERS.get(atlas.atlas.resource_path.get_file(), "")

# SpriteFrames de una capa: copia de las animaciones del sprite principal con la hoja de la capa.
func _get_frames(layer: String, set_id: String) -> SpriteFrames:
	var key := layer + "/" + set_id
	if _frames_cache.has(key): return _frames_cache[key]
	var src := _sprite.sprite_frames
	var sf := SpriteFrames.new()
	if sf.has_animation("default"): sf.remove_animation("default")
	var file := layer + ("_" + set_id if set_id != "" else "") + ".png"
	var sheet_cache := {}
	for anim in src.get_animation_names():
		sf.add_animation(anim)
		sf.set_animation_loop(anim, src.get_animation_loop(anim))
		sf.set_animation_speed(anim, src.get_animation_speed(anim))
		for i in src.get_frame_count(anim):
			var tex := src.get_frame_texture(anim, i)
			var out: Texture2D = tex
			var folder := _folder_of(tex)
			if folder != "":
				var path := LAYER_DIR + folder + "/" + file
				if not sheet_cache.has(path):
					sheet_cache[path] = load(path) if ResourceLoader.exists(path) else null
				var sheet: Texture2D = sheet_cache[path]
				if sheet != null:
					var at := AtlasTexture.new()
					at.atlas = sheet
					at.region = (tex as AtlasTexture).region
					at.margin = (tex as AtlasTexture).margin
					at.filter_clip = (tex as AtlasTexture).filter_clip
					out = at
			sf.add_frame(anim, out, src.get_frame_duration(anim, i))
	_frames_cache[key] = sf
	return sf

# Copia animación, cuadro, volteo y desplazamiento del sprite principal a las capas.
func _sync() -> void:
	var t0 := Time.get_ticks_usec()
	_do_sync()
	sync_usec += Time.get_ticks_usec() - t0
	sync_calls += 1

func _do_sync() -> void:
	if _sprite == null or _layers.is_empty(): return
	var anim: StringName = _sprite.animation
	var show: bool = _layered_anims.has(anim)
	if show != _layers_active:
		_layers_active = show
		# El sprite completo se oculta solo en su propio dibujo (self_modulate): los hijos y el
		# modulate de daño/curación siguen funcionando.
		var c := _base_self_modulate
		if show: c.a = 0.0
		_sprite.self_modulate = c
		for layer in _layers: (_layers[layer] as AnimatedSprite2D).visible = show
		_dirty = true
	if not show: return
	var frame := _sprite.frame
	if not _dirty and anim == _last_anim and frame == _last_frame and _sprite.flip_h == _last_flip_h and _sprite.flip_v == _last_flip_v and _sprite.offset == _last_offset and _sprite.centered == _last_centered:
		return
	_dirty = false
	_last_anim = anim
	_last_frame = frame
	_last_flip_h = _sprite.flip_h
	_last_flip_v = _sprite.flip_v
	_last_offset = _sprite.offset
	_last_centered = _sprite.centered
	for layer in _layers:
		var s: AnimatedSprite2D = _layers[layer]
		if s.sprite_frames == null: continue
		if s.animation != anim: s.animation = anim
		if s.frame != _sprite.frame: s.frame = _sprite.frame
		s.flip_h = _sprite.flip_h
		s.flip_v = _sprite.flip_v
		s.offset = _sprite.offset
		s.centered = _sprite.centered
