extends RefCounted
class_name CryptEnemyArt

## Lo visual del arte de un enemigo de La Cripta: elegir la animación según la
## dirección, espejar o girar el sprite, flotar, temblar, retroceder, dejar
## estelas y dejar el cadáver al morir. CryptEnemy decide qué pasa; esta clase
## decide cómo se ve.
##
## Nombres de animación: "idle", "walk", "attack_windup", "attack_cone",
## "attack", "hurt", "death", "summon", "petrify", "stone_shield". Si el arte
## tiene versiones por dirección ("walk_down", "walk_side", "walk_up") se elige
## sola la que corresponde.

var enemy: CryptEnemy
var sprite: AnimatedSprite2D
var facing := Vector2.DOWN
var recoil := Vector2.ZERO
var _rest_position := Vector2.ZERO
var _rotation_target := 0.0
var _afterimage_timer := 0.0
var _resume_animation := &""

func _init(owner_enemy: CryptEnemy, art: AnimatedSprite2D) -> void:
	enemy = owner_enemy
	sprite = art
	if sprite:
		_rest_position = sprite.position
		_rotation_target = sprite.rotation

func body() -> Node2D:
	return sprite if sprite else enemy.get_node_or_null("Sprite2D") as Node2D

# --- Animaciones ---

## Reproduce la primera animación de la lista que exista.
func play(names: Array, restart := false) -> void:
	if not sprite or not sprite.sprite_frames: return
	# el golpe recibido termina antes de volver a caminar
	if not restart and sprite.is_playing() and sprite.animation == _resolve(&"hurt"): return
	for base_name in names:
		var resolved := _resolve(base_name)
		if resolved == &"": continue
		if restart or sprite.animation != resolved or not sprite.is_playing():
			sprite.play(resolved)
		return

func has(base_name: StringName) -> bool:
	return sprite != null and sprite.sprite_frames != null and _resolve(base_name) != &""

func walk(velocity: Vector2) -> void:
	if not sprite: return
	if velocity.length_squared() < 1.0:
		play([&"idle"])
		return
	face(velocity)
	play([&"walk", &"idle"])

## Golpe recibido: si el arte tiene "hurt" lo muestra y vuelve a lo que hacía.
func hurt() -> void:
	if not has(&"hurt"): return
	if sprite.animation != _resolve(&"hurt"):
		_resume_animation = sprite.animation
	play([&"hurt"], true)
	if not sprite.animation_finished.is_connected(_after_hurt):
		sprite.animation_finished.connect(_after_hurt)

func _after_hurt() -> void:
	if sprite.animation == _resolve(&"hurt") and _resume_animation != &"":
		sprite.play(_resume_animation)

func _resolve(base_name: StringName) -> StringName:
	var frames := sprite.sprite_frames
	var directed := StringName("%s_%s" % [base_name, _direction_suffix()])
	if frames.has_animation(directed): return directed
	if frames.has_animation(base_name): return base_name
	return &""

func _direction_suffix() -> String:
	if enemy.art_rotates or absf(facing.y) <= absf(facing.x) * 1.2: return "side"
	return "down" if facing.y > 0.0 else "up"

func _is_directional() -> bool:
	return sprite.sprite_frames.has_animation(&"idle_side") or sprite.sprite_frames.has_animation(&"walk_side")

# --- Orientación ---

func face(direction: Vector2) -> void:
	if not sprite or direction.length_squared() < 0.0025: return
	facing = direction.normalized()
	if enemy.art_rotates:
		_rotation_target = facing.angle() - deg_to_rad(enemy.art_forward_degrees)
		return
	if _is_directional() and _direction_suffix() != "side":
		sprite.flip_h = false
		return
	if absf(facing.x) < 0.05: return
	sprite.flip_h = facing.x > 0.0 if enemy.art_faces_left else facing.x < 0.0

# --- Movimiento del cuerpo (flotar, temblar, retroceder, girar) ---

func update(delta: float, time: float, shake: float) -> void:
	var node := body()
	if node == null: return
	var rest := _rest_position if sprite else Vector2.ZERO
	var offset := Vector2(sin(time * 75.0) * 1.5 * shake, sin(time * 6.0) * enemy.hover_amplitude)
	recoil = recoil.lerp(Vector2.ZERO, minf(1.0, 12.0 * delta))
	node.position = rest + offset + recoil
	if sprite and enemy.art_rotates:
		sprite.rotation = lerp_angle(sprite.rotation, _rotation_target, minf(1.0, 14.0 * delta))

## Estela que deja al acelerar (el ghoul cuando le das la espalda).
func afterimages(delta: float, active: bool, tint: Color) -> void:
	if not active: return
	_afterimage_timer -= delta
	if _afterimage_timer > 0.0: return
	_afterimage_timer = 0.07
	_fade(_ghost(tint), 0.28, Vector2.ONE)

# --- Muerte ---

## Deja el cadáver en la sala: si el arte tiene "death" se ve caer; si no, el
## cuerpo se aplasta y se desvanece.
func leave_corpse() -> void:
	var node := body()
	if node == null or not node.visible: return
	if has(&"death"):
		_corpse_with_animation()
	else:
		_fade(_ghost(Color(2.2, 2.2, 2.2, 1.0)), 0.3, Vector2(1.35, 0.35))
	node.hide()

func _corpse_with_animation() -> void:
	var corpse := AnimatedSprite2D.new()
	corpse.sprite_frames = sprite.sprite_frames
	corpse.flip_h = sprite.flip_h
	corpse.texture_filter = sprite.texture_filter
	corpse.offset = sprite.offset
	corpse.z_index = enemy.z_index - 1
	enemy.get_parent().add_child(corpse)
	corpse.global_transform = sprite.global_transform
	corpse.play(_resolve(&"death"))
	var tween := corpse.create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(corpse, "modulate:a", 0.0, 0.6)
	tween.tween_callback(corpse.queue_free)

# Copia quieta del cuadro actual (o del arte provisional), para estelas y muerte.
func _ghost(tint: Color) -> Node2D:
	var source := body()
	var ghost: Node2D
	if sprite:
		var still := Sprite2D.new()
		still.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		still.flip_h = sprite.flip_h
		still.offset = sprite.offset
		still.centered = sprite.centered
		still.texture_filter = sprite.texture_filter
		ghost = still
	else:
		ghost = source.duplicate()
	ghost.modulate = tint
	ghost.z_index = enemy.z_index - 1
	enemy.get_parent().add_child(ghost)
	ghost.global_transform = source.global_transform
	return ghost

func _fade(ghost: Node2D, duration: float, end_scale: Vector2) -> void:
	var tween := ghost.create_tween().set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, duration)
	tween.tween_property(ghost, "scale", ghost.scale * end_scale, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ghost.queue_free)
