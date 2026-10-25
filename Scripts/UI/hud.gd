extends CanvasLayer
class_name HUD

@export var health_bar: TextureProgressBar
@export var scrap_label: Label
@export var flesh_label: Label
@export var dash_cd_bar: TextureProgressBar

@export var primary_weapon_rect: TextureRect
@export var secondary_weapon_rect: TextureRect
var _dash_was_on_cooldown: bool = false

@export_category("Cartel de entrada a la sala")
## Prendido: cartel nuevo (RoomTitleCard). Apagado: el texto animado de antes.
@export var use_new_room_title: bool = true

@export_category("Eyelight Settings")
@export var eyelight_color: Color = Color(0.9, 0.05, 0.05, 1.0)
@export var eyelight_low_health_threshold: float = 0.25

var _eyelights: Array[PointLight2D] = []
var _eyelight_heartbeat_tween: Tween = null
var _is_eyelight_pulsing: bool = false
var _protocol_panel: PanelContainer
var _protocol_icon: TextureRect
var _protocol_name_label: Label
var _protocol_status_label: Label
var _protocol_displayed_id := ""
var _protocol_refresh_left := 0.0

func _ready():
	add_to_group("hud")
	_setup_eyelights()
	_setup_dash_cooldown()
	_setup_weapon_hud()
	_setup_protocol_hud()
	update_scrap(GameData.scrap)
	update_flesh(GameData.flesh)
	_initialize_health()
	# diferido: así ya están en el árbol los jefes de la sala (ver más abajo)
	_play_intro_room_animation.call_deferred()

func _setup_weapon_hud() -> void:
	var circle_bg = _create_filled_circle_texture(Color(0.05, 0.05, 0.1, 0.7), Color(0.2, 0.8, 1.0, 0.8))
	var primary_panel = get_node_or_null("Control/WeaponHUD/PrimaryPanel")
	if primary_panel and primary_panel is TextureRect:
		primary_panel.texture = circle_bg
	var secondary_panel = get_node_or_null("Control/WeaponHUD/SecondaryPanel")
	if secondary_panel and secondary_panel is TextureRect:
		secondary_panel.texture = circle_bg

func _setup_protocol_hud() -> void:
	var control = get_node_or_null("Control")
	if not control: return
	_protocol_panel = UIStyle.panel(UIStyle.TEX_PANEL_INSET)
	_protocol_panel.name = "ProtocolHUD"
	_protocol_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_protocol_panel.position = Vector2(32, 170)
	_protocol_panel.custom_minimum_size = Vector2(354, 58)
	_protocol_panel.visible = false
	control.add_child(_protocol_panel)
	var margin = UIStyle.padded(8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_protocol_panel.add_child(margin)
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	_protocol_icon = UIStyle.icon(null, 24)
	_protocol_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_protocol_icon.modulate = UIStyle.COLOR_TEAL
	_protocol_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_protocol_icon)
	var texts = VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	_protocol_name_label = UIStyle.label("", 16, UIStyle.COLOR_TEAL)
	_protocol_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(_protocol_name_label)
	_protocol_status_label = UIStyle.label("", 13, UIStyle.COLOR_MUTED)
	_protocol_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(_protocol_status_label)

func _update_protocol_hud(player: Node2D, delta: float) -> void:
	if not is_instance_valid(_protocol_panel): return
	_protocol_refresh_left -= delta
	if _protocol_refresh_left > 0.0: return
	_protocol_refresh_left = 0.1
	var id: String = GameData.active_protocol
	var in_lab: bool = player.has_method("_is_in_lab_room") and player._is_in_lab_room()
	_protocol_panel.visible = not id.is_empty() and not in_lab and "protocols" in player and player.protocols != null
	if not _protocol_panel.visible: return
	if id != _protocol_displayed_id:
		_protocol_displayed_id = id
		var definition = OmniaCatalog.protocol_definition(id)
		_protocol_name_label.text = OmniaCatalog.protocol_name(id)
		_protocol_icon.texture = OmniaCatalog.load_icon(str(definition.get("icon", "icon_energy")))
		_protocol_icon.modulate = Color.WHITE if id == "reciclaje_instantaneo" else UIStyle.COLOR_TEAL
	var status: String = player.protocols.status_text()
	if _protocol_status_label.text != status:
		_protocol_status_label.text = status

func _create_filled_circle_texture(bg_color: Color, border_color: Color) -> ImageTexture:
	var img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var center = Vector2(40, 40)
	for x in range(80):
		for y in range(80):
			var d = Vector2(x, y).distance_to(center)
			if d <= 38.0 and d >= 35.0:
				img.set_pixel(x, y, border_color)
			elif d < 35.0:
				img.set_pixel(x, y, bg_color)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)

func _initialize_health() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if "stats" in p and p.stats:
			update_health(p.stats.current_health, p.stats.max_health)

func _setup_dash_cooldown() -> void:
	if dash_cd_bar:
		_configure_existing_dash_bar(dash_cd_bar)
		return
	if _find_dash_bar_node():
		_configure_existing_dash_bar(dash_cd_bar)
		return
	_create_dash_bar_fallback()

func _configure_existing_dash_bar(bar: TextureProgressBar) -> void:
	if not bar.texture_under and not bar.texture_progress:
		_assign_fallback_textures(bar)

func _assign_fallback_textures(bar: TextureProgressBar) -> void:
	if not bar.texture_under:
		bar.texture_under = _create_circle_texture(Color(0.2, 0.2, 0.2, 0.5))
	if not bar.texture_progress:
		bar.texture_progress = _create_circle_texture(Color(0.2, 0.8, 1.0, 1.0))

func _find_dash_bar_node() -> bool:
	var control = get_node_or_null("Control")
	if not control: return false
	var found = control.get_node_or_null("DashCDBar")
	if found:
		dash_cd_bar = found
		return true
	return false

func _create_dash_bar_fallback() -> void:
	var tex = _create_circle_texture(Color(0.2, 0.8, 1.0, 1.0))
	var tex_bg = _create_circle_texture(Color(0.2, 0.2, 0.2, 0.5))
	
	dash_cd_bar = TextureProgressBar.new()
	dash_cd_bar.texture_under = tex_bg
	dash_cd_bar.texture_progress = tex
	dash_cd_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	dash_cd_bar.max_value = 5.0
	dash_cd_bar.step = 0.01
	dash_cd_bar.value = 5.0
	dash_cd_bar.position = Vector2(64, 120)
	
	var lbl = _create_dash_label()
	dash_cd_bar.add_child(lbl)
	
	var control = get_node_or_null("Control")
	if control:
		control.add_child(dash_cd_bar)

func _create_circle_texture(color: Color) -> ImageTexture:
	var img = Image.create(72, 72, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(72):
		for y in range(72):
			var d = Vector2(x, y).distance_to(center)
			if d <= 30.0 and d >= 22.0:
				img.set_pixel(x, y, color)
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)

func _create_dash_label() -> Label:
	var lbl = Label.new()
	lbl.text = "DASH"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	return lbl

func _process(delta: float) -> void:
	var p = GameData.get_player()
	if not p:
		if is_instance_valid(_protocol_panel):
			_protocol_panel.visible = false
		return
	if "dash_cd_timer" in p and p.dash_cd_timer:
		var time_left = 0.0 if p.dash_cd_timer.is_stopped() else p.dash_cd_timer.time_left
		var max_time = p.dash_cd_timer.wait_time
		update_dash_cooldown(time_left, max_time)
	_update_weapons_hud(p)
	_update_protocol_hud(p, delta)

func _update_weapons_hud(p: Node2D) -> void:
	# En el laboratorio no mostramos el HUD de armas (el jugador tampoco las
	# tiene visibles ahí, ver _is_in_lab_room en player.gd).
	var weapon_hud = get_node_or_null("Control/WeaponHUD")
	var hide_weapon_hud = p.has_method("_is_in_lab_room") and p._is_in_lab_room()
	if weapon_hud:
		weapon_hud.visible = not hide_weapon_hud
	if hide_weapon_hud:
		return

	if "active_weapon" in p and p.active_weapon:
		var tex = _get_display_weapon_texture(p, p.active_weapon, true)
		if primary_weapon_rect:
			_show_weapon_icon(primary_weapon_rect, tex)
			
	if "second_weapon" in p and p.second_weapon:
		var tex = _get_display_weapon_texture(p, p.second_weapon, false)
		if secondary_weapon_rect:
			_show_weapon_icon(secondary_weapon_rect, tex)

# Las dos armas del HUD a la misma escala entera (x2), un solo cuadro.
# Solo se rearma cuando cambia el arma (esto corre en cada cuadro).
func _show_weapon_icon(rect: TextureRect, tex: Texture2D) -> void:
	if rect.has_meta("source") and rect.get_meta("source") == tex: return
	if tex:
		rect.set_meta("source", tex)
	elif rect.has_meta("source"):
		rect.remove_meta("source")
	PixelIcon.apply(rect, tex, PixelIcon.WEAPON, Vector2(70, 70))

# El HUD usa los íconos recortados del Códice. Las texturas de los sprites de
# mundo incluyen mucho margen transparente y dentro de un círculo se ven mínimas.
var _codex_weapon_icons: Dictionary = {}
var _synergy_weapon_icons: Dictionary = {}

func _get_display_weapon_texture(player: Node, weapon_container: Node, is_main: bool) -> Texture2D:
	var equipment = player.get_node_or_null("Equipment") if player else null
	var weapon_id = _get_codex_weapon_id(weapon_container)
	var synergy_id = SynergyManager.get_active_weapon_display_synergy(equipment, weapon_id, is_main)
	if synergy_id != "":
		if not _synergy_weapon_icons.has(synergy_id):
			_synergy_weapon_icons[synergy_id] = UIStyle.trimmed(OmniaCatalog.synergy_icon(synergy_id))
		return _synergy_weapon_icons[synergy_id]
	return _get_codex_weapon_texture(weapon_container)

func _get_codex_weapon_texture(weapon_container: Node) -> Texture2D:
	var weapon_id = _get_codex_weapon_id(weapon_container)
	if weapon_id != "" and CodexData.DATA.get("weapons", {}).has(weapon_id):
		if not _codex_weapon_icons.has(weapon_id):
			var icon = CodexData.DATA["weapons"][weapon_id].get("icon", null) as Texture2D
			_codex_weapon_icons[weapon_id] = UIStyle.trimmed(icon)
		return _codex_weapon_icons[weapon_id]
	return _get_weapon_texture(weapon_container)

func _get_codex_weapon_id(weapon_container: Node) -> String:
	if weapon_container and weapon_container.has_method("get_base_weapon_id"):
		var base_id = weapon_container.get_base_weapon_id()
		if base_id != "":
			return base_id
	var current_weapon = weapon_container.get("current_weapon") if weapon_container else null
	if current_weapon and "id" in current_weapon:
		return current_weapon.id
	return ""

# Armas con hoja de cuadros (Speed Demon, Holy Fire): el ícono muestra solo el primero.
var _frame_icons: Dictionary = {}

func _first_frame(sprite: Sprite2D) -> Texture2D:
	if sprite.hframes <= 1 or not sprite.texture:
		return sprite.texture
	if not _frame_icons.has(sprite.texture):
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite.texture
		var size = sprite.texture.get_size()
		atlas.region = Rect2(0, 0, size.x / sprite.hframes, size.y / sprite.vframes)
		_frame_icons[sprite.texture] = atlas
	return _frame_icons[sprite.texture]

func _get_weapon_texture(weapon_container: Node) -> Texture2D:
	if not weapon_container: return null
	var cur = weapon_container.get("current_weapon")
	if not cur: return null
	
	var sprite = cur.get_node_or_null("Melee_sprite")
	if sprite and sprite is Sprite2D:
		return _first_frame(sprite)
		
	var anim_sprite = cur.get_node_or_null("Weapon_Sprites")
	if anim_sprite and anim_sprite is AnimatedSprite2D:
		var frames = anim_sprite.sprite_frames
		if frames and frames.has_animation(anim_sprite.animation):
			var frame_count = frames.get_frame_count(anim_sprite.animation)
			if frame_count > 0:
				return frames.get_frame_texture(anim_sprite.animation, 0)
				
	return null

func update_dash_cooldown(time_left: float, max_time: float) -> void:
	if not dash_cd_bar: return
	dash_cd_bar.max_value = max_time
	dash_cd_bar.value = max_time - time_left
	_check_dash_ready_trigger(time_left)

func _check_dash_ready_trigger(time_left: float) -> void:
	if time_left > 0.0:
		_dash_was_on_cooldown = true
		return
	if not _dash_was_on_cooldown:
		return
	_dash_was_on_cooldown = false
	_play_dash_ready_fx()

func _play_dash_ready_fx() -> void:
	if not dash_cd_bar:
		return
	_create_dash_ready_tween()

func _create_dash_ready_tween() -> void:
	var tween = create_tween()
	
	# Primera fase: Brillar intensamente en blanco
	tween.tween_property(dash_cd_bar, "self_modulate", Color(5.0, 5.0, 5.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Segunda fase: Restaurar el color original
	tween.tween_property(dash_cd_bar, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)




func update_health(new_health: int, max_health: int):
	_update_health_bar_values(new_health, max_health)
	_update_eyelights_health(new_health, max_health)

func _setup_eyelights() -> void:
	_eyelights.clear()
	_collect_eyelights(self)
	for light in _eyelights:
		light.color = eyelight_color
		light.energy = 0.0
		light.visible = false
		light.blend_mode = PointLight2D.BLEND_MODE_ADD
		light.range_layer_min = -100
		light.range_layer_max = 100

func _collect_eyelights(node: Node) -> void:
	for child in node.get_children():
		if child is PointLight2D and "eyelight" in child.name.to_lower():
			_eyelights.append(child)
		_collect_eyelights(child)

func _update_eyelights_health(new_health: int, max_health: int) -> void:
	if _eyelights.is_empty() or max_health <= 0: return
	var health_ratio = float(new_health) / float(max_health)
	var is_critical = new_health > 0 and health_ratio < eyelight_low_health_threshold
	if is_critical:
		_start_eyelight_heartbeat()
	else:
		_stop_eyelight_heartbeat()

func _start_eyelight_heartbeat() -> void:
	if _is_eyelight_pulsing: return
	_is_eyelight_pulsing = true
	_set_eyelights_visible(true)
	_animate_eyelight_heartbeat()

func _stop_eyelight_heartbeat() -> void:
	if not _is_eyelight_pulsing:
		_set_eyelights_visible(false)
		return
	_is_eyelight_pulsing = false
	if _eyelight_heartbeat_tween and _eyelight_heartbeat_tween.is_valid():
		_eyelight_heartbeat_tween.kill()
	_set_eyelights_visible(false)

func _set_eyelights_visible(target_visible: bool) -> void:
	for light in _eyelights:
		if not is_instance_valid(light): continue
		light.visible = target_visible
		if not target_visible:
			light.energy = 0.0

func _animate_eyelight_heartbeat() -> void:
	if not _is_eyelight_pulsing: return
	if _eyelight_heartbeat_tween and _eyelight_heartbeat_tween.is_valid():
		_eyelight_heartbeat_tween.kill()
	_eyelight_heartbeat_tween = create_tween()
	# Primer latido fuerte (Sístole 1)
	_eyelight_heartbeat_tween.tween_method(_set_eyelights_energy, 0.4, 2.5, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_eyelight_heartbeat_tween.tween_method(_set_eyelights_energy, 2.5, 0.6, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Segundo latido rebote (Sístole 2)
	_eyelight_heartbeat_tween.tween_method(_set_eyelights_energy, 0.6, 1.8, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_eyelight_heartbeat_tween.tween_method(_set_eyelights_energy, 1.8, 0.3, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Pausa de diástole antes del próximo ciclo de latido
	_eyelight_heartbeat_tween.tween_interval(0.42)
	_eyelight_heartbeat_tween.finished.connect(_on_eyelight_heartbeat_cycle_finished)

func _on_eyelight_heartbeat_cycle_finished() -> void:
	if _is_eyelight_pulsing:
		_animate_eyelight_heartbeat()

func _set_eyelights_energy(val: float) -> void:
	for light in _eyelights:
		if is_instance_valid(light):
			light.energy = val

func _update_health_bar_values(new_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = new_health

func update_scrap(amount: int):
	if scrap_label:
		scrap_label.text = str(amount)

func update_flesh(amount: int):
	if flesh_label:
		flesh_label.text = str(amount)

func _play_intro_room_animation() -> void:
	var intro_node = get_node_or_null("Control/Intro_room")
	if use_new_room_title:
		_hide_old_room_intro(intro_node)
		# los jefes con entrada propia muestran su título (que se convierte en su barra)
		if not get_tree().get_nodes_in_group("boss_entrance").is_empty():
			return
		var scene = get_tree().current_scene
		RoomTitleCard.show_in(self, _get_room_title_data(scene.scene_file_path if scene else ""))
		return
	if not intro_node: return
	
	var label = intro_node.get_node_or_null("Name_room") as Label
	if label:
		var scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
		label.text = _get_pretty_room_name(scene_path)
		
	var anim_player = intro_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player:
		anim_player.play("Intro_room")

# El AnimationPlayer viejo arranca solo (autoplay), así que hay que frenarlo.
func _hide_old_room_intro(intro_node: Node) -> void:
	if not intro_node: return
	intro_node.visible = false
	var anim_player = intro_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player:
		anim_player.stop()

# Textos del cartel nuevo: línea chica de arriba, nombre grande, subtítulo y color.
func _get_room_title_data(path: String) -> Dictionary:
	var filename = path.get_file().to_lower()
	if "lab_room" in filename:
		return _title_data("BASE DE OPERACIONES", "LABORATORIO", "ZONA SEGURA", UIStyle.COLOR_TEAL)
	if "core_upgrade" in filename:
		return _title_data("TERMINAL DE MEJORAS", "O.M.N.I.A.", "MEJORAS PERMANENTES", UIStyle.COLOR_TEAL)
	if "tutorial" in filename:
		return _title_data("SIMULACIÓN GUIADA", "TUTORIAL", "APRENDE A SOBREVIVIR", UIStyle.COLOR_GOLD)
	if "training" in filename:
		return _title_data("SIMULACIÓN", "ENTRENAMIENTO", "PROTOCOLO DE PRUEBA", UIStyle.COLOR_TEAL)
	if "debug_scene" in filename:
		return _title_data("ENTORNO DE PRUEBAS", "SALA DE DEBUG", "", UIStyle.COLOR_MUTED)
	var lvl_num = _get_digits(filename.split("_")[0]) if filename.begins_with("level") else ""
	if lvl_num == "":
		return _title_data("", "DISTRITO ASPHODEL", "", UIStyle.COLOR_TEAL)
	var zone_name = GameData.get_zone_name(int(lvl_num)).to_upper()
	var room_tag = "ZONA %s · SALA %02d" % [lvl_num, maxi(GameData.current_run_room, 1)]
	if "bossfight" in filename:
		return _title_data("ZONA %s · ENCUENTRO" % lvl_num, zone_name, "AMENAZA DETECTADA", Color("#E5484D"))
	if "ygor" in filename:
		return _title_data(room_tag, "TIENDA DE YGOR", "COMERCIO CLANDESTINO", UIStyle.COLOR_GOLD)
	if "treasure" in filename:
		return _title_data(room_tag, "SALA DEL TESORO", "CARGAMENTO SIN VIGILANCIA", UIStyle.COLOR_GOLD)
	return _title_data(room_tag, zone_name, "SECTOR HOSTIL", UIStyle.COLOR_TEAL)

func _title_data(eyebrow: String, title: String, subtitle: String, accent: Color) -> Dictionary:
	return {"eyebrow": eyebrow, "title": title, "subtitle": subtitle, "accent": accent}

func _get_pretty_room_name(path: String) -> String:
	var filename = path.get_file().to_lower()
	if "ygor" in filename:
		return "TIENDA DE YGOR"
	if "treasure" in filename:
		return "SALA DEL TESORO"
	if "lab_room" in filename:
		return "LABORATORIO"
	if "debug_scene" in filename:
		return "SALA DE DEBUG"
	if "core_upgrade" in filename:
		return "O.M.N.I.A."
	if filename.begins_with("level"):
		return _get_formatted_level_room_name(filename)
	return "DISTRITO ASPHODEL"

# "LA CRIPTA / SALA - 3": nombre de la zona (sale del número de LevelN_) y la
# sala de la run. En la sala del jefe dice "SALA DEL JEFE".
func _get_formatted_level_room_name(filename: String) -> String:
	var lvl_num = _get_digits(filename.split("_")[0])
	if lvl_num == "":
		return "DISTRITO ASPHODEL"
	var zone_name = GameData.get_zone_name(int(lvl_num)).to_upper()
	if "bossfight" in filename:
		return "%s\nSALA DEL JEFE" % zone_name
	var current_room = maxi(GameData.current_run_room, 1)
	return "%s\nSALA - %d" % [zone_name, current_room]

func _get_digits(text: String) -> String:
	var digits = ""
	for i in range(text.length()):
		var c = text[i]
		if c >= "0" and c <= "9":
			digits += c
	return digits
