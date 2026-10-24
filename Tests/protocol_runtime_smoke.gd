extends Node2D

var active_enemies := 0
var room_cleared := false
var failures := 0

class TestPlayer extends Node2D:
	var stats := PlayerStats.new()
	var is_cutscene_frozen := false
	var protocols: ProtocolRuntime
	func _show_heal_text(_amount: int) -> void: pass

class Target extends Node2D:
	var current_health := 100.0
	var is_dying := false
	func take_damage(amount: float, _crit: bool = false) -> void:
		current_health = maxf(0, current_health - amount)
		is_dying = current_health <= 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("PROTOCOL_RUNTIME_FAILED: " + message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true # Ninguna escritura al guardado del jugador.
	GameData.reset_protocol_run()
	GameData.core_upgrades["compactador"] = 0
	var p := TestPlayer.new()
	p.stats.current_health = 100
	add_child(p)
	p.add_to_group("player")
	var runtime := ProtocolRuntime.new()
	p.protocols = runtime
	p.add_child(runtime)
	runtime.set_process(false)
	GameData.active_protocol = "circuito_emergencia"
	check(runtime.modify_incoming(20, 0) == 10, "Escudo reduce 50%")
	check(runtime.modify_incoming(20, 0) == 20, "Solo primer golpe")
	check(GameData.protocol_run_stats.get("blocked") == 10, "Daño evitado real")
	GameData.active_protocol = "blindaje_reactivo"
	check(runtime.modify_incoming(10, 0) == 10, "Blindaje no protege golpe activador")
	check(runtime.modify_incoming(10, 0) == 8, "Blindaje protege golpe siguiente")
	runtime.armor_left = 0.0
	check(runtime.modify_incoming(10, 0) == 10 and runtime.armor_left == 0, "Recarga impide renovar blindaje")
	GameData.active_protocol = "sobrecarga"
	runtime.selected_protocol = "sobrecarga"
	runtime.room_id = get_instance_id()
	check(runtime.damage_multiplier() == 1.0, "Sin bono antes de combate")
	add_to_group("combat_room")
	active_enemies = 1
	p.is_cutscene_frozen = true
	runtime._process(1.0)
	check(not runtime.combat_started, "No consumir carga en cinemática")
	p.is_cutscene_frozen = false
	runtime._process(0.1)
	check(runtime.damage_multiplier() == 1.2, "Bono real al iniciar combate")
	runtime._process(6.0)
	check(runtime.damage_multiplier() == 1.0, "Bono termina sin temporizador de sala anterior")
	var target := Target.new()
	add_child(target)
	target.add_to_group("enemy")
	ProtocolRuntime.deal_damage(target, 24, false, "overload_damage", 1.0 / 6.0)
	check(target.current_health == 76 and is_equal_approx(GameData.protocol_run_stats.get("overload_damage", 0.0), 4.0), "Registra daño extra")
	GameData.active_protocol = "furia_de_titanio"
	p.stats.current_health = 29
	check(runtime.is_fury_active(), "Furia bajo30%")
	p.stats.current_health = 30
	check(not runtime.is_fury_active(), "Furia no activa al30% exacto")
	GameData.active_protocol = "reparacion_autonoma"
	p.stats.current_health = 99
	check(ProtocolRuntime.heal_player(p, 3) == 1, "No sobrecurar ni inflar resumen")
	GameData.active_protocol = "nucleo_vampirico"
	target.position = Vector2(100, 100)
	for i in 10: GameData.protocol_enemy_defeated(target)
	await get_tree().process_frame
	check(GameData.vampiric_kills_counter == 0, "Coágulo cada10bajas")
	var clots: Array[Node] = []
	for child in get_children():
		if child.get_script() == preload("res://Scripts/Effects/protocol_clot.gd"): clots.append(child)
	check(clots.size() == 1, "Genera un coágulo")
	p.stats.current_health = 90
	p.position = target.position
	if not clots.is_empty(): clots[0]._process(0.01)
	check(p.stats.current_health == 92, "Coágulo cura al acercarse")
	GameData.active_protocol = "reciclaje_instantaneo"
	GameData.scrap = 0
	for path in ["res://Scenes/Enemies/boss1.tscn", "res://Scenes/Enemies/Boss2.tscn"]:
		var boss = load(path).instantiate()
		GameData.protocol_enemy_defeated(boss)
		boss.free()
	var prometeo = load("res://Scripts/Enemies/boss3_prometeo.gd").new()
	GameData.protocol_enemy_defeated(prometeo)
	prometeo.is_clone = true
	GameData.protocol_enemy_defeated(prometeo)
	prometeo.free()
	check(GameData.scrap == 150, "Tres jefes y ningún clon")
	var inventory := Inventory.new()
	var item := ItemData.new()
	inventory.items.append(item)
	GameData.current_level = 1
	GameData.current_run_room = 1
	check(GameData.recycle_protocol_item(item, inventory), "Recicla mochila")
	inventory.items.append(item)
	check(not GameData.recycle_protocol_item(item, inventory), "Una vez por zona")
	GameData.current_level = 2
	check(GameData.recycle_protocol_item(item, inventory), "Nueva zona renueva reciclaje")
	check(GameData.scrap == 230, "40 por pieza reciclada")
	GameData.vampiric_kills_counter = 9
	GameData.reset_protocol_run()
	check(GameData.vampiric_kills_counter == 0 and GameData.protocol_recycled_levels.is_empty() and GameData.protocol_run_stats.is_empty(), "Reinicio completo de run")
	inventory.free()
	p.queue_free()
	target.queue_free()
	await get_tree().process_frame
	if failures == 0: print("PROTOCOL_RUNTIME_OK")
	get_tree().quit(1 if failures else 0)
