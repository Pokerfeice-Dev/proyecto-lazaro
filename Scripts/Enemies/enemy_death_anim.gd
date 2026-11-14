class_name EnemyDeathAnim
extends RefCounted
# Muerte animada de los enemigos con sprite propio: reproduce la animación "death" del
# AnimatedSprite2D y, al terminar, se desintegra en píxeles como el resto.
# Es opt-in: el enemigo la llama desde su _spawn_pixel_death() y, si no tiene "death", sigue
# el flujo normal.

const PIXEL_DEATH = preload("res://Scripts/Effects/pixel_death.gd")

static func play(enemy: Node2D) -> bool:
	var sprite := enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null: return false
	if not sprite.sprite_frames.has_animation("death"): return false
	enemy.set_meta("death_anim_playing", true)  # EnemyBase._hide_sprite no oculta mientras dura
	sprite.modulate = Color(1, 1, 1, 1)
	sprite.speed_scale = 1.0
	sprite.visible = true
	sprite.play("death")
	sprite.animation_finished.connect(_on_finished.bind(enemy, sprite), CONNECT_ONE_SHOT)
	return true

static func _on_finished(enemy: Node2D, sprite: AnimatedSprite2D) -> void:
	if not is_instance_valid(sprite): return
	if is_instance_valid(enemy): enemy.set_meta("death_anim_playing", false)
	PIXEL_DEATH.spawn_from(sprite)
	sprite.hide()
