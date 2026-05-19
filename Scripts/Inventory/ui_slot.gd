class_name UISlot
extends PanelContainer

@export var is_inventory_slot: bool = false
@export var slot_type: ItemData.ItemSlot
@export var empty_text: String = ""
var item: ItemData = null

signal item_dropped(item_data: ItemData, source_slot: UISlot, target_slot: UISlot)
signal slot_clicked(item_data: ItemData)

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)

func update_slot(new_item: ItemData) -> void:
	item = new_item
	for c in get_children():
		c.queue_free()
	
	tooltip_text = ""
	if item:
		tooltip_text = item.item_name
		if item.icon:
			var trect = TextureRect.new()
			trect.texture = item.icon
			trect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			trect.set_anchors_preset(Control.PRESET_FULL_RECT)
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
			add_child(lbl)
	else:
		var lbl = Label.new()
		lbl.text = empty_text
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
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
	elif drag_item.type == ItemData.ItemType.ARMS and slot_type == ItemData.ItemSlot.ARMS: return true
	elif drag_item.type == ItemData.ItemType.LEGS and slot_type == ItemData.ItemSlot.LEGS: return true
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var drag_item: ItemData = data["item"]
	var source_slot: UISlot = data.get("source_slot")
	if source_slot == self: return
	item_dropped.emit(drag_item, source_slot, self)
