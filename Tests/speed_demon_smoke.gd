extends Node2D

class Pilot extends CharacterBody2D:
	var _speed_demon_driver: Node2D
	var is_cutscene_frozen := false
	var is_dashing := false
	var drive_time := 0.0
	var attack_bonus := 2.0
	func _get_equip_stat(stat: String, _main: bool) -> float: return attack_bonus if stat == "attack_speed" else 0.0
	func get_aim_position() -> Vector2: return global_position + Vector2(100, 0)
	func begin_speed_demon_drive(_driver: Node2D, _direction: Vector2, duration: float) -> void: drive_time = duration
	func end_speed_demon_drive(_driver: Node2D) -> void: drive_time = 0
	func apply_custom_camera_shake(_strength: float, _duration: float) -> void: pass

class Victim extends CharacterBody2D:
	var current_health := 200
	var is_dying := false
	var hits := 0
	func take_damage(amount: int, _crit: bool = false) -> void:
		hits += 1
		current_health -= amount
		is_dying = current_health <= 0

var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("SPEED_DEMON: " + message)

func _ready() -> void: _run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true
	var pilot := Pilot.new()
	pilot.position = Vector2(350, 300)
	add_child(pilot)
	pilot.add_to_group("player")
	var weapon = load("res://Scenes/Weapon/SpeedDemonDagger.tscn").instantiate()
	pilot.add_child(weapon)
	var victim := Victim.new()
	victim.collision_layer = 2
	victim.position = pilot.position + Vector2(25, -4)
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 8
	victim.add_child(shape)
	add_child(victim)
	victim.add_to_group("enemy")
	await get_tree().physics_frame
	weapon.attack()
	weapon.set_physics_process(false)
	weapon._physics_process(0.04)
	check(victim.hits == 0 and pilot.drive_time == 0, "Arranque sin daño ni impulso")
	weapon.set_physics_process(true)
	await get_tree().create_timer(0.15).timeout
	check(weapon._motor.playing and pilot.drive_time > 0, "Motor e impulso durante corte")
	check(weapon._fx._exhaust.emitting, "Motor emite humo durante corte")
	check(victim.has_meta("saw_contact_fx"), "Contacto crea surcos y fragmentos")
	check(weapon.drive_multiplier < 1.0, "Contacto agrega resistencia")
	check(is_zero_approx(weapon.rotation), "Arma fija sin cuchillada")
	check(not weapon.attack_fx.visible and not weapon.has_node("Snd_mele1"), "Sin FX ni sonido de daga")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://speed_demon_cut.png")
	await get_tree().create_timer(0.5).timeout
	check(victim.hits == 4, "Cuatro pulsos controlados: " + str(victim.hits))
	check(victim.current_health == 164, "Daño de cuatro pulsos incluye escalado de cadencia")
	check(not weapon.is_attacking() and not weapon._motor.playing and pilot.drive_time == 0, "Fin limpia motor e impulso")
	check(not weapon._fx._exhaust.emitting, "Escape deja de emitir al apagar")
	check(get_tree().get_nodes_in_group("saw_contact_fx").is_empty(), "Fragmentos de corte se limpian")
	var normal_reach: float = weapon.scale.x
	var normal_drive: float = weapon.drive_speed_multiplier
	var normal_damage: float = weapon._pulse_damage
	pilot.attack_bonus = 4.0
	weapon.attack()
	check(weapon.scale.x > normal_reach and weapon.drive_speed_multiplier > normal_drive and weapon._pulse_damage > normal_damage, "Mayor cadencia aumenta alcance, impulso y daño")
	var capped_reach: float = weapon.scale.x
	var capped_drive: float = weapon.drive_speed_multiplier
	weapon.cancel_drive()
	pilot.attack_bonus = 100.0
	weapon.attack()
	check(is_equal_approx(weapon.scale.x, capped_reach) and is_equal_approx(weapon.drive_speed_multiplier, capped_drive), "Cadencia extrema mantiene límites espaciales")
	weapon.cancel_drive()
	pilot.attack_bonus = 2.0
	weapon.attack()
	check(is_equal_approx(weapon.scale.x, normal_reach) and is_equal_approx(weapon._pulse_damage, normal_damage), "Recalcula sin acumular bonus entre ataques")
	weapon.cancel_drive()
	victim.current_health = 1
	weapon.attack()
	await get_tree().create_timer(0.16).timeout
	check(victim.is_dying and weapon._boost_time > 0, "Muerte activa acelerón y remate")
	weapon.cancel_drive()
	weapon.attack()
	await get_tree().create_timer(0.13).timeout
	weapon.brake_on_wall()
	check(weapon.phase == weapon.Phase.BRAKE and pilot.drive_time == 0, "Pared frena inmediatamente")
	await get_tree().create_timer(0.3).timeout
	weapon.attack()
	pilot.is_cutscene_frozen = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not weapon.is_attacking() and pilot._speed_demon_driver == null, "Cinemática cancela motor")
	pilot.is_cutscene_frozen = false
	weapon.attack()
	weapon.queue_free()
	await get_tree().process_frame
	check(pilot._speed_demon_driver == null and pilot.drive_time == 0, "Cambio de arma limpia impulso")
	pilot.queue_free()
	victim.queue_free()
	await get_tree().process_frame
	await _check_real_player()
	if failures == 0: print("SPEED_DEMON_OK")
	get_tree().quit(failures)

func _check_real_player() -> void:
	var player = load("res://Scenes/Player/Player.tscn").instantiate()
	add_child(player)
	player.position = Vector2(800, 600)
	player.set_physics_process(false)
	await get_tree().create_timer(0.5).timeout
	player.second_weapon.apply_synergy_weapon_override("res://Scenes/Weapon/SpeedDemonDagger.tscn")
	player._show_secondary_weapon()
	var saw = player.second_weapon.current_weapon
	saw.attack()
	var start: Vector2 = player.position
	for i in 30:
		await get_tree().physics_frame
		if player._speed_demon_push_time > 0:
			player._apply_speed_demon_push(1.0 / 60)
			player.move_and_slide()
	check(player.position.distance_to(start) > 25, "Jugador real avanza con motor: " + str(player.position.distance_to(start)) + " fase=" + str(saw.phase))
	saw.cancel_drive()
	var wall := StaticBody2D.new()
	var dir: Vector2 = (player.get_aim_position() - player.global_position).normalized()
	wall.position = player.position + dir * 48
	wall.collision_layer = 4
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	wall.add_child(collision)
	add_child(wall)
	await get_tree().physics_frame
	saw.attack()
	var braked := false
	for i in 30:
		await get_tree().physics_frame
		if player._speed_demon_push_time > 0:
			player._apply_speed_demon_push(1.0 / 60)
			if saw.phase == saw.Phase.BRAKE: braked = true
			player.move_and_slide()
	check(braked, "Colisión real con pared dispara frenada")
	player.queue_free()
	wall.queue_free()
	await get_tree().process_frame
