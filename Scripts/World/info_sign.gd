extends Node2D
class_name InfoSign

## Cartel interactivo genérico: al acercarse y presionar E, abre una ventana
## con información de introducción o lore (por ejemplo, cómo funciona
## O.M.N.I.A.), con el estilo de la UI del juego.
## Formato de sign_body: el primer párrafo en [b]negrita[/b] es el subtítulo;
## cada párrafo siguiente es un punto de la lista. Se acepta BBCode.

const ICON_INFO := preload("res://Art/Ui/svg/icon_info.svg")
const ICON_POINT := preload("res://Art/Ui/svg/icon_chevron_right.svg")

@export_multiline var sign_title: String = "O.M.N.I.A."
@export_multiline var sign_body: String = ""

@onready var area_2d: Area2D = get_node_or_null("Area2D")
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var interact_label: Label = get_node_or_null("InteractLabel")

var player_nearby: bool = false
var ui_instance: UIWindow = null

func _ready() -> void:
	set_process_input(true)
	_connect_area_signals()
	_setup_interact_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interact_label)

func _connect_area_signals() -> void:
	if not area_2d:
		return
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

func _setup_interact_label() -> void:
	if interact_label:
		interact_label.visible = false
		return
	interact_label = Label.new()
	interact_label.text = "[E] Leer cartel"
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.position = Vector2(-70, -70)
	interact_label.visible = false
	add_child(interact_label)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if interact_label and not ui_instance:
			interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if interact_label:
			interact_label.visible = false

func _input(event: InputEvent) -> void:
	if not player_nearby or ui_instance:
		return
	var is_interact = event.is_action_pressed("interact")
	if not is_interact and event is InputEventKey:
		is_interact = event.physical_keycode == KEY_E and event.pressed and not event.echo
	if is_interact:
		get_viewport().set_input_as_handled()
		_open_sign_ui()

# --- Ventana ---

func _open_sign_ui() -> void:
	if interact_label:
		interact_label.visible = false
	ui_instance = UIWindow.open("  " + sign_title.to_upper(), ICON_INFO, 640.0)
	ui_instance.closed.connect(_on_sign_closed)
	var paragraphs = _paragraphs()
	ui_instance.body.add_child(_header(paragraphs[0] if not paragraphs.is_empty() else ""))
	for i in range(1, paragraphs.size()):
		ui_instance.body.add_child(_point(paragraphs[i]))
	ui_instance.add_button("ENTENDIDO", true, "E", ui_instance.close)

func _on_sign_closed() -> void:
	ui_instance = null
	if interact_label:
		interact_label.visible = player_nearby

func _paragraphs() -> PackedStringArray:
	var out = PackedStringArray()
	for p in sign_body.split("\n\n", false):
		if p.strip_edges() != "":
			out.append(p.strip_edges())
	return out

# Título grande dorado y, debajo, el subtítulo (el primer párrafo) en turquesa.
func _header(subtitle: String) -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var title = UIStyle.label(sign_title, 34, UIStyle.COLOR_GOLD)
	box.add_child(title)
	if subtitle != "":
		var sub = _rich(subtitle.replace("[b]", "").replace("[/b]", ""), 15, UIStyle.COLOR_TEAL)
		box.add_child(sub)
	return box

func _point(text: String) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var bullet = UIStyle.icon(ICON_POINT, 18)
	bullet.modulate = UIStyle.COLOR_TEAL
	bullet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(bullet)
	var label = _rich(text, 16, UIStyle.COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row

func _rich(text: String, size: int, color: Color) -> RichTextLabel:
	var r = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = text
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
