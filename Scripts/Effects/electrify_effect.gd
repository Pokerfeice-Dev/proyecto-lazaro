class_name ElectrifyEffect
extends Node

## Sinergia Relampago: marca a un enemigo como "electrificado" (aturdido +
## daño, con tinte amarillo notorio mientras dura el stun) y hace que el
## efecto salte en cadena a los enemigos cercanos, como el Espiritu
## Electrico de Clash Royale. El tinte usa enemy_base.gd's is_electrified
## (mismo patron que is_frozen_by_ice) para sobrevivir al flash blanco de
## cada golpe; el resto del estado vive en meta + timers, como ignite_effect.gd.

const CHAIN_META_KEY := "electrified_recently"
const CHAIN_RADIUS := 130.0
const CHAIN_DELAY := 0.15
const CHAIN_COOLDOWN := 1.0 # evita que la cadena rebote infinito entre 2 enemigos
const MAX_CHAIN_DEPTH := 8 # limite de seguridad
const STUN_COLOR := Color(2.2, 2.0, 0.2, 1.0)

static func apply_electrify(target: Node, chain_damage: int, stun_duration: float = 0.5, source_pos = null, chain_depth: int = 0) -> void:
	if not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	if target.get("is_dying") == true:
		return
	if target.has_meta(CHAIN_META_KEY):
		return

	target.set_meta(CHAIN_META_KEY, true)
	var cooldown_timer := Timer.new()
	cooldown_timer.wait_time = CHAIN_COOLDOWN
	cooldown_timer.one_shot = true
	target.add_child(cooldown_timer)
	cooldown_timer.timeout.connect(func():
		if is_instance_valid(target):
			target.remove_meta(CHAIN_META_KEY)
		if is_instance_valid(cooldown_timer):
			cooldown_timer.queue_free()
	)
	cooldown_timer.start()

	# El tinte amarillo se activa ANTES del take_damage: asi el flash blanco
	# del golpe decanta en amarillo (_get_flash_target_color ya lo contempla)
	# en vez de volver al color normal del enemigo.
	if "is_electrified" in target:
		target.is_electrified = true
	target.take_damage(chain_damage, false)
	var sprite = target._get_sprite() if target.has_method("_get_sprite") else null
	if sprite and is_instance_valid(sprite):
		sprite.modulate = STUN_COLOR
	if "hit_stun_timer" in target:
		target.hit_stun_timer = max(target.hit_stun_timer, stun_duration)

	var tree = target.get_tree()
	if tree:
		var revert_timer = tree.create_timer(stun_duration)
		revert_timer.timeout.connect(_revert_stun_visual.bind(target))

	_spawn_zap_visual(target)
	_play_zap_sound(target)
	if source_pos != null:
		_spawn_chain_crackle(target, source_pos, target.global_position)

	if chain_depth >= MAX_CHAIN_DEPTH:
		return
	_chain_to_nearby(target, chain_damage, stun_duration, chain_depth)

static func _revert_stun_visual(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if "is_electrified" in target:
		target.is_electrified = false
	if target.has_meta(CHAIN_META_KEY):
		return # todavia en cooldown de cadena: puede volver a electrificarse, no lo despintemos a mitad de otro stun
	var sprite = target._get_sprite() if target.has_method("_get_sprite") else null
	if not sprite or not is_instance_valid(sprite):
		return
	if target.has_method("_get_flash_target_color"):
		sprite.modulate = target._get_flash_target_color()
	elif "_default_modulate" in target:
		sprite.modulate = target._default_modulate

static func _chain_to_nearby(source: Node, chain_damage: int, stun_duration: float, chain_depth: int) -> void:
	if not is_instance_valid(source):
		return
	var tree = source.get_tree()
	if not tree:
		return
	var source_pos: Vector2 = source.global_position
	for enemy in tree.get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or enemy == source:
			continue
		if enemy.has_meta(CHAIN_META_KEY):
			continue
		if enemy.get("is_dying") == true:
			continue
		if source_pos.distance_to(enemy.global_position) > CHAIN_RADIUS:
			continue
		var delay_timer = tree.create_timer(CHAIN_DELAY)
		delay_timer.timeout.connect(apply_electrify.bind(enemy, chain_damage, stun_duration, source_pos, chain_depth + 1))

static func _spawn_zap_visual(target: Node) -> void:
	var tree = target.get_tree()
	if not tree or not tree.current_scene:
		return
	var sparks := CPUParticles2D.new()
	sparks.amount = 10
	sparks.lifetime = 0.3
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.direction = Vector2.UP
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 60.0
	sparks.initial_velocity_max = 150.0
	sparks.damping_min = 120.0
	sparks.damping_max = 200.0
	sparks.scale_amount_min = 1.5
	sparks.scale_amount_max = 3.0
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.add_point(0.4, Color(1.0, 0.9, 0.2, 0.9))
	gradient.set_color(1, Color(0.9, 0.6, 0.0, 0.0))
	sparks.color_ramp = gradient
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = mat
	tree.current_scene.add_child(sparks)
	sparks.global_position = target.global_position
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)

	var ring = load("res://Scripts/Effects/furia_shockwave.gd").new()
	ring.max_radius = 70.0
	ring.speed = 260.0
	ring.set_meta("color_fill", Color(1.0, 0.9, 0.2, 0.35))
	ring.set_meta("color_stroke", Color(1.0, 0.95, 0.6, 0.9))
	tree.current_scene.add_child(ring)
	ring.global_position = target.global_position

static func _play_zap_sound(target: Node) -> void:
	var tree = target.get_tree()
	if not tree or not tree.current_scene:
		return
	var stream_path = "res://Audio/Sfx/Barril/frost.ogg"
	if not ResourceLoader.exists(stream_path):
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = load(stream_path)
	player.bus = "SFX"
	player.pitch_scale = 1.7
	player.volume_db = -3.0
	tree.current_scene.add_child(player)
	player.global_position = target.global_position
	player.play()
	player.finished.connect(player.queue_free)

static func _spawn_chain_crackle(target: Node, from_pos: Vector2, to_pos: Vector2) -> void:
	var tree = target.get_tree()
	if not tree or not tree.current_scene:
		return
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.95, 0.4, 0.9)
	line.z_index = 55
	line.z_as_relative = false
	var mid = (from_pos + to_pos) * 0.5 + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
	line.add_point(from_pos)
	line.add_point(mid)
	line.add_point(to_pos)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	line.material = mat
	tree.current_scene.add_child(line)
	var tw = line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.25)
	tw.tween_callback(line.queue_free)
