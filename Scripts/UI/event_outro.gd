class_name EventOutro
extends RefCounted

## Cierre de la run en el build del evento, después del resumen:
##  1. "¿Qué te pareció?": QR al formulario de opinión. Es anónimo, así la
##     gente puede decir lo que piensa sin tenernos al lado.
##  2. "Esto es solo el comienzo": un video corto con lo que no entra en la
##     demo (zonas 2 y 3, sus jefes, sinergias y O.M.N.I.A.) y el QR a itch.io.
## Usa la misma ventana que el resto de la UI (UIWindow): A / E sigue, B / ESC
## también. Si nadie toca nada, el modo stand (EventKiosk) vuelve al menú.
## Uso: EventOutro.play(func(): SceneTransition.change_scene(escena))

const ICON_INFO := preload("res://Art/Ui/svg/icon_info.svg")
const ICON_POINT := preload("res://Art/Ui/svg/icon_chevron_right.svg")
const QR_OPINION := preload("res://Art/Ui/Event/qr_opinion.png")
const QR_ITCH := preload("res://Art/Ui/Event/qr_itchio.png")
const REEL := "res://Art/Ui/Event/reel_contenido.ogv"
const ITCH_TEXT := "kidgunz.itch.io"
const MORE_CONTENT := [
	"Tres zonas, cada una con su jefe: la Cripta, El Primogénito, El Núcleo y Prometeo.",
	"Quince sinergias para descubrir combinando piezas.",
	"O.M.N.I.A.: mejoras e investigaciones entre runs.",
	"Un códice que guarda todo lo que vas encontrando.",
]

static var _showing := false

## Se muestra en el build del evento o con el interruptor del modo evento
## prendido (o mientras corre una run del evento).
static func should_show() -> bool:
	return GameData.is_event_build() or GameData.is_event_demo()

static func is_showing() -> bool:
	return _showing

static func play(on_done: Callable) -> void:
	_showing = true
	var w = UIWindow.open("  ¿QUÉ TE PARECIÓ?", ICON_INFO, 820.0)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	w.body.add_child(row)
	row.add_child(_qr(QR_OPINION, 300.0))
	var texts = _column()
	row.add_child(texts)
	texts.add_child(_text("¡Gracias por jugar!", 30, UIStyle.COLOR_GOLD))
	texts.add_child(_text("Nos ayudaría mucho saber cómo te fue.", 20, UIStyle.COLOR_TEXT))
	texts.add_child(_text("Escanea el código con tu celular y completa un formulario corto. Es anónimo y toma un par de minutos.", 18, UIStyle.COLOR_MUTED))
	w.add_button("CONTINUAR", true, "E", w.close)
	w.closed.connect(_show_more.bind(on_done))

static func _show_more(on_done: Callable) -> void:
	var w = UIWindow.open("  ESTO ES SOLO EL COMIENZO", ICON_INFO, 1260.0)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	w.body.add_child(row)
	row.add_child(_reel())
	var texts = _column()
	row.add_child(texts)
	texts.add_child(_text("Esta demo es solo la zona 1.", 26, UIStyle.COLOR_GOLD))
	for line in MORE_CONTENT:
		texts.add_child(_bullet(line))
	var qr_row = HBoxContainer.new()
	qr_row.add_theme_constant_override("separation", 16)
	texts.add_child(qr_row)
	qr_row.add_child(_qr(QR_ITCH, 170.0))
	var qr_texts = _column()
	qr_texts.alignment = BoxContainer.ALIGNMENT_CENTER
	qr_row.add_child(qr_texts)
	qr_texts.add_child(_text("Síguenos y juega en", 18, UIStyle.COLOR_MUTED))
	qr_texts.add_child(_text(ITCH_TEXT, 26, UIStyle.COLOR_TEAL))
	w.add_button("TERMINAR", true, "E", w.close)
	w.closed.connect(_finish.bind(on_done))

static func _finish(on_done: Callable) -> void:
	_showing = false
	if on_done.is_valid():
		on_done.call()

# --- Piezas ---

# Video en loop de lo que hay fuera de la demo (sin sonido: suena la música del juego).
static func _reel() -> Control:
	var frame = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var video = VideoStreamPlayer.new()
	video.custom_minimum_size = Vector2(640, 360)
	video.expand = true
	video.volume_db = -80.0
	video.loop = true
	video.autoplay = true
	if ResourceLoader.exists(REEL):
		video.stream = load(REEL)
	frame.add_child(video)
	return frame

static func _qr(tex: Texture2D, size: float) -> Control:
	# fondo blanco con margen: los celulares leen mejor el código con borde claro
	var frame = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	frame.add_theme_stylebox_override("panel", style)
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var rect = TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	frame.add_child(rect)
	return frame

static func _column() -> VBoxContainer:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	return col

static func _text(text: String, size: int, color: Color) -> Label:
	var l = UIStyle.label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 300
	return l

static func _bullet(text: String) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var ic = UIStyle.icon(ICON_POINT, 18)
	ic.modulate = UIStyle.COLOR_TEAL
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(ic)
	var l = _text(text, 18, UIStyle.COLOR_TEXT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	return row
