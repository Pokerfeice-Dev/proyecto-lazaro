extends Node2D
class_name BossAirstrike

@export var delay_before_impact: float = 1.0
@export var damage_radius: float = 55.0
@export var damage: int = 20

var elapsed_time: float = 0.0
var has_exploded: bool = false
var impact_age := 0.0

var explosion_frames: SpriteFrames
var explosion_sprite: AnimatedSprite2D
var explosion_audio: AudioStreamPlayer2D

func _ready() -> void:
	z_index = 5
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	_setup_resources()
	_setup_audio()

func _setup_resources() -> void:
	explosion_frames = SpriteFrames.new()
	explosion_frames.add_animation("explode")
	explosion_frames.set_animation_speed("explode", 14.0)
	explosion_frames.set_animation_loop("explode", false)
	
	for i in range(11):
		var frame_num = str(i).lpad(4, "0")
		var path = "res://Art/Enemy_Boss_1/Fx/frame" + frame_num + ".png"
		var tex = load(path)
		if tex:
			explosion_frames.add_frame("explode", tex)

func _setup_audio() -> void:
	explosion_audio = AudioStreamPlayer2D.new()
	var snd = load("res://Audio/Enemy_snd/Boss1/Explosion.mp3")
	if snd:
		explosion_audio.stream = snd
	explosion_audio.volume_db = -2.0
	explosion_audio.bus = "SFX"
	add_child(explosion_audio)

func _process(delta: float) -> void:
	if has_exploded:
		impact_age += delta
		queue_redraw()
		return
	
	elapsed_time += delta
	queue_redraw()
	
	if elapsed_time >= delay_before_impact:
		_trigger_impact()

func _draw() -> void:
	if has_exploded:
		_draw_blast()
		return
	
	var progress := clampf(elapsed_time / maxf(delay_before_impact, 0.001), 0.0, 1.0)
	var pulse := (sin(elapsed_time * 15.0) + 1.0) * 0.5
	
	var outer_color = Color(1.0, 0.15, 0.15, 0.5 + pulse * 0.3)
	var fill_color = Color(1.0, 0.2, 0.1, 0.25)
	var ring_color = Color(1.0, 0.8, 0.2, 0.8)
	
	# Background fill
	draw_circle(Vector2.ZERO, damage_radius, fill_color)
	
	# Outer warning circle
	draw_arc(Vector2.ZERO, damage_radius, 0, TAU, 32, outer_color, 2.5)
	
	# Countdown shrinking / growing circle
	draw_circle(Vector2.ZERO, damage_radius * progress, Color(1.0, 0.1, 0.1, 0.35))
	draw_arc(Vector2.ZERO, damage_radius * progress, 0, TAU, 32, ring_color, 2.0)
	# El borde fijo representa exactamente el radio de daño.
	# Los segmentos exteriores cuentan el tiempo, sin agrandar la zona peligrosa.
	for i in 12:
		var angle := float(i) * TAU / 12 - PI / 2
		var lit := progress >= float(i + 1) / 12
		var tint := Color("ffe1a1") if lit else Color("b33c68")
		draw_arc(Vector2.ZERO, damage_radius + 6, angle + 0.035, angle + TAU / 12 - 0.035, 3, Color(tint, 0.95 if lit else 0.35), 3)
	for i in 4:
		var dir := Vector2.from_angle(float(i) * PI / 2)
		var side := dir.orthogonal()
		var pos := dir * (damage_radius + 12 - progress * 4)
		draw_polyline(PackedVector2Array([(pos + side * 7 + dir * 4).round(), pos.round(), (pos - side * 7 + dir * 4).round()]), Color("ff785e"), 2)
	var spin := elapsed_time * 3
	draw_arc(Vector2.ZERO, 9 + pulse * 2, spin, spin + PI * 1.4, 8, Color("72ddff"), 2)
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color("fff3ce"), 2)
	draw_line(Vector2(0, -5), Vector2(0, 5), Color("fff3ce"), 2)
	# Cometa descendente durante el tramo final del aviso.
	var fall := clampf((progress - 0.68) / 0.32, 0, 1)
	if fall > 0:
		var head := Vector2(0, -240 * (1 - fall * fall))
		for i in range(10, 0, -1):
			var t := float(i) / 10
			var pos := head + Vector2(sin(elapsed_time * 35 - i) * t * 5, -t * 85)
			var width := 2 + (1 - t) * 7
			var tint := Color("ff6b40").lerp(Color("ba63ff"), t)
			draw_rect(Rect2(pos.round() - Vector2(width, 4), Vector2(width * 2, 10)), Color(tint, (1 - t) * fall))
		draw_circle(head, 12, Color(1, 0.35, 0.5, 0.3 * fall))
		draw_colored_polygon(PackedVector2Array([head + Vector2(0, 10), head + Vector2(-6, -2), head + Vector2(0, -9), head + Vector2(6, -2)]), Color("fff4d5"))

func _draw_blast() -> void:
	var fade := clampf(1 - impact_age / 0.85, 0, 1)
	var hot := Color("ff783e").lerp(Color("cc55ff"), minf(impact_age * 2, 1))
	var flash := maxf(0, 1 - impact_age / 0.13)
	draw_circle(Vector2.ZERO, damage_radius * (0.55 + impact_age * 3), Color(1, 0.85, 0.65, flash * 0.6))
	for i in 3:
		var age := impact_age - i * 0.06
		if age < 0: continue
		var radius := damage_radius * (0.25 + minf(age / 0.4, 1) * (0.85 + i * 0.15))
		var alpha := maxf(0, 1 - age / 0.55)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, Color(hot if i != 1 else Color("86e5ff"), alpha), 3 if i == 0 else 2)
	var count := 14 if OS.has_feature("web") else 22
	for i in count:
		var angle := float(i) * TAU / count + sin(i * 2.7) * 0.15
		var dir := Vector2.from_angle(angle)
		var speed := 65 + fposmod(i * 31.7, 95)
		var pos := dir * speed * impact_age + Vector2(0, impact_age * impact_age * 65)
		var size := 2.0 + float(i % 3)
		draw_line(pos.round(), (pos - dir * 10 * fade).round(), Color(hot, fade * 0.6), 2)
		draw_rect(Rect2(pos.round(), Vector2.ONE * size * fade), Color(Color("a5eaff") if i % 3 == 0 else Color("ffe7b5"), fade))

func _trigger_impact() -> void:
	if has_exploded: return
	has_exploded = true
	queue_redraw()
	_deal_area_damage()
	_spawn_explosion_fx()
	_play_explosion_sound()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.has_method("apply_custom_camera_shake"):
		var strength := 4.0 * clampf(1 - global_position.distance_to(player.global_position) / 600.0, 0, 1)
		if strength > 0.1: player.apply_custom_camera_shake(strength, 0.2)

func _deal_area_damage() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player): return
	
	var dist = global_position.distance_to(player.global_position)
	if dist <= damage_radius and player.has_method("take_damage"):
		player.take_damage(damage, "Mutante Génesis (Misil)")

func _spawn_explosion_fx() -> void:
	explosion_sprite = AnimatedSprite2D.new()
	explosion_sprite.sprite_frames = explosion_frames
	explosion_sprite.scale = Vector2(2.5, 2.5)
	explosion_sprite.use_parent_material = true
	add_child(explosion_sprite)
	
	explosion_sprite.animation_finished.connect(_on_explosion_finished)
	explosion_sprite.play("explode")

func _play_explosion_sound() -> void:
	if explosion_audio:
		explosion_audio.play()

func _on_explosion_finished() -> void:
	var t = create_tween()
	t.tween_interval(0.3)
	t.tween_callback(queue_free)
