class_name CharacterLook
extends RefCounted
# Le da volumen a los personajes (jugador, enemigos y NPCs) para que no se vean planos:
#  - "Volumen en personajes": shader compartido (Art/Effects/character_volume.gdshader) con borde
#    de luz, sombra en los pies y reacción a las lámparas de la sala.
#  - "Sombras proyectadas": CastShadow, una sombra que se estira hacia el lado contrario de la
#    lámpara más cercana.
# Las dos cosas se prenden y apagan en vivo desde Opciones > Efectos (GameSettings llama a
# refresh_all). Con calidad Baja las lámparas están apagadas, así que las sombras proyectadas
# no aparecen; el shader sigue (cuesta muy poco).
#
# Uso: CharacterLook.apply(personaje) en su _ready (EnemyBase ya lo hace para todos los enemigos).

const VOLUME_SHADER := preload("res://Art/Effects/character_volume.gdshader")
const GROUP := "character_look"

static var _material: ShaderMaterial = null
static var _player_material: ShaderMaterial = null

static func shared_material(for_player: bool = false) -> ShaderMaterial:
	if for_player:
		if _player_material == null:
			_player_material = ShaderMaterial.new()
			_player_material.shader = VOLUME_SHADER
			# el cuerpo de Lázaro va por capas: cada capa tiene su borde, así que el brillo va más suave
			_player_material.set_shader_parameter("rim_strength", 0.18)
		return _player_material
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = VOLUME_SHADER
	return _material

## Busca el sprite principal del personaje si no se lo pasan.
static func find_sprite(character: Node) -> CanvasItem:
	var s = character.get("anim_sprite")
	if s is AnimatedSprite2D or s is Sprite2D: return s
	if character.has_method("_get_sprite"):
		s = character.call("_get_sprite")
		if s is AnimatedSprite2D or s is Sprite2D: return s
	for c in character.get_children():
		if (c is AnimatedSprite2D or c is Sprite2D) and not (c is DropShadow) and c.visible:
			return c
	return null

static func apply(character: Node2D, sprite: CanvasItem = null, is_player: bool = false) -> void:
	if character == null or not is_instance_valid(character): return
	if sprite == null: sprite = find_sprite(character)
	if sprite == null: return
	character.set_meta("look_sprite", sprite)
	character.set_meta("look_player", is_player)
	if not character.is_in_group(GROUP): character.add_to_group(GROUP)
	_apply_volume(character, FxSettings.on("volumen_personajes"))
	_apply_cast_shadow(character, FxSettings.on("sombras_proyectadas"))

static func _apply_volume(character: Node, enabled: bool) -> void:
	var sprite = character.get_meta("look_sprite", null)
	if not (sprite is CanvasItem) or not is_instance_valid(sprite): return
	var mat := shared_material(bool(character.get_meta("look_player", false)))
	if enabled:
		# no pisa materiales propios (por ejemplo, el del jefe al emerger de la pared)
		if sprite.material == null: sprite.material = mat
	elif sprite.material == mat:
		sprite.material = null

static func _apply_cast_shadow(character: Node, enabled: bool) -> void:
	var existing := character.get_node_or_null("CastShadow")
	if not enabled:
		if existing: existing.queue_free()
		return
	if existing: return
	var sprite = character.get_meta("look_sprite", null)
	if not (sprite is CanvasItem) or not is_instance_valid(sprite): return
	var shadow := CastShadow.new()
	shadow.name = "CastShadow"
	shadow.setup(sprite)
	character.add_child(shadow)
	character.move_child(shadow, 0)

## Lo llama GameSettings cuando se cambia una de las dos opciones.
static func refresh_all(tree: SceneTree) -> void:
	if tree == null: return
	var vol := FxSettings.on("volumen_personajes")
	var cast := FxSettings.on("sombras_proyectadas")
	for c in tree.get_nodes_in_group(GROUP):
		_apply_volume(c, vol)
		_apply_cast_shadow(c, cast)
