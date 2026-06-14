extends Node2D
## Ygor – NPC de compras.
## Detecta si el jugador está cerca y habla con él.

@onready var interact_area: Area2D = $Interact_area
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var interact_label: Label = null
var dialogue_active: bool = false

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_setup_interact_label()
	anim_sprite.play("idle")

func _setup_interact_label() -> void:
	interact_label = get_node_or_null("Label")
	if not interact_label:
		interact_label = _find_label_child()
	if not interact_label:
		_create_interact_label_fallback()
	
	if interact_label:
		interact_label.text = "[E] Hablar con Ygor"
		interact_label.visible = false

func _find_label_child() -> Label:
	for child in get_children():
		if child is Label:
			return child
	return null

func _create_interact_label_fallback() -> void:
	interact_label = Label.new()
	interact_label.text = "[E] Hablar con Ygor"
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.add_theme_font_size_override("font_size", 14)
	interact_label.add_theme_color_override("font_color", Color.WHITE)
	interact_label.position = Vector2(-70, -90)
	interact_label.visible = false
	add_child(interact_label)

func _input(event: InputEvent) -> void:
	_check_interaction_input(event)

func _check_interaction_input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if dialogue_active:
		return
	if not event.is_action_pressed("interact") and not _is_key_e_pressed(event):
		return
	_talk_to_ygor()

func _is_key_e_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo

func _talk_to_ygor() -> void:
	if GameData.has_method("unlock_codex_entry"):
		GameData.unlock_codex_entry("npcs", "ygor")
	_show_random_dialogue()

func _show_random_dialogue() -> void:
	dialogue_active = true
	var dialogues = [
		"Ygor: Interesante...",
		"Ygor: ¿Quieres comerciar?",
		"Ygor: La carne es la única moneda aquí.",
		"Ygor: Mira mis hologramas."
	]
	interact_label.text = dialogues.pick_random()
	_start_dialogue_timer()

func _start_dialogue_timer() -> void:
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_reset_dialogue)

func _reset_dialogue() -> void:
	dialogue_active = false
	interact_label.text = "[E] Hablar con Ygor"

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
	_reset_dialogue()
