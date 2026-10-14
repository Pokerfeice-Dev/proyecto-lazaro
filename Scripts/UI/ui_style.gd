extends RefCounted
class_name UIStyle

## Estilo de la UI nueva (la del inventario): paneles y botones con los SVG de
## res://Art/Ui/svg en 9-slice y la misma paleta. Lo usan los menús que siguen
## esa línea visual (por ahora el menú de pausa).

const COLOR_TEXT := Color("#E5EEF0")
const COLOR_MUTED := Color("#8DAAB4")
const COLOR_GOLD := Color("#F4C45E")
const COLOR_TEAL := Color("#52D8C6")
const COLOR_DARK := Color("#171D22")
const COLOR_BACKDROP := Color(0.0, 0.0, 0.0, 0.75)

const TEX_PANEL_MAIN := preload("res://Art/Ui/svg/panel_main.svg")
const TEX_PANEL_INSET := preload("res://Art/Ui/svg/panel_inset.svg")
const TEX_PANEL_FOOTER := preload("res://Art/Ui/svg/panel_footer.svg")
const TEX_TAB_ACTIVE := preload("res://Art/Ui/svg/tab_active.svg")
const TEX_KEYCAP := preload("res://Art/Ui/svg/keycap.svg")
const TEX_DIVIDER_H := preload("res://Art/Ui/svg/divider_horizontal.svg")
const TEX_SLOT := {
	"normal": preload("res://Art/Ui/svg/slot_normal.svg"),
	"hover": preload("res://Art/Ui/svg/slot_hover.svg"),
	"selected": preload("res://Art/Ui/svg/slot_selected.svg"),
	"equipped": preload("res://Art/Ui/svg/slot_equipped.svg"),
	"disabled": preload("res://Art/Ui/svg/slot_disabled.svg"),
}
const TEX_SCROLL_TRACK := preload("res://Art/Ui/svg/scroll_track.svg")
const TEX_SCROLL_THUMB := preload("res://Art/Ui/svg/scroll_thumb.svg")
const TEX_SCROLL_THUMB_HOVER := preload("res://Art/Ui/svg/scroll_thumb_hover.svg")
const COLOR_WARNING := Color("#EDB35B")
const TEX_PRIMARY := {
	"normal": preload("res://Art/Ui/svg/primary_normal.svg"),
	"hover": preload("res://Art/Ui/svg/primary_hover.svg"),
	"pressed": preload("res://Art/Ui/svg/primary_pressed.svg"),
	"disabled": preload("res://Art/Ui/svg/primary_disabled.svg"),
}
const TEX_SECONDARY := {
	"normal": preload("res://Art/Ui/svg/secondary_normal.svg"),
	"hover": preload("res://Art/Ui/svg/secondary_hover.svg"),
	"pressed": preload("res://Art/Ui/svg/secondary_pressed.svg"),
	"disabled": preload("res://Art/Ui/svg/secondary_disabled.svg"),
}

static func nine_slice(tex: Texture2D, margin: float = 8.0) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = tex
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	return style

static func panel(tex: Texture2D) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", nine_slice(tex))
	return p

static func label(text: String, size: int, color: Color) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

## Botón principal (relleno dorado, texto oscuro) o secundario (contorno, texto claro).
static func button(text: String, primary: bool, size: Vector2 = Vector2(0, 48), font_size: int = 20) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = size
	btn.add_theme_font_size_override("font_size", font_size)
	var textures = TEX_PRIMARY if primary else TEX_SECONDARY
	for state in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, nine_slice(textures[state]))
	btn.add_theme_stylebox_override("focus", nine_slice(textures["hover"]))
	var font_col = COLOR_DARK if primary else COLOR_TEXT
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(key, font_col)
	return btn

## Pestaña activa usada como título de ventana (no se puede clickear).
static func title_tab(text: String) -> Button:
	var tab = Button.new()
	tab.text = text
	tab.custom_minimum_size = Vector2(170, 44)
	tab.focus_mode = Control.FOCUS_NONE
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.add_theme_font_size_override("font_size", 22)
	tab.add_theme_stylebox_override("normal", nine_slice(TEX_TAB_ACTIVE))
	tab.add_theme_color_override("font_color", COLOR_GOLD)
	return tab

static func keycap(key_text: String) -> PanelContainer:
	var p = PanelContainer.new()
	p.custom_minimum_size = Vector2(32, 32)
	p.add_theme_stylebox_override("panel", nine_slice(TEX_KEYCAP))
	var l = label(key_text, 14, COLOR_TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p

static func icon(tex: Texture2D, size: float = 22.0) -> TextureRect:
	var r = TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return r

static func divider() -> TextureRect:
	var div = TextureRect.new()
	div.texture = TEX_DIVIDER_H
	div.custom_minimum_size = Vector2(0, 2)
	div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div.stretch_mode = TextureRect.STRETCH_TILE
	div.modulate = Color(1.0, 1.0, 1.0, 0.4)
	return div

## Botón con forma de slot (como los del inventario). base = "normal",
## "selected", "equipped" o "disabled"; el hover se ve igual que en el inventario.
static func style_slot_button(btn: BaseButton, base: String) -> void:
	var normal = nine_slice(TEX_SLOT[base])
	var hover = normal if base == "selected" else nine_slice(TEX_SLOT["hover"])
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", nine_slice(TEX_SLOT["selected"]))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", normal)

static func style_scroll(scroll: ScrollContainer) -> void:
	var bar = scroll.get_v_scroll_bar()
	bar.add_theme_stylebox_override("scroll", nine_slice(TEX_SCROLL_TRACK, 2.0))
	bar.add_theme_stylebox_override("grabber", nine_slice(TEX_SCROLL_THUMB, 2.0))
	bar.add_theme_stylebox_override("grabber_highlight", nine_slice(TEX_SCROLL_THUMB_HOVER, 2.0))
	bar.add_theme_stylebox_override("grabber_pressed", nine_slice(TEX_SCROLL_THUMB_HOVER, 2.0))

## Margen interno estándar de las columnas.
static func padded(amount: int) -> MarginContainer:
	var m = MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, amount)
	return m

## Slider con la paleta de la UI: riel oscuro con borde, relleno turquesa y
## tirador dorado.
static func style_slider(slider: HSlider) -> void:
	slider.add_theme_stylebox_override("slider", _slider_box(Color("#0E171B"), COLOR_MUTED.darkened(0.45)))
	slider.add_theme_stylebox_override("grabber_area", _slider_box(COLOR_TEAL.darkened(0.15), COLOR_TEAL))
	slider.add_theme_stylebox_override("grabber_area_highlight", _slider_box(COLOR_TEAL, COLOR_TEAL.lightened(0.3)))
	var grabber = _square_texture(16, COLOR_GOLD, COLOR_DARK)
	slider.add_theme_icon_override("grabber", grabber)
	slider.add_theme_icon_override("grabber_highlight", _square_texture(16, COLOR_GOLD.lightened(0.25), COLOR_DARK))

## Recorta el borde transparente de un sprite para que se vea grande dentro
## de un marco (muchos PNG de armas y objetos tienen mucho aire alrededor).
static func trimmed(tex: Texture2D) -> Texture2D:
	if not tex or tex is AtlasTexture: return tex
	var img = tex.get_image()
	if not img: return tex
	var used = img.get_used_rect()
	if used.size == Vector2i.ZERO or used.size == img.get_size(): return tex
	var atlas = AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(used)
	return atlas

static func _slider_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box

static func _square_texture(size: int, fill: Color, border: Color) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(border)
	img.fill_rect(Rect2i(2, 2, size - 4, size - 4), fill)
	return ImageTexture.create_from_image(img)
