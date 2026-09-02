extends Node2D
class_name InfoSign

## Cartel interactivo genérico: al acercarse y presionar E, muestra un panel
## con información de introducción/lore (ej: cómo funciona O.M.N.I.A.)

@export_multiline var sign_title: String = "O.M.N.I.A."
@export_multiline var sign_body: String = ""

@onready var area_2d: Area2D = get_node_or_null("Area2D")

var player_nearby: bool = false
var interact_label: Label = null
var ui_instance: CanvasLayer = null

func _ready() -> void:
	set_process_input(true)
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.body_exited.connect(_on_body_exited)
	_setup_interact_label()

func _setup_interact_label() -> void:
	interact_label = Label.new()
	interact_label.text = "[E] Leer cartel"
	interact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interact_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	interact_label.add_theme_font_size_override("font_size", 16)
	interact_label.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0))
	interact_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interact_label.add_theme_constant_override("outline_size", 4)
	interact_label.position = Vector2(-70, -70)
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
		_close_sign_ui()

func _input(event: InputEvent) -> void:
	if not player_nearby:
		return

	var is_interact = event.is_action_pressed("interact")
	if not is_interact and event is InputEventKey:
		if event.physical_keycode == KEY_E and event.pressed and not event.echo:
			is_interact = true

	if is_interact and not ui_instance:
		_open_sign_ui()

func _open_sign_ui() -> void:
	get_tree().paused = true
	if interact_label:
		interact_label.visible = false

	ui_instance = CanvasLayer.new()
	ui_instance.name = "InfoSignPanel"
	ui_instance.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_instance.layer = 220
	get_tree().root.add_child(ui_instance)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_instance.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_instance.add_child(center)

	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	sb.border_color = Color(0.2, 0.7, 1.0, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 35
	sb.content_margin_right = 35
	sb.content_margin_top = 25
	sb.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = sign_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	vbox.add_child(title)

	var sep = HSeparator.new()
	vbox.add_child(sep)

	var body = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.text = sign_body
	body.add_theme_font_override("normal_font", load("res://Art/Fonts/Exo2-Regular.otf"))
	body.add_theme_font_size_override("normal_font_size", 15)
	body.add_theme_color_override("default_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(body)

	var close_btn = Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(140, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	close_btn.add_theme_font_size_override("font_size", 14)

	var sb_c_normal = StyleBoxFlat.new()
	sb_c_normal.bg_color = Color(0.1, 0.22, 0.32)
	sb_c_normal.border_color = Color(0.2, 0.6, 0.8)
	sb_c_normal.set_border_width_all(1)
	sb_c_normal.set_corner_radius_all(5)

	var sb_c_hover = StyleBoxFlat.new()
	sb_c_hover.bg_color = Color(0.14, 0.28, 0.4)
	sb_c_hover.border_color = Color(0.3, 0.7, 0.9)
	sb_c_hover.set_border_width_all(1)
	sb_c_hover.set_corner_radius_all(5)

	close_btn.add_theme_stylebox_override("normal", sb_c_normal)
	close_btn.add_theme_stylebox_override("hover", sb_c_hover)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	vbox.add_child(close_btn)
	close_btn.pressed.connect(_close_sign_ui)

func _close_sign_ui() -> void:
	if ui_instance:
		ui_instance.queue_free()
		ui_instance = null
		get_tree().paused = false
		if interact_label:
			interact_label.visible = player_nearby
