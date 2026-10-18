extends Area2D
class_name WeaponTerminal

## Terminal interactivo para probar combinaciones de armas dentro de la sala
## de entrenamiento (sin necesidad de arrancar una run nueva). Reutiliza el
## mismo popup que la puerta de inicio de run (ver weapon_selection_menu.gd),
## pero al confirmar solo guarda la elección y re-equipa al jugador ahí
## mismo, en vez de mandarlo a jugar.

@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

const SIGN_ICON := preload("res://Art/Ui/svg/icon_damage.svg")

var player_inside: bool = false
var interaction_label: Label = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_interaction_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interaction_label)
	# cartel fijo con el nombre de la estación, como las puertas del laboratorio
	DoorSign.create(self, "ARMERÍA", SIGN_ICON, UIStyle.COLOR_GOLD, Vector2(0, -46))

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

	# top_level para que el texto se muestre siempre recto, igual que en door.gd;
	# va debajo de la estación porque arriba está el cartel con su nombre
	interaction_label.top_level = true
	interaction_label.rotation = 0.0
	interaction_label.scale = Vector2.ONE
	interaction_label.position = global_position + Vector2(-110, 34)
	interaction_label.text = "Presiona E: elegir equipo"
	interaction_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = true
	_set_highlight(true)
	if interaction_label:
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = false
	_set_highlight(false)
	if interaction_label:
		interaction_label.visible = false

# La estación se ilumina mientras el jugador está cerca.
func _set_highlight(on: bool) -> void:
	var art = get_node_or_null("Sprite2D")
	if art and art.has_method("set_highlight"):
		art.set_highlight(on)

func _input(event: InputEvent) -> void:
	if not player_inside: return
	if not InputMode.is_interact(event): return # E o X del joystick

	WeaponSelectionMenu.show_popup(
		self,
		"SELECCIÓN DE EQUIPO",
		"Prueba combinaciones de armas (no inicia una run)",
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
