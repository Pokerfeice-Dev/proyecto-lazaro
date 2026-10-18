extends CanvasLayer
class_name InventoryTutorialPopup

const UI_SOUND_PATH = "res://Audio/Sfx/Piano_Ui (2).wav"
const ICON_INFO := preload("res://Art/Ui/svg/icon_info.svg")

var _blur_rect: ColorRect
var _panel: Control
var _title_lbl: Label
var _desc_lbl: Label
var _continue_btn: Button
var _open_btn: Button
var _vbox: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_create_ui_elements()
	PadFocus.push_modal(self, _continue_btn) # con joystick el foco queda en el cartel
	_play_activation_sound()
	_animate_entrance()

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
		
	if event.is_action_pressed("toggle_inventory"):
		get_viewport().set_input_as_handled()
		_dismiss_popup(true)
	elif InputMode.is_interact(event) or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_dismiss_popup(false)

func _create_ui_elements() -> void:
	_create_blur_overlay()
	
	# Create a full-screen root control so anchors work perfectly inside CanvasLayer
	var root_control = Control.new()
	root_control.anchor_left = 0.0
	root_control.anchor_top = 0.0
	root_control.anchor_right = 1.0
	root_control.anchor_bottom = 1.0
	root_control.offset_left = 0.0
	root_control.offset_top = 0.0
	root_control.offset_right = 0.0
	root_control.offset_bottom = 0.0
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	_create_center_panel(root_control)
	_create_content_labels()
	_create_continue_button()

func _create_blur_overlay() -> void:
	_blur_rect = ColorRect.new()
	_blur_rect.anchor_left = 0.0
	_blur_rect.anchor_top = 0.0
	_blur_rect.anchor_right = 1.0
	_blur_rect.anchor_bottom = 1.0
	_blur_rect.offset_left = 0.0
	_blur_rect.offset_top = 0.0
	_blur_rect.offset_right = 0.0
	_blur_rect.offset_bottom = 0.0
	
	var shader = Shader.new()
	shader.code = _get_blur_shader_code()
	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("blur_amount", 0.0)
	mat.set_shader_parameter("brightness", 1.0)
	_blur_rect.material = mat
	
	add_child(_blur_rect)

func _get_blur_shader_code() -> String:
	return """shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform float brightness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
	color.rgb *= brightness;
	COLOR = color;
}
"""

# Ventana con el estilo de la UI del juego: pestaña de título, panel principal,
# una tecla "I" grande que se aprieta sola y los dos botones con su tecla.
func _create_center_panel(parent: Control) -> void:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var window = VBoxContainer.new()
	window.add_theme_constant_override("separation", 0)
	window.custom_minimum_size.x = 540
	center.add_child(window)
	var tab = UIStyle.title_tab("  TUTORIAL")
	tab.icon = ICON_INFO
	tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	window.add_child(tab)
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	window.add_child(panel)
	var m = UIStyle.padded(24)
	panel.add_child(m)
	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 16)
	m.add_child(_vbox)
	_panel = window

func _create_content_labels() -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	_vbox.add_child(row)
	row.add_child(_key_illustration())
	var texts = VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.add_theme_constant_override("separation", 8)
	row.add_child(texts)
	_title_lbl = UIStyle.label("INVENTARIO", 24, UIStyle.COLOR_GOLD)
	texts.add_child(_title_lbl)
	_desc_lbl = UIStyle.label(_desc_text(), 16, UIStyle.COLOR_TEXT)
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_desc_lbl)
	InputMode.instance().mode_changed.connect(_on_input_mode_changed)
	_vbox.add_child(UIStyle.divider())

func _desc_text() -> String:
	var how = "con el botón Y" if InputMode.is_gamepad() else "con la tecla I"
	return "Abre el inventario %s para equipar los objetos que encuentres en tus armas y en tu cuerpo." % how

func _on_input_mode_changed(_gamepad: bool) -> void:
	_desc_lbl.text = _desc_text()

# Tecla "I" grande dentro de un casillero; cada tanto se hunde como si la apretaran.
func _key_illustration() -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped"])
	frame.custom_minimum_size = Vector2(112, 112)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var center = CenterContainer.new()
	frame.add_child(center)
	var key = UIStyle.keycap("I")
	key.custom_minimum_size = Vector2(64, 64)
	key.get_child(0).add_theme_font_size_override("font_size", 30)
	center.add_child(key)
	key.resized.connect(func(): key.pivot_offset = key.size / 2.0)
	var t = key.create_tween().set_loops()
	t.tween_interval(0.8)
	t.tween_property(key, "scale", Vector2(0.86, 0.86), 0.08).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(key, "modulate", Color(1.5, 1.5, 1.5), 0.08)
	t.tween_property(key, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(key, "modulate", Color.WHITE, 0.25)
	return frame

func _create_continue_button() -> void:
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	_vbox.add_child(footer)
	footer.add_child(UIStyle.keycap("E", "A"))
	_continue_btn = UIStyle.button("ENTENDIDO", false, Vector2(150, 46), 17)
	_continue_btn.pressed.connect(func(): _dismiss_popup(false))
	footer.add_child(_continue_btn)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	_open_btn = UIStyle.button("ABRIR INVENTARIO", true, Vector2(220, 46), 18)
	_open_btn.pressed.connect(func(): _dismiss_popup(true))
	footer.add_child(_open_btn)
	footer.add_child(UIStyle.keycap("I"))

func _play_activation_sound() -> void:
	if ResourceLoader.exists(UI_SOUND_PATH):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(UI_SOUND_PATH)
		sfx.bus = "SFX"
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(sfx)
		sfx.play()

func _animate_entrance() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_blur_intensity, 0.0, 3.5, 0.6)
	tween.tween_method(_set_brightness_intensity, 1.0, 0.4, 0.6)
	
	_panel.modulate.a = 0.0
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.9, 0.9)
	var pop = _panel.create_tween()
	pop.tween_property(_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_blur_intensity(val: float) -> void:
	if _blur_rect and _blur_rect.material:
		_blur_rect.material.set_shader_parameter("blur_amount", val)

func _set_brightness_intensity(val: float) -> void:
	if _blur_rect and _blur_rect.material:
		_blur_rect.material.set_shader_parameter("brightness", val)

func _dismiss_popup(open_inventory: bool) -> void:
	set_process_input(false)
	_continue_btn.disabled = true
	_open_btn.disabled = true
	_panel.pivot_offset = _panel.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_blur_intensity, 3.5, 0.0, 0.4)
	tween.tween_method(_set_brightness_intensity, 0.4, 1.0, 0.4)
	tween.tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.25)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.25)
	
	tween.chain().tween_callback(func():
		get_tree().paused = false
		if open_inventory:
			_open_player_inventory()
		queue_free()
	)

func _open_player_inventory() -> void:
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		var inv_ui = p.find_child("InventoryUI", true, false)
		if inv_ui and inv_ui.has_method("toggle_visibility"):
			inv_ui.toggle_visibility()
			break
