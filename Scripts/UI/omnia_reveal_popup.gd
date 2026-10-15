extends CanvasLayer
class_name OmniaRevealPopup

## Ventanas de O.M.N.I.A. para las investigaciones, con el estilo de la UI del
## juego (pestaña de título, panel principal, teclas y botones dorados):
##  - ask_hint: confirma la compra de una pista. Si se compra, la pieza se da
##    vuelta y se revela (silueta que se aclara, nombre que se "decodifica" y un
##    sello de PISTA OBTENIDA).
##  - research_unlocked: celebra que se desbloqueó una investigación: escaneo,
##    número que se decodifica, la pista escrita y las piezas que se dan vuelta.
## ESC o el botón secundario cierran; Enter confirma.

signal hint_bought
signal closed

const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
const ICON_EYE := preload("res://Art/Ui/svg/icon_eye.svg")
const ICON_LOCK := preload("res://Art/Ui/svg/icon_lock.svg")
const ICON_COIN := preload("res://Art/Ui/svg/icon_coin.svg")
const ICON_SEARCH := preload("res://Art/Ui/svg/icon_search.svg")
const BUY_SOUND := "res://Audio/Sfx/Equipar_items.wav"
const REVEAL_SOUND := "res://Audio/Sfx/SciFi reward.mp3"
const CANCEL_SOUND := "res://Audio/Sfx/UI_cancelar.wav"
const GLYPHS := "#%&@$*+=<>/?01"
const CHIP_BIG := Vector2(128, 128)
const WINDOW_WIDTH := 560.0

var synergy_id: String = ""
var hint_index: int = -1
var _window: VBoxContainer
var _tab: Button
var _body: VBoxContainer
var _footer: HBoxContainer
var _confirm_btn: Button
var _decode_label: Label
var _decode_text: String = ""
var _decode_t: float = -1.0
var _closing: bool = false

## Ventana para comprar la pista de la pieza "index" de la sinergia.
static func ask_hint(id: String, index: int) -> OmniaRevealPopup:
	var popup = OmniaRevealPopup.new()
	popup.synergy_id = id
	popup.hint_index = index
	Engine.get_main_loop().root.add_child(popup)
	popup._show_hint_question()
	return popup

## Celebración al desbloquear una investigación. "title" es el nombre visible
## (por ejemplo "Investigación 03" mientras no se descubra).
static func research_unlocked(id: String, title: String) -> OmniaRevealPopup:
	var popup = OmniaRevealPopup.new()
	popup.synergy_id = id
	Engine.get_main_loop().root.add_child(popup)
	popup._show_research(title)
	return popup

func _init() -> void:
	layer = 260
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	_build_shell()

func _input(event: InputEvent) -> void:
	if _closing: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_play(CANCEL_SOUND)
		close()
	elif event is InputEventKey and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _confirm_btn and not _confirm_btn.disabled:
			_confirm_btn.pressed.emit()

func _process(delta: float) -> void:
	if _decode_t < 0.0 or not _decode_label: return
	_decode_t += delta
	var k = clampf(_decode_t / 0.6, 0.0, 1.0)
	_decode_label.text = _scrambled(_decode_text, k)
	if k >= 1.0: _decode_t = -1.0

func close() -> void:
	if _closing: return
	_closing = true
	var t = create_tween().set_parallel(true)
	t.tween_property(_window, "modulate:a", 0.0, 0.15)
	t.tween_property(_window, "scale", Vector2(0.96, 0.96), 0.15)
	t.chain().tween_callback(func():
		closed.emit()
		queue_free())

# --- Ventana base ---

func _build_shell() -> void:
	var backdrop = ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.6)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_window = VBoxContainer.new()
	_window.add_theme_constant_override("separation", 0)
	_window.custom_minimum_size.x = WINDOW_WIDTH
	center.add_child(_window)
	_tab = UIStyle.title_tab("")
	_tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tab.icon = ICON_EYE
	_tab.add_theme_color_override("icon_normal_color", UIStyle.COLOR_GOLD)
	_window.add_child(_tab)
	var panel = UIStyle.panel(UIStyle.TEX_PANEL_MAIN)
	_window.add_child(panel)
	var m = UIStyle.padded(24)
	panel.add_child(m)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	m.add_child(col)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	col.add_child(_body)
	col.add_child(UIStyle.divider())
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 10)
	col.add_child(_footer)
	_animate_in(backdrop)

func _animate_in(backdrop: ColorRect) -> void:
	backdrop.modulate.a = 0.0
	_window.modulate.a = 0.0
	backdrop.create_tween().tween_property(backdrop, "modulate:a", 1.0, 0.18)
	await get_tree().process_frame
	_window.pivot_offset = _window.size / 2.0
	_window.scale = Vector2(0.92, 0.92)
	var t = _window.create_tween().set_parallel(true)
	t.tween_property(_window, "modulate:a", 1.0, 0.18)
	t.tween_property(_window, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _clear(box: Container) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()

# --- Comprar pista ---

func _show_hint_question() -> void:
	_tab.text = "  REVELAR COMPONENTE"
	var count = OmniaCatalog.synergy_ingredients(synergy_id).size()
	var cost = OmniaCatalog.hint_cost(hint_index)
	var center = CenterContainer.new()
	center.add_child(_secret_chip())
	_body.add_child(center)
	_body.add_child(_centered(UIStyle.label("PIEZA %d DE %d" % [hint_index + 1, count], 15, UIStyle.COLOR_TEAL)))
	var text = _centered(UIStyle.label("La pista revela su nombre y su imagen para siempre.\nNo te da el objeto: lo tienes que encontrar en una run.", 15, UIStyle.COLOR_MUTED))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(text)
	_body.add_child(_cost_row(cost))

	_footer.add_child(UIStyle.keycap("ESC"))
	var cancel = UIStyle.button("SEGUIR EXPLORANDO", false, Vector2(0, 46), 17)
	cancel.pressed.connect(func():
		_play(CANCEL_SOUND)
		close())
	_footer.add_child(cancel)
	_footer.add_child(_spacer())
	var enough = GameData.scrap >= cost
	_confirm_btn = UIStyle.button("COMPRAR PISTA" if enough else "CHATARRA INSUFICIENTE", enough, Vector2(220, 46), 18)
	_confirm_btn.disabled = not enough
	_confirm_btn.pressed.connect(_buy_hint)
	_footer.add_child(_confirm_btn)

func _cost_row(cost: int) -> Control:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(UIStyle.icon(ICON_COIN, 26))
	var enough = GameData.scrap >= cost
	row.add_child(UIStyle.label(str(cost), 26, UIStyle.COLOR_GOLD if enough else UIStyle.COLOR_WARNING))
	row.add_child(UIStyle.label("   ·   tienes %d" % GameData.scrap, 15, UIStyle.COLOR_MUTED))
	return row

# Pieza oculta: "?" que late y una línea de escaneo que la recorre sin parar.
func _secret_chip() -> Control:
	var chip = UIStyle.panel(UIStyle.TEX_SLOT["disabled"])
	chip.name = "Chip"
	chip.custom_minimum_size = CHIP_BIG
	chip.clip_contents = true
	var q = UIStyle.label("?", 56, Color("#4E6B73"))
	q.name = "Question"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(q)
	var pulse = q.create_tween().set_loops()
	pulse.tween_property(q, "modulate", Color(1.6, 1.6, 1.6), 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(q, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE)
	chip.add_child(_scan_line(true))
	return chip

func _buy_hint() -> void:
	if not OmniaCatalog.purchase_hint(synergy_id, hint_index):
		_play(CANCEL_SOUND)
		return
	_play(BUY_SOUND)
	hint_bought.emit()
	_show_hint_revealed()

func _show_hint_revealed() -> void:
	var part: Dictionary = OmniaCatalog.synergy_ingredients(synergy_id)[hint_index]
	_tab.text = "  PISTA OBTENIDA"
	var chip: Control = _body.find_child("Chip", true, false)
	_clear(_footer)
	for c in _body.get_children():
		if c != chip.get_parent(): c.queue_free()
	_decode_label = _centered(UIStyle.label("", 24, UIStyle.COLOR_GOLD))
	_body.add_child(_decode_label)
	var note = _centered(UIStyle.label("Ya sabes qué buscar. Encuéntralo en una run.", 15, UIStyle.COLOR_MUTED))
	_body.add_child(note)
	_continue_footer()
	await _flip_to_item(chip, part.icon, true)
	_decode_text = str(part.name).to_upper()
	_decode_t = 0.0
	_stamp(chip, "PISTA\nOBTENIDA")

# La ficha gira de canto, cambia a la pieza y se revela como en O.M.N.I.A.
func _flip_to_item(chip: Control, icon: Texture2D, big: bool) -> void:
	await get_tree().process_frame
	chip.pivot_offset = chip.size / 2.0
	var t = chip.create_tween()
	t.tween_property(chip, "scale:x", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished
	if not is_instance_valid(chip): return
	for c in chip.get_children():
		chip.remove_child(c)
		c.queue_free()
	chip.add_theme_stylebox_override("panel", UIStyle.nine_slice(UIStyle.TEX_SLOT["equipped"]))
	var art = UIStyle.icon(icon, CHIP_BIG.x - 36.0 if big else 34.0)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat = ShaderMaterial.new()
	mat.shader = LOCKED_SHADER
	art.material = mat
	chip.add_child(art)
	chip.modulate = Color(2.0, 2.0, 2.0)
	var t2 = chip.create_tween().set_parallel(true)
	t2.tween_property(chip, "scale:x", 1.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(chip, "modulate", Color.WHITE, 0.4)
	t2.tween_method(func(v: float): mat.set_shader_parameter("reveal", v), 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	if big: _play(REVEAL_SOUND)
	await t2.finished
	if is_instance_valid(art): art.material = null

# --- Investigación desbloqueada ---

func _show_research(title: String) -> void:
	_tab.text = "  INVESTIGACIÓN DESBLOQUEADA"
	_tab.icon = ICON_SEARCH
	var frame = UIStyle.panel(UIStyle.TEX_SLOT["equipped"])
	frame.name = "ResearchFrame"
	frame.custom_minimum_size = Vector2(150, 150)
	frame.clip_contents = true
	var lock = UIStyle.icon(ICON_LOCK, 64)
	lock.modulate = UIStyle.COLOR_GOLD
	frame.add_child(lock)
	frame.add_child(_scan_line(false))
	var center = CenterContainer.new()
	center.add_child(frame)
	_body.add_child(center)
	_decode_label = _centered(UIStyle.label("", 26, UIStyle.COLOR_TEXT))
	_body.add_child(_decode_label)
	var clue = OmniaCatalog.RESEARCH.clues.get(synergy_id, "")
	if clue != "":
		var c = _centered(UIStyle.label("«%s»" % clue, 15, UIStyle.COLOR_MUTED))
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(c)
	var chips = HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 10)
	var parts = OmniaCatalog.synergy_ingredients(synergy_id)
	for i in parts.size():
		chips.add_child(_small_secret_chip())
	_body.add_child(chips)
	var help = _centered(UIStyle.label("Arma la combinación en una run para descubrirla.\nLas pistas revelan las demás piezas.", 14, UIStyle.COLOR_TEAL))
	_body.add_child(help)
	_continue_footer()
	_play(REVEAL_SOUND)
	_decode_text = title.to_upper()
	_decode_t = 0.0
	_stamp(frame, "INVESTIGACIÓN\nDESBLOQUEADA")
	await get_tree().create_timer(0.55).timeout
	for i in parts.size():
		if not is_instance_valid(chips): return
		if OmniaCatalog.is_ingredient_revealed(synergy_id, i):
			_flip_to_item(chips.get_child(i), parts[i].icon, false)
		else:
			_pop(chips.get_child(i))
		await get_tree().create_timer(0.14).timeout

func _small_secret_chip() -> Control:
	var chip = UIStyle.panel(UIStyle.TEX_SLOT["disabled"])
	chip.custom_minimum_size = Vector2(56, 56)
	var q = UIStyle.label("?", 24, Color("#4E6B73"))
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(q)
	return chip

# --- Piezas comunes ---

func _continue_footer() -> void:
	_confirm_btn = null
	_footer.add_child(_spacer())
	var ok = UIStyle.button("CONTINUAR", true, Vector2(220, 46), 18)
	ok.pressed.connect(close)
	_footer.add_child(ok)
	_footer.add_child(UIStyle.keycap("ENTER"))
	_confirm_btn = ok

# Línea turquesa que recorre la ficha de arriba a abajo (en bucle o una vez).
func _scan_line(loop: bool) -> Control:
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line = ColorRect.new()
	line.color = Color(UIStyle.COLOR_TEAL, 0.7)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(line)
	var glow = ColorRect.new()
	glow.color = Color(UIStyle.COLOR_TEAL, 0.15)
	glow.position.y = -14
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(glow)
	holder.resized.connect(func():
		line.size = Vector2(holder.size.x, 2)
		glow.size = Vector2(holder.size.x, 14))
	var t = line.create_tween()
	if loop: t.set_loops()
	t.tween_property(line, "position:y", 160.0, 1.3).from(-4.0).set_trans(Tween.TRANS_SINE)
	if loop: t.tween_interval(0.4)
	else: t.tween_callback(holder.queue_free)
	return holder

# Sello dorado que cae girado sobre la ficha y se queda un rato.
func _stamp(target: Control, text: String) -> void:
	var center = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(center)
	var stamp = PanelContainer.new()
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box = StyleBoxFlat.new()
	box.bg_color = Color(0.06, 0.05, 0.02, 0.88)
	box.border_color = UIStyle.COLOR_GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	stamp.add_theme_stylebox_override("panel", box)
	var lbl = UIStyle.label(text, 14, UIStyle.COLOR_GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.add_child(lbl)
	center.add_child(stamp)
	await get_tree().process_frame
	if not is_instance_valid(stamp): return
	stamp.pivot_offset = stamp.size / 2.0
	stamp.rotation = -0.22
	stamp.scale = Vector2(2.4, 2.4)
	stamp.modulate.a = 0.0
	var t = stamp.create_tween()
	t.tween_interval(0.35)
	t.tween_property(stamp, "modulate:a", 1.0, 0.08)
	t.parallel().tween_property(stamp, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func(): _pop(target))
	t.tween_property(stamp, "rotation", -0.12, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.4)
	t.tween_property(stamp, "modulate:a", 0.0, 0.35)
	t.tween_callback(center.queue_free)

func _pop(target: Control) -> void:
	if not is_instance_valid(target): return
	target.pivot_offset = target.size / 2.0
	target.scale = Vector2(1.12, 1.12)
	target.modulate = Color(1.8, 1.8, 1.8)
	var t = target.create_tween().set_parallel(true)
	t.tween_property(target, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(target, "modulate", Color.WHITE, 0.4)

func _centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _spacer() -> Control:
	var s = Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s

func _scrambled(text: String, k: float) -> String:
	var fixed = int(floor(text.length() * k))
	var out = text.substr(0, fixed)
	for i in range(fixed, text.length()):
		out += " " if text[i] == " " else GLYPHS[randi() % GLYPHS.length()]
	return out

func _play(path: String) -> void:
	if not ResourceLoader.exists(path): return
	var p = AudioStreamPlayer.new()
	p.stream = load(path)
	p.bus = "SFX"
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
