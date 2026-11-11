extends Node2D

class Pilot extends Node2D:
	func _get_equip_stat(_stat: String, _main: bool) -> float: return 0.0

class Target extends Node2D:
	var current_health := 1000.0
	var is_dying := false
	var hits := 0
	var push := Vector2.ZERO
	func take_damage(amount: float, _crit: bool = false) -> void:
		current_health -= amount
		hits += 1
	func apply_knockback(force: float, direction: Vector2) -> void:
		push = direction * force

func _ready() -> void:
	call_deferred("verify")

func verify() -> void:
	var pilot := Pilot.new()
	add_child(pilot)
	pilot.position = Vector2(320, 230)
	var weapon = preload("res://Scenes/Weapon/PacemakerMace.tscn").instantiate()
	pilot.add_child(weapon)
	var enemy := Target.new()
	add_child(enemy)
	enemy.position = pilot.position + Vector2(120, 0)
	enemy.add_to_group("enemy")
	await get_tree().physics_frame
	weapon.attack()
	assert(weapon.armed and weapon.chain == 0)
	await get_tree().create_timer(weapon.period * 0.56).timeout
	# Early input restarts the rhythm without granting a bonus.
	weapon.attack()
	assert(weapon.chain == 0 and weapon._hit_multiplier == 1.0)
	await get_tree().create_timer(weapon.period).timeout
	for count in range(1, 4):
		weapon.attack()
		assert(weapon.chain == (count % 3))
		await get_tree().create_timer(weapon.period * 0.25).timeout
		assert(enemy.hits == count, "one wave hit per swing")
		weapon._on_body_entered(enemy)
		assert(enemy.hits == count, "no duplicate collision damage")
		if count == 3:
			assert(enemy.push.x < 0, "finisher pulls toward focus")
			assert(weapon._hit_multiplier == weapon.contraction_damage)
		await get_tree().create_timer(weapon.period * 0.75).timeout
	assert(enemy.current_health == 807.0, "58 + 58 + 77 damage")
	# A wall blocks both pressure damage and the pull.
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10, 100)
	shape.shape = rectangle
	wall.add_child(shape)
	add_child(wall)
	wall.position = pilot.position + Vector2(90, 0)
	await get_tree().physics_frame
	weapon.remaining = 0
	weapon.attack()
	await get_tree().create_timer(weapon.period * 0.3).timeout
	assert(enemy.hits == 3, "pressure blocked by wall")
	wall.queue_free()
	var before: float = weapon.remaining
	get_tree().paused = true
	await get_tree().create_timer(0.2, true).timeout
	assert(is_equal_approx(before, weapon.remaining), "pause preserves rhythm")
	get_tree().paused = false
	await get_tree().create_timer(weapon.period + 0.3).timeout
	assert(not weapon.armed and weapon.chain == 0, "miss expires chain")
	weapon.attack_speed = 3.0
	weapon.attack()
	assert(weapon.period == 0.42 and weapon.window < weapon.period * 0.25)
	weapon.queue_free()
	await get_tree().process_frame
	print("PACEMAKER_OK: timing, damage, contraction, deduplication, pause, timeout, speed, cleanup")
	get_tree().quit()
