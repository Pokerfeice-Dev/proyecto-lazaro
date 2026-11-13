extends PanelContainer

var _message: RichTextLabel

func _ready() -> void:
	name = "InventoryReminder"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	offset_left = -360
	offset_right = 360
	offset_top = 135
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#102126ed")
	style.border_color = UIStyle.COLOR_TEAL
	style.border_width_left = 3
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	_message = RichTextLabel.new()
	_message.bbcode_enabled = true
	_message.fit_content = true
	_message.scroll_active = false
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.add_theme_font_size_override("normal_font_size", 22)
	_message.add_theme_color_override("default_color", UIStyle.COLOR_TEXT)
	add_child(_message)
	GameData.inventory_guidance_changed.connect(_refresh)
	InputMode.instance().mode_changed.connect(_on_input_mode_changed)
	get_viewport().size_changed.connect(_resize)
	_resize()
	_refresh()

func _resize() -> void:
	var half_width := minf(360.0, (get_viewport_rect().size.x - 40.0) * 0.5)
	offset_left = -half_width
	offset_right = half_width

func _on_input_mode_changed(_gamepad: bool) -> void:
	_refresh()

func _refresh() -> void:
	visible = GameData.needs_inventory_reminder()
	var key := "Y" if InputMode.is_gamepad() else "I"
	_message.text = "[center]Toca %s para abrir el inventario y equipar objetos[/center]" % UIStyle.colored_text(key, "positive")
