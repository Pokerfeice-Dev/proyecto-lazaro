class_name Inventory
extends Node

## Mochila del jugador. Tiene lugar para CAPACITY objetos (prueba: 12).
## Si está llena, add_item() no guarda nada y devuelve false: quien da el
## objeto decide qué hacer (dejarlo en el piso, no venderlo, etc.).
## Los objetos se tiran con Q / flecha arriba del joystick desde el inventario.

signal inventory_updated
signal inventory_full

const CAPACITY := 12
const DROP_SCENE := preload("res://Scenes/Items/item_drop_world.tscn")

var items: Array[ItemData] = []

func _ready() -> void:
	items = GameData.inventory_items
	# partidas de antes del límite: lo que no entra queda en el piso
	if items.size() > CAPACITY:
		_drop_extra.call_deferred()

func _drop_extra() -> void:
	while items.size() > CAPACITY:
		drop_item(items.back())

func is_full() -> bool:
	return items.size() >= CAPACITY

## force: para casos que no suman objetos (devolver una pieza al cambiarla por otra).
func add_item(item: ItemData, force: bool = false) -> bool:
	if not force and is_full():
		notify_full()
		return false
	items.append(item)
	if GameData.has_method("unlock_codex_entry") and item:
		GameData.unlock_codex_entry("items", item.id)
	inventory_updated.emit()
	return true

## Lo guarda en la mochila; si no entra, lo deja en el piso al lado del jugador.
func add_or_drop(item: ItemData) -> bool:
	if add_item(item):
		return true
	drop_on_floor(item, _owner_position() + Vector2(0, 26))
	return false

func remove_item(item: ItemData) -> void:
	items.erase(item)
	inventory_updated.emit()

func get_items() -> Array[ItemData]:
	return items

## Saca el objeto de la mochila y lo deja en el piso, cerca del jugador.
func drop_item(item: ItemData) -> void:
	if not items.has(item): return
	items.erase(item)
	inventory_updated.emit()
	var angle = randf_range(0.0, TAU)
	drop_on_floor(item, _owner_position() + Vector2(cos(angle), sin(angle) * 0.6) * 34.0)

static func drop_on_floor(item: ItemData, pos: Vector2) -> void:
	var tree = Engine.get_main_loop() as SceneTree
	if not tree or not tree.current_scene or not item: return
	var drop = DROP_SCENE.instantiate()
	drop.item_data = item
	drop.global_position = pos
	tree.current_scene.call_deferred("add_child", drop)

## Aviso "Mochila llena" sobre el jugador (y Ygor lo comenta si está cerca).
func notify_full() -> void:
	inventory_full.emit()
	var owner_node = get_parent() as Node2D
	if not owner_node or not owner_node.is_inside_tree(): return
	var label = UIStyle.label("Mochila llena (%d/%d)" % [items.size(), CAPACITY], 18, UIStyle.COLOR_WARNING)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.size = Vector2(240, 30)
	label.position = Vector2(-60, -15)
	label.scale = Vector2(0.5, 0.5)
	var floating = Node2D.new()
	floating.z_index = 80
	floating.global_position = owner_node.global_position + Vector2(0, -44)
	floating.add_child(label)
	owner_node.get_tree().current_scene.add_child(floating)
	var t = floating.create_tween().set_parallel(true)
	t.tween_property(floating, "global_position:y", floating.global_position.y - 22.0, 1.2)
	t.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.8)
	t.chain().tween_callback(floating.queue_free)
	var ygor = owner_node.get_tree().get_first_node_in_group("ygor")
	if ygor and ygor.has_method("comment"):
		ygor.comment("mochila_llena")

func _owner_position() -> Vector2:
	var owner_node = get_parent() as Node2D
	return owner_node.global_position if owner_node else Vector2.ZERO
