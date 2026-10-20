extends Node

func _ready() -> void:
	var hud = HUD.new()
	var rect = TextureRect.new()
	var icon = preload("res://Art/Scrap/Scrap_icon.png")
	hud._show_weapon_icon(rect, null)
	assert(rect.texture == null)
	hud._show_weapon_icon(rect, icon)
	assert(rect.texture != null)
	var first_texture = rect.texture
	hud._show_weapon_icon(rect, icon)
	assert(rect.texture == first_texture)
	hud._show_weapon_icon(rect, null)
	assert(rect.texture == null and not rect.has_meta("source"))
	hud._show_weapon_icon(rect, null)
	hud._show_weapon_icon(rect, icon)
	assert(rect.texture != null)
	rect.free()
	hud.free()
	print("HUD_WEAPON_ICON_OK")
	get_tree().quit()
