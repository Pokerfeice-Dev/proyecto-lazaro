# Popup tipo "logro desbloqueado" (estilo Xbox 360) que avisa cuando se
# descubre una entrada nueva del códex. Se abre desde el eje central del
# rectángulo hacia afuera y se cierra de la misma forma pero al revés.
extends CanvasLayer
class_name CodexToast

const UI_SOUND_PATH = "res://Audio/Sfx/Fantasy_UI (8).wav"
const DISPLAY_SECONDS: float = 3.0

const CATEGORY_LABELS = {
	"enemies": "¡NUEVO ENEMIGO DESCUBIERTO!",
	"weapons": "¡NUEVA ARMA DESCUBIERTA!",
	"items": "¡NUEVO OBJETO DESCUBIERTO!",
	"npcs": "¡NUEVO PERSONAJE DESCUBIERTO!",
	"levels": "¡NUEVA ZONA DESCUBIERTA!",
}

var category: String = ""
var entry_id: String = ""

var _panel: PanelContainer

signal finished

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_play_ui_sound()
	_animate_in()

func _get_entry_data() -> Dictionary:
	if not CodexData.DATA.has(category): return {}
	if not CodexData.DATA[category].has(entry_id): return {}
	return CodexData.DATA[category][entry_id]

func _build_ui() -> void:
	var data = _get_entry_data()

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 84)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -210
	_panel.offset_right = 210
	_panel.offset_top = 24
	_panel.offset_bottom = 108
	_panel.pivot_offset = Vector2(210, 42)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	sb.border_color = Color(0.0, 0.8, 0.5, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0.8, 0.5, 0.2)
	sb.shadow_size = 16
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)

	add_child(_panel)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hbox)

	if data.get("icon"):
		var icon_rect = TextureRect.new()
		icon_rect.texture = data["icon"]
		icon_rect.custom_minimum_size = Vector2(60, 60)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon_rect)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(vbox)

	var lbl_header = Label.new()
	lbl_header.text = CATEGORY_LABELS.get(category, "¡NUEVO DESCUBRIMIENTO!")
	lbl_header.add_theme_font_override("font", load("res://Art/Fonts/Exo2-Regular.otf"))
	lbl_header.add_theme_font_size_override("font_size", 12)
	lbl_header.add_theme_color_override("font_color", Color(0.0, 0.85, 0.55))
	vbox.add_child(lbl_header)

	var lbl_name = Label.new()
	lbl_name.text = str(data.get("name", entry_id))
	lbl_name.add_theme_font_override("font", load("res://Art/Fonts/Dekatron-SemiBold.otf"))
	lbl_name.add_theme_font_size_override("font_size", 20)
	lbl_name.add_theme_color_override("font_color", Color(1, 1, 1))
	vbox.add_child(lbl_name)

func _play_ui_sound() -> void:
	if not ResourceLoader.exists(UI_SOUND_PATH): return
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load(UI_SOUND_PATH)
	sfx.bus = "SFX"
	sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx)
	sfx.play()

# se abre desde el eje central (pivot en el medio) escalando en X hacia afuera
func _animate_in() -> void:
	_panel.scale = Vector2(0.0, 1.0)
	_panel.modulate.a = 0.0
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale:x", 1.0, 0.45)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tween.chain().tween_callback(_hold_then_close)

func _hold_then_close() -> void:
	var t = create_tween()
	t.tween_interval(DISPLAY_SECONDS)
	t.tween_callback(_animate_out)

# se cierra igual que se abrió pero al revés, volviendo al eje central
func _animate_out() -> void:
	_play_ui_sound()
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_panel, "scale:x", 0.0, 0.35)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(_on_close_finished)

func _on_close_finished() -> void:
	finished.emit()
	queue_free()
