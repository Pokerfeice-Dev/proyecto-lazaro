extends Node2D

# Prueba temporal del códice. Se borra después.

const CATS := ["enemies", "weapons", "items", "npcs", "levels", "synergies"]

func _ready() -> void:
	_correr.call_deferred()

func _find_inventory(n: Node) -> Node:
	if n.has_method("_refresh_codex_grid"):
		return n
	for c in n.get_children():
		var r = _find_inventory(c)
		if r: return r
	return null

func _correr() -> void:
	var room = (load("res://Scenes/Rooms/Level1_Room12(Ygor1).tscn") as PackedScene).instantiate()
	add_child(room)
	await get_tree().create_timer(0.6).timeout
	var inv = _find_inventory(get_tree().root)
	print("PRUEBACODEX inv=", inv)
	inv.toggle_visibility()
	await get_tree().create_timer(0.5).timeout
	inv._on_codex_tab_pressed()
	for i in CATS.size():
		inv._on_codex_category_pressed(CATS[i])
		await get_tree().create_timer(0.7).timeout
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tmp_codex_%d.png" % i))
	get_tree().quit()
