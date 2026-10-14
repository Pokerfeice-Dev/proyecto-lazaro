extends Node

# Prueba temporal: carteles de interacción, Speed Demon, Snowman y pestaña de sinergias del códice.
# Todo en memoria (no guarda la partida a propósito). Se borra después.

const ITEMS := "res://Art/Items/Weapons/"

func _ready() -> void:
	GameData.debug_god_mode = true
	_correr.call_deferred()

func _correr() -> void:
	GameData.unlocked_synergies = ["roadkill", "speed_demon", "snowman"] as Array[String]
	var room = (load("res://Scenes/Rooms/Level1_Room11(treasure).tscn") as PackedScene).instantiate()
	get_tree().root.add_child(room)
	get_tree().current_scene = room
	await get_tree().create_timer(4.0).timeout
	var player = get_tree().get_first_node_in_group("player")

	var prompts = 0
	for lbl in room.find_children("*", "Label", true, false):
		if lbl.has_node("InteractPrompt"):
			lbl.visible = true
			prompts += 1
	print("PRUEBATODO carteles=", prompts)
	await get_tree().create_timer(0.5).timeout
	_captura("res://tmp_todo_1.png")

	var equip = player.get_node("Equipment")
	GameData.chosen_melee_weapon = "daga"
	equip.slots[ItemData.ItemSlot.SEC_W1] = load(ITEMS + "Item9_SierraCircular.tres")
	equip.slots[ItemData.ItemSlot.SEC_W2] = load(ITEMS + "Item6.tres")
	equip.slots[ItemData.ItemSlot.SEC_W3] = load(ITEMS + "Item10_Bateria.tres")
	equip.equipment_changed.emit()
	player.second_weapon._load_default_weapon()
	await get_tree().create_timer(0.3).timeout
	print("PRUEBATODO speed_demon activa=", player._is_speed_demon_active(), " bonus vel ataque=", player._get_equip_stat("attack_speed", false))
	var p0 = player.global_position
	player.second_weapon.attack()
	player._start_speed_demon_push()
	await get_tree().create_timer(0.25).timeout
	print("PRUEBATODO empuje=", snappedf(player.global_position.distance_to(p0), 0.1))

	GameData.chosen_primary_weapon = "shotgun"
	equip.slots[ItemData.ItemSlot.MAIN_W1] = load(ITEMS + "Item1.tres")
	equip.slots[ItemData.ItemSlot.MAIN_W2] = load(ITEMS + "Item8_CabezaHumana.tres")
	equip.slots[ItemData.ItemSlot.MAIN_W3] = load(ITEMS + "Item12_Nitrogeno.tres")
	equip.equipment_changed.emit()
	player.active_weapon._load_default_weapon()
	await get_tree().create_timer(0.4).timeout
	var syns = SynergyManager.get_active_synergies(equip, player.get_active_ranged_weapon_id(), true)
	print("PRUEBATODO arma=", player.get_active_ranged_weapon_id(), " sinergias=", syns)
	player.can_shoot = true
	player.fire_projectile(Vector2.RIGHT)
	await get_tree().create_timer(0.5).timeout
	var balls = 0
	for n in get_tree().root.find_children("*", "Area2D", true, false):
		if n.get_script() and "snowball" in n.get_script().resource_path:
			balls += 1
	print("PRUEBATODO bolas de nieve=", balls)
	_captura("res://tmp_todo_2.png")

	var inv = get_tree().root.find_children("InventoryUI", "", true, false)
	if inv.size() > 0:
		inv[0].toggle_visibility()
		await get_tree().create_timer(0.6).timeout
		inv[0]._on_codex_tab_pressed()
		inv[0]._on_codex_category_pressed("synergies")
		await get_tree().create_timer(0.6).timeout
		_captura("res://tmp_todo_3.png")
	print("PRUEBATODO FIN")
	get_tree().quit()

func _captura(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
