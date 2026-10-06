class_name UISlot
extends PanelContainer

@export var is_inventory_slot: bool = false
@export var slot_type: ItemData.ItemSlot
@export var empty_text: String = ""
var item: ItemData = null

signal item_dropped(item_data: ItemData, source_slot: UISlot, target_slot: UISlot)
signal slot_clicked(item_data: ItemData)
signal slot_double_clicked(item_data: ItemData, slot: UISlot)
signal slot_hovered(item_data: ItemData, slot_rect: Rect2)
signal slot_unhovered()
signal drag_started(item_data: ItemData, source_slot: UISlot)

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	_setup_slot_style()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		set_highlight(false)

func _on_mouse_entered() -> void:
	if not item:
		return
	slot_hovered.emit(item, get_global_rect())

func _on_mouse_exited() -> void:
	slot_unhovered.emit()

var has_synergy_affinity: bool = false
var is_highlighted: bool = false
var _synergy_badge: Label = null

func _setup_slot_style() -> void:
	var style = StyleBoxTexture.new()
	style.texture = load("res://Art/Ui/Cell 2.png")
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)

func set_synergy_affinity(active: bool) -> void:
	has_synergy_affinity = active
	_refresh_slot_style()
	_update_synergy_badge()

func set_highlight(active: bool) -> void:
	is_highlighted = active
	_refresh_slot_style()

func _refresh_slot_style() -> void:
	if is_highlighted:
		_apply_highlight_style()
		return
	if has_synergy_affinity:
		_apply_synergy_style()
		return
	_setup_slot_style()

func _apply_synergy_style() -> void:
	var style = StyleBoxTexture.new()
	style.texture = load("res://Art/Ui/Cell 2.png")
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	style.modulate_color = Color(0.85, 0.45, 1.35, 1.0)
	add_theme_stylebox_override("panel", style)

func _update_synergy_badge() -> void:
	if not has_synergy_affinity or not item:
		_hide_synergy_badge()
		return
	_ensure_and_show_synergy_badge()

func _hide_synergy_badge() -> void:
	if _synergy_badge:
		_synergy_badge.visible = false

func _ensure_and_show_synergy_badge() -> void:
	if not _synergy_badge:
		_create_synergy_badge()
	_synergy_badge.visible = true

func _create_synergy_badge() -> void:
	_synergy_badge = Label.new()
	_synergy_badge.text = "SYN"
	_synergy_badge.add_theme_font_size_override("font_size", 9)
	_synergy_badge.add_theme_color_override("font_color", Color(0.9, 0.6, 1.0))
	_synergy_badge.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.2))
	_synergy_badge.add_theme_constant_override("outline_size", 3)
	_synergy_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_synergy_badge.position = Vector2(custom_minimum_size.x - 24, 2)
	_synergy_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_synergy_badge)

func _apply_highlight_style() -> void:
	var style = StyleBoxTexture.new()
	style.texture = load("res://Art/Ui/Cell 2.png")
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	style.modulate_color = Color(0.2, 1.4, 1.0, 1.0)
	add_theme_stylebox_override("panel", style)

func update_slot(new_item: ItemData, qty: int = 1) -> void:
	item = new_item
	_clear_slot_children()
	tooltip_text = ""
	_render_slot_content(qty)
	_refresh_slot_style()
	_update_synergy_badge()

func _clear_slot_children() -> void:
	_synergy_badge = null
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _render_slot_content(qty: int) -> void:
	if not item:
		_render_empty_text()
		return
	_render_item_icon_or_name()
	_render_item_quantity(qty)

func _render_empty_text() -> void:
	var lbl = Label.new()
	lbl.text = empty_text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

func _render_item_icon_or_name() -> void:
	if item.icon:
		_render_texture_rect()
		return
	_render_item_name_label()

func _render_texture_rect() -> void:
	var trect = TextureRect.new()
	trect.texture = item.icon
	trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trect.set_anchors_preset(Control.PRESET_FULL_RECT)
	trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(trect)

func _render_item_name_label() -> void:
	var lbl = Label.new()
	lbl.text = item.item_name
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

func _render_item_quantity(qty: int) -> void:
	if qty <= 1:
		return
	var helper_control = Control.new()
	helper_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	helper_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(helper_control)
	
	var count_lbl = Label.new()
	count_lbl.text = str(qty)
	count_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	count_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	count_lbl.offset_left = -20
	count_lbl.offset_top = -16
	count_lbl.offset_right = -4
	count_lbl.offset_bottom = -2
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count_lbl.add_theme_font_size_override("font_size", 10)
	count_lbl.add_theme_color_override("font_color", Color(0, 1, 0.8))
	count_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	count_lbl.add_theme_constant_override("outline_size", 3)
	count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	helper_control.add_child(count_lbl)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	_handle_mouse_button(event as InputEventMouseButton)

func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	if mb.button_index == MOUSE_BUTTON_LEFT:
		_handle_left_click(mb)
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click()

func _handle_left_click(mb: InputEventMouseButton) -> void:
	if not item:
		return
	if mb.double_click:
		slot_double_clicked.emit(item, self)
		return
	slot_clicked.emit(item)

func _handle_right_click() -> void:
	if not item:
		return
	slot_double_clicked.emit(item, self)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item:
		return null
	
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
	preview.add_child(trect)

func _add_text_drag_preview(preview: Control) -> void:
	var lbl = Label.new()
	lbl.text = item.item_name
	lbl.position = Vector2(-20, -10)
	preview.add_child(lbl)

func is_valid_target_for(drag_item: ItemData) -> bool:
	if not drag_item:
		return false
	if is_inventory_slot:
		return true
	return _is_valid_equipment_slot_for(drag_item)

func _is_valid_equipment_slot_for(drag_item: ItemData) -> bool:
	if drag_item.type == ItemData.ItemType.WEAPON:
		return slot_type in [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3, ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]
	if drag_item.type == ItemData.ItemType.TORSO:
		return slot_type == ItemData.ItemSlot.TORSO
	if drag_item.type == ItemData.ItemType.ARMS:
		return slot_type in [ItemData.ItemSlot.ARM_L, ItemData.ItemSlot.ARM_R]
	if drag_item.type == ItemData.ItemType.LEGS:
		return slot_type in [ItemData.ItemSlot.LEG_L, ItemData.ItemSlot.LEG_R]
	return false

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item"):
		return false
	return is_valid_target_for(data["item"])

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var drag_item: ItemData = data["item"]
	var source_slot: UISlot = data.get("source_slot")
	if source_slot == self:
		return
	item_dropped.emit(drag_item, source_slot, self)

