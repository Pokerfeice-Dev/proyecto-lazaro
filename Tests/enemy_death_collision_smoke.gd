extends Node2D
class Pilot extends CharacterBody2D:
	var hits := 0
	func take_damage(_amount: int, _source: String, _pos: Vector2) -> void: hits += 1
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _ready() -> void: run.call_deferred()
func run() -> void:
	GameData.event_demo_active = true
	var pilot := Pilot.new()
	add_child(pilot)
	pilot.add_to_group("player")
	var turret = load("res://Scenes/Enemies/EnemyTurret.tscn").instantiate()
	add_child(turret)
	var tank = load("res://Scenes/Enemies/EnemyTank.tscn").instantiate()
	add_child(tank)
	tank.set_physics_process(false)
	turret.set_physics_process(false)
	await get_tree().process_frame
	check(tank.get_collision_exceptions().has(turret) and turret.get_collision_exceptions().has(tank), "Delivery still blocks enemies")
	check(turret.collision_layer == 2, "Delivery cannot receive projectile hits")
	check(tank.get_node("CollisionShape2D2").shape is CapsuleShape2D, "Tank body not capsule")
	var attack := Area2D.new()
	attack.collision_layer = 8
	add_child(attack)
	tank.register_attack(attack)
	tank.current_state = tank.State.ATTACK
	tank.has_damaged_this_attack = false
	tank.target = pilot
	tank.die()
	check(tank.collision_layer == 0 and tank.collision_mask == 0, "Dead tank remains solid")
	check(attack.is_queued_for_deletion() and attack.collision_layer == 0, "Attack survives owner death")
	tank._on_attack_timeout()
	tank._trigger_ground_slam()
	tank._apply_damage_to_area()
	check(pilot.hits == 0, "Dead tank dealt damage")
	var hp: int = tank.current_health
	tank.take_damage(10)
	check(tank.current_health == hp, "Dead enemy still receives hits")
	await get_tree().process_frame
	check(tank.get_node("CollisionShape2D2").disabled, "Tank collider still enabled")
	await get_tree().create_timer(2.0).timeout
	print("ENEMY_DEATH_COLLISION failures=", failures)
	get_tree().quit(failures)
