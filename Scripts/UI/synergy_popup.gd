extends CanvasLayer

const UI_SOUND_PATH = "res://Audio/Sfx/Piano_Ui (2).wav"

var synergy_name: String = ""
var synergy_desc: String = ""

var _blur_rect: ColorRect
var _panel: PanelContainer
var _title_lbl: Label
var _name_lbl: Label
var _desc_lbl: Label
var _continue_btn: Button
var _continue_prompt: Label

func setup(syn_name: String, syn_desc: String) -> void:
	synergy_name = syn_name
	synergy_desc = syn_desc

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui_elements()
	_play_activation_sound()
	_animate_entrance()

func _input(event: InputEvent) -> void:
	if not _is_close_action(event):
		return
	get_viewport().set_input_as_handled()
	_on_continue_pressed()

func _is_close_action(event: InputEvent) -> bool:
	if event.is_action_pressed("interact"):
		return true
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		return true
	return false

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

func _create_center_panel(parent: Control) -> void:
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 300)
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -250
	_panel.offset_top = -150
	_panel.offset_right = 250
	_panel.offset_bottom = 150
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.pivot_offset = Vector2(250, 150)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	sb.border_color = Color(0.0, 0.8, 0.5, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0.8, 0.5, 0.15)
	sb.shadow_size = 20
	sb.content_margin_left = 32
	sb.content_margin_right = 32
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", sb)
	
	parent.add_child(_panel)

func _create_content_labels() -> void:
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)
	
	_title_lbl = Label.new()
	_title_lbl.text = "¡SINERGIA DESBLOQUEADA!"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	vbox.add_child(_title_lbl)
	
	_name_lbl = Label.new()
	_name_lbl.text = synergy_name.to_upper()
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	_name_lbl.add_theme_font_size_override("font_size", 24)
	_name_lbl.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	vbox.add_child(_name_lbl)
	
	_desc_lbl = Label.new()
	_desc_lbl.text = synergy_desc
	_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	_desc_lbl.add_theme_font_size_override("font_size", 14)
	_desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(_desc_lbl)
	
	_continue_prompt = Label.new()
	_continue_prompt.text = "Presiona [E] para continuar"
	_continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_prompt.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	_continue_prompt.add_theme_font_size_override("font_size", 12)
	_continue_prompt.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(_continue_prompt)

func _create_continue_button() -> void:
	var vbox = _panel.get_child(0)
	
	_continue_btn = Button.new()
	_continue_btn.text = "CONTINUAR"
	_continue_btn.custom_minimum_size = Vector2(150, 36)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_continue_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_continue_btn.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	_continue_btn.add_theme_font_size_override("font_size", 14)
	
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.0, 0.6, 0.4)
	sb_norm.set_border_width_all(1)
	sb_norm.border_color = Color(0.0, 0.8, 0.5)
	sb_norm.set_corner_radius_all(6)
	
	var sb_hov = StyleBoxFlat.new()
	sb_hov.bg_color = Color(0.0, 0.8, 0.5)
	sb_hov.set_border_width_all(1)
	sb_hov.border_color = Color(0.0, 1.0, 0.6)
	sb_hov.set_corner_radius_all(6)
	
	_continue_btn.add_theme_stylebox_override("normal", sb_norm)
	_continue_btn.add_theme_stylebox_override("hover", sb_hov)
	_continue_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

func _play_activation_sound() -> void:
	if ResourceLoader.exists(UI_SOUND_PATH):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(UI_SOUND_PATH)
		sfx.bus = "Master"
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(sfx)
		sfx.play()

func _animate_entrance() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_blur_intensity, 0.0, 3.5, 0.6)
	tween.tween_method(_set_brightness_intensity, 1.0, 0.4, 0.6)
	
	_panel.scale = Vector2(0.3, 0.3)
	_panel.modulate.a = 0.0
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.6)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.6)

func _set_blur_intensity(val: float) -> void:
	if _blur_rect and _blur_rect.material:
		_blur_rect.material.set_shader_parameter("blur_amount", val)

func _set_brightness_intensity(val: float) -> void:
	if _blur_rect and _blur_rect.material:
		_blur_rect.material.set_shader_parameter("brightness", val)

func _on_continue_pressed() -> void:
	set_process_input(false)
	_continue_btn.disabled = true
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_method(_set_blur_intensity, 3.5, 0.0, 0.4)
	tween.tween_method(_set_brightness_intensity, 0.4, 1.0, 0.4)
	tween.tween_property(_panel, "scale", Vector2(0.5, 0.5), 0.4)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.4)
	
	tween.chain().tween_callback(func():
		get_tree().paused = false
		queue_free()
	)
