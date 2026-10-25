extends Node2D
var failures := 0
var scripts := 0
var rooms := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func scan(path: String) -> void:
	for entry in DirAccess.get_directories_at(path): scan(path + "/" + entry)
	for entry in DirAccess.get_files_at(path):
		if entry.ends_with(".gd"):
			var script = load(path + "/" + entry) as GDScript
			check(script != null and script.can_instantiate(), "Cannot compile " + path + "/" + entry)
			scripts += 1
func run() -> void:
	GameData.event_demo_active = true
	scan("res://Scripts")
	for entry in DirAccess.get_files_at("res://Scenes/Rooms"):
		if not entry.ends_with(".tscn"): continue
		var packed = load("res://Scenes/Rooms/" + entry) as PackedScene
		check(packed != null, "Cannot load room " + entry)
		if not packed: continue
		var room = packed.instantiate()
		check(room != null, "Cannot instantiate room " + entry)
		if room:
			if room.has_method("_setup_spawn_points"):
				room._setup_spawn_points()
				var count: int = room.spawn_points.size()
				room._setup_spawn_points()
				check(room.spawn_points.size() == count, "Duplicate spawns " + entry)
				check(not room.spawn_points.has(room.get_node_or_null("Spawns")), "Container used as spawn " + entry)
			room.free()
		rooms += 1
	var bee := BeeProjectile.new()
	bee.enable_trail = false
	bee.lifetime = 0.05
	add_child(bee)
	await get_tree().create_timer(0.12).timeout
	check(not is_instance_valid(bee) or bee.is_destroyed, "Bee did not expire")
	var compass := EnemyCompass.new()
	add_child(compass)
	compass.set_process(false)
	var enemy := Node2D.new()
	add_child(enemy)
	enemy.add_to_group("enemy")
	check(compass._get_alive_enemies(0.2).has(enemy), "Enemy cache did not populate")
	enemy.free()
	check(compass._get_alive_enemies(0.01).is_empty(), "Freed enemy retained")
	var moved_parent := Node2D.new()
	moved_parent.position = Vector2(200, 200)
	add_child(moved_parent)
	DistortionShockwave.spawn(moved_parent, Vector2(40, 60))
	check(moved_parent.get_child(0).global_position == Vector2(40, 60), "Shockwave misplaced")
	var dust := AmbientDust.new()
	AmbientDust.is_globally_enabled = false
	add_child(dust)
	check(dust.amount == dust.base_amount and not dust.emitting, "Disabled dust was not configured")
	AmbientDust.is_globally_enabled = true
	dust.set_dust_enabled(true)
	check(dust.visible, "Dust did not enable")
	var laser := BossLaserFX.new()
	add_child(laser)
	laser.update_beam(Vector2(80, 180), Vector2(400, 350), 1.0, true, true, Vector2.UP)
	var mesh := laser._distortion_mesh.mesh
	await get_tree().create_timer(0.1).timeout
	check(laser._distortion_mesh.mesh == mesh, "Laser rebuilt mesh")
	laser.stop(true)
	check(not laser._distortion_mesh.visible, "Laser distortion remained visible")
	var p1 := Node2D.new()
	var p2 := Node2D.new()
	add_child(p1)
	add_child(p2)
	GameData.register_player(p1)
	GameData.register_player(p2)
	GameData.unregister_player(p1)
	check(GameData.get_player() == p2, "Old player cleared new player cache")
	GameData.unregister_player(p2)
	p1.free()
	p2.free()
	print("OPTIMIZATION_AUDIT scripts=", scripts, " rooms=", rooms, " failures=", failures)
	get_tree().quit(failures)
