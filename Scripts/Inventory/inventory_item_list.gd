class_name InventoryItemList
extends ItemList

func _get_drag_data(at_position: Vector2) -> Variant:
	var idx = get_item_at_position(at_position, true)
	if idx < 0: return null
	var metadata = get_item_metadata(idx)
	if not metadata is ItemData: return null
	
	var preview = Label.new()
	preview.text = metadata.item_name
	set_drag_preview(preview)
	
	return {"item": metadata, "index": idx}
