class_name ItemDropWorld
extends Node2D

@export var item_data: ItemData

var player: Node2D = null
var target_inventory: Inventory = null
var is_collected: bool = false
var player_nearby: bool = false
var interaction_label: Label = null

func _ready() -> void:
	if item_data and item_data.icon:
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.texture = item_data.icon
			
	var grab = get_node_or_null("Grab_area")
	if grab:
		grab.body_entered.connect(_on_grab_area_body_entered)
		grab.body_exited.connect(_on_grab_area_body_exited)
		
	_create_interaction_label()

func _check_and_show_inventory_tutorial() -> void:
	if GameData.has_shown_inventory_tutorial:
		return
		
	GameData.has_shown_inventory_tutorial = true
	GameData.save_game()
	
	var popup_script = load("res://Scripts/UI/inventory_tutorial_popup.gd")
	if not popup_script:
		return
	var popup = CanvasLayer.new()
	popup.set_script(popup_script)
	get_tree().current_scene.call_deferred("add_child", popup)

func _create_interaction_label() -> void:
	interaction_label = Label.new()
	interaction_label.text = "E"
	interaction_label.visible = false
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.custom_minimum_size = Vector2(40, 20)
	interaction_label.position = Vector2(-20, -30)
	
	interaction_label.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	interaction_label.add_theme_font_size_override("font_size", 10)
	interaction_label.add_theme_color_override("font_color", Color.WHITE)
	interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_label.add_theme_constant_override("outline_size", 3)
	add_child(interaction_label)

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if is_collected:
		return
	if _is_interact_action(event):
		get_viewport().set_input_as_handled()
		_collect()

func _is_interact_action(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		return true
	return false

func _collect() -> void:
	is_collected = true
	if target_inventory:
		target_inventory.add_item(item_data)
	if interaction_label:
		interaction_label.visible = false
	_play_sound_and_free()

func _play_sound_and_free() -> void:
	visible = false
	var snd = get_node_or_null("Scrap_snd")
	if not snd:
		queue_free()
		return
	snd.bus = "SFX"
	snd.finished.connect(queue_free)
	snd.play()

func _on_grab_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	var inv = body.get_node_or_null("Inventory")
	if not inv: return
	player = body
	target_inventory = inv
	player_nearby = true
	if interaction_label:
		interaction_label.visible = true
	_check_and_show_inventory_tutorial()

func _on_grab_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_nearby = false
	if interaction_label:
		interaction_label.visible = false
