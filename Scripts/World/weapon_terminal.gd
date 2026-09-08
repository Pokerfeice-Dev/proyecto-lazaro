extends Area2D
class_name WeaponTerminal

## Terminal interactivo para probar combinaciones de armas dentro de la sala
## de entrenamiento (sin necesidad de arrancar una run nueva). Reutiliza el
## mismo popup que la puerta de inicio de run (ver weapon_selection_menu.gd),
## pero al confirmar solo guarda la elección y re-equipa al jugador ahí
## mismo, en vez de mandarlo a jugar.

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

var player_inside: bool = false
var interaction_label: Label = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_interaction_label()

func _setup_interaction_label() -> void:
	interaction_label = get_node_or_null("Label") as Label
	if not interaction_label:
		interaction_label = Label.new()
		interaction_label.name = "Label"
		add_child(interaction_label)
		interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interaction_label.custom_minimum_size = Vector2(220, 30)
		interaction_label.add_theme_color_override("font_color", Color.WHITE)
		interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
		interaction_label.add_theme_constant_override("outline_size", 4)

	# top_level para que el texto se muestre siempre recto, igual que en door.gd
	interaction_label.top_level = true
	interaction_label.rotation = 0.0
	interaction_label.scale = Vector2.ONE
	interaction_label.position = global_position + Vector2(-110, -70)
	interaction_label.text = "Presiona E: elegir equipo"
	interaction_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = true
	if interaction_label:
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = false
	if interaction_label:
		interaction_label.visible = false

func _input(event: InputEvent) -> void:
	if not player_inside: return
	if not event is InputEventKey: return
	if event.physical_keycode != KEY_E: return
	if not event.pressed or event.echo: return

	WeaponSelectionMenu.show_popup(
		self,
		"SELECCIÓN DE EQUIPO",
		"Probá combinaciones de armas (no arranca una run)",
		"APLICAR",
		func(_selections): _reequip_player()
	)

func _reequip_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player: return
	if "active_weapon" in player and player.active_weapon and player.active_weapon.has_method("_load_default_weapon"):
		player.active_weapon._load_default_weapon()
	if "second_weapon" in player and player.second_weapon and player.second_weapon.has_method("_load_default_weapon"):
		player.second_weapon._load_default_weapon()
