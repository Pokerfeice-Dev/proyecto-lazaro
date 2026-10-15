extends Node2D

# Prueba temporal: duplicado al equipar con E y cartel de sala con el juego en pausa. Se borra después.

var _log := ""

func _p(a = "", b = "", c = "", d = "") -> void:
	_log += str(a) + str(b) + str(c) + str(d) + "\n"

func _ready() -> void:
	_correr.call_deferred()

func _find_inventory(n: Node) -> Node:
	if n.has_method("_on_detail_equip_pressed"):
		return n
	for c in n.get_children():
		var r = _find_inventory(c)
		if r: return r
	return null

func _contar(inv_ui, id: String) -> String:
	var en_mochila = 0
	for it in inv_ui.inventory.items:
		if it.id == id: en_mochila += 1
	var puestos = 0
	for k in inv_ui.equipment.slots:
		var it = inv_ui.equipment.slots[k]
		if it and it.id == id: puestos += 1
	return "mochila=%d equipados=%d" % [en_mochila, puestos]

func _correr() -> void:
	var room = (load("res://Scenes/Rooms/Level1_Room12(Ygor1).tscn") as PackedScene).instantiate()
	add_child(room)
	await get_tree().create_timer(0.5).timeout
	var cards = get_tree().root.find_children("*", "RoomTitleCard", true, false)
	_p("PRUEBABUGS cartel antes de pausar=", cards.size())
	var inv_ui = _find_inventory(get_tree().root)
	inv_ui.toggle_visibility()
	await get_tree().create_timer(0.6, true).timeout
	cards = get_tree().root.find_children("*", "RoomTitleCard", true, false)
	_p("PRUEBABUGS cartel con inventario abierto=", cards.size())
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tmp_bugs_1.png"))
	# duplicado: un objeto de arma y uno de cuerpo, E tres veces cada uno
	for path in ["res://Art/Items/Weapons/Item1.tres", "res://Art/Items/Player/Body/Item2_TorsoBlindado.tres"]:
		var item = (load(path) as ItemData).duplicate()
		inv_ui.inventory.add_item(item)
		inv_ui._on_slot_clicked(item)
		_p("PRUEBABUGS ", item.id, " antes: ", _contar(inv_ui, item.id))
		for i in 3:
			inv_ui._on_detail_equip_pressed()
		_p("PRUEBABUGS ", item.id, " despues de 3 E: ", _contar(inv_ui, item.id))
	_p("PRUEBABUGS FIN")
	var f = FileAccess.open("res://tmp_bugs_log.txt", FileAccess.WRITE)
	f.store_string(_log)
	f.close()
	get_tree().quit()
