class_name UISlot
extends PanelContainer

@export var is_inventory_slot: bool = false
@export var slot_type: ItemData.ItemSlot
@export var empty_text: String = ""
@export var empty_icon_name: String = ""

var item: ItemData = null
@export var is_equipped_slot: bool = false
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

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	update_slot(item)

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

func _refresh_slot_style() -> void:
	theme_type_variation = _pick_slot_variation()
	self_modulate = Color.WHITE
	if is_highlighted or is_valid_drop_target:
		self_modulate = Color(0.3, 1.2, 1.1, 1.0)
	elif is_invalid_drop_target:
		self_modulate = Color(1.3, 0.4, 0.3, 1.0)
	elif has_synergy_affinity:
		self_modulate = Color(0.85, 0.45, 1.35, 1.0)

func _pick_slot_variation() -> String:
	if is_selected:
		return "InventorySlotSelected"
	if is_valid_drop_target:
		return "InventorySlotValid"
	if is_invalid_drop_target:
		return "InventorySlotInvalid"
	if is_hovered:
		return "InventorySlotHover"
	if is_equipped_slot:
		return "InventorySlotEquipped"
	if item == null:
		return "InventorySlotEmpty"
	return "InventorySlotNormal"

func update_slot(new_item: ItemData, qty: int = 1) -> void:
	item = new_item
	tooltip_text = ""
	# Child nodes and their layout are authored in inventory_slot.tscn.
	var empty_icon: TextureRect = $Visuals/EmptyIcon
	var empty_label: Label = $Visuals/EmptyText
	var icon: TextureRect = $Visuals/ItemIcon
	var item_label: Label = $Visuals/ItemName
	var badge: TextureRect = $Visuals/EquippedBadge
	var quantity: Label = $Visuals/Quantity
	if not empty_icon_name.is_empty():
		empty_icon.texture = load("res://Art/Ui/svg/%s.svg" % empty_icon_name)
	empty_icon.visible = item == null and empty_icon.texture != null
	empty_label.text = empty_text
	empty_label.visible = item == null and not empty_icon.visible
	icon.texture = item.icon if item else null
	icon.visible = icon.texture != null
	item_label.text = item.item_name if item else ""
	item_label.visible = item != null and not icon.visible
	badge.visible = false
	quantity.text = str(qty)
	quantity.visible = item != null and qty > 1
	_refresh_slot_style()

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
