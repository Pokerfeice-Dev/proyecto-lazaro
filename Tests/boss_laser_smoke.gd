extends Node2D

class TestBoss extends Boss1:
	func _ready() -> void:
		damage = 30
		_setup_lasers()
		set_physics_process(false)

class Target extends Node2D:
	var hits := 0
	var shakes := 0
	func take_damage(_amount: int, _source: String, _origin: Vector2) -> void:
		hits += 1
	func apply_custom_camera_shake(_strength: float, _duration: float) -> void:
		shakes += 1

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("LASER_FAILED: " + message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true
	var target := Target.new()
	add_child(target)
	target.add_to_group("player")
	var boss = load("res://Scenes/Enemies/boss1.tscn").instantiate()
	var configured_stream = boss.get_node("Laser_sound").stream
	var configured_pitch: float = boss.get_node("Laser_sound").pitch_scale
	var configured_volume: float = boss.get_node("Laser_sound").volume_db
	boss.set_script(TestBoss)
	add_child(boss)
	boss.position = Vector2(360, 130)
	var wall := StaticBody2D.new()
	wall.collision_layer = 4
	wall.position = Vector2(360, 500)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1000, 20)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	boss.is_laser_active = true
	boss._update_laser_audio_state()
	boss._process_laser_logic(0.35)
	boss._check_laser_damage(target, 0.35)
	check(target.hits == 0 and not boss._laser_firing, "Carga sin daño")
	check(is_equal_approx(boss.laser_angle, PI / 2), "Aviso fijo")
	boss._process_laser_logic(0.41)
	check(boss._laser_firing and target.shakes == 1, "Ignición única")
	check(boss.laser_sound.playing, "Audio sostenido")
	check(boss.laser_sound.stream == configured_stream, "Respeta stream de Laser_sound")
	check(is_equal_approx(boss.laser_sound.pitch_scale, configured_pitch), "Respeta tono de Laser_sound")
	check(is_equal_approx(boss.laser_sound.volume_db, configured_volume), "Respeta volumen de Laser_sound")
	boss.laser_sound.stop()
	boss.laser_sound.finished.emit()
	check(boss.laser_sound.playing, "Repite audio mientras dispara")
	check(boss.left_raycast.get_collider() == wall and boss.right_raycast.get_collider() == wall, "Muros detienen ambos rayos")
	boss._check_laser_damage(target, 0.01)
	boss._check_laser_damage(target, 0.01)
	check(target.hits == 1, "Ambos rayos comparten cooldown")
	boss._process_laser_logic(0.08)
	boss._check_laser_damage(target, 0.08)
	check(target.hits == 1, "Cooldown no se decrementa por rayo")
	boss._process_laser_logic(0.08)
	boss._check_laser_damage(target, 0.08)
	check(target.hits == 2, "Daño vuelve tras intervalo")
	boss.left_laser_line.update_beam(Vector2(-40, 0), Vector2(-180, 380), 1, true, true, Vector2.UP)
	boss.right_laser_line.update_beam(Vector2(40, 0), Vector2(180, 380), 1, true, true, Vector2.UP)
	boss._spawn_projectile_at_angle(Vector2(700, 250), 0.4)
	var comet = get_child(get_child_count() - 1)
	check(is_instance_valid(comet._boss_fx) and not comet.anim_sprite.visible, "Proyectil del jefe activa cometa")
	await get_tree().create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://boss_laser_preview.png")
	comet._explode()
	check(comet._boss_fx.impact_age == 0.0 and not comet.is_physics_processing(), "Impacto detiene cometa")
	boss.is_laser_active = false
	boss._update_laser_audio_state()
	await get_tree().create_timer(0.25).timeout
	check(not boss.laser_sound.playing and not boss.left_laser_line.visible, "Apagado limpia audio y haz")
	boss.laser_sound.finished.emit()
	check(not boss.laser_sound.playing, "No repite audio al apagar")
	boss.is_phase_two = true
	boss.is_laser_active = true
	boss._update_laser_audio_state()
	boss._process_laser_logic(0.76)
	check(is_equal_approx(boss.laser_sound.volume_db, configured_volume) and is_equal_approx(boss.laser_sound.pitch_scale, configured_pitch), "Restaura volumen tras fade y conserva tono en fase dos")
	boss._stop_all_boss_sounds()
	check(not boss._laser_charge_audio.playing and not boss._laser_firing, "Muerte interrumpe carga")
	await get_tree().create_timer(0.3).timeout
	check(not is_instance_valid(comet), "Impacto elimina proyectil y efectos")
	if failures == 0: print("BOSS_LASER_OK")
	get_tree().quit(failures)
