extends CharacterBody2D
class_name EnemyBase

@export var max_health: int = 50
@export var current_health: int = 50
@export var move_speed: float = 150.0
@export var damage: int = 10
@export var attack_speed: float = 1.0

@export var scrap_scene: PackedScene = preload("res://Scenes/UI/scrap.tscn")
@export var scrap_drop_chance: float = 1.0
@export var item_drop_scene: PackedScene = preload("res://Scenes/Items/item_drop_world.tscn")
@export var item_drop_data: ItemData = preload("res://Art/Items/Item1.tres")
@export var item_drop_chance: float = 1.0

var target: Node2D = null
var is_spawning: bool = false
var is_dying: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

signal enemy_died(enemy: EnemyBase)

func _ready() -> void:
	current_health = max_health
	add_to_group("enemy")
	_find_player()
	_setup_health_bar()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	target = players[0]

func _setup_health_bar() -> void:
	var bar = ProgressBar.new()
	bar.max_value = max_health
	bar.value = current_health
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(30, 4)
	bar.position = Vector2(-15, -30)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	sb_bg.corner_radius_top_left = 2
	sb_bg.corner_radius_top_right = 2
	sb_bg.corner_radius_bottom_left = 2
	sb_bg.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("background", sb_bg)
	
	var sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.8, 0.1, 0.1, 0.9)
	sb_fill.corner_radius_top_left = 2
	sb_fill.corner_radius_top_right = 2
	sb_fill.corner_radius_bottom_left = 2
	sb_fill.corner_radius_bottom_right = 2
	bar.add_theme_stylebox_override("fill", sb_fill)
	
	bar.name = "HealthBar"
	add_child(bar)

func spawn_appear() -> void:
	is_spawning = true
	set_physics_process(false)
	_hide_sprite_alpha()
	_play_summon_anim()

func _hide_sprite_alpha() -> void:
	var sprite = _get_sprite()
	if not sprite: return
	sprite.modulate.a = 0.0

func _get_sprite() -> Node2D:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite: sprite = get_node_or_null("Sprite2D")
	return sprite

func _play_summon_anim() -> void:
	var summon_anim = get_node_or_null("Summon_anim")
	if not summon_anim:
		_fade_in_sprite()
		return
	summon_anim.show()
	_safe_play_animated_sprite(summon_anim, "summon")
	summon_anim.animation_finished.connect(_on_summon_finished.bind(summon_anim), CONNECT_ONE_SHOT)

func _on_summon_finished(summon_anim: Node) -> void:
	summon_anim.hide()
	_fade_in_sprite()

func _fade_in_sprite() -> void:
	var sprite = _get_sprite()
	if not sprite:
		_finish_spawn()
		return
	var t = create_tween()
	t.tween_property(sprite, "modulate:a", 1.0, 0.2)
	t.finished.connect(_finish_spawn, CONNECT_ONE_SHOT)

func _finish_spawn() -> void:
	set_physics_process(true)
	is_spawning = false

func _physics_process(delta: float) -> void:
	process_movement(delta)
	
	if knockback_velocity.length() > 5.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10.0 * delta)
		velocity += knockback_velocity
	else:
		knockback_velocity = Vector2.ZERO
		
	move_and_slide()
	handle_collisions()

func apply_knockback(force: float, direction: Vector2) -> void:
	if is_dying: return
	knockback_velocity = direction.normalized() * force

func process_movement(_delta: float) -> void:
	pass # To be overridden by specific enemy types

func take_damage(amount: int, is_crit: bool = false) -> void:
	current_health -= amount
	_show_damage_text(amount, is_crit)
	_flash_red()
	_update_health_bar()
	_check_death()

func _update_health_bar() -> void:
	var bar = get_node_or_null("HealthBar")
	if not bar: return
	var t = create_tween()
	var target_val = maxi(0, current_health)
	t.tween_property(bar, "value", target_val, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_damage_text(amount: int, is_crit: bool) -> void:
	var label = Label.new()
	if is_crit:
		label.text = "¡%d!" % amount
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_outline_color", Color(0.8, 0.2, 0.0))
		label.add_theme_constant_override("outline_size", 4)
	else:
		label.text = str(amount)
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
		label.add_theme_constant_override("outline_size", 3)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(100, 30)
	label.position = Vector2(-50, -15)
	
	var floating_node = Node2D.new()
	floating_node.global_position = global_position + Vector2(randf_range(-15.0, 15.0), -40.0)
	floating_node.add_child(label)
	
	get_tree().current_scene.call_deferred("add_child", floating_node)
	
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	tween.tween_property(floating_node, "global_position", floating_node.global_position + Vector2(0, -40), 0.6).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(floating_node.queue_free)

func _flash_red() -> void:
	var sprite = _get_sprite()
	if not sprite: return
	var original_modulate = sprite.modulate
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func _check_death() -> void:
	if current_health > 0: return
	die()

func die() -> void:
	if is_dying: return
	is_dying = true
	enemy_died.emit(self)
	_attempt_drops()
	_disable_physics()
	_hide_sprite()
	_hide_health_bar()
	_play_death_sound()
	_play_death_fx()

func _hide_health_bar() -> void:
	var bar = get_node_or_null("HealthBar")
	if not bar: return
	bar.hide()

func _attempt_drops() -> void:
	_spawn_scrap()
	_spawn_item()

func _spawn_scrap() -> void:
	if not scrap_scene: return
	if randf() > scrap_drop_chance: return
	var scrap = scrap_scene.instantiate()
	scrap.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", scrap)

func _spawn_item() -> void:
	if not item_drop_scene:
		print("ERROR: item_drop_scene no está asignado.")
		return
	if not item_drop_data:
		print("ERROR: item_drop_data no está asignado en el Inspector. ¡Debes arrastrar el recurso ItemData (no el PNG) al enemigo!")
		return
	if randf() > item_drop_chance: return
	var item_drop = item_drop_scene.instantiate()
	item_drop.item_data = item_drop_data
	item_drop.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", item_drop)
	print("Item instanciado exitosamente.")

func _disable_physics() -> void:
	set_physics_process(false)
	var col = get_node_or_null("CollisionShape2D")
	if not col: return
	col.set_deferred("disabled", true)

func _hide_sprite() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if not sprite: return
	sprite.hide()

func _play_death_sound() -> void:
	var death_sound = get_node_or_null("Death_sound")
	if not death_sound: death_sound = get_node_or_null("DeathSound")
	if not death_sound: return
	if not death_sound.has_method("play"): return
	death_sound.play()

func _play_death_fx() -> void:
	var death_fx = get_node_or_null("Death_fx")
	if not death_fx:
		_check_sound_and_free()
		return
	death_fx.show()
	_safe_play_animated_sprite(death_fx, "death")
	death_fx.animation_finished.connect(_on_death_fx_finished, CONNECT_ONE_SHOT)

func _on_death_fx_finished() -> void:
	queue_free()

func _check_sound_and_free() -> void:
	var ds = get_node_or_null("Death_sound")
	if not ds: ds = get_node_or_null("DeathSound")
	if ds and ds.playing:
		ds.finished.connect(queue_free, CONNECT_ONE_SHOT)
		return
	queue_free()

func handle_collisions() -> void:
	var count = get_slide_collision_count()
	if count == 0: return
	_process_collisions(count)

func _process_collisions(count: int) -> void:
	for i in range(count):
		_check_single_collision(i)

func _check_single_collision(i: int) -> void:
	var collision = get_slide_collision(i)
	var collider = collision.get_collider()
	if not collider: return
	if not collider.is_in_group("player"): return
	if not collider.has_method("take_damage"): return
	collider.take_damage(damage)

func _safe_play_animated_sprite(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if not sprite: return
	if not sprite.sprite_frames: return
	if not sprite.sprite_frames.has_animation(anim_name): return
	sprite.play(anim_name)
