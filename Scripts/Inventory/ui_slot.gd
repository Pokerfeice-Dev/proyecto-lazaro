class_name UISlot
extends PanelContainer

@export var is_inventory_slot: bool = false
@export var slot_type: ItemData.ItemSlot
@export var empty_text: String = ""
var item: ItemData = null

signal item_dropped(item_data: ItemData, source_slot: UISlot, target_slot: UISlot)
signal slot_clicked(item_data: ItemData)
signal slot_hovered(item_data: ItemData, slot_rect: Rect2)
signal slot_unhovered()

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	_setup_slot_style()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if item:
		slot_hovered.emit(item, get_global_rect())

func _on_mouse_exited() -> void:
	slot_unhovered.emit()

func _setup_slot_style() -> void:
	var style = StyleBoxTexture.new()
	style.texture = load("res://Art/Ui/Cell 2.png")
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)

func update_slot(new_item: ItemData, qty: int = 1) -> void:
	item = new_item
	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	tooltip_text = ""
	if item:
		if item.icon:
			var trect = TextureRect.new()
			trect.texture = item.icon
			trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			trect.set_anchors_preset(Control.PRESET_FULL_RECT)
			trect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(trect)
		else:
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
		
		# Mostrar cantidad si es mayor a 1
		if qty > 1:
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
			count_lbl.add_theme_color_override("font_color", Color(0, 1, 0.8)) # Color cian/verde
			count_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
			count_lbl.add_theme_constant_override("outline_size", 3)
			count_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			helper_control.add_child(count_lbl)
	else:
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if item:
			slot_clicked.emit(item)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not item: return null
	
	var preview = Control.new()
	if item.icon:
		var trect = TextureRect.new()
		trect.texture = item.icon
		trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		trect.custom_minimum_size = Vector2(64, 64)
		trect.position = -trect.custom_minimum_size / 2.0
		preview.add_child(trect)
	else:
		var lbl = Label.new()
		lbl.text = item.item_name
		lbl.position = Vector2(-20, -10)
		preview.add_child(lbl)
		
	set_drag_preview(preview)
	return {"item": item, "source_slot": self}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY: return false
	if not data.has("item"): return false
	if is_inventory_slot: return true
	var drag_item: ItemData = data["item"]
	
	if drag_item.type == ItemData.ItemType.WEAPON:
		if slot_type in [ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3, ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3]:
			return true
	elif drag_item.type == ItemData.ItemType.TORSO and slot_type == ItemData.ItemSlot.TORSO: return true
	elif drag_item.type == ItemData.ItemType.ARMS and slot_type in [ItemData.ItemSlot.ARM_L, ItemData.ItemSlot.ARM_R]: return true
	elif drag_item.type == ItemData.ItemType.LEGS and slot_type in [ItemData.ItemSlot.LEG_L, ItemData.ItemSlot.LEG_R]: return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var drag_item: ItemData = data["item"]
	var source_slot: UISlot = data.get("source_slot")
	if source_slot == self: return
	item_dropped.emit(drag_item, source_slot, self)
