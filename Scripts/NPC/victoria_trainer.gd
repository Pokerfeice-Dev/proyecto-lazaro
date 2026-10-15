extends Node2D
## Victoria en la sala de entrenamiento: da consejos y charla un poco, con el
## mismo cuadro de diálogo que Ygor (NpcDialogueBox). El cuerpo es la escena de
## Victoria de O.M.N.I.A. (npc_chatarra.tscn) instanciada como "Body".

const PORTRAIT_SHEET := preload("res://Art/npc/drwollstonecraft_idle_16x36.png")
const ACCENT := Color("#52D8C6")

const FIRST_LINE := "Bienvenido al simulador, Lázaro. Aquí nada es permanente: todo lo que pruebes se borra al salir."
const LINES: Array[String] = [
	"El esquive te vuelve intangible por un instante. Úsalo para atravesar proyectiles, no solo para huir.",
	"Las sinergias aparecen cuando juntas tres piezas compatibles en un arma. La incubadora te deja probarlas sin riesgo.",
	"En la armería puedes cambiar de arma cuando quieras. Prueba combinaciones antes de bajar.",
	"Si un enemigo marca el suelo o brilla, está por atacar. Lee la señal y muévete antes del golpe.",
	"La chatarra se queda contigo aunque caigas. Invierte en O.M.N.I.A. entre cada despliegue.",
	"El códice registra todo lo que encuentras: enemigos, objetos y sinergias. Ábrelo con la I cuando quieras.",
	"Manny no siente dolor. Golpéalo todo lo que quieras; para eso lo construí.",
	"En La Cripta, los ghouls te persiguen más rápido cuando les das la espalda. Míralos de frente.",
	"¿Te duele algo? Es normal. Tu cuerpo todavía está aprendiendo a estar vivo otra vez.",
	"A veces me pregunto si el primer intento sigue ahí abajo, en la cripta... Olvídalo. Concéntrate.",
	"Ygor vende piezas útiles, pero no le creas todo lo que dice sobre su mercadería.",
]

@onready var area: Area2D = get_node_or_null("Body/Area2D")

var player_nearby := false
var interact_label: Label
var dialogue_box: NpcDialogueBox
var _index := -1
var _greeted := false

func _ready() -> void:
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	interact_label = Label.new()
	interact_label.text = "[E] Hablar con Victoria"
	interact_label.position = Vector2(-90, -78)
	interact_label.custom_minimum_size = Vector2(180, 20)
	interact_label.visible = false
	add_child(interact_label)
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interact_label)
	dialogue_box = NpcDialogueBox.create(self, "VICTORIA", "Científica de O.M.N.I.A.", ACCENT, _portrait())
	dialogue_box.closed.connect(_on_dialogue_closed)

func _portrait() -> Texture2D:
	var atlas = AtlasTexture.new()
	atlas.atlas = PORTRAIT_SHEET
	atlas.region = Rect2(0, 0, 17, 20)
	return atlas

func _input(event: InputEvent) -> void:
	if not player_nearby: return
	var pressed = event.is_action_pressed("interact")
	if not pressed and event is InputEventKey:
		pressed = event.physical_keycode == KEY_E and event.pressed and not event.echo
	if not pressed: return
	get_viewport().set_input_as_handled()
	_talk()

func _talk() -> void:
	GameData.unlock_codex_entry("npcs", "victoria")
	interact_label.visible = false
	if not _greeted:
		_greeted = true
		dialogue_box.say(FIRST_LINE)
		return
	_index = (_index + 1) % LINES.size()
	dialogue_box.say(LINES[_index])

func _on_dialogue_closed() -> void:
	interact_label.visible = player_nearby

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_nearby = true
	interact_label.visible = not dialogue_box.active

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_nearby = false
	interact_label.visible = false
	dialogue_box.close()
