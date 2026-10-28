extends Node2D
class Walker extends EnemyBase:
	var goal := Vector2.ZERO
	func _ready() -> void:
		super._ready()
		has_footstep_fx = false
		move_speed = 100
	func _setup_health_bar() -> void: pass
	func _setup_enemy_shadow() -> void: pass
	func process_movement(_delta: float) -> void:
		var offset := goal - global_position
		velocity = offset.normalized() * minf(100, offset.length() * 5)
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameData.event_demo_active = true
	var pilot := CharacterBody2D.new()
	pilot.position = Vector2(1000, 1000)
	add_child(pilot)
	pilot.add_to_group("player")
	for y in [65.0, 295.0]:
		var wall := StaticBody2D.new()
		wall.position = Vector2(300, y)
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(600, 20)
		col.shape = rect
		wall.add_child(col)
		add_child(wall)
	var walkers: Array[Walker] = []
	for team in range(2):
		for i in range(6):
			var walker := Walker.new()
			walker.position = Vector2(100 if team == 0 else 500, 100 + i * 32)
			walker.goal = Vector2(500 if team == 0 else 100, walker.position.y)
			walker.collision_layer = 2
			walker.collision_mask = 7
			var col := CollisionShape2D.new()
			var capsule := CapsuleShape2D.new()
			capsule.radius = 9
			capsule.height = 22
			col.shape = capsule
			walker.add_child(col)
			add_child(walker)
			walkers.append(walker)
	await get_tree().create_timer(6).timeout
	for walker in walkers:
		check(walker.position.distance_to(walker.goal) < 15, "Crowd stuck: " + str(walker.position))
		check(walker.collision_layer == 2 and not walker.get_collision_mask_value(2), "Enemy layer/mask incorrect")
		walker.queue_free()
	await get_tree().process_frame
	pilot.position = Vector2(300, 400)
	var shooter = load("res://Scenes/Enemies/EnemyShooter.tscn").instantiate()
	shooter.position = Vector2(100, 400)
	add_child(shooter)
	shooter.target = pilot
	shooter.player_in_shoot_range = true
	shooter.current_state = shooter.State.SHOOT
	shooter.is_attacking = true
	shooter._on_attack_finished()
	check(shooter.current_state == shooter.State.REPOSITION, "Carpenter did not reposition")
	var start: Vector2 = shooter.position
	await get_tree().create_timer(0.6).timeout
	check(shooter.position.distance_to(start) > 25, "Carpenter stayed planted")
	shooter.queue_free()
	for filename in ["CryptDeathSquad", "CryptLaserEye", "CryptBellKeeper", "CryptFleshBee", "CryptDeadBeekeeperSummoner", "CryptCentipede"]:
		var enemy = load("res://Scenes/Enemies/Crypt/" + filename + ".tscn").instantiate()
		enemy.position = Vector2(100, 400)
		add_child(enemy)
		enemy.target = pilot
		enemy.set_physics_process(false)
		enemy.phase = enemy.Phase.ATTACK
		enemy._next_phase()
		enemy.process_movement(0.016)
		check(enemy.phase == enemy.Phase.RECOVERY and enemy.velocity.length() > 0, "No reposition: " + filename)
		enemy.queue_free()
	await get_tree().process_frame
	print("ENEMY_CROWD_SMOKE failures=", failures)
	get_tree().quit(failures)
