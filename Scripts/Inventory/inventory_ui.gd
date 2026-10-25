class_name InventoryUI
extends Control

@export var inventory: Inventory
@export var equipment: Equipment
var player_sprite: AnimatedSprite2D

var ui_slots: Array[UISlot] = []
var inventory_slots: Array[UISlot] = []

# Referencias a slots corporales
var body_slots: Dictionary = {} # ItemData.ItemSlot -> UISlot
# Referencias a slots de armas
var main_weapon_slots: Array[UISlot] = []
var sec_weapon_slots: Array[UISlot] = []
@onready var primary_weapon_slot_panel: PanelContainer = %PrimaryWeaponSlotPanel
@onready var primary_weapon_icon: TextureRect = %PrimaryWeaponIcon
@onready var secondary_weapon_slot_panel: PanelContainer = %SecondaryWeaponSlotPanel
@onready var secondary_weapon_icon: TextureRect = %SecondaryWeaponIcon

# Estado de UI
var current_tab: String = "INVENTORY" # "INVENTORY" o "CODEX"
var current_filter: String = "ALL" # "ALL", "WEAPON", "BODY"
var sort_mode: String = "DEFAULT" # "DEFAULT", "TYPE", "NAME"
var _is_animating: bool = false
var _default_margin_pos_y: float = 40.0

# Item seleccionado en el inventario o equipamiento
var selected_item: ItemData = null
var selected_source_slot: UISlot = null
var is_comparing: bool = false
var _recycle_btn: Button
var _pad_holding: bool = false # joystick: objeto elegido con A esperando casillero
var _synergy_tutorial_slot_highlights: Array[Control] = []
var _synergy_tutorial_click_hints: Array[Control] = []
var _synergy_tutorial_slots_visible := false

const TUTORIAL_SYNERGY_ITEM_IDS := ["colmena", "cerebro", "cabeza_humana"]

# Nodos principales
@onready var dark_backdrop: ColorRect = %DarkBackdrop
@onready var window_margin: MarginContainer = %WindowMargin
@onready var window_panel: PanelContainer = %WindowPanel
@onready var top_bar: HBoxContainer = %TopBar
@onready var content_area: Control = %ContentArea
@onready var bottom_bar: PanelContainer = %BottomBar

# Vistas guardadas en inventory_ui.tscn
@onready var main_three_columns: HBoxContainer = %MainThreeColumns
@onready var codex_view: Control = %CodexView

# Pestañas superiores
@onready var tab_inventory_btn: Button = %TabInventoryBtn
@onready var tab_codex_btn: Button = %TabCodexBtn
@onready var capacity_label: Label = %CapacityLabel

# Columna 1: Inventario
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var filter_all_btn: Button = %FilterAllBtn
@onready var filter_weapons_btn: Button = %FilterWeaponsBtn
@onready var filter_body_btn: Button = %FilterBodyBtn
@onready var sort_option_btn: OptionButton = %SortOptionBtn

# Ficha de detalle inferior (columna 1)
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_empty_label: Label = %DetailEmptyLabel
@onready var detail_content_box: VBoxContainer = %DetailContentBox
@onready var detail_icon_rect: TextureRect = %DetailIconRect
@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_meta_label: Label = %DetailMetaLabel
@onready var detail_desc_label: Label = %DetailDescLabel
@onready var detail_stats_label: RichTextLabel = %DetailStatsLabel
@onready var detail_equip_btn: Button = %DetailEquipBtn
@onready var detail_compare_btn: Button = %DetailCompareBtn

# Columna 2: Equipamiento
@onready var character_name_label: Label = %CharacterNameLabel
@onready var portrait_container: Control = %PortraitContainer
@onready var portrait_anim_sprite: AnimatedSprite2D = %PortraitAnimSprite

# Columna 3: Atributos
@onready var stats_char_vbox: VBoxContainer = %StatsCharVbox
@onready var stats_body_synergy_container: VBoxContainer = %StatsBodySynergyContainer
@onready var stats_body_synergy_title: Label = %StatsBodySynergyTitle
@onready var stats_body_synergy_desc: Label = %StatsBodySynergyDesc
@onready var stats_weapon_vbox: VBoxContainer = %StatsWeaponVbox
@onready var stats_weapon_header_box: HBoxContainer = %StatsWeaponHeaderBox
@onready var stats_weapon_icon: TextureRect = %StatsWeaponIcon
@onready var stats_weapon_name: Label = %StatsWeaponName
@onready var stats_preview_badge: HBoxContainer = %StatsPreviewBadge
@onready var stats_synergy_description: Label = %StatsSynergyDescription
@onready var stats_tab_primary_btn: Button = %StatsTabPrimaryBtn
@onready var stats_tab_secondary_btn: Button = %StatsTabSecondaryBtn
var active_weapon_stats_tab: String = "PRIMARY"

# Tooltip flotante (para Códice y slots)
@onready var tooltip_panel: PanelContainer = %TooltipPanel
@onready var tooltip_name: Label = %TooltipName
@onready var tooltip_rarity: Label = %TooltipRarity
@onready var tooltip_type: Label = %TooltipType
@onready var tooltip_desc: RichTextLabel = %TooltipDesc
@onready var tooltip_stats: RichTextLabel = %TooltipStats
@onready var tooltip_action: Label = %TooltipAction

# Códice
var selected_codex_category: String = "enemies"
@onready var codex_grid: GridContainer = %CodexGrid
@onready var research_browser: Control = %ResearchBrowser
@onready var tab_research_btn: Button = %TabResearchBtn
var codex_category_buttons: Dictionary = {}
@onready var codex_progress_label: Label = %CodexProgressLabel

const SLOT_SCENE = preload("res://Scenes/UI/inventory_slot.tscn")





# Diccionario de etiquetas legibles para atributos
const STAT_LABELS: Dictionary = {
	"max_health_percent": "Vida Máxima",
	"move_speed_percent": "Velocidad de Movimiento",
	"armor": "Armadura",
	"damage": "Daño",
	"projectile_speed": "Velocidad de Proyectil",
	"bullet_count": "Cantidad de Proyectiles",
	"cone_spread_angle": "Dispersión",
	"piercing": "Perforación",
	"crit_chance": "Prob. Crítica",
	"crit_damage": "Daño Crítico",
	"attack_speed": "Cadencia",
	"damage_multiplier": "Multiplicador Daño",
	"knockback_force": "Empuje",
	"stun_chance": "Prob. Aturdimiento",
	"burn_chance": "Prob. Quemadura",
	"slow_chance": "Prob. Ralentización",
}

func _ready() -> void:
	UIStyle.enlarge_texts(self) # letra más grande (en el evento costaba leer)
	_auto_fetch_player_nodes()
	_limit_inventory_slots()
	for node in main_three_columns.find_children("*", "PanelContainer", true, false):
		if not node is UISlot or not node.is_equipped_slot: continue
		ui_slots.append(node)
		if node.slot_type <= ItemData.ItemSlot.MAIN_W3:
			main_weapon_slots.append(node)
		elif node.slot_type <= ItemData.ItemSlot.SEC_W3:
			sec_weapon_slots.append(node)
		else:
			body_slots[node.slot_type] = node
	for button in %CodexCategories.get_children():
		codex_category_buttons[button.get_meta("category")] = button
	if inventory:
		inventory.inventory_updated.connect(update_items_list)
	if equipment:
		equipment.equipment_changed.connect(update_ui)
	_default_margin_pos_y = window_margin.position.y
	_setup_pad_hints()
	for slot in inventory_slots + ui_slots:
		slot.slot_pad_equip.connect(_on_slot_pad_equip)
	update_ui()

# Con joystick, las teclas de la barra de abajo y de "Cerrar" pasan a ser
# botones, y aparecen LB / RB al lado de las pestañas.
func _setup_pad_hints() -> void:
	var hints = %BottomBar.get_node("MarginContainer/HBoxContainer")
	KeycapSwitch.swap_icon(hints.get_node("HBoxContainer/TextureRect"), "A")
	_pad_keycap(hints.get_node("HBoxContainer2/PanelContainer"), "X")
	_pad_keycap(hints.get_node("HBoxContainer3/PanelContainer"), "RS")
	_pad_keycap(hints.get_node("HBoxContainer4/PanelContainer"), "B")
	_add_drop_hint(hints)
	_pad_keycap(top_bar.get_node("HBoxContainer/HBoxContainer/PanelContainer"), "B")
	KeycapSwitch.add_tab_hints(top_bar.get_node("TabsBox"), 34.0)
	KeycapSwitch.add_tab_hints(%CodexCategories, 34.0, "LT", "RT")

# Mochila de Inventory.CAPACITY lugares (prueba: 12): sobran casilleros de la escena.
# Con menos lugares, los casilleros son más grandes (4 x 3) y se ve todo sin scroll.
const SLOT_COLUMNS := 4
const SLOT_SIZE := Vector2(104, 104)

func _limit_inventory_slots() -> void:
	inventory_grid.columns = SLOT_COLUMNS
	for slot in inventory_grid.get_children():
		if not slot is UISlot: continue
		if inventory_slots.size() < Inventory.CAPACITY:
			inventory_slots.append(slot)
			slot.custom_minimum_size = SLOT_SIZE
		else:
			inventory_grid.remove_child(slot)
			slot.queue_free()

# "Q Soltar" en la barra de abajo (con joystick, la cruceta).
func _add_drop_hint(hints: Node) -> void:
	var drop = hints.get_node("HBoxContainer2").duplicate()
	drop.name = "DropHint"
	hints.add_child(drop)
	hints.move_child(drop, hints.get_node("HBoxContainer4").get_index())
	(drop.get_node("PanelContainer/Label") as Label).text = "Q"
	for child in drop.get_children():
		if child is Label: child.text = "Soltar"
	_pad_keycap(drop.get_node("PanelContainer"), "DPAD")

# Q o flecha arriba del joystick: tira al piso el objeto elegido.
func _is_drop_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.physical_keycode == KEY_Q
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_DPAD_UP
	return false

func _drop_target_item() -> ItemData:
	var focus = get_viewport().gui_get_focus_owner()
	if focus is UISlot and inventory_slots.has(focus) and focus.item:
		return focus.item
	for slot in inventory_slots:
		if slot.is_hovered and slot.item:
			return slot.item
	if selected_item and inventory.items.has(selected_item):
		return selected_item
	return null

func _drop_selected_item() -> void:
	var item = _drop_target_item()
	if not item:
		_play_cancel_sound()
		return
	inventory.drop_item(item)
	if selected_item == item and not inventory.items.has(item):
		selected_item = null
	_clear_pad_selection()
	_play_cancel_sound()
	update_ui()
	_refresh_pad_tooltip()

func _pad_keycap(cap: PanelContainer, pad: String) -> void:
	KeycapSwitch.attach(cap, cap.get_child(0) as Label, pad)

func _apply_tab_style(btn: Button, is_active: bool) -> void:
	btn.theme_type_variation = "InventoryTabActive" if is_active else "InventoryTab"

func _apply_secondary_button_style(btn: Button) -> void:
	btn.theme_type_variation = "InventorySecondary"

func _apply_primary_button_style(btn: Button) -> void:
	btn.theme_type_variation = "InventoryPrimary"

func toggle_visibility() -> void:
	if _is_animating: return
	if visible:
		_animate_close()
	else:
		_animate_open()

func _animate_open() -> void:
	_is_animating = true
	RunLog.note("inventario")
	visible = true
	get_tree().paused = true
	SceneTransition.set_menu_muffle(true)
	update_ui()
	_start_open_tweens()
	PadFocus.push_modal(self) # con joystick el foco no sale del inventario
	_focus_first_slot.call_deferred()

func _start_open_tweens() -> void:
	var start_y = get_viewport_rect().size.y
	window_margin.position.y = start_y
	dark_backdrop.modulate.a = 0.0

	var slide_tween = create_tween()
	slide_tween.tween_property(window_margin, "position:y", _default_margin_pos_y, 0.35)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	var fade_tween = create_tween()
	fade_tween.tween_property(dark_backdrop, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	slide_tween.tween_callback(_on_open_finished)

func _on_open_finished() -> void:
	_is_animating = false

func _animate_close() -> void:
	_is_animating = true
	_hide_tooltip()
	_clear_pad_selection()
	SceneTransition.set_menu_muffle(false)
	PadFocus.pop_modal(self)
	get_viewport().gui_release_focus()
	var target_y = get_viewport_rect().size.y

	var slide_tween = create_tween()
	slide_tween.tween_property(window_margin, "position:y", target_y, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)

	var fade_tween = create_tween()
	fade_tween.tween_property(dark_backdrop, "modulate:a", 0.0, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	slide_tween.tween_callback(_on_close_finished)

func _on_close_finished() -> void:
	visible = false
	get_tree().paused = false
	_is_animating = false

func _input(event: InputEvent) -> void:
	if visible and get_viewport().gui_get_focus_owner() is LineEdit and not event.is_action_pressed("ui_cancel"):
		return
	if event.is_action_pressed("toggle_inventory"):
		if not visible:
			var root = get_tree().root
			if root.has_node("WeaponSelectionMenu") or root.has_node("UpgradesMenu"):
				return
		toggle_visibility()
		get_viewport().set_input_as_handled()
		return

	if not visible: return

	if event.is_action_pressed("ui_cancel"):
		_play_cancel_sound()
		get_viewport().set_input_as_handled()
		if _pad_holding and event is InputEventJoypadButton:
			_clear_pad_selection() # B suelta el objeto elegido; otra B cierra
		else:
			toggle_visibility()
		return

	if current_tab == "INVENTORY" and _is_drop_input(event):
		_drop_selected_item()
		get_viewport().set_input_as_handled()
		return

	if _handle_pad_input(event):
		get_viewport().set_input_as_handled()
		return

	if current_tab == "INVENTORY" and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_on_detail_equip_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SHIFT:
			_toggle_compare_mode()
			get_viewport().set_input_as_handled()

# --- Joystick ---

# LB / RB: pestañas · LT / RT: categorías del códice · clic del analógico der.: comparar.
func _handle_pad_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_tab_prev") or event.is_action_pressed("ui_tab_next"):
		_cycle_tab(-1 if event.is_action_pressed("ui_tab_prev") else 1)
		return true
	if event is InputEventJoypadMotion and current_tab == "CODEX":
		# una categoría por pulsación del gatillo, no una por cada evento del eje
		if InputMode.trigger_tap(event):
			_cycle_codex_category(-1 if event.axis == JOY_AXIS_TRIGGER_LEFT else 1)
			return true
		return false
	if current_tab == "INVENTORY" and event.is_action_pressed("ui_compare"):
		_toggle_compare_mode()
		return true
	return false

func _cycle_tab(step: int) -> void:
	var tabs = ["INVENTORY", "CODEX", "RESEARCH"]
	match tabs[wrapi(tabs.find(current_tab) + step, 0, tabs.size())]:
		"INVENTORY": _on_inventory_tab_pressed()
		"CODEX": _on_codex_tab_pressed()
		"RESEARCH": _on_research_tab_pressed()
	_focus_first_slot.call_deferred()

func _cycle_codex_category(step: int) -> void:
	var cats = codex_category_buttons.keys()
	if cats.is_empty(): return
	_on_codex_category_pressed(cats[wrapi(cats.find(selected_codex_category) + step, 0, cats.size())])

## Con joystick, al abrir o cambiar de pestaña el foco va al primer casillero
## (o a la primera ficha del códice), así se puede navegar con la cruceta.
func _focus_first_slot() -> void:
	if not visible or not InputMode.is_gamepad(): return
	get_viewport().gui_release_focus()
	match current_tab:
		"INVENTORY":
			for slot in inventory_slots:
				if slot.is_visible_in_tree():
					slot.grab_focus()
					return
		"CODEX": _focus_codex()
		"RESEARCH": research_browser.focus_first()

## X del joystick sobre un casillero:
##  - si antes elegiste un objeto de la mochila con A y el casillero de equipo
##    le sirve, lo equipa ahí;
##  - si no, equipa el objeto del casillero en el primer lugar libre (o lo
##    quita, si ya estaba equipado).
func _on_slot_pad_equip(slot: UISlot) -> void:
	var held = _pad_held_item()
	if held and not slot.is_inventory_slot and slot.is_valid_target_for(held):
		_clear_pad_selection()
		_equip_item_to_slot(held, slot.slot_type)
	elif slot.item:
		_clear_pad_selection()
		_on_slot_double_clicked(slot.item, slot)
		return
	_refresh_pad_tooltip()

# Objeto de la mochila elegido con A, esperando que elijas dónde ponerlo.
func _pad_held_item() -> ItemData:
	if _pad_holding and selected_item and inventory.items.has(selected_item):
		return selected_item
	return null

# Marca en verde los casilleros de equipo donde entra el objeto y en rojo los
# demás, como al arrastrarlo con el mouse.
func _show_pad_targets(item: ItemData) -> void:
	_pad_holding = true
	for slot in ui_slots:
		var valid = slot.is_valid_target_for(item)
		slot.set_drop_target_state(valid, not valid)

func _clear_pad_selection() -> void:
	if not _pad_holding: return
	_pad_holding = false
	for slot in ui_slots:
		slot.set_drop_target_state(false, false)

# Después de equipar o desequipar con X, el casillero enfocado puede tener
# otro objeto: se actualiza el cartel.
func _refresh_pad_tooltip() -> void:
	if not InputMode.is_gamepad(): return
	var slot = get_viewport().gui_get_focus_owner() as UISlot
	if slot and slot.item:
		_show_slot_tooltip(slot.item, slot.get_global_rect())
	else:
		_hide_tooltip()

func _play_cancel_sound() -> void:
	$CancelSound.play()

func _play_equip_sound() -> void:
	$EquipSound.play()

func update_if_visible() -> void:
	if not visible: return
	update_ui()

func update_ui() -> void:
	_update_header_data()
	_update_portrait()
	update_items_list()
	update_equipment_display()
	_update_weapon_displays()
	_update_attributes_display()
	_update_detail_panel()
	_update_slot_highlights_and_targets()
	if _synergy_tutorial_slots_visible:
		_refresh_synergy_tutorial_guidance.call_deferred()

	if current_tab == "CODEX":
		_refresh_codex_grid()
	elif current_tab == "RESEARCH":
		research_browser.configure("synergies", true)

func _update_header_data() -> void:
	if capacity_label and inventory:
		capacity_label.text = "%d / %d" % [inventory.items.size(), inventory_slots.size()]
		capacity_label.modulate = UIStyle.COLOR_WARNING if inventory.is_full() else Color.WHITE

func _auto_fetch_player_nodes() -> void:
	if inventory and equipment and player_sprite: return
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	if not inventory:
		inventory = p.get_node_or_null("Inventory")
	if not equipment:
		equipment = p.get_node_or_null("Equipment")
	if not player_sprite:
		player_sprite = p.get_node_or_null("AnimatedSprite2D")

func _update_portrait() -> void:
	if not portrait_anim_sprite: return
	_auto_fetch_player_nodes()
	if not player_sprite or not player_sprite.sprite_frames: return
	if portrait_anim_sprite.sprite_frames != player_sprite.sprite_frames:
		portrait_anim_sprite.sprite_frames = player_sprite.sprite_frames
	var anim = &"idle_down"
	if portrait_anim_sprite.sprite_frames.has_animation(anim):
		portrait_anim_sprite.play(anim)

func update_items_list() -> void:
	if not inventory: return

	# un objeto por casillero: con la mochila limitada, los repetidos ocupan lugar
	var grouped: Array = []
	for item_data in inventory.items:
		grouped.append({"item": item_data, "count": 1})

	_sort_grouped_items(grouped)

	var filtered: Array = []
	for entry in grouped:
		if current_filter == "ALL":
			filtered.append(entry)
		elif current_filter == "WEAPON" and entry.item.type == ItemData.ItemType.WEAPON:
			filtered.append(entry)
		elif current_filter == "BODY" and entry.item.type in [ItemData.ItemType.TORSO, ItemData.ItemType.ARMS, ItemData.ItemType.LEGS]:
			filtered.append(entry)

	for i in range(inventory_slots.size()):
		var slot = inventory_slots[i]
		if i < filtered.size():
			var entry = filtered[i]
			slot.update_slot(entry.item, entry.count)
			slot.set_selected(selected_item != null and selected_item.id == entry.item.id)
		else:
			slot.update_slot(null)
			slot.set_selected(false)

func _sort_grouped_items(list: Array) -> void:
	match sort_mode:
		"TYPE":
			list.sort_custom(func(a, b): return int(a.item.type) < int(b.item.type))
		"NAME":
			list.sort_custom(func(a, b): return a.item.item_name < b.item.item_name)
		_:
			pass

func update_equipment_display() -> void:
	if not equipment: return
	for slot_ui in ui_slots:
		var item_in_slot = equipment.slots.get(slot_ui.slot_type)
		slot_ui.update_slot(item_in_slot)
		slot_ui.set_selected(selected_item != null and item_in_slot != null and selected_item == item_in_slot)

func _update_weapon_displays() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	if primary_weapon_icon and "active_weapon" in p and p.active_weapon:
		_set_weapon_icon(primary_weapon_icon, _get_weapon_texture(p.active_weapon, p, true))
	if secondary_weapon_icon and "second_weapon" in p and p.second_weapon:
		_set_weapon_icon(secondary_weapon_icon, _get_weapon_texture(p.second_weapon, p, false))

# Armas a escala entera fija (un solo cuadro, recortado): todas con el mismo
# tamaño de píxel aunque vengan en lienzos u hojas distintas.
func _set_weapon_icon(rect: TextureRect, tex: Texture2D) -> void:
	var holder = rect.get_parent() as Control
	var box = holder.custom_minimum_size - Vector2(12, 12) if holder and holder.custom_minimum_size != Vector2.ZERO else Vector2(64, 64)
	PixelIcon.apply(rect, tex, PixelIcon.WEAPON, box)

func _get_weapon_texture(weapon_container: Node, player: Node = null, is_main: bool = true) -> Texture2D:
	if not weapon_container: return null
	var synergy_icon = _get_active_synergy_icon(player, weapon_container, is_main)
	if synergy_icon:
		return synergy_icon
	var codex_icon = _get_codex_weapon_texture(weapon_container)
	if codex_icon:
		return codex_icon
	var cur = weapon_container.get("current_weapon")
	if not cur:
		cur = weapon_container

	# 1. Sprite2D directo (Melee_sprite o Sprite2D)
	var melee_sprite = cur.get_node_or_null("Melee_sprite")
	if melee_sprite is Sprite2D and melee_sprite.texture:
		return melee_sprite.texture
	var sprite_node = cur.get_node_or_null("Sprite2D")
	if sprite_node is Sprite2D and sprite_node.texture:
		return sprite_node.texture

	# 2. AnimatedSprite2D (Weapon_Sprites o AnimatedSprite2D)
	var anim_sprite = cur.get_node_or_null("Weapon_Sprites")
	if not anim_sprite:
		anim_sprite = cur.get_node_or_null("AnimatedSprite2D")
	if anim_sprite is AnimatedSprite2D and anim_sprite.sprite_frames:
		var frames = anim_sprite.sprite_frames
		var anim = anim_sprite.animation
		if not frames.has_animation(anim):
			var anim_names = frames.get_animation_names()
			if anim_names.size() > 0:
				anim = anim_names[0]
		if frames.has_animation(anim) and frames.get_frame_count(anim) > 0:
			return frames.get_frame_texture(anim, 0)

	# 3. Fallback en caso de nodos anidados
	for child in cur.get_children():
		if child is Sprite2D and child.texture:
			return child.texture
		if child is AnimatedSprite2D and child.sprite_frames:
			var anim_names = child.sprite_frames.get_animation_names()
			if anim_names.size() > 0 and child.sprite_frames.get_frame_count(anim_names[0]) > 0:
				return child.sprite_frames.get_frame_texture(anim_names[0], 0)

	# 4. Fallback si es el arma por defecto o elegida
	var chosen = GameData.chosen_primary_weapon if GameData else "pistol"
	match chosen:
		"pistol":
			return load("res://Art/Weapons/Distance/Pistol/weapon_revolver_sprite.png")
		"shotgun":
			return load("res://Art/Weapons/Distance/Shotgun/weapon_shotgun_sprite.png")
		"uzi":
			return load("res://Art/Weapons/Distance/Uzi/weapon_uzi_sprite.png")
	return null

# Igual que el HUD: las fichas del Códice están recortadas y fueron pensadas
# para leerse dentro de marcos pequeños; los sprites de mundo tienen aire extra.
var _codex_weapon_icons: Dictionary = {}
var _synergy_weapon_icons: Dictionary = {}

func _get_active_synergy_icon(player: Node, weapon_container: Node, is_main: bool) -> Texture2D:
	if not player:
		return null
	var player_equipment = player.get_node_or_null("Equipment")
	var weapon_id = _get_codex_weapon_id(weapon_container)
	var synergy_id = SynergyManager.get_active_weapon_display_synergy(player_equipment, weapon_id, is_main)
	if synergy_id == "":
		return null
	if not _synergy_weapon_icons.has(synergy_id):
		_synergy_weapon_icons[synergy_id] = UIStyle.trimmed(OmniaCatalog.synergy_icon(synergy_id))
	return _synergy_weapon_icons[synergy_id]

func _get_codex_weapon_texture(weapon_container: Node) -> Texture2D:
	var weapon_id = _get_codex_weapon_id(weapon_container)
	if weapon_id == "" or not CodexData.DATA.get("weapons", {}).has(weapon_id):
		return null
	if not _codex_weapon_icons.has(weapon_id):
		var icon = CodexData.DATA["weapons"][weapon_id].get("icon", null) as Texture2D
		_codex_weapon_icons[weapon_id] = UIStyle.trimmed(icon)
	return _codex_weapon_icons[weapon_id]

func _get_codex_weapon_id(weapon_container: Node) -> String:
	if weapon_container.has_method("get_base_weapon_id"):
		var base_id = weapon_container.get_base_weapon_id()
		if base_id != "":
			return base_id
	var current_weapon = weapon_container.get("current_weapon")
	if current_weapon and "id" in current_weapon:
		return current_weapon.id
	return ""

# Mismo nombre que en el códice (o el de la sinergia activa, si cambia el arma).
func _get_weapon_display_name_text(weapon_container: Node) -> String:
	if not weapon_container: return "Pistola"
	var players = get_tree().get_nodes_in_group("player")
	var player = players[0] if not players.is_empty() else null
	var weapon_id = _get_codex_weapon_id(weapon_container)
	if player and weapon_id != "":
		var is_main = weapon_container == player.get("active_weapon")
		var synergy_id = SynergyManager.get_active_weapon_display_synergy(player.get_node_or_null("Equipment"), weapon_id, is_main)
		if synergy_id != "":
			return SynergyManager.SYNERGIES.get(synergy_id, {}).get("name", synergy_id)
		if CodexData.DATA.get("weapons", {}).has(weapon_id):
			return SynergyManager.get_weapon_display_name(weapon_id)
	var cur = weapon_container.get("current_weapon")
	if not cur: cur = weapon_container
	if "id" in cur and str(cur.id) != "":
		return str(cur.id).capitalize()
	if "weapon_name" in cur and str(cur.weapon_name) != "":
		return str(cur.weapon_name)
	var scene_name = cur.name
	match scene_name.to_lower():
		"pistol": return "Pistola"
		"shotgun": return "Escopeta"
		"uzi": return "Uzi"
		"dagger": return "Daga"
		"axe": return "Hacha"
		"mace": return "Maza"
	return scene_name.capitalize()

# ── Interacción con Slots ──────────────────────────────────────────────────────

func _on_slot_clicked(item: ItemData) -> void:
	_clear_pad_selection()
	selected_item = item
	update_ui()
	# joystick: elegir un objeto de la mochila marca dónde se puede equipar;
	# te mueves hasta el casillero y X lo pone ahí
	if InputMode.is_gamepad() and inventory.items.has(item):
		_show_pad_targets(item)

func _on_slot_double_clicked(item: ItemData, slot_ui: UISlot) -> void:
	if slot_ui.is_inventory_slot:
		_equip_item_direct(item)
	else:
		_unequip_item_direct(item, slot_ui.slot_type)
	_refresh_pad_tooltip()

func _on_drag_started(drag_item: ItemData, source_slot: UISlot) -> void:
	selected_item = drag_item
	selected_source_slot = source_slot
	_highlight_slots_for_item(drag_item)

func _highlight_slots_for_item(item: ItemData) -> void:
	for slot in ui_slots:
		var is_valid = slot.is_valid_target_for(item)
		slot.set_drop_target_state(is_valid, not is_valid)
	for slot in inventory_slots:
		slot.set_drop_target_state(true, false)

func _update_slot_highlights_and_targets() -> void:
	if selected_item == null:
		for slot in ui_slots:
			slot.set_drop_target_state(false, false)
			slot.set_highlight(false)
		return

	# Resaltar destinos compatibles en equipamiento
	for slot in ui_slots:
		var is_valid = slot.is_valid_target_for(selected_item)
		slot.set_highlight(is_valid)

func _on_item_dropped(drag_item: ItemData, source_slot: UISlot, target_slot: UISlot) -> void:
	if source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		_equip_item_to_slot(drag_item, target_slot.slot_type)
	elif not source_slot.is_inventory_slot and target_slot.is_inventory_slot:
		_unequip_item_direct(drag_item, source_slot.slot_type)
	elif not source_slot.is_inventory_slot and not target_slot.is_inventory_slot:
		_swap_equipment_slots(source_slot.slot_type, target_slot.slot_type)

	selected_item = drag_item
	update_ui()
	_hide_tooltip()

func _equip_item_direct(item: ItemData) -> void:
	var target_slot_type = _get_available_slot_for_item(item)
	_equip_item_to_slot(item, target_slot_type)

func _equip_item_to_slot(item: ItemData, target_slot_type: ItemData.ItemSlot) -> void:
	# Solo se equipa lo que está en la mochila: si el objeto ya está puesto,
	# equiparlo de nuevo lo duplicaba (quedaba en otro slot o volvía a la mochila).
	if not inventory.items.has(item): return
	var old_item = equipment.slots.get(target_slot_type)
	if old_item == item: return
	# poner una pieza de cuerpo encima de otra destruye la vieja: se avisa antes
	if old_item and equipment.is_body_part(old_item):
		BodyPartWarning.ask_replace(old_item, item, _install_item.bind(item, target_slot_type))
		return
	_install_item(item, target_slot_type)

func _install_item(item: ItemData, target_slot_type: ItemData.ItemSlot) -> void:
	if not inventory.items.has(item): return
	var old_item = equipment.slots.get(target_slot_type)
	item.slot = target_slot_type
	inventory.remove_item(item)

	if old_item and not equipment.is_body_part(old_item):
		inventory.add_item(old_item, true) # ocupa el lugar que dejó la pieza nueva

	equipment.equip_item(item)
	_play_equip_sound()
	update_ui()

func _unequip_item_direct(item: ItemData, slot_type: ItemData.ItemSlot) -> void:
	# las piezas de cuerpo no vuelven a la mochila: quitarlas las destruye
	# (si volvían, se podían poner y quitar para curarse sin límite)
	if equipment.is_body_part(item):
		BodyPartWarning.ask_remove(item, _destroy_body_part.bind(item, slot_type))
		return
	if inventory.is_full(): # no hay lugar para devolverla a la mochila
		inventory.notify_full()
		_play_cancel_sound()
		return
	equipment.slots[slot_type] = null
	equipment.equipment_changed.emit()
	inventory.add_item(item)
	update_ui()

func _destroy_body_part(item: ItemData, slot_type: ItemData.ItemSlot) -> void:
	if equipment.slots.get(slot_type) != item: return
	equipment.remove_old_item(slot_type)
	equipment.equipment_changed.emit()
	if selected_item == item:
		selected_item = null
	_play_equip_sound()
	update_ui()
	_refresh_pad_tooltip()

func _swap_equipment_slots(slot_a: ItemData.ItemSlot, slot_b: ItemData.ItemSlot) -> void:
	var item_a = equipment.slots.get(slot_a)
	var item_b = equipment.slots.get(slot_b)
	equipment.slots[slot_a] = item_b
	equipment.slots[slot_b] = item_a
	if item_a: item_a.slot = slot_b
	if item_b: item_b.slot = slot_a
	equipment.equipment_changed.emit()
	_play_equip_sound()
	update_ui()

func _get_available_slot_for_item(item: ItemData) -> ItemData.ItemSlot:
	match item.type:
		ItemData.ItemType.TORSO:
			return ItemData.ItemSlot.TORSO
		ItemData.ItemType.ARMS:
			if equipment.slots.get(ItemData.ItemSlot.ARM_L) == null: return ItemData.ItemSlot.ARM_L
			if equipment.slots.get(ItemData.ItemSlot.ARM_R) == null: return ItemData.ItemSlot.ARM_R
			return ItemData.ItemSlot.ARM_L
		ItemData.ItemType.LEGS:
			if equipment.slots.get(ItemData.ItemSlot.LEG_L) == null: return ItemData.ItemSlot.LEG_L
			if equipment.slots.get(ItemData.ItemSlot.LEG_R) == null: return ItemData.ItemSlot.LEG_R
			return ItemData.ItemSlot.LEG_L
		ItemData.ItemType.WEAPON:
			var w_slots = [
				ItemData.ItemSlot.MAIN_W1, ItemData.ItemSlot.MAIN_W2, ItemData.ItemSlot.MAIN_W3,
				ItemData.ItemSlot.SEC_W1, ItemData.ItemSlot.SEC_W2, ItemData.ItemSlot.SEC_W3
			]
			for s in w_slots:
				if equipment.slots.get(s) == null:
					return s
			return ItemData.ItemSlot.MAIN_W1
	return ItemData.ItemSlot.TORSO

# El entrenamiento usa estos nodos sobre los tres huecos del arma principal.
# No cambia la lógica de equipamiento y se puede activar desde cualquier tutorial.
func set_synergy_tutorial_weapon_slots(enabled: bool) -> void:
	if enabled == _synergy_tutorial_slots_visible:
		if enabled:
			_refresh_synergy_tutorial_guidance.call_deferred()
		return
	_synergy_tutorial_slots_visible = enabled
	_clear_synergy_tutorial_guidance()
	if not enabled:
		return
	# El tutorial siempre abre donde están las piezas: mochila, filtro de armas.
	_on_inventory_tab_pressed()
	_on_filter_pressed("WEAPON")
	_refresh_synergy_tutorial_guidance.call_deferred()

func _refresh_synergy_tutorial_guidance() -> void:
	if not _synergy_tutorial_slots_visible:
		return
	_clear_synergy_tutorial_guidance()
	for slot in inventory_slots:
		if _is_tutorial_synergy_piece(slot.item):
			_add_synergy_tutorial_highlight(slot, UIStyle.COLOR_TEAL, "PIEZA")
			_add_synergy_tutorial_right_click_hint(slot)
	for slot in main_weapon_slots:
		_add_synergy_tutorial_highlight(slot, UIStyle.COLOR_GOLD, "EQUIPA AQUÍ")

func _clear_synergy_tutorial_guidance() -> void:
	for highlight in _synergy_tutorial_slot_highlights:
		if is_instance_valid(highlight):
			highlight.queue_free()
	_synergy_tutorial_slot_highlights.clear()
	for hint in _synergy_tutorial_click_hints:
		if is_instance_valid(hint):
			hint.queue_free()
	_synergy_tutorial_click_hints.clear()

func _is_tutorial_synergy_piece(item: ItemData) -> bool:
	return item != null and item.id in TUTORIAL_SYNERGY_ITEM_IDS

func _add_synergy_tutorial_right_click_hint(slot: UISlot) -> void:
	var hint := Control.new()
	hint.name = "SynergyTutorialRightClickHint"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint.z_index = 2
	slot.add_child(hint)
	var mouse = TutorialInputIcon.create("MOUSE_R", 0.66, randf_range(0.0, TutorialInputIcon.PRESS_EVERY))
	mouse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse.size = mouse.custom_minimum_size
	mouse.set_anchors_preset(Control.PRESET_CENTER)
	mouse.position = -mouse.size / 2.0 + Vector2(18.0, 8.0)
	hint.add_child(mouse)
	_synergy_tutorial_click_hints.append(hint)

func _add_synergy_tutorial_highlight(slot: UISlot, color: Color, caption: String) -> void:
	var highlight := Panel.new()
	highlight.name = "SynergyTutorialSlotHighlight"
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.10)
	style.border_color = color
	style.set_border_width_all(3)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	highlight.add_theme_stylebox_override("panel", style)
	slot.add_child(highlight)
	var caption_label := Label.new()
	caption_label.text = caption
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_size_override("font_size", 11)
	caption_label.add_theme_color_override("font_color", color)
	caption_label.add_theme_color_override("font_outline_color", Color("#061013"))
	caption_label.add_theme_constant_override("outline_size", 3)
	caption_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	caption_label.position = Vector2(-42, -24)
	caption_label.size = Vector2(132, 22)
	highlight.add_child(caption_label)
	var pulse := highlight.create_tween().set_loops()
	pulse.tween_property(highlight, "modulate:a", 0.35, 0.55)
	pulse.tween_property(highlight, "modulate:a", 1.0, 0.55)
	_synergy_tutorial_slot_highlights.append(highlight)

# ── Ficha de Detalle y Comparación ─────────────────────────────────────────────

func _update_detail_panel() -> void:
	if not is_instance_valid(_recycle_btn):
		_recycle_btn = Button.new()
		_recycle_btn.text = "Reciclar +40"
		_recycle_btn.theme_type_variation = &"InventorySecondary"
		_recycle_btn.add_theme_font_size_override("font_size", 18)
		detail_compare_btn.get_parent().add_child(_recycle_btn)
		_recycle_btn.pressed.connect(_ask_protocol_recycle)
	_recycle_btn.visible = GameData.active_protocol == "reciclaje_instantaneo" and selected_item != null
	_recycle_btn.disabled = not GameData.can_recycle_protocol(selected_item, inventory)
	_recycle_btn.tooltip_text = "Convierte una pieza de la mochila en 40 de chatarra base. Una vez por zona."
	if selected_item == null:
		detail_empty_label.visible = true
		detail_content_box.visible = false
		return

	detail_empty_label.visible = false
	detail_content_box.visible = true

	PixelIcon.apply(detail_icon_rect, selected_item.icon, PixelIcon.SLOT, Vector2(56, 56))
	detail_name_label.text = selected_item.item_name

	var type_str = _get_item_type_string(selected_item)
	detail_meta_label.text = "%s • Raro" % type_str

	detail_desc_label.text = _get_item_description(selected_item)

	detail_compare_btn.text = "Ver valores" if is_comparing else "Comparar"
	if is_comparing:
		var current_equipped = equipment.slots.get(_get_comparison_slot(selected_item))
		detail_desc_label.text = "Comparando con: %s" % (current_equipped.item_name if current_equipped else "casillero vacío")
		detail_stats_label.text = _format_item_comparison_stats(selected_item)
	else:
		var lines: Array[String] = []
		for key in selected_item.stats:
			var value: float = selected_item.stats[key]
			lines.append(_format_single_stat_diff_line(key, value, value))
		detail_stats_label.text = "\n".join(lines) if not lines.is_empty() else "[color=#8DAAB4]Sin mejoras adicionales[/color]"

func _ask_protocol_recycle() -> void:
	if not GameData.can_recycle_protocol(selected_item, inventory): return
	var item := selected_item
	var dialog := ConfirmationDialog.new()
	dialog.title = "Reciclaje Instantáneo"
	dialog.dialog_text = "¿Reciclar %s?\nLa pieza se consume y recibís 40 de chatarra base.\nSolo podés reciclar una pieza por zona." % item.item_name
	dialog.ok_button_text = "Reciclar"
	dialog.cancel_button_text = "Conservar"
	dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog)
	dialog.confirmed.connect(func():
		if GameData.recycle_protocol_item(item, inventory):
			selected_item = null
			update_ui()
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(470, 180))

func _get_item_type_string(item: ItemData) -> String:
	match item.type:
		ItemData.ItemType.WEAPON: return "Arma"
		ItemData.ItemType.TORSO: return "Torso"
		ItemData.ItemType.ARMS: return "Brazos"
		ItemData.ItemType.LEGS: return "Piernas"
	return "Componente"

func _get_item_description(item: ItemData) -> String:
	if item.type == ItemData.ItemType.WEAPON:
		return "Módulo de combate para armamento táctico."
	if item.type == ItemData.ItemType.TORSO:
		return "Coraza blindada ligera que disipa la energía del impacto."
	if item.type == ItemData.ItemType.ARMS:
		return "Guantes servoasistidos que mejoran la velocidad y potencia."
	if item.type == ItemData.ItemType.LEGS:
		return "Botas cinéticas para optimizar la movilidad y el esquive."
	return "Dispositivo avanzado de combate."

func _get_comparison_slot(item: ItemData) -> ItemData.ItemSlot:
	# Una pieza ya equipada se compara con su propio casillero.
	for slot in equipment.slots:
		if equipment.slots[slot] == item:
			return slot
	return _get_available_slot_for_item(item)

func _format_item_comparison_stats(item: ItemData) -> String:
	var target_slot = _get_comparison_slot(item)
	var current_equipped = equipment.slots.get(target_slot)
	var stat_keys: Array = item.stats.keys()
	if current_equipped:
		for key in current_equipped.stats:
			if not stat_keys.has(key):
				stat_keys.append(key)
	if stat_keys.is_empty():
		return "[color=#8DAAB4]Sin mejoras adicionales[/color]"

	var lines: Array[String] = []
	for k in stat_keys:
		var new_val: float = item.stats.get(k, 0.0)
		var old_val: float = current_equipped.stats.get(k, 0.0) if current_equipped else 0.0
		var line = _format_single_stat_diff_line(k, old_val, new_val)
		lines.append(line)

	return "\n".join(lines)

func _format_single_stat_diff_line(stat_key: String, old_val: float, new_val: float) -> String:
	var label = STAT_LABELS.get(stat_key, stat_key.capitalize())
	var diff = new_val - old_val
	var is_percent = stat_key in ["max_health_percent", "move_speed_percent", "crit_chance", "attack_speed", "stun_chance", "burn_chance", "slow_chance"]

	var old_str = ("%d%%" % round(old_val * 100)) if is_percent else str(old_val)
	var new_str = ("%d%%" % round(new_val * 100)) if is_percent else str(new_val)
	var diff_str = ("%+d%%" % round(diff * 100)) if is_percent else ("%+d" % int(diff) if diff == int(diff) else "%+.1f" % diff)

	var is_improvement = _is_stat_improvement(stat_key, diff)
	var col = "#52D8C6" if is_improvement else "#EDB35B"

	if abs(diff) < 0.001:
		return "%s: %s" % [label, new_str]
	return "%s: %s → [color=%s]%s (%s)[/color]" % [label, old_str, col, new_str, diff_str]

func _is_stat_improvement(stat_key: String, diff: float) -> bool:
	if stat_key == "cone_spread_angle":
		return diff < 0.0 # menor dispersión es mejora
	return diff > 0.0

func _on_detail_equip_pressed() -> void:
	if selected_item == null or not inventory.items.has(selected_item): return
	_equip_item_direct(selected_item)

func _toggle_compare_mode() -> void:
	if selected_item == null:
		return
	is_comparing = !is_comparing
	update_ui()

func _on_stats_weapon_tab_pressed(tab_key: String) -> void:
	active_weapon_stats_tab = tab_key
	_update_stats_weapon_tab_buttons()
	_update_attributes_display()

func _update_stats_weapon_tab_buttons() -> void:
	if not stats_tab_primary_btn or not stats_tab_secondary_btn: return
	var is_primary = (active_weapon_stats_tab == "PRIMARY")
	_apply_subtab_button_style(stats_tab_primary_btn, is_primary)
	_apply_subtab_button_style(stats_tab_secondary_btn, not is_primary)

func _apply_subtab_button_style(btn: Button, is_active: bool) -> void:
	_apply_tab_style(btn, is_active)

func _update_attributes_display() -> void:

	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]

	# Personaje
	var max_hp = p.stats.max_health
	var armor = int(p._get_equip_stat("armor", false))
	_set_attribute_value(stats_char_vbox.get_node("Health"), str(max_hp))
	_set_attribute_value(stats_char_vbox.get_node("Armor"), str(armor))
	_update_body_synergy_display(p)

	for row in stats_weapon_vbox.get_children():
		row.visible = (row.name not in ["Range", "Knockback"]) if active_weapon_stats_tab == "PRIMARY" else (row.name in ["Damage", "FireRate", "Range", "Knockback"])
	if active_weapon_stats_tab == "PRIMARY":
		_render_primary_weapon_stats(p)
	else:
		_render_secondary_weapon_stats(p)

	stats_preview_badge.visible = (selected_item != null)
	_update_weapon_synergy_description(p)

func _update_body_synergy_display(player: Node2D) -> void:
	if not stats_body_synergy_container:
		return
	var equip: Object = player.get_node_or_null("Equipment")
	var body_syn_id := SynergyManager.get_active_body_synergy(equip)
	if body_syn_id.is_empty():
		stats_body_synergy_container.hide()
		return
	var def: Dictionary = SynergyManager.SYNERGIES.get(body_syn_id, {})
	var title: String = str(def.get("name", "Sinergia Corporal"))
	var desc: String = SynergyManager.get_body_synergy_short_description(body_syn_id)
	if stats_body_synergy_title:
		stats_body_synergy_title.text = title
	if stats_body_synergy_desc:
		stats_body_synergy_desc.text = desc
	stats_body_synergy_container.show()

func _update_weapon_synergy_description(player: Node2D) -> void:
	stats_synergy_description.text = ""
	stats_synergy_description.hide()
	var is_main := active_weapon_stats_tab == "PRIMARY"
	var weapon: Node = player.active_weapon if is_main else player.second_weapon
	if not weapon:
		return
	var synergy_id := SynergyManager.get_active_weapon_display_synergy(
		player.get_node_or_null("Equipment"), _get_codex_weapon_id(weapon), is_main)
	if synergy_id.is_empty():
		return
	var definition: Dictionary = SynergyManager.SYNERGIES.get(synergy_id, {})
	stats_synergy_description.text = str(definition.get("description", ""))
	stats_synergy_description.visible = not stats_synergy_description.text.is_empty()

func _render_primary_weapon_stats(p: Node2D) -> void:
	if stats_weapon_icon and p.active_weapon:
		_set_weapon_icon(stats_weapon_icon, _get_weapon_texture(p.active_weapon, p, true))
	if stats_weapon_name and p.active_weapon:
		stats_weapon_name.text = _get_weapon_display_name_text(p.active_weapon)

	var base_dmg = p._get_weapon_damage() * p._get_weapon_damage_multiplier() if p.active_weapon else 10.0
	var equip_dmg = p._get_equip_stat("damage", true)
	var total_dmg = int((base_dmg + equip_dmg) * (1.0 + p._get_equip_stat("damage_multiplier", true)))

	var aps = p._get_weapon_attack_speed() if p.active_weapon else 1.0
	var total_aps = aps * (1.0 + p._get_equip_stat("attack_speed", true))

	var bullets = (p._get_weapon_bullets() if p.active_weapon else 1) + int(p._get_equip_stat("bullet_count", true))
	var crit_c = (p._get_weapon_crit_chance() if p.active_weapon else 0.0) + p._get_equip_stat("crit_chance", true)
	var crit_d = (p._get_weapon_crit_damage() if p.active_weapon else 2.0) + p._get_equip_stat("crit_damage", true)
	var proj_speed = (p._get_weapon_proj_speed() if p.active_weapon else 600.0) + p._get_equip_stat("projectile_speed", true)
	var piercing = (p._get_weapon_piercing() if p.active_weapon else 0) + int(p._get_equip_stat("piercing", true))

	_set_attribute_value(stats_weapon_vbox.get_node("Damage"), str(total_dmg), _get_preview_delta("damage"))
	_set_attribute_value(stats_weapon_vbox.get_node("FireRate"), "%.1f/s" % total_aps, _get_preview_delta("attack_speed"))
	_set_attribute_value(stats_weapon_vbox.get_node("Projectiles"), str(bullets), _get_preview_delta("bullet_count"))
	_set_attribute_value(stats_weapon_vbox.get_node("CritChance"), "%d%%" % int(crit_c * 100), _get_preview_delta("crit_chance"))
	_set_attribute_value(stats_weapon_vbox.get_node("CritDamage"), "x%.1f" % crit_d, _get_preview_delta("crit_damage"))
	_set_attribute_value(stats_weapon_vbox.get_node("ProjectileSpeed"), "%d" % int(proj_speed), _get_preview_delta("projectile_speed"))
	_set_attribute_value(stats_weapon_vbox.get_node("Piercing"), str(piercing), _get_preview_delta("piercing"))

func _render_secondary_weapon_stats(p: Node2D) -> void:
	if stats_weapon_icon and p.second_weapon:
		_set_weapon_icon(stats_weapon_icon, _get_weapon_texture(p.second_weapon, p, false))
	if stats_weapon_name and p.second_weapon:
		stats_weapon_name.text = _get_weapon_display_name_text(p.second_weapon)

	var base_dmg = float(p.second_weapon.damage) if p.second_weapon and "damage" in p.second_weapon else 15.0
	var equip_dmg = p._get_equip_stat("damage", false)
	var total_dmg = int((base_dmg + equip_dmg) * (1.0 + p._get_equip_stat("damage_multiplier", false)))

	var base_aps = float(p.second_weapon.attack_speed) if p.second_weapon and "attack_speed" in p.second_weapon else 1.0
	var total_aps = base_aps * (1.0 + p._get_equip_stat("attack_speed", false))

	var base_range = float(p.second_weapon.attack_range) if p.second_weapon and "attack_range" in p.second_weapon else 1.0
	var flat_range = p._get_equip_stat("attack_range", false)
	var pct_range = p._get_equip_stat("attack_range_percent", false)
	var total_range = (base_range + flat_range) * (1.0 + pct_range)

	var base_kb = float(p.second_weapon.knockback_force) if p.second_weapon and "knockback_force" in p.second_weapon else 150.0
	var total_kb = base_kb + p._get_equip_stat("knockback_force", false)

	_set_attribute_value(stats_weapon_vbox.get_node("Damage"), str(total_dmg), _get_preview_delta("damage"))
	_set_attribute_value(stats_weapon_vbox.get_node("FireRate"), "%.1f/s" % total_aps, _get_preview_delta("attack_speed"))
	_set_attribute_value(stats_weapon_vbox.get_node("Range"), "x%.2f" % total_range, _get_preview_delta("attack_range"))
	_set_attribute_value(stats_weapon_vbox.get_node("Knockback"), "%d" % int(total_kb), _get_preview_delta("knockback_force"))

func _set_attribute_value(row: HBoxContainer, value_text: String, delta_text: String = "") -> void:
	row.get_node("Value").text = value_text
	var delta_label: Label = row.get_node("Delta")
	delta_label.text = delta_text
	delta_label.visible = not delta_text.is_empty()
	delta_label.modulate = Color("#52D8C6") if delta_text.begins_with("+") else Color("#EDB35B")

func _get_preview_delta(stat_name: String) -> String:
	if selected_item == null: return ""
	if not selected_item.stats.has(stat_name): return ""
	var val = selected_item.stats[stat_name]
	if stat_name in ["crit_chance", "attack_speed"]:
		return "%+d%%" % round(val * 100)
	if val == int(val):
		return "%+d" % int(val)
	return "%+.1f" % val

# ── Pestañas y Filtros ─────────────────────────────────────────────────────────

func _on_inventory_tab_pressed() -> void:
	current_tab = "INVENTORY"
	_set_inventory_hints(true)
	research_browser.hide()
	_apply_tab_style(tab_research_btn, false)
	main_three_columns.visible = true
	codex_view.visible = false
	_apply_tab_style(tab_inventory_btn, true)
	_apply_tab_style(tab_codex_btn, false)
	_hide_tooltip()
	update_ui()

func _on_codex_tab_pressed() -> void:
	current_tab = "CODEX"
	_set_inventory_hints(false)
	research_browser.hide()
	_apply_tab_style(tab_research_btn, false)
	main_three_columns.visible = false
	codex_view.visible = true
	_apply_tab_style(tab_inventory_btn, false)
	_apply_tab_style(tab_codex_btn, true)
	_hide_tooltip()
	_refresh_codex_grid()

func _on_filter_pressed(filter_type: String) -> void:
	current_filter = filter_type
	update_items_list()

func _on_sort_option_selected(index: int) -> void:
	match index:
		0: sort_mode = "DEFAULT"
		1: sort_mode = "TYPE"
		2: sort_mode = "NAME"
	update_items_list()

# ── Lógica de Códice ──────────────────────────────────────────────────────────

func _on_codex_category_pressed(cat: String) -> void:
	selected_codex_category = cat
	_hide_tooltip()
	_refresh_codex_grid()
	_focus_first_slot.call_deferred()

# Cada categoría del códice tiene su propia página (ver Scripts/UI/Codex/) y
# las sinergias usan fichas grandes (CodexSynergyCard).
func _refresh_codex_grid() -> void:
	if not codex_grid: return
	for key in codex_category_buttons:
		_apply_tab_style(codex_category_buttons[key], key == selected_codex_category)
	for c in codex_grid.get_children():
		codex_grid.remove_child(c)
		c.queue_free()
	_codex_scroll().scroll_vertical = 0
	if selected_codex_category == "synergies":
		_fill_codex_synergies()
		return
	codex_grid.columns = 1
	var cat_data = CodexData.DATA.get(selected_codex_category, {})
	var unlocked_count = 0
	for entry_id in cat_data.keys():
		if GameData.is_codex_unlocked(selected_codex_category, entry_id): unlocked_count += 1
	var page = _codex_page(selected_codex_category)
	if page:
		codex_grid.add_child(page)
	codex_progress_label.text = "%d / %d registrados" % [unlocked_count, cat_data.size()]

func _codex_page(category: String) -> Control:
	match category:
		"enemies": return CodexBestiary.new()
		"weapons": return CodexArmory.new()
		"items": return CodexItems.new()
		"npcs": return CodexNpcs.new()
		"levels": return CodexZones.new()
	return null

func _fill_codex_synergies() -> void:
	codex_grid.columns = 3
	var ids = OmniaCatalog.synergy_ids()
	var discovered = 0
	for syn_id in ids:
		if GameData.is_synergy_discovered(syn_id):
			discovered += 1
		codex_grid.add_child(CodexSynergyCard.create(syn_id))
	codex_progress_label.text = "%d / %d sinergias descubiertas" % [discovered, ids.size()]

func _codex_scroll() -> ScrollContainer:
	return codex_grid.get_parent().get_parent() as ScrollContainer

# Joystick: el foco va a la primera ficha que se pueda elegir de la página.
func _focus_codex() -> void:
	for c in codex_grid.find_children("*", "Control", true, false):
		if c.focus_mode == Control.FOCUS_ALL and c.is_visible_in_tree():
			c.grab_focus()
			return

func _on_research_tab_pressed() -> void:
	current_tab = "RESEARCH"
	_set_inventory_hints(false)
	main_three_columns.hide()
	codex_view.hide()
	research_browser.show()
	_apply_tab_style(tab_inventory_btn, false)
	_apply_tab_style(tab_codex_btn, false)
	_apply_tab_style(tab_research_btn, true)
	_hide_tooltip()
	research_browser.configure("synergies", true)

# ── Tooltip Flotante ──────────────────────────────────────────────────────────

func _on_slot_hovered(item_data: ItemData, slot_rect: Rect2) -> void:
	if not tooltip_panel: return
	_show_slot_tooltip(item_data, slot_rect)

func _show_slot_tooltip(item_data: ItemData, slot_rect: Rect2) -> void:
	var codex_cat = CodexData.get_category_for_id(item_data.id)
	if codex_cat != "":
		var entry = CodexData.DATA[codex_cat].get(item_data.id, {})
		var is_unlocked = GameData.is_codex_unlocked(codex_cat, item_data.id)
		tooltip_name.text = entry.get("name", "???") if is_unlocked else "???"
		tooltip_rarity.text = "DESBLOQUEADO" if is_unlocked else "BLOQUEADO"
		tooltip_type.text = codex_cat.to_upper()
		tooltip_desc.text = entry.get("lore", "") if is_unlocked else "Información clasificada."
		tooltip_stats.text = entry.get("stats", "") if is_unlocked else ""
		tooltip_action.text = ""
	else:
		tooltip_name.text = item_data.item_name
		tooltip_rarity.text = "RARO"
		tooltip_type.text = _get_item_type_string(item_data)
		tooltip_desc.text = _get_item_description(item_data)
		tooltip_stats.text = _format_item_comparison_stats(item_data)
		tooltip_action.text = "A: elegir dónde equiparlo • X: equipar o quitar" if InputMode.is_gamepad() else "Clic para seleccionar • Arrastrar para equipar"

	var tooltip_pos = Vector2(slot_rect.end.x + 12, slot_rect.position.y)
	if tooltip_pos.x + tooltip_panel.size.x > get_viewport_rect().size.x:
		tooltip_pos.x = slot_rect.position.x - tooltip_panel.size.x - 12
	tooltip_panel.global_position = tooltip_pos
	tooltip_panel.show()

func _on_slot_unhovered() -> void:
	_hide_tooltip()

func _hide_tooltip() -> void:
	if tooltip_panel:
		tooltip_panel.hide()

func _on_weapon_badge_hovered(is_main: bool) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var panel = primary_weapon_slot_panel if is_main else secondary_weapon_slot_panel
	if not panel: return
	tooltip_name.text = "ARMA " + ("PRINCIPAL" if is_main else "SECUNDARIA")
	tooltip_rarity.text = "EQUIPADA"
	tooltip_type.text = "ARMAMENTO ACTIVO"
	tooltip_desc.text = "Arma actualmente en tus manos. Los módulos contiguos aumentan sus características."
	tooltip_stats.text = ""
	tooltip_action.text = ""
	var rect = panel.get_global_rect()
	var pos = Vector2(rect.end.x + 12, rect.position.y)
	tooltip_panel.global_position = pos
	tooltip_panel.show()

func _on_weapon_badge_unhovered() -> void:
	_hide_tooltip()

func _set_inventory_hints(enabled: bool) -> void:
	%BottomBar.get_node("MarginContainer/HBoxContainer/HBoxContainer2").visible = enabled
	%BottomBar.get_node("MarginContainer/HBoxContainer/HBoxContainer3").visible = enabled
