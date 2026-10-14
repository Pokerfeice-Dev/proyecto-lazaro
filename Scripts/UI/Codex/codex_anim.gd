extends TextureRect
class_name CodexAnim

## Muestra en el códice la animación idle de un enemigo o NPC, sacada de su
## propia escena (o SpriteFrames), así no hay que duplicar sprites. Si la
## entrada no tiene animación conocida, usa el ícono del códice y lo hace
## flotar un poco para que no quede muerto.
## Bloqueada: queda congelada en el primer cuadro y en silueta.
## Uso: CodexAnim.create("enemies", "follower", 96.0, true)

const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
## "categoría/id" -> [escena o SpriteFrames, animación]
const SOURCES := {
	"enemies/follower": ["res://Scenes/Enemies/EnemyFollower.tscn", "idle"],
	"enemies/shooter": ["res://Scenes/Enemies/EnemyShooter.tscn", "idle"],
	"enemies/tank": ["res://Scenes/Enemies/EnemyTank.tscn", "idle"],
	"enemies/charger": ["res://Scenes/Enemies/Enemy_bee_summon.tscn", "idle"],
	"enemies/spawner": ["res://Scenes/Enemies/EnemySummoner.tscn", "idle"],
	"enemies/boss2": ["res://Scenes/Enemies/Boss2.tscn", "idle_front"],
	"enemies/boss3": ["res://Art/Enemies/Prometeo/prometeo_frames.tres", "idle_down"],
	"npcs/ygor": ["res://Scenes/Ygor/ygor.tscn", "idle"],
	"npcs/victoria": ["res://Scenes/Npc/npc_chatarra.tscn", "idle"],
}
const FLOAT_HEIGHT := 3.0

static var _frames_cache: Dictionary = {}

var _frames: Array = []
var _fps: float = 6.0
var _time: float = 0.0
var _floating: bool = false
var _locked: bool = false

static func create(category: String, id: String, art_size: float, unlocked: bool) -> CodexAnim:
	var anim = CodexAnim.new()
	anim.custom_minimum_size = Vector2(art_size, art_size)
	anim._setup(category, id, unlocked)
	return anim

func _setup(category: String, id: String, unlocked: bool) -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_locked = not unlocked
	var data = _load_frames(category + "/" + id)
	_frames = data.get("frames", [])
	_fps = data.get("fps", 6.0)
	if _frames.is_empty():
		var icon = CodexData.DATA.get(category, {}).get(id, {}).get("icon", null)
		_frames = [UIStyle.trimmed(icon)] if icon else []
		_floating = true
	texture = _frames[0] if not _frames.is_empty() else null
	if _locked:
		var mat = ShaderMaterial.new()
		mat.shader = LOCKED_SHADER
		mat.set_shader_parameter("blur", 1.0)
		mat.set_shader_parameter("phase", fmod(abs(id.hash()) * 0.0001, 1.0))
		material = mat

func _process(delta: float) -> void:
	if _locked or _frames.is_empty(): return
	_time += delta
	if _frames.size() > 1:
		texture = _frames[int(_time * _fps) % _frames.size()]
	if _floating:
		pivot_offset = size / 2.0
		position.y = sin(_time * 2.2) * FLOAT_HEIGHT

# --- Carga de cuadros ---

static func _load_frames(key: String) -> Dictionary:
	if _frames_cache.has(key):
		return _frames_cache[key]
	var out := {}
	if SOURCES.has(key):
		var sf = _find_sprite_frames(SOURCES[key][0], SOURCES[key][1])
		if sf:
			var anim_name = SOURCES[key][1]
			var frames = []
			for i in sf.get_frame_count(anim_name):
				frames.append(sf.get_frame_texture(anim_name, i))
			out = {"frames": frames, "fps": sf.get_animation_speed(anim_name)}
	_frames_cache[key] = out
	return out

static func _find_sprite_frames(path: String, anim_name: String) -> SpriteFrames:
	if not ResourceLoader.exists(path): return null
	var res = load(path)
	if res is SpriteFrames:
		return res if res.has_animation(anim_name) else null
	if not res is PackedScene: return null
	var state = (res as PackedScene).get_state()
	for i in state.get_node_count():
		for j in state.get_node_property_count(i):
			if state.get_node_property_name(i, j) != "sprite_frames": continue
			var sf = state.get_node_property_value(i, j)
			if sf is SpriteFrames and sf.has_animation(anim_name):
				return sf
	return null
