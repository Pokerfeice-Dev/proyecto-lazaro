extends Node2D

var failures := 0

func _ready() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("CRYPT_FAILED: " + message)

func spawn(file: String) -> CryptEnemy:
	var enemy = load("res://Scenes/Enemies/Crypt/" + file + ".tscn").instantiate()
	add_child(enemy)
	enemy.position = Vector2(100, 300)
	enemy.set_physics_process(false)
	enemy.has_detected_player = true
	enemy.flesh_drop_chance = 0.0
	enemy.item_drop_chance = 0.0
	return enemy

func verify() -> void:
	GameData.current_level = 1
	var old_allowed = GameData.get_room_config().allowed_enemies
	GameData.current_level = 2
	var allowed = GameData.get_room_config().allowed_enemies
	check(allowed.size() == 7, "seven crypt types in level two")
	for id in allowed: check(not old_allowed.has(id), "no level one enemies in crypt")
	var room = CombatRoom.new()
	room._build_enemy_pool(allowed)
	check(room.enemy_pool.size() == 7, "crypt scenes populate pool")
	room.free()
	$Player.position = Vector2(320, 300)
	var gargoyle = spawn("CryptGargoyle")
	var before = gargoyle.current_health
	gargoyle._enter_phase(CryptEnemy.Phase.STONE, 2.0)
	gargoyle.take_damage(20)
	check(gargoyle.current_health == before, "stone blocks damage")
	gargoyle._next_phase()
	gargoyle.take_damage(20)
	check(gargoyle.current_health == before - 20, "vulnerable after stone")
	check(gargoyle.all_items.size() == 1 and gargoyle.all_items[0].id == "corazon_petreo", "specific drop")
	gargoyle.queue_free()
	var ghoul = spawn("CryptGhoul")
	$Player.last_dir = "right"
	ghoul.process_movement(0.01)
	var rear_speed = ghoul.velocity.length()
	$Player.last_dir = "left"
	ghoul.process_movement(0.01)
	check(rear_speed > ghoul.velocity.length() * 1.5, "accelerates only when player faces away")
	ghoul.queue_free()
	$Player.position = Vector2(1200, 300)
	var soldier = spawn("CryptDeathSquad")
	soldier._begin_attack()
	check(soldier.phase == CryptEnemy.Phase.ANTICIPATION, "attack starts with anticipation")
	check(get_tree().get_nodes_in_group("crypt_projectile").is_empty(), "no shot during anticipation")
	await get_tree().create_timer(1.05).timeout
	check(get_tree().get_nodes_in_group("crypt_projectile").size() == 3, "three sequential projectiles")
	soldier.queue_free()
	for bullet in get_tree().get_nodes_in_group("crypt_projectile"): bullet.queue_free()
	var eye = spawn("CryptLaserEye")
	$Player.position = Vector2(400, 300)
	eye._begin_attack()
	await get_tree().create_timer(0.7).timeout
	var direction = eye.locked_direction
	$Player.position = Vector2(400, 400)
	eye.process_movement(0.01)
	check(eye.locked_direction == direction, "laser stops tracking before firing")
	var hits = $Player.hits
	eye._enter_phase(CryptEnemy.Phase.ATTACK, 0.4)
	eye._damage_laser()
	check($Player.hits == hits, "lateral dodge avoids laser")
	$Player.position = Vector2(400, 300)
	eye._damage_laser()
	check($Player.hits == hits + 1, "beam hits marked line")
	$Wall.position = Vector2(250, 300)
	await get_tree().physics_frame
	await get_tree().physics_frame
	eye._attack_hit = false
	eye._damage_laser()
	check($Player.hits == hits + 1, "wall blocks laser")
	check(eye._beam_end().x < 251.0, "beam visual stops at wall")
	eye.queue_free()
	var centipede = spawn("CryptCentipede")
	centipede.locked_direction = Vector2.RIGHT
	$Player.position = Vector2(270, 300)
	centipede._apply_poison_in_cone()
	check(not $Player.has_node("CryptPoison"), "wall blocks toxic spray")
	$Wall.position = Vector2(2000, 2000)
	await get_tree().physics_frame
	await get_tree().physics_frame
	$Player.position = Vector2(200, 300)
	centipede._apply_poison_in_cone()
	check($Player.has_node("CryptPoison"), "cone applies poison")
	centipede._apply_poison_in_cone()
	check($Player.get_child_count() == 2, "poison refreshes without stacking")
	hits = $Player.hits
	await get_tree().create_timer(1.1).timeout
	check($Player.hits == hits + 1, "poison ticks")
	$Player.get_node("CryptPoison").duration = 0.1
	$Player.get_node("CryptPoison").refresh(centipede.global_position)
	await get_tree().create_timer(0.2).timeout
	check(not $Player.has_node("CryptPoison"), "poison expires")
	centipede.queue_free()
	var queen = spawn("CryptDeadBeekeeperSummoner")
	queen._enter_phase(CryptEnemy.Phase.ATTACK, 0.4)
	queen._perform_attack()
	queen._perform_attack()
	check(queen._live_summons() == 3, "summon cap respected")
	for bee in queen._summons:
		check(bee.kind == CryptEnemy.Kind.FLESH_BEE, "ranged bee type")
	var bees = queen._summons.duplicate()
	queen.die()
	await get_tree().process_frame
	await get_tree().process_frame
	for bee in bees: check(not is_instance_valid(bee), "queen death removes swarm")
	var bell = spawn("CryptBellKeeper")
	$Player.position = Vector2(450, 300)
	bell._enter_phase(CryptEnemy.Phase.ATTACK, 2.3)
	bell._perform_attack()
	var echoes = get_tree().get_nodes_in_group("crypt_echo")
	check(echoes.size() == 1, "first bell mark")
	var first_position = echoes[0].global_position
	$Player.position = Vector2(450, 450)
	await get_tree().create_timer(0.55).timeout
	echoes = get_tree().get_nodes_in_group("crypt_echo")
	check(echoes.size() == 2, "second bell mark")
	check(echoes[0].global_position == first_position, "echo stays where player was")
	check(echoes[1].global_position == $Player.global_position, "new echo records current position")
	$Player.position = Vector2(700, 450)
	await get_tree().create_timer(0.5).timeout
	check(bell._echoes.size() == 3, "three marks maximum")
	bell.die()
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group("crypt_echo").is_empty(), "death cancels outstanding echoes")
	var mark = load("res://Scenes/Effects/crypt_echo.tscn").instantiate()
	add_child(mark)
	mark.global_position = $Player.global_position
	hits = $Player.hits
	await get_tree().create_timer(0.5).timeout
	check($Player.hits == hits, "echo warning does no damage")
	await get_tree().create_timer(0.6).timeout
	check($Player.hits == hits + 1, "echo detonates after warning")
	GameData.current_level = 1
	check(GameData.get_room_config().allowed_enemies == old_allowed, "level one pool unchanged")
	print("CRYPT_PASS" if failures == 0 else "CRYPT_FAILURES: %d" % failures)
	get_tree().quit(0 if failures == 0 else 1)
