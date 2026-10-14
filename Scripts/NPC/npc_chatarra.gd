extends Node2D

@onready var area_2d: Area2D = get_node_or_null("Area2D")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var player_nearby: bool = false
var interact_label: Label = null
var ui_instance: OmniaMenu = null

func _ready() -> void:
	set_process_input(true)
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.body_exited.connect(_on_body_exited)
	_setup_interact_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interact_label)
	_setup_shadow()

func _setup_shadow() -> void:
	DropShadow.attach_to(self, Vector2(28.0, 14.0), Vector2(0.0, 16.0), 0.38)

func _setup_interact_label() -> void:
	interact_label = Label.new()
	interact_label.text = "[E] Terminal de Mejoras"
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	interact_label.add_theme_font_size_override("font_size", 16)
	interact_label.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0))
	interact_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interact_label.add_theme_constant_override("outline_size", 4)
	interact_label.position = Vector2(-80, -60)
	interact_label.visible = false
	add_child(interact_label)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if interact_label:
			interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if interact_label:
			interact_label.visible = false
		_close_upgrade_ui()

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return

	var is_interact = event.is_action_pressed("interact")
	if not is_interact and event is InputEventKey:
		if event.physical_keycode == KEY_E and event.pressed and not event.echo:
			is_interact = true

	if is_interact and not ui_instance:
		_open_upgrade_ui()

# La ventana de O.M.N.I.A. vive en OmniaMenu (pausa el juego mientras está abierta).
# Hablar con Victoria por primera vez la registra en el códice (pestaña NPCs).
func _open_upgrade_ui() -> void:
	if interact_label:
		interact_label.visible = false
	GameData.unlock_codex_entry("npcs", "victoria")
	ui_instance = OmniaMenu.new()
	ui_instance.closed.connect(_on_upgrade_ui_closed)
	get_tree().root.add_child(ui_instance)

func _close_upgrade_ui() -> void:
	if ui_instance and is_instance_valid(ui_instance):
		ui_instance.close()

func _on_upgrade_ui_closed() -> void:
	ui_instance = null
	if interact_label:
		interact_label.visible = player_nearby
