class_name BodyPartWarning
extends RefCounted

## Aviso antes de perder una pieza de cuerpo (torso, brazo o pierna). Según el
## GDD, cambiar o quitar una pieza la destruye para siempre: este cartel lo
## deja claro y pide confirmación. Usa la misma ventana que el resto de la UI
## (UIWindow), así que funciona igual con teclado, mouse y joystick.
## Uso:
##   BodyPartWarning.ask_remove(pieza, func(): ...)
##   BodyPartWarning.ask_replace(pieza_vieja, pieza_nueva, func(): ...)

const ICON := preload("res://Art/Ui/svg/icon_warning.svg")
const ICON_SIZE := 72.0

## Quitar una pieza puesta: se destruye y no vuelve a la mochila.
static func ask_remove(lost: ItemData, on_confirm: Callable) -> UIWindow:
	var text = "Si quitas [color=#F4C45E]%s[/color], la pieza se destruye y la pierdes para siempre. No vuelve a la mochila." % lost.item_name
	return _open(lost, null, text, "QUITAR Y DESTRUIR", on_confirm)

## Poner una pieza nueva encima de otra: la vieja se destruye.
static func ask_replace(lost: ItemData, new_item: ItemData, on_confirm: Callable) -> UIWindow:
	var text = "Al instalar [color=#52D8C6]%s[/color], [color=#F4C45E]%s[/color] se destruye y la pierdes para siempre. A cambio, la pieza nueva te cura un poco." % [new_item.item_name, lost.item_name]
	return _open(lost, new_item, text, "INSTALAR", on_confirm)

static func _open(lost: ItemData, new_item: ItemData, text: String, confirm_text: String, on_confirm: Callable) -> UIWindow:
	var window = UIWindow.open("  PIEZA DE CUERPO", ICON, 620.0)
	window.body.add_child(_parts_row(lost, new_item))
	window.body.add_child(_message(text))
	window.add_button("CANCELAR", false, "ESC", window.close)
	window.add_button(confirm_text, true, "E", func():
		window.close()
		on_confirm.call())
	return window

# Pieza que se pierde (tachada en rojo) y, si hay, la que entra.
static func _parts_row(lost: ItemData, new_item: ItemData) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.add_child(_part_card(lost, "SE PIERDE", UIStyle.COLOR_WARNING, true))
	if new_item:
		row.add_child(UIStyle.label("→", 30, UIStyle.COLOR_MUTED))
		row.add_child(_part_card(new_item, "ENTRA", UIStyle.COLOR_TEAL, false))
	return row

static func _part_card(item: ItemData, caption: String, color: Color, crossed: bool) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var frame = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	frame.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE) + Vector2(20, 20)
	box.add_child(frame)
	var icon = PixelIcon.make(item.icon, ICON_SIZE)
	if crossed:
		icon.modulate = Color(1, 0.55, 0.5, 0.75)
	frame.add_child(icon)
	var name_label = UIStyle.label(item.item_name, 14, UIStyle.COLOR_TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	var cap = UIStyle.label(caption, 12, color)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cap)
	return box

static func _message(text: String) -> RichTextLabel:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = "[center]" + text + "[/center]"
	label.add_theme_font_size_override("normal_font_size", 18)
	label.add_theme_color_override("default_color", UIStyle.COLOR_TEXT)
	label.custom_minimum_size.x = 540
	return label
