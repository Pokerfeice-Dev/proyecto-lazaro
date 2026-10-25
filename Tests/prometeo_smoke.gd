extends Node2D
class Pilot extends CharacterBody2D:
	var hits := 0
	func take_damage(_amount: int, _source: String, _origin: Vector2) -> void: hits += 1
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func make_boss(pos: Vector2) -> Boss3Prometeo:
	var boss = load("res://Scenes/Enemies/Boss3_Prometeo.tscn").instantiate()
	boss.is_clone = true
	boss.position = pos
	add_child(boss)
	boss.set_physics_process(false)
	boss.state = Boss3Prometeo.State.ATTACKING
	return boss
func run() -> void:
	GameData.event_demo_active = true
	var pilot := Pilot.new()
	pilot.position = Vector2(350, 250)
	add_child(pilot)
	pilot.add_to_group("player")
	var boss := make_boss(Vector2(250, 250))
	boss.target = pilot
	var clone := make_boss(Vector2(600, 250))
	clone.target = pilot
	var warning := PrometeoTelegraph.circle(boss.arsenal, Vector2(300, 250), 100, 5)
	PrometeoTelegraph.circle(clone.arsenal, Vector2(600, 250), 100, 5)
	boss.position.x += 10
	check(warning.global_position == Vector2(300, 250), "Warning moved with owner")
	clone.arsenal.stop_all()
	await get_tree().process_frame
	check(is_instance_valid(warning), "Clone removed original warning")
	boss.arsenal.stop_all()
	var wall := StaticBody2D.new()
	wall.position = Vector2(305, 250)
	wall.collision_layer = 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 160)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	await get_tree().physics_frame
	await get_tree().physics_frame
	boss.arsenal._hit_target_in_radius(boss.position, 200, 22)
	check(pilot.hits == 0, "Melee passed through obstacle")
	check(boss._clamp_travel(Vector2.RIGHT, 150) < 40, "Dash ignored body clearance")
	check(boss.safe_landing(wall.position).distance_to(wall.position) > 20, "Landing inside obstacle")
	boss.arsenal._flame_cone.global_position = boss.global_position
	boss.arsenal._flame_cone.global_rotation = 0
	boss.arsenal._flame_cone._burn_targets()
	check(pilot.hits == 0, "Flame passed through obstacle")
	wall.queue_free()
	await get_tree().physics_frame
	boss.leap_to(Vector2(450, 250), 0.4)
	await get_tree().create_timer(0.1).timeout
	boss._cancel_motion()
	var stopped := boss.position
	await get_tree().create_timer(0.45).timeout
	check(boss.position.distance_to(stopped) < 0.01 and not boss._is_airborne, "Cancelled leap continued")
	boss.arsenal.perform("pistola")
	await get_tree().create_timer(0.1).timeout
	boss.arsenal.stop_all()
	await get_tree().create_timer(0.5).timeout
	check(get_tree().get_nodes_in_group("prometeo_bullet").is_empty(), "Cancelled pistol fired")
	boss.energy_fx.transform_phase(true)
	await get_tree().create_timer(2.2).timeout
	check(boss.energy_fx.empowered and not boss.energy_fx._bolts.is_empty(), "Phase 3 lightning stopped after transformation")
	for i in range(120): boss.energy_fx.burst(boss.global_position, 90)
	check(boss.energy_fx._bolts.size() <= 24 and boss.energy_fx._sparks.size() <= 96 and boss.energy_fx._rings.size() <= 8, "FX buffers exceeded limits")
	boss.energy_fx.stop()
	check(boss.energy_fx._bolts.is_empty() and not boss.energy_fx.empowered, "FX did not stop")
	boss.phase = 3
	for attack in PrometeoArsenal.WEAPONS.keys() + ["espiral"]:
		boss.arsenal.equip(attack if attack != "espiral" else "pistola", false)
		await boss.arsenal.perform(attack)
		check(not boss.arsenal.aim_locked and not boss._is_airborne, "Attack did not finish: " + attack)
		boss._clear_bullets()
	await boss.arsenal.perform_follow_up()
	boss._clear_bullets()
	boss.queue_free()
	clone.queue_free()
	await get_tree().process_frame
	var index := 0
	for id in PrometeoArsenal.WEAPONS:
		for angle in [0.0, PI]:
			var preview := make_boss(Vector2(100 + (index % 6) * 180, 130 + (index / 6) * 220))
			preview.energy_fx.empowered = true
			preview.arsenal.equip(id, false)
			preview.arsenal.aim_angle = angle
			preview.arsenal._update_weapon_transform()
			preview._facing = Vector2.from_angle(angle)
			preview._play_body_animation()
			var label := Label.new()
			label.text = id
			label.position = Vector2(-40, 70)
			preview.add_child(label)
			check(preview.arsenal._muzzle().distance_to(preview.global_position) < 100, "Incorrect muzzle: " + id)
			index += 1
	await get_tree().create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://prometeo_weapons.png")
	print("PROMETEO_TEST failures=", failures)
	get_tree().quit(failures)
