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
	"El Centinela Génesis no tolerará tu presencia por mucho tiempo. Prepárate.",
	"¿Ves la máquina roja? Te remienda la carne... y cada vez cobra un poco más. Así es el negocio.",
	"La máquina de la suerte es honesta: a veces te da algo, a veces te da nada. Como la vida misma.",
	"¿Mochila llena? Échale tus porquerías a la recicladora. Yo pago en carne, no en sentimientos.",
]

## Comentarios cortos que Ygor suelta (sobre su cabeza) cuando usas sus máquinas
const QUIPS := {
	"vida": ["Así me gusta, bien remendado.", "Cada parche sale más caro, espécimen.", "Otra costura más... ya pareces un mapa."],
	"vida_llena": ["Estás entero. No vendo salud a quien no la necesita... bueno, sí, pero hoy no."],
	"azar_nada": ["Jeje. La casa siempre gana.", "Mala suerte. Prueba otra vez... insisto.", "Nada. Qué pena. Para ti."],
	"azar_premio": ["¡Vaya! Esa máquina no suele ser tan generosa.", "Disfrútalo. No va a pasar seguido."],
	"azar_rota": ["Rompiste mi máquina. Ya no da más premios, codicioso."],
	"reciclaje": ["Mm, chatarra con olor a carne. Me sirve.", "Todo se aprovecha en este laboratorio.", "Gracias por la donación."],
	"mochila_llena": ["Tu mochila no da para más. Suelta algo con Q... o recicla."],
}
var _quip_label: Label = null
var _quip_cooldown := 0.0
var current_dialogue_index: int = -1

## Máquinas de la tienda: posición relativa a Ygor según la sala
const MACHINE_KINDS := ["vida", "azar", "reciclaje"]
const MACHINE_OFFSETS := [Vector2(-88, 184), Vector2(0, 184), Vector2(88, 184)]
const MACHINE_OFFSETS_YGOR2 := [Vector2(-128, 102), Vector2(0, 102), Vector2(128, 102)]

func _ready() -> void:
	add_to_group("ygor")
	call_deferred("_spawn_machines")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_setup_interact_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interact_label)
	dialogue_box = NpcDialogueBox.create(self, "YGOR", "Mercader de Prótesis y Órganos", Color(0.25, 0.85, 1.0), _portrait())
	dialogue_box.closed.connect(_on_dialogue_closed)
	_setup_shadow()
	anim_sprite.play("idle")

func _process(delta: float) -> void:
	_quip_cooldown = maxf(0.0, _quip_cooldown - delta)

## Una máquina avisa qué pasó; Ygor a veces lo comenta (siempre la primera vez).
func comment(kind: String, always: bool = false) -> void:
	if not QUIPS.has(kind): return
	if _quip_cooldown > 0.0 and not always: return
	if not always and randf() > 0.6: return
	_quip_cooldown = 4.0
	_show_quip(QUIPS[kind].pick_random())

func _show_quip(text: String) -> void:
	if is_instance_valid(_quip_label): _quip_label.queue_free()
	var l = UIStyle.label(text, 22, Color(0.55, 0.95, 1.0))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	l.add_theme_constant_override("outline_size", 6)
	l.size = Vector2(520, 0)
	l.scale = Vector2(0.4, 0.4)
	l.position = Vector2(-104, -78)
	l.z_index = 70
	add_child(l)
	_quip_label = l
	l.modulate.a = 0.0
	var t = l.create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.2)
	t.tween_interval(2.8)
	t.tween_property(l, "modulate:a", 0.0, 0.4)
	t.tween_callback(l.queue_free)

func _spawn_machines() -> void:
	var room = get_parent()
	if not room or room.get_node_or_null("YgorMachines"): return
	var holder = Node2D.new()
	holder.name = "YgorMachines"
	room.add_child(holder)
	var offsets = MACHINE_OFFSETS_YGOR2 if _room_file().contains("Ygor2") else MACHINE_OFFSETS
	for i in MACHINE_KINDS.size():
		var m = YgorMachine.create(MACHINE_KINDS[i])
		m.position = position + offsets[i]
		holder.add_child(m)

func _room_file() -> String:
	var room = owner if owner else get_parent()
	return room.scene_file_path if room else ""

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
	return InputMode.is_interact(event) # E o X del joystick

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
