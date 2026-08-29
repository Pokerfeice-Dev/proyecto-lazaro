extends Node2D
## Ygor – NPC de compras con cuadro de diálogo inferior.

@onready var interact_area: Area2D = $Interact_area
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player_nearby: bool = false
var interact_label: Label = null
var dialogue_active: bool = false

# UI de Diálogo Inferior
var dialogue_layer: CanvasLayer = null
var dialogue_panel: PanelContainer = null
var dialogue_text_label: Label = null
var name_badge_label: Label = null
var footer_label: Label = null
var typewriter_tween: Tween = null
var auto_close_tween: Tween = null

var dialogue_lines: Array[String] = [
	"Interesante espécimen... Sigues entero, por ahora.",
	"¿Quieres comerciar? Mis implantes no son baratos, pero la muerte cuesta más.",
	"La carne es la única moneda que importa en estos laboratorios.",
	"Mira mis hologramas. Modifica tu cuerpo antes de que la infección lo haga por ti.",
	"No confíes en las máquinas de este lugar... solo confía en el acero que lleves pegado a los huesos.",
	"El Mutante Génesis no tolerará tu presencia por mucho tiempo. Prepárate."
]
var current_dialogue_index: int = -1

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_setup_interact_label()
	_setup_dialogue_ui()
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

func _setup_dialogue_ui() -> void:
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.layer = 110
	add_child(dialogue_layer)
	
	_build_dialogue_panel()

func _build_dialogue_panel() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 180
	dialogue_panel.offset_right = -180
	dialogue_panel.offset_bottom = -30
	dialogue_panel.offset_top = -180
	dialogue_panel.modulate.a = 0.0
	dialogue_panel.visible = false
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.95)
	sb.border_color = Color(0.18, 0.75, 0.95, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	dialogue_panel.add_theme_stylebox_override("panel", sb)
	
	dialogue_layer.add_child(dialogue_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialogue_panel.add_child(vbox)
	
	_build_header_row(vbox)
	_build_body_label(vbox)
	_build_footer_row(vbox)

func _build_header_row(parent: Control) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	parent.add_child(header)
	
	name_badge_label = Label.new()
	name_badge_label.text = "◆ YGOR"
	name_badge_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	name_badge_label.add_theme_font_size_override("font_size", 20)
	name_badge_label.add_theme_color_override("font_color", Color(0.25, 0.85, 1.0))
	header.add_child(name_badge_label)
	
	var role_label = Label.new()
	role_label.text = "|  Mercader de Prótesis y Órganos"
	role_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.7))
	header.add_child(role_label)

func _build_body_label(parent: Control) -> void:
	dialogue_text_label = Label.new()
	dialogue_text_label.text = ""
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	dialogue_text_label.add_theme_font_size_override("font_size", 20)
	dialogue_text_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	dialogue_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(dialogue_text_label)

func _build_footer_row(parent: Control) -> void:
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	parent.add_child(footer)
	
	footer_label = Label.new()
	footer_label.text = "[E] Siguiente"
	footer_label.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	footer_label.add_theme_font_size_override("font_size", 14)
	footer_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 0.75))
	footer.add_child(footer_label)

func _input(event: InputEvent) -> void:
	_check_interaction_input(event)

func _check_interaction_input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if not event.is_action_pressed("interact") and not _is_key_e_pressed(event):
		return
	_talk_to_ygor()

func _is_key_e_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo

func _talk_to_ygor() -> void:
	if GameData.has_method("unlock_codex_entry"):
		GameData.unlock_codex_entry("npcs", "ygor")
	
	if interact_label:
		interact_label.visible = false
		
	_show_next_dialogue()

func _show_next_dialogue() -> void:
	dialogue_active = true
	_cancel_active_tweens()
	
	current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()
	var text = dialogue_lines[current_dialogue_index]
	
	dialogue_panel.visible = true
	_animate_panel_entrance()
	_play_typewriter_effect(text)
	_start_auto_close_timer()

func _cancel_active_tweens() -> void:
	if typewriter_tween and typewriter_tween.is_valid():
		typewriter_tween.kill()
	if auto_close_tween and auto_close_tween.is_valid():
		auto_close_tween.kill()

func _animate_panel_entrance() -> void:
	var t = create_tween()
	t.tween_property(dialogue_panel, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _play_typewriter_effect(full_text: String) -> void:
	dialogue_text_label.text = full_text
	dialogue_text_label.visible_ratio = 0.0
	
	var duration = clampf(full_text.length() * 0.02, 0.4, 1.2)
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(dialogue_text_label, "visible_ratio", 1.0, duration).set_trans(Tween.TRANS_LINEAR)

func _start_auto_close_timer() -> void:
	auto_close_tween = create_tween()
	auto_close_tween.tween_interval(4.5)
	auto_close_tween.tween_callback(_close_dialogue)

func _close_dialogue() -> void:
	if not dialogue_active:
		return
	dialogue_active = false
	_cancel_active_tweens()
	
	var t = create_tween()
	t.tween_property(dialogue_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	t.tween_callback(_on_close_dialogue_finished)

func _on_close_dialogue_finished() -> void:
	if dialogue_panel:
		dialogue_panel.visible = false
	if player_nearby and interact_label:
		interact_label.visible = true

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_nearby = true
	if not dialogue_active and interact_label:
		interact_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_nearby = false
	if interact_label:
		interact_label.visible = false
	_close_dialogue()
