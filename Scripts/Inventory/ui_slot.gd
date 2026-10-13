class_name UISlot
extends PanelContainer

@export var is_inventory_slot: bool = false
@export var slot_type: ItemData.ItemSlot
@export var empty_text: String = ""
@export var empty_icon_name: String = ""

var item: ItemData = null
var is_equipped_slot: bool = false
var is_selected: bool = false
var is_valid_drop_target: bool = false
var is_invalid_drop_target: bool = false
var is_hovered: bool = false

var has_synergy_affinity: bool = false
var is_highlighted: bool = false

signal item_dropped(item_data: ItemData, source_slot: UISlot, target_slot: UISlot)
signal slot_clicked(item_data: ItemData)
signal slot_double_clicked(item_data: ItemData, slot: UISlot)
signal slot_hovered(item_data: ItemData, slot_rect: Rect2)
signal slot_unhovered()
signal drag_started(item_data: ItemData, source_slot: UISlot)

# Texturas SVG de los 9-slice para slots
static var tex_slot_empty: Texture2D = preload("res://Art/Ui/svg/slot_empty.svg")
static var tex_slot_normal: Texture2D = preload("res://Art/Ui/svg/slot_normal.svg")
static var tex_slot_hover: Texture2D = preload("res://Art/Ui/svg/slot_hover.svg")
static var tex_slot_selected: Texture2D = preload("res://Art/Ui/svg/slot_selected.svg")
static var tex_slot_equipped: Texture2D = preload("res://Art/Ui/svg/slot_equipped.svg")
static var tex_slot_valid: Texture2D = preload("res://Art/Ui/svg/slot_valid.svg")
static var tex_slot_invalid: Texture2D = preload("res://Art/Ui/svg/slot_invalid.svg")
static var tex_badge_equipped: Texture2D = preload("res://Art/Ui/svg/badge_equipped.svg")

func _ready() -> void:
	custom_minimum_size = Vector2(80, 80)
	_setup_slot_style()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_highlight(false)
		set_drop_target_state(false, false)

func _on_mouse_entered() -> void:
	is_hovered = true
	_refresh_slot_style()
	if not item: return
	slot_hovered.emit(item, get_global_rect())

func _on_mouse_exited() -> void:
	is_hovered = false
	_refresh_slot_style()
	slot_unhovered.emit()

func set_selected(selected: bool) -> void:
	is_selected = selected
	_refresh_slot_style()

func set_drop_target_state(is_valid: bool, is_invalid: bool) -> void:
	is_valid_drop_target = is_valid
	is_invalid_drop_target = is_invalid
	_refresh_slot_style()

func set_synergy_affinity(active: bool) -> void:
	has_synergy_affinity = active
	_refresh_slot_style()

func set_highlight(active: bool) -> void:
	is_highlighted = active
	_refresh_slot_style()

func _setup_slot_style() -> void:
	_refresh_slot_style()

func _refresh_slot_style() -> void:
	var tex = _pick_slot_texture()
	var style = _create_slot_stylebox(tex)
	if is_highlighted or is_valid_drop_target:
		style.modulate_color = Color(0.3, 1.2, 1.1, 1.0)
	elif is_invalid_drop_target:
		style.modulate_color = Color(1.3, 0.4, 0.3, 1.0)
	elif has_synergy_affinity:
		style.modulate_color = Color(0.85, 0.45, 1.35, 1.0)
	add_theme_stylebox_override("panel", style)

func _pick_slot_texture() -> Texture2D:
	if is_selected:
		return tex_slot_selected
	if is_valid_drop_target:
		return tex_slot_valid
	if is_invalid_drop_target:
		return tex_slot_invalid
	if is_hovered:
		return tex_slot_hover
	if is_equipped_slot:
		return tex_slot_equipped
	if item == null:
		return tex_slot_empty
	return tex_slot_normal

func _create_slot_stylebox(tex: Texture2D) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = 16.0
	style.texture_margin_top = 16.0
	style.texture_margin_right = 16.0
	style.texture_margin_bottom = 16.0
	return style

func update_slot(new_item: ItemData, qty: int = 1) -> void:
	item = new_item
	_clear_slot_children()
	tooltip_text = ""
	_render_slot_content(qty)
	_refresh_slot_style()

func _clear_slot_children() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _render_slot_content(qty: int) -> void:
	if not item:
		_render_empty_visuals()
		return
	_render_item_icon_or_name()
	_render_item_quantity(qty)

func _render_empty_visuals() -> void:
	if not empty_icon_name.is_empty():
		_render_empty_body_icon()
		return
	if not empty_text.is_empty():
		_render_empty_text()

func _render_empty_body_icon() -> void:
	var icon_path = "res://Art/Ui/svg/" + empty_icon_name + ".svg"
	if not ResourceLoader.exists(icon_path):
		_render_empty_text()
		return
	var trect = TextureRect.new()
	trect.texture = load(icon_path)
	trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trect.custom_minimum_size = Vector2(36, 36)
	trect.modulate = Color(0.22, 0.38, 0.42, 0.5)
	trect.set_anchors_preset(Control.PRESET_FULL_RECT)
	trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trect)

func _render_empty_text() -> void:
	var lbl = Label.new()
	lbl.text = empty_text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.45, 0.48))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

func _render_item_icon_or_name() -> void:
	if item.icon:
		_render_texture_rect()
		return
	_render_item_name_label()

func _render_texture_rect() -> void:
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	add_child(margin_container)

	var trect = TextureRect.new()
	trect.texture = item.icon
	trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trect.set_anchors_preset(Control.PRESET_FULL_RECT)
	trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(trect)

func _render_item_name_label() -> void:
	var lbl = Label.new()
	lbl.text = item.item_name
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 0.94))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

func _render_item_quantity(qty: int) -> void:
	if qty <= 1: return
	var count_lbl = Label.new()
	count_lbl.text = str(qty)
	count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_lbl.offset_left = -32
	count_lbl.offset_top = -24
	count_lbl.offset_right = -8
	count_lbl.offset_bottom = -6
	count_lbl.add_theme_font_size_override("font_size", 16)
	count_lbl.add_theme_color_override("font_color", Color(0.32, 0.85, 0.78))
	count_lbl.add_theme_color_override("font_outline_color", Color(0.09, 0.11, 0.13))
	count_lbl.add_theme_constant_override("outline_size", 3)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(count_lbl)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	_handle_mouse_button(event as InputEventMouseButton)

func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index == MOUSE_BUTTON_LEFT:
		_handle_left_click(mb)
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click()

func _handle_left_click(mb: InputEventMouseButton) -> void:
	if not item: return
	if mb.double_click:
		slot_double_clicked.emit(item, self)
		return
	slot_clicked.emit(item)

func _handle_right_click() -> void:
	if not item: return
	slot_double_clicked.emit(item, self)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item: return null
	var preview = _create_drag_preview()
	set_drag_preview(preview)
	drag_started.emit(item, self)
	return {"item": item, "source_slot": self}

func _create_drag_preview() -> Control:
	var preview = Control.new()
	if item.icon:
		_add_icon_drag_preview(preview)
		return preview
	_add_text_drag_preview(preview)
	return preview

func _add_icon_drag_preview(preview: Control) -> void:
	var trect = TextureRect.new()
	trect.texture = item.icon
	trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trect.custom_minimum_size = Vector2(64, 64)
	trect.position = -trect.custom_minimum_size / 2.0
	trect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	preview.add_child(trect)

func _add_text_drag_preview(preview: Control) -> void:
	var lbl = Label.new()
	lbl.text = item.item_name
	lbl.position = Vector2(-20, -10)
	preview.add_child(lbl)

func is_valid_target_for(drag_item: ItemData) -> bool:
	if not drag_item: return false
	if is_inventory_slot: return true
	return _is_valid_equipment_slot_for(drag_item)

func _is_valid_equipment_slot_for(drag_item: ItemData) -> bool:
	if drag_item.type == ItemData.ItemType.WEAPON:
		return slot_type in [
			ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3,
			ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3
		]
	if drag_item.type == ItemData.ItemType.TORSO:
		return slot_type == ItemData.ItemSlot.TORSO
	if drag_item.type == ItemData.ItemType.ARMS:
		return slot_type in [ItemData.ItemSlot.ARM_L, ItemData.ItemSlot.ARM_R]
	if drag_item.type == ItemData.ItemType.LEGS:
		return slot_type in [ItemData.ItemSlot.LEG_L, ItemData.ItemSlot.LEG_R]
	return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY: return false
	if not data.has("item"): return false
	return is_valid_target_for(data["item"])

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var drag_item: ItemData = data["item"]
	var source_slot: UISlot = data.get("source_slot")
	if source_slot == self: return
	item_dropped.emit(drag_item, source_slot, self)
