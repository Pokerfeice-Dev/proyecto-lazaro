class_name WeaponFx
extends RefCounted
# Efectos animados de las armas (estelas de corte, estocadas, chispas de impacto, fogonazos...).
# Las tiras están en Art/Effects/WeaponFX/ y se cortan en cuadros al vuelo, así que para agregar o
# cambiar un efecto basta con tocar el PNG y su fila en STRIPS. Todo es de un solo uso: el nodo se
# borra solo al terminar la animación.

const DIR := "res://Art/Effects/WeaponFX/"

# nombre → [tamaño de cuadro, cantidad de cuadros, cuadros por segundo]
const STRIPS := {
	"slash_trail": [Vector2i(96, 96), 6, 24.0],
	"thrust_streak": [Vector2i(72, 32), 5, 26.0],
	"spin_ring": [Vector2i(96, 96), 6, 24.0],
	"hit_spark": [Vector2i(32, 32), 5, 30.0],
	"muzzle_flash": [Vector2i(40, 28), 4, 36.0],
	"muzzle_flash_big": [Vector2i(64, 48), 4, 32.0],
	"dust_ring": [Vector2i(64, 32), 5, 20.0],
}

static var _frames_cache: Dictionary = {}
static var _casing_texture: Texture2D = null

static func frames_for(fx_name: String) -> SpriteFrames:
	if _frames_cache.has(fx_name):
		return _frames_cache[fx_name]
	if not STRIPS.has(fx_name):
		return null
	var path := DIR + fx_name + ".png"
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	if tex == null:
		return null
	var info: Array = STRIPS[fx_name]
	var size: Vector2i = info[0]
	var frames := SpriteFrames.new()
	frames.add_animation("play")
	frames.set_animation_loop("play", false)
	frames.set_animation_speed("play", info[2])
	for i in int(info[1]):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * size.x, 0, size.x, size.y)
		frames.add_frame("play", at)
	_frames_cache[fx_name] = frames
	return frames

## Reproduce un efecto como hijo de `host` y devuelve el nodo (o null si falta el arte).
## `origin_left`: el cuadro nace en el borde izquierdo (estocadas y fogonazos apuntan a +x).
static func play(host: Node, fx_name: String, pos: Vector2, rot: float = 0.0, fx_scale: Vector2 = Vector2.ONE,
		flip_h: bool = false, origin_left: bool = false, z: int = 1, speed_mult: float = 1.0) -> AnimatedSprite2D:
	if host == null or not is_instance_valid(host):
		return null
	var frames := frames_for(fx_name)
	if frames == null:
		return null
	var info: Array = STRIPS[fx_name]
	var size: Vector2i = info[0]
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = frames
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.speed_scale = speed_mult
	sp.z_index = z
	sp.position = pos
	sp.rotation = rot
	sp.scale = fx_scale
	sp.flip_h = flip_h
	if origin_left:
		sp.centered = false
		sp.offset = Vector2(0.0, -size.y * 0.5)
	sp.animation_finished.connect(sp.queue_free)
	host.add_child(sp)
	sp.play("play")
	return sp

## Igual que play(), pero en el mundo (no sigue a nadie): chispas, polvo.
static func play_world(tree: SceneTree, fx_name: String, world_pos: Vector2, rot: float = 0.0,
		fx_scale: Vector2 = Vector2.ONE, z: int = 20) -> AnimatedSprite2D:
	if tree == null or tree.current_scene == null:
		return null
	var sp := play(tree.current_scene, fx_name, Vector2.ZERO, rot, fx_scale, false, false, z)
	if sp:
		sp.global_position = world_pos
	return sp

## Copia fugaz del sprite del arma (imagen residual): da la sensación de velocidad del golpe.
static func ghost(source: Node2D, host: Node, behind: bool = false, tint: Color = Color(1.0, 0.86, 0.55, 0.55), life: float = 0.16) -> void:
	if source == null or host == null or not is_instance_valid(source) or not is_instance_valid(host):
		return
	var tex: Texture2D = null
	if source is Sprite2D:
		tex = (source as Sprite2D).texture
	elif source is AnimatedSprite2D:
		var a := source as AnimatedSprite2D
		if a.sprite_frames:
			tex = a.sprite_frames.get_frame_texture(a.animation, a.frame)
	if tex == null:
		return
	var g := Sprite2D.new()
	g.texture = tex
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.centered = (source as Sprite2D).centered if source is Sprite2D else true
	g.modulate = tint
	host.add_child(g)
	g.global_transform = source.global_transform
	g.show_behind_parent = behind
	var tw := g.create_tween()
	tw.tween_property(g, "modulate:a", 0.0, life)
	tw.tween_callback(g.queue_free)

## Casquillo que sale disparado y cae (decoración).
static func casing(tree: SceneTree, world_pos: Vector2, aim_dir: Vector2, strength: float = 1.0) -> void:
	if tree == null or tree.current_scene == null:
		return
	if _casing_texture == null:
		var img := Image.create(3, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 0.77, 0.18, 1.0))
		img.set_pixel(0, 0, Color(1.0, 0.95, 0.6, 1.0))
		_casing_texture = ImageTexture.create_from_image(img)
	var s := Sprite2D.new()
	s.texture = _casing_texture
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = 15
	tree.current_scene.add_child(s)
	s.global_position = world_pos
	var side := aim_dir.rotated(PI * 0.5 * (1.0 if randf() < 0.5 else -1.0))
	var vel := side * randf_range(35.0, 70.0) * strength + Vector2(0.0, randf_range(-90.0, -55.0))
	var dur := randf_range(0.38, 0.5)
	var start := world_pos
	var tw := s.create_tween()
	tw.tween_method(_casing_step.bind(s, start, vel), 0.0, dur, dur)
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.tween_callback(s.queue_free)

static func _casing_step(t: float, s: Sprite2D, start: Vector2, vel: Vector2) -> void:
	if not is_instance_valid(s):
		return
	s.global_position = start + vel * t + Vector2(0.0, 120.0 * t * t)
	s.rotation = t * 14.0
