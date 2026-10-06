extends Control

# Menú de selección de slot. Usa el mismo fondo que el menú principal (Lázaro respirando
# detrás de los barrotes, lluvia y nieve) y muestra cada slot como una tarjeta con los FX de
# botón del menú (ButtonFX). Borrar un slot pide confirmar con un segundo click.

const SLOT_COUNT := 3
const CARD_SIZE := Vector2(760, 150)
const CARD_GAP := 22.0
const CARDS_ORIGIN := Vector2(1060, 300)
const COLOR_ACENTO := Color(0.35, 1.0, 0.85)
const COLOR_VACIO := Color(0.55, 0.65, 0.68)
const COLOR_PELIGRO := Color(1.0, 0.32, 0.32)
const TIEMPO_CONFIRMAR_BORRADO := 2.5
const FONT_TITULO = preload("res://Art/Fonts/Dekatron-SemiBold.otf")
const BTN_SOUND = preload("res://Audio/Sfx/Fantasy_UI (8).wav")

var _cards_layer: Control
var _cards: Array[Button] = []
var _title_box: VBoxContainer
var _back_btn: Button
var _btn_snd: AudioStreamPlayer
var _fondo_material: Material
var _leaving: bool = false

func _ready() -> void:
	_setup_overlay()
	_setup_title()
	_setup_cards_layer()
	_setup_back_button()
	_setup_sound()
	_populate_slots()
	_apply_menu_settings()
	_play_intro_animation()

# ---------- armado de la pantalla ----------

# degradé oscuro hacia la derecha: Lázaro se sigue viendo y las tarjetas se leen bien
func _setup_overlay() -> void:
	var grad = Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 0.62, 1.0])
	grad.colors = PackedColorArray([
		Color(0.0, 0.03, 0.04, 0.15),
		Color(0.0, 0.03, 0.04, 0.35),
		Color(0.0, 0.03, 0.04, 0.82),
		Color(0.0, 0.03, 0.04, 0.92),
	])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var overlay = TextureRect.new()
	overlay.name = "Sombra"
	overlay.texture = tex
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func _setup_title() -> void:
	_title_box = VBoxContainer.new()
	_title_box.position = Vector2(CARDS_ORIGIN.x, 150)
	_title_box.custom_minimum_size = Vector2(CARD_SIZE.x, 0)
	_title_box.add_theme_constant_override("separation", 4)
	add_child(_title_box)
	var title = _make_label("SELECCIONÁ UN SLOT", 46, Color(0.88, 1.0, 0.97), FONT_TITULO)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(COLOR_ACENTO, 0.3))
	_title_box.add_child(title)
	_title_box.add_child(_make_label("Cada slot guarda el progreso del Laboratorio.", 20, Color(0.7, 0.82, 0.8)))
	# la línea de acento se estira al entrar
	var line = ColorRect.new()
	line.name = "Linea"
	line.color = COLOR_ACENTO
	line.custom_minimum_size = Vector2(0, 3)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_title_box.add_child(line)

func _setup_cards_layer() -> void:
	_cards_layer = Control.new()
	_cards_layer.name = "Tarjetas"
	_cards_layer.position = CARDS_ORIGIN
	_cards_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cards_layer)

func _setup_back_button() -> void:
	_back_btn = Button.new()
	_back_btn.text = "VOLVER"
	_back_btn.position = Vector2(90, 950)
	_back_btn.custom_minimum_size = Vector2(260, 64)
	_back_btn.add_theme_font_override("font", FONT_TITULO)
	_back_btn.add_theme_font_size_override("font_size", 24)
	_apply_button_styles(_back_btn, COLOR_ACENTO, 2)
	_back_btn.pressed.connect(_on_back_pressed)
	add_child(_back_btn)
	ButtonFX.attach(_back_btn, 0, 1.05)

func _setup_sound() -> void:
	_btn_snd = AudioStreamPlayer.new()
	_btn_snd.stream = BTN_SOUND
	_btn_snd.bus = "SFX"
	add_child(_btn_snd)

# ---------- tarjetas de slot ----------

func _populate_slots() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	for i in range(SLOT_COUNT):
		var card = _make_slot_card(i + 1)
		card.position = Vector2(0, i * (CARD_SIZE.y + CARD_GAP))
		_cards_layer.add_child(card)
		_cards.append(card)
		ButtonFX.attach(card, i, 1.03)

func _make_slot_card(slot: int) -> Button:
	var info = GameData.get_slot_info(slot)
	var exists: bool = info.exists
	var accent = COLOR_ACENTO if exists else COLOR_VACIO
	var card = Button.new()
	card.name = "Slot%d" % slot
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	_apply_card_styles(card, accent, exists)
	card.pressed.connect(_on_slot_selected.bind(slot, exists))

	var row = HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 22)
	card.add_child(row)
	row.add_child(_make_slot_number(slot, accent))
	row.add_child(_make_slot_info(info) if exists else _make_empty_info())
	if exists:
		row.add_child(_make_delete_button(slot))
	else:
		row.add_child(_make_new_badge())
	return card

func _make_slot_number(slot: int, accent: Color) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(130, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", -6)
	var num = _make_label("%02d" % slot, 58, accent, FONT_TITULO)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(num)
	var tag = _make_label("SLOT", 15, Color(accent, 0.7), FONT_TITULO)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	return box

func _make_slot_info(info: Dictionary) -> VBoxContainer:
	var box = _make_info_box()
	box.add_child(_make_label("PARTIDA GUARDADA", 15, COLOR_ACENTO, FONT_TITULO))
	var nivel = "Nivel máx. %d-%d" % [info.get("max_reached_level", 1), info.get("max_reached_room", 1)]
	box.add_child(_make_label(nivel, 30, Color(0.95, 1.0, 0.98)))
	var guardado = info.get("last_save_time", "")
	if guardado == "":
		guardado = "--/--/----"
	var despliegues: int = info.get("total_deployments", 0)
	var detalle = "Tiempo %s   ·   %d %s" % [GameData.format_time(info.play_time), despliegues,
		"despliegue" if despliegues == 1 else "despliegues"]
	box.add_child(_make_label(detalle, 17, Color(0.68, 0.78, 0.78)))
	box.add_child(_make_label("Guardado %s" % guardado, 14, Color(0.5, 0.6, 0.6)))
	return box

func _make_empty_info() -> VBoxContainer:
	var box = _make_info_box()
	box.add_child(_make_label("SLOT LIBRE", 15, COLOR_VACIO, FONT_TITULO))
	box.add_child(_make_label("Nueva partida", 30, Color(0.85, 0.9, 0.9)))
	box.add_child(_make_label("Empezá desde cero, con tutorial si querés.", 17, Color(0.6, 0.68, 0.68)))
	return box

func _make_info_box() -> VBoxContainer:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	return box

# el "+" de los slots libres late despacio
func _make_new_badge() -> Label:
	var plus = _make_label("+", 64, COLOR_ACENTO, FONT_TITULO)
	plus.custom_minimum_size = Vector2(110, 0)
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var t = plus.create_tween().set_loops()
	t.tween_property(plus, "modulate:a", 0.35, 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(plus, "modulate:a", 1.0, 1.1).set_trans(Tween.TRANS_SINE)
	return plus

# Borrar pide un segundo click: el primero cambia el texto a "¿SEGURO?" por unos segundos.
func _make_delete_button(slot: int) -> Control:
	var holder = CenterContainer.new()
	holder.custom_minimum_size = Vector2(140, 0)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var del = Button.new()
	del.text = "BORRAR"
	del.custom_minimum_size = Vector2(124, 46)
	del.focus_mode = Control.FOCUS_NONE
	del.add_theme_font_override("font", FONT_TITULO)
	del.add_theme_font_size_override("font_size", 15)
	del.add_theme_color_override("font_color", COLOR_PELIGRO)
	del.add_theme_color_override("font_hover_color", Color.WHITE)
	_apply_button_styles(del, COLOR_PELIGRO, 1)
	del.pressed.connect(_on_delete_pressed.bind(slot, del))
	holder.add_child(del)
	return holder

# ---------- estilos ----------

func _apply_card_styles(card: Button, accent: Color, exists: bool) -> void:
	var normal = _make_card_style(accent, 0.88 if exists else 0.72, 0.25)
	var hover = _make_card_style(accent, 0.9, 0.85)
	hover.bg_color = Color(0.05, 0.12, 0.13, 0.92)
	card.add_theme_stylebox_override("normal", normal)
	card.add_theme_stylebox_override("hover", hover)
	card.add_theme_stylebox_override("pressed", hover)
	card.add_theme_stylebox_override("hover_pressed", hover)
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_card_style(accent: Color, bg_alpha: float, border_alpha: float) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.07, bg_alpha)
	sb.border_color = Color(accent, border_alpha)
	sb.set_border_width_all(1)
	sb.border_width_left = 6
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	return sb

func _apply_button_styles(btn: Button, accent: Color, border: int) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.03, 0.06, 0.07, 0.85)
	normal.border_color = Color(accent, 0.6)
	normal.set_border_width_all(border)
	normal.set_corner_radius_all(8)
	var hover = normal.duplicate()
	hover.bg_color = Color(accent, 0.22)
	hover.border_color = accent
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("hover_pressed", hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _make_label(text: String, font_size: int, color: Color, font: Font = null) -> Label:
	var label = Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font:
		label.add_theme_font_override("font", font)
	return label

# ---------- acciones ----------

func _on_slot_selected(slot: int, exists: bool) -> void:
	if _leaving: return
	_btn_snd.play()
	if exists:
		GameData.load_game(slot)
		_leave_to("res://Scenes/Rooms/lab_room.tscn")
	else:
		_show_tutorial_prompt(slot)

func _on_delete_pressed(slot: int, del: Button) -> void:
	if del.has_meta("confirmando"):
		_delete_slot(slot)
		return
	del.set_meta("confirmando", true)
	del.text = "¿SEGURO?"
	del.add_theme_color_override("font_color", Color.WHITE)
	_shake(del)
	get_tree().create_timer(TIEMPO_CONFIRMAR_BORRADO).timeout.connect(_reset_delete_button.bind(del))

func _reset_delete_button(del: Button) -> void:
	if not is_instance_valid(del): return
	del.remove_meta("confirmando")
	del.text = "BORRAR"
	del.add_theme_color_override("font_color", COLOR_PELIGRO)

# la tarjeta se va hacia la derecha y vuelve como slot libre
func _delete_slot(slot: int) -> void:
	_btn_snd.play()
	GameData.delete_save(slot)
	var card = _cards[slot - 1]
	var t = create_tween().set_parallel(true)
	t.tween_property(card, "position:x", 120.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_property(card, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(_rebuild_after_delete.bind(slot))

func _rebuild_after_delete(slot: int) -> void:
	_populate_slots()
	var card = _cards[slot - 1]
	_slide_in(card, 0.0)

func _on_back_pressed() -> void:
	if _leaving: return
	_btn_snd.play()
	_leave_to("res://Scenes/UI/MainMenu.tscn")

func _leave_to(path: String) -> void:
	_leaving = true
	_play_exit_animation(func(): SceneTransition.change_scene(path))

func _shake(node: Control) -> void:
	var base = node.position
	var t = create_tween()
	for k in 4:
		t.tween_property(node, "position", base + Vector2(randf_range(-4, 4), 0), 0.03)
	t.tween_property(node, "position", base, 0.04)

# ---------- animaciones ----------

func _play_intro_animation() -> void:
	_title_box.modulate.a = 0.0
	_title_box.position.y -= 30.0
	var t = create_tween().set_parallel(true)
	t.tween_property(_title_box, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	t.tween_property(_title_box, "position:y", _title_box.position.y + 30.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var line = _title_box.get_node("Linea")
	t.tween_property(line, "custom_minimum_size:x", 220.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.2)
	for i in _cards.size():
		_slide_in(_cards[i], 0.15 + i * 0.09)
	_back_btn.modulate.a = 0.0
	create_tween().tween_property(_back_btn, "modulate:a", 1.0, 0.4).set_delay(0.45)

# entra desde la derecha con un rebote chico
func _slide_in(card: Control, delay: float) -> void:
	var final_x = card.position.x
	card.position.x = final_x + 120.0
	card.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(card, "position:x", final_x, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(delay)
	t.tween_property(card, "modulate:a", 1.0, 0.3).set_delay(delay)

func _play_exit_animation(on_finished: Callable) -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(on_finished)

# ---------- opciones de efectos (igual que el menú principal) ----------

func _apply_menu_settings() -> void:
	if has_node("Background"): _fondo_material = $Background.material
	_set_menu_particles(FxSettings.on("particulas_menu"))
	_set_menu_background_anim(FxSettings.on("fondo_animado_menu"))
	var gs = FxSettings.instance()
	if gs: gs.setting_changed.connect(_on_setting_changed)

func _on_setting_changed(_section: String, key: String, value: Variant) -> void:
	match key:
		"particulas_menu": _set_menu_particles(bool(value))
		"fondo_animado_menu": _set_menu_background_anim(bool(value))

func _set_menu_particles(enabled: bool) -> void:
	for n in ["RainParticles", "SnowParticles"]:
		var p = get_node_or_null(n)
		if not p: continue
		p.visible = enabled
		p.emitting = enabled

func _set_menu_background_anim(enabled: bool) -> void:
	if not has_node("Background"): return
	$Background.material = _fondo_material if enabled else null

# ---------- popup de tutorial (slot nuevo) ----------

func _show_tutorial_prompt(slot: int) -> void:
	var popup = CanvasLayer.new()
	popup.layer = 100
	popup.set_meta("popup_tutorial", true)
	add_child(popup)
	var root_control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(root_control)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0.02, 0.03, 0.0)
	bg.gui_input.connect(_on_popup_bg_input.bind(popup)) # click afuera = cancelar
	root_control.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(center)
	var panel = _make_popup_panel()
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 26)
	panel.add_child(vbox)
	var title = _make_label("¿Querés hacer el tutorial?", 26, COLOR_ACENTO, FONT_TITULO)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub = _make_label("Slot %02d · partida nueva   (click afuera o Esc para cancelar)" % slot, 16, Color(0.68, 0.78, 0.78))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 22)
	vbox.add_child(hbox)
	var yes_btn = _make_popup_button("SÍ", COLOR_ACENTO, 0)
	var no_btn = _make_popup_button("NO, SOY UN CAPO", Color(1.0, 0.55, 0.35), 1)
	yes_btn.pressed.connect(_start_new_game.bind(slot, popup, "res://Scenes/Rooms/training_room.tscn"))
	no_btn.pressed.connect(_start_new_game.bind(slot, popup, "res://Scenes/Rooms/lab_room.tscn"))
	hbox.add_child(yes_btn)
	hbox.add_child(no_btn)

	_animate_popup_in(bg, panel)

func _make_popup_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 260)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.07, 0.96)
	sb.border_color = Color(COLOR_ACENTO, 0.8)
	sb.set_border_width_all(2)
	sb.border_width_left = 6
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 24
	sb.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", sb)
	return panel

func _make_popup_button(text: String, accent: Color, index: int) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 58)
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override("font", FONT_TITULO)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_apply_button_styles(btn, accent, 2)
	ButtonFX.attach(btn, index, 1.06)
	return btn

func _animate_popup_in(bg: ColorRect, panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.88, 0.88)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)
	var t = create_tween().set_parallel(true)
	t.tween_property(bg, "color:a", 0.75, 0.25)
	t.tween_property(panel, "modulate:a", 1.0, 0.25)
	t.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_popup_bg_input(event: InputEvent, popup: CanvasLayer) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_popup(popup)

func _close_popup(popup: CanvasLayer) -> void:
	if not is_instance_valid(popup) or popup.has_meta("cerrando"): return
	popup.set_meta("cerrando", true)
	var t = create_tween()
	t.tween_property(popup.get_child(0), "modulate:a", 0.0, 0.15)
	t.tween_callback(popup.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): return
	for child in get_children():
		if child is CanvasLayer and child.has_meta("popup_tutorial"):
			get_viewport().set_input_as_handled()
			_close_popup(child)
			return

func _start_new_game(slot: int, popup: CanvasLayer, scene_path: String) -> void:
	if _leaving: return
	_btn_snd.play()
	GameData.reset_data()
	GameData.current_slot = slot
	GameData.save_game(slot)
	popup.queue_free()
	_leave_to(scene_path)
