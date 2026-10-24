extends Node2D
## Reconstrucción del frame real, con los mismos fragmentos que pixel_death.
const DURATION := 0.36
enum Style { REVERSE_DEATH, RADIAL, RISE }
var elapsed := 0.0
var _player: Node2D
var _source: AnimatedSprite2D
var _revealed := false
var _texture: Texture2D
var _pieces: Array[Dictionary] = []
var _style := Style.REVERSE_DEATH
static var _arrival_sound: AudioStreamWAV

static func spawn(player: Node2D) -> Node2D:
	var effect := new()
	effect._player = player
	effect._style = player.arrival_pixel_style
	effect._source = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	player.hide()
	player.get_tree().current_scene.add_child(effect)
	effect.z_index = 6
	effect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var energy_material := CanvasItemMaterial.new()
	energy_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	effect.material = energy_material
	effect.add_to_group("player_arrival_fx")
	if not effect._source or not effect._source.sprite_frames:
		effect._reveal_player()
		effect.queue_free()
		return effect
	effect._texture = effect._source.sprite_frames.get_frame_texture(effect._source.animation, effect._source.frame)
	if not effect._texture:
		effect._reveal_player()
		effect.queue_free()
		return effect
	effect.global_transform = effect._source.global_transform
	effect._build_pieces()
	effect._play_sound()
	return effect

func _build_pieces() -> void:
	var dimensions := _texture.get_size()
	var origin := _source.offset
	if _source.centered: origin -= dimensions * 0.5
	var step := maxi(2, ceili(maxf(dimensions.x, dimensions.y) / 16.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 81
	for y in range(0, int(dimensions.y), step):
		for x in range(0, int(dimensions.x), step):
			var piece_size := Vector2(minf(step, dimensions.x - x), minf(step, dimensions.y - y))
			var position_px := Vector2(x, y)
			var dest := position_px + origin
			if _source.flip_h: dest.x = -dest.x - piece_size.x
			if _source.flip_v: dest.y = -dest.y - piece_size.y
			var scatter := Vector2(rng.randf_range(-24, 24), rng.randf_range(-60, -22))
			if _style == Style.RADIAL:
				scatter = (dest + piece_size * 0.5).normalized() * rng.randf_range(25, 50)
			elif _style == Style.RISE:
				scatter = Vector2(rng.randf_range(-10, 10), rng.randf_range(25, 55))
			_pieces.append({"source": Rect2(position_px, piece_size), "dest": Rect2(dest, piece_size),
				"scatter": scatter, "delay": rng.randf_range(0, 0.065)})

func _process(delta: float) -> void:
	elapsed += delta
	if not is_instance_valid(_player) or not is_instance_valid(_source):
		queue_free()
		return
	# La reconstrucción acompaña al jugador si se mueve: no salta del spawn al final.
	global_transform = _source.global_transform
	if elapsed >= DURATION:
		_reveal_player()
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not _texture: return
	for piece in _pieces:
		var delay: float = piece.delay
		var progress := clampf((elapsed - delay) / (DURATION - 0.025 - delay), 0.0, 1.0)
		var remaining := 1.0 - smoothstep(0.0, 1.0, progress)
		var rect: Rect2 = piece.dest
		rect.position += (piece.scatter * remaining).round()
		var shrink := lerpf(0.6, 1.0, progress)
		rect.position += rect.size * (1.0 - shrink) * 0.5
		rect.size *= shrink
		if _source.flip_h: rect.size.x = -rect.size.x
		if _source.flip_v: rect.size.y = -rect.size.y
		var tint := Color.WHITE.lerp(Color(0.45, 1.0, 0.85), remaining * 0.55)
		tint.a = smoothstep(0.0, 0.22, progress)
		draw_texture_rect_region(_texture, rect, piece.source, tint)

func _reveal_player() -> void:
	if _revealed: return
	_revealed = true
	if is_instance_valid(_player) and _player.is_inside_tree() and _player.stats.current_health > 0:
		_player.show()

func _exit_tree() -> void:
	_reveal_player()

func _play_sound() -> void:
	if not _arrival_sound:
		_arrival_sound = AudioStreamWAV.new()
		_arrival_sound.format = AudioStreamWAV.FORMAT_16_BITS
		_arrival_sound.mix_rate = 22050
		var samples := PackedByteArray()
		var count := 7056
		samples.resize(count * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 81
		var noise := 0.0
		var phase := 0.0
		for index in count:
			var t := float(index) / float(count)
			noise = lerpf(noise, rng.randf_range(-1.0, 1.0), 0.22)
			phase += TAU * lerpf(640.0, 150.0, t) / 22050.0
			var envelope := sin(PI * t) * pow(1.0 - t, 1.8)
			var sample := int((noise * 0.6 + sin(phase) * 0.12) * envelope * 18000.0)
			samples.encode_s16(index * 2, sample)
		_arrival_sound.data = samples
	var audio := AudioStreamPlayer2D.new()
	audio.stream = _arrival_sound
	audio.bus = "SFX"
	audio.volume_db = -14.0
	add_child(audio)
	audio.play()


