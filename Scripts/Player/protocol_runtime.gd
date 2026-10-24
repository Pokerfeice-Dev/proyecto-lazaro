class_name ProtocolRuntime
extends Node2D
## Estado por sala. El progreso y aporte de la run viven en GameData.

var player: Node2D
var overload_left := 0.0
var armor_left := 0.0
var armor_cooldown := 0.0
var shield_ready := true
var combat_started := false
var room_id := 0
var flash := 0.0
var recent_target: Node2D
var target_left := 0.0
var bee: Node2D
var selected_protocol := ""

func _ready() -> void:
	player = get_parent()
	z_index = 2
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

func _process(delta: float) -> void:
	var room := get_tree().current_scene
	if not room: return
	if room_id != room.get_instance_id():
		room_id = room.get_instance_id()
		shield_ready = true
		combat_started = false
		overload_left = 0.0
		armor_left = 0.0
		armor_cooldown = 0.0
	if selected_protocol != GameData.active_protocol:
		selected_protocol = GameData.active_protocol
		overload_left = 0.0
		armor_left = 0.0
		armor_cooldown = 0.0
		if is_instance_valid(bee): bee.queue_free()
		bee = null
	if selected_protocol == "enjambre_residual" and room.is_in_group("combat_room") and not is_instance_valid(bee):
		bee = preload("res://Scripts/Player/allied_bee.gd").new()
		room.add_child(bee)
		bee.global_position = player.global_position + Vector2(-35, -30)
	if player.is_cutscene_frozen or SceneTransition.is_transitioning: return
	if not combat_started and room.is_in_group("combat_room") and int(room.get("active_enemies")) > 0:
		start_combat()
	overload_left = maxf(0.0, overload_left - delta)
	armor_left = maxf(0.0, armor_left - delta)
	armor_cooldown = maxf(0.0, armor_cooldown - delta)
	flash = maxf(0.0, flash - delta)
	target_left = maxf(0.0, target_left - delta)
	if is_fury_active() and combat_started and not bool(room.get("room_cleared")):
		GameData.record_protocol("furia_seconds", delta)
	queue_redraw()

func start_combat() -> void:
	if combat_started: return
	combat_started = true
	if GameData.active_protocol == "sobrecarga":
		overload_left = 6.0
		flash = 0.35

func damage_multiplier() -> float:
	return 1.2 if GameData.active_protocol == "sobrecarga" and overload_left > 0.0 else 1.0

func is_fury_active() -> bool:
	return GameData.active_protocol == "furia_de_titanio" and player.stats.current_health > 0 and player.stats.current_health < player.stats.max_health * 0.3

func modify_incoming(amount: int, armor: int) -> int:
	var normal := maxi(1, amount - armor)
	var reduced := amount
	if GameData.active_protocol == "circuito_emergencia" and shield_ready:
		shield_ready = false
		reduced = int(ceil(amount * 0.5))
		flash = 0.4
	var extra_armor := 2 if GameData.active_protocol == "blindaje_reactivo" and armor_left > 0.0 else 0
	var result := maxi(1, reduced - armor - extra_armor)
	GameData.record_protocol("blocked", maxi(0, normal - result))
	# Se activa después del cálculo: no reduce el golpe disparador ni se renueva.
	if GameData.active_protocol == "blindaje_reactivo" and armor_cooldown <= 0.0:
		armor_left = 3.0
		armor_cooldown = 7.0
		flash = 0.3
	return result

func note_target(enemy: Node2D) -> void:
	if valid_enemy(enemy):
		recent_target = enemy
		target_left = 3.0

func preferred_target() -> Node2D:
	if target_left > 0.0 and valid_enemy(recent_target): return recent_target
	return null

static func valid_enemy(enemy: Node2D) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.is_in_group("enemy") and enemy.get("is_dying") != true

static func heal_player(target: Node, amount: int) -> int:
	if not is_instance_valid(target) or target.stats.current_health <= 0: return 0
	var before: int = target.stats.current_health
	target.stats.heal(amount)
	var healed: int = target.stats.current_health - before
	GameData.record_protocol("healed", healed)
	if healed > 0:
		target._show_heal_text(healed)
		if target.get("protocols"): target.protocols.flash = 0.5
	return healed

static func deal_damage(target: Node, amount: float, crit: bool = false, metric: String = "", bonus_ratio: float = 0.0) -> void:
	var before: float = float(target.get("current_health")) if target.get("current_health") != null else 0.0
	target.take_damage(amount, crit)
	if metric.is_empty() or before <= 0.0: return
	var after: float = maxf(0.0, float(target.get("current_health"))) if is_instance_valid(target) else 0.0
	var actual := maxf(0.0, before - after)
	GameData.record_protocol(metric, actual * bonus_ratio if bonus_ratio > 0.0 else actual)

func status_text() -> String:
	match GameData.active_protocol:
		"circuito_emergencia": return "Escudo listo · −50% primer golpe" if shield_ready else "Escudo consumido"
		"reparacion_autonoma": return "+3 HP al limpiar combate"
		"nucleo_vampirico": return "%d / 10 bajas · coágulo +2 HP" % GameData.vampiric_kills_counter
		"sobrecarga": return "+20% daño · %.1f s" % overload_left if overload_left > 0.0 else ("Carga consumida" if combat_started else "Lista al iniciar combate")
		"reflejo_sintetico": return "Eco al terminar el dash · 50% daño"
		"enjambre_residual": return "Abeja aliada · sigue tus ataques"
		"blindaje_reactivo":
			if armor_left > 0.0: return "+2 defensa · %.1f s" % armor_left
			return "Recarga · %.1f s" % armor_cooldown if armor_cooldown > 0.0 else "Blindaje listo"
		"furia_de_titanio": return "FURIA · +35% velocidad de ataque" if is_fury_active() else "Se activa bajo 30% de vida"
		"reciclaje_instantaneo": return "Reciclaje usado en esta zona" if GameData.protocol_recycled_levels.has(GameData.current_level) else "1 reciclaje disponible · inventario"
	return ""

func _draw() -> void:
	var center := Vector2(0, 2)
	if GameData.active_protocol == "circuito_emergencia" and shield_ready:
		draw_arc(center, 21, PI * 1.1, PI * 1.9, 8, Color(0.3, 0.9, 1.0, 0.7), 2.0)
	if armor_left > 0.0:
		for i in 4:
			var point := center + Vector2.from_angle(float(i) * PI / 2.0 + PI / 4.0) * 23.0
			draw_rect(Rect2(point.round() - Vector2(3, 3), Vector2(6, 6)), Color("80e5dd"))
	if overload_left > 0.0 or is_fury_active():
		var color := Color("ffac49") if overload_left > 0.0 else Color("fa4e77")
		draw_arc(center, 24, PI * 0.1, PI * 0.9, 8, Color(color, 0.75), 2.0)
	if flash > 0.0:
		draw_arc(center, 22 + (0.5 - flash) * 25, 0, TAU, 12, Color(0.4, 1, 0.8, flash * 1.5), 2.0)
