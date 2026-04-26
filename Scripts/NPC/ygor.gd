extends Node2D
## Ygor – NPC de compras.
## Detecta si el jugador está cerca y abre el ShopMenu con E.

const SHOP_MENU_SCENE: PackedScene = preload("res://Scenes/UI/ShopMenu.tscn")

@onready var interact_area: Area2D = $Interact_area
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var shop_instance: CanvasLayer = null
var interact_label: Label = null

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_create_interact_label()
	anim_sprite.play("idle")

func _create_interact_label() -> void:
	interact_label = Label.new()
	interact_label.text = "[E] Hablar con Ygor"
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.add_theme_font_size_override("font_size", 14)
	interact_label.add_theme_color_override("font_color", Color.WHITE)
	interact_label.position = Vector2(-70, -90)
	interact_label.visible = false
	add_child(interact_label)

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if _is_shop_open():
		return
	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		_open_shop()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_nearby = true
	interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_nearby = false
	interact_label.visible = false

func _is_shop_open() -> bool:
	return shop_instance != null and shop_instance.visible

func _open_shop() -> void:
	if shop_instance == null:
		shop_instance = SHOP_MENU_SCENE.instantiate()
		get_tree().current_scene.add_child(shop_instance)
		shop_instance.menu_closed.connect(_on_shop_closed)
	shop_instance.open_menu()
	interact_label.visible = false

func _on_shop_closed() -> void:
	interact_label.visible = player_nearby
