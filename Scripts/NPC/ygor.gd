extends Node2D
## Ygor – NPC de compras con cuadro de diálogo inferior (NpcDialogueBox).

const PORTRAIT_SHEET := preload("res://Scenes/Ygor/ygor_idle_24x24.png")

@onready var interact_area: Area2D = $Interact_area
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var interact_label: Label = null
var dialogue_box: NpcDialogueBox = null

var dialogue_lines: Array[String] = [
	"Interesante espécimen... Sigues entero, por ahora.",
	"¿Quieres comerciar? Mis implantes no son baratos, pero la muerte cuesta más.",
	"La carne es la única moneda que importa en estos laboratorios.",
	"Mira mis hologramas. Modifica tu cuerpo antes de que la infección lo haga por ti.",
	"No confíes en las máquinas de este lugar... solo confía en el acero que lleves pegado a los huesos.",
	"El Centinela Génesis no tolerará tu presencia por mucho tiempo. Prepárate."
]
var current_dialogue_index: int = -1

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_setup_interact_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interact_label)
	dialogue_box = NpcDialogueBox.create(self, "YGOR", "Mercader de Prótesis y Órganos", Color(0.25, 0.85, 1.0), _portrait())
	dialogue_box.closed.connect(_on_dialogue_closed)
	_setup_shadow()
	anim_sprite.play("idle")

func _portrait() -> Texture2D:
	var atlas = AtlasTexture.new()
	atlas.atlas = PORTRAIT_SHEET
	atlas.region = Rect2(0, 0, 25, 24)
	return atlas

func _setup_shadow() -> void:
	DropShadow.attach_to(self, Vector2(28.0, 14.0), Vector2(0.0, 18.0), 0.38)

func _setup_interact_label() -> void:
	interact_label = get_node_or_null("Label")
	if not interact_label:
		interact_label = _find_label_child()
	if not interact_label:
		interact_label = Label.new()
		interact_label.position = Vector2(-70, -90)
		add_child(interact_label)
	interact_label.text = "[E] Hablar con Ygor"
	interact_label.visible = false

func _find_label_child() -> Label:
	for child in get_children():
		if child is Label:
			return child
	return null

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if not event.is_action_pressed("interact") and not _is_key_e_pressed(event):
		return
	_talk_to_ygor()

func _is_key_e_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo

func _talk_to_ygor() -> void:
	GameData.unlock_codex_entry("npcs", "ygor")
	if interact_label:
		interact_label.visible = false
	current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()
	dialogue_box.say(dialogue_lines[current_dialogue_index])

func _on_dialogue_closed() -> void:
	if player_nearby and interact_label:
		interact_label.visible = true

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_nearby = true
	if not dialogue_box.active and interact_label:
		interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_nearby = false
	if interact_label:
		interact_label.visible = false
	dialogue_box.close()
