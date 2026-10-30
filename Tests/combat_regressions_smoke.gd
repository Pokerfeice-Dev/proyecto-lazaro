extends Node2D

class ElectricBoss extends Boss1:
	func _ready() -> void:
		set_physics_process(false)
	func take_damage(amount: int, _crit: bool = false) -> void:
		current_health -= amount
	func _get_sprite() -> Node2D:
		return null

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true
	for path in ["boss1", "boss2", "boss3_prometeo"]:
		var boss = load("res://Scripts/Enemies/" + path + ".gd").new()
		var speed: float = boss.move_speed
		boss.freeze_enemy(10.0)
		boss.apply_status_effect("stun")
		boss.apply_status_effect("slow")
		boss.set_speed_modifier("ice_puddle", 0.2)
		check(not boss.is_frozen_by_ice and boss._freeze_timer == null, path + " immune to freeze")
		check(boss.hit_stun_timer == 0.0 and not boss.is_electrified, path + " immune to stun")
		check(boss.move_speed == speed and boss._speed_modifiers.is_empty(), path + " immune to slow")
		boss.free()

	var electric_boss := ElectricBoss.new()
	for marker_name in ["Muzzle_left", "Muzzle_right", "Muzzle_center"]:
		var marker := Marker2D.new()
		marker.name = marker_name
		electric_boss.add_child(marker)
	add_child(electric_boss)
	var boss_health: int = electric_boss.current_health
	ElectrifyEffect.apply_electrify(electric_boss, 2, 1.0)
	check(electric_boss.current_health == boss_health - 2, "Electricity still damages bosses")
	check(electric_boss.hit_stun_timer == 0.0 and not electric_boss.is_electrified, "Electricity cannot stun bosses")

	var enemy := EnemyBase.new()
	enemy._setup_health_bar()
	check(enemy.get_node("HealthBar").material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, "Base bar unshaded")
	enemy.free()

	for barrel_path in ["FireBarrel", "IceBarrel"]:
		for weapon in ["roadkill", "cerberus"]:
			var barrel = load("res://Scenes/Objects/" + barrel_path + ".tscn").instantiate()
			add_child(barrel)
			barrel.position = Vector2(2000, 2000)
			if weapon == "roadkill":
				var bullet = preload("res://Scenes/Projectiles/RoadkillProjectile.tscn").instantiate()
				bullet.enable_trail = false
				add_child(bullet)
				bullet._on_body_entered(barrel)
				check(bullet.is_destroyed and bullet.bounces_left == 3, "Roadkill breaks barrel without wall bounce")
				bullet.queue_free()
			else:
				var stream := FlameStream.new()
				stream._apply_tick_to_body(barrel, 3.0)
				stream.free()
			check(barrel.is_exploding, weapon + " breaks " + barrel_path)
			barrel.queue_free()

	var player := CharacterBody2D.new()
	player.add_to_group("player")
	add_child(player)
	var gargoyle = preload("res://Scenes/Enemies/Crypt/CryptGargoyle.tscn").instantiate()
	add_child(gargoyle)
	check(gargoyle.get_node("HealthBar").material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, "Crypt bar unshaded")
	gargoyle.stone_duration = 0.08
	gargoyle._enter_phase(CryptEnemy.Phase.STONE_WARNING, 0.05)
	gargoyle.apply_status_effect("stun")
	gargoyle.freeze_enemy(0.5)
	gargoyle.freeze_enemy(0.5)
	await get_tree().create_timer(0.25).timeout
	check(gargoyle.phase == CryptEnemy.Phase.RECOVERY, "Stone expires while frozen and stunned")
	check(gargoyle.is_frozen_by_ice, "Freeze still active after stone expires")
	var health: int = gargoyle.current_health
	gargoyle.take_damage(1)
	check(gargoyle.current_health == health - 1, "Gargoyle vulnerable after stone expires")
	check(gargoyle.get_node("PhaseTimer").paused, "Recovery waits for thaw")
	gargoyle.freeze_enemy(0.1)
	await get_tree().create_timer(0.2).timeout
	check(not gargoyle.is_frozen_by_ice, "Repeated freeze expires")
	check(not gargoyle.get_node("PhaseTimer").paused, "Repeated freeze resumes phase timer")
	gargoyle.queue_free()
	player.queue_free()
	await get_tree().create_timer(1.2).timeout
	for audio in find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
	electric_boss.queue_free()
	await get_tree().process_frame
	print("COMBAT_REGRESSIONS_PASS" if failures == 0 else "COMBAT_REGRESSIONS_FAILED: %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
