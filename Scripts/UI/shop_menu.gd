extends CanvasLayer
## ShopMenu – Menú de mejoras de Ygor.
## Se abre/cierra desde el NPC Ygor. Lee y escribe en GameData.

signal menu_closed

@onready var root_panel: Panel        = $BgDim/Panel
@onready var scrap_label: Label       = $BgDim/Panel/VBox/Header/ScrapLabel
@onready var items_container: VBoxContainer = $BgDim/Panel/VBox/Scroll/Items
@onready var close_btn: Button        = $BgDim/Panel/VBox/Header/CloseBtn
@onready var bg_dim: ColorRect        = $BgDim

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100 # Ensure it's above other UI
	visible = false
	close_btn.pressed.connect(close_menu)

func open_menu() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_ui()

func close_menu() -> void:
	get_tree().paused = false
	visible = false
	menu_closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo:
		close_menu()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed and not event.echo:
		close_menu()
		get_viewport().set_input_as_handled()

# ── UI construction ───────────────────────────────────────────────────────────
func _refresh_ui() -> void:
	_update_scrap_label()
	_rebuild_items()

func _update_scrap_label() -> void:
	scrap_label.text = "🔩 Scrap: %d" % GameData.scrap

func _rebuild_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	for def in GameData.UPGRADE_DEFS:
		items_container.add_child(_build_row(def))

func _build_row(def: Dictionary) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = def["label"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	info.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = def["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.add_child(desc_lbl)

	var val_lbl = Label.new()
	val_lbl.name = "ValLabel_" + def["key"]
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	_update_value_label(val_lbl, def["key"])
	info.add_child(val_lbl)

	row.add_child(info)

	var cost_lbl = Label.new()
	cost_lbl.text = "🔩 %d" % def["cost"]
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(cost_lbl)

	var buy_btn = Button.new()
	buy_btn.text = "COMPRAR"
	buy_btn.custom_minimum_size = Vector2(120, 44)
	buy_btn.pressed.connect(_on_buy_pressed.bind(def, row))
	_style_buy_button(buy_btn)
	row.add_child(buy_btn)

	var separator = HSeparator.new()
	var wrapper = VBoxContainer.new()
	wrapper.add_child(row)
	wrapper.add_child(separator)
	return wrapper

func _style_buy_button(btn: Button) -> void:
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.55, 0.35)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.2, 0.75, 0.48)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.1, 0.4, 0.25)
	btn.add_theme_stylebox_override("pressed", pressed_style)

func _update_value_label(lbl: Label, key: String) -> void:
	var val = GameData.get_upgrade_level(key)
	match key:
		"fire_rate":
			lbl.text = "Actual: %.2f s (%.1f disp/s)" % [val, 1.0 / val]
		"crit_chance":
			lbl.text = "Actual: %.0f%%" % (val * 100.0)
		"spread":
			lbl.text = "Actual: %.0f°" % val
		"damage_multiplier":
			lbl.text = "Actual: x%.2f" % val
		_:
			lbl.text = "Actual: %s" % str(val)

func _on_buy_pressed(def: Dictionary, row: Control) -> void:
	var purchased = GameData.spend_scrap(def["cost"])
	if not purchased:
		_flash_no_scrap(row)
		return
	GameData.apply_upgrade(def["key"], def["step"])
	_apply_upgrades_to_player()
	_refresh_ui()

func _flash_no_scrap(row: Control) -> void:
	var tween = create_tween()
	tween.tween_property(row, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(row, "modulate", Color.WHITE, 0.3)

func _apply_upgrades_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	GameData.apply_to_player_stats(player.stats)
	GameData.apply_to_weapon(player.active_weapon)
	GameData.apply_to_melee(player.second_weapon)
