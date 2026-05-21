extends CanvasLayer
## ShopMenu – Menú de mejoras de Ygor.
## Se abre/cierra desde el NPC Ygor. Lee y escribe en GameData.

signal menu_closed

@onready var root_panel: PanelContainer = $BgDim/Panel
@onready var scrap_label: Label       = $BgDim/Panel/MarginContainer/VBox/Header/ScrapLabel
@onready var items_container: VBoxContainer = $BgDim/Panel/MarginContainer/VBox/Scroll/Items
@onready var close_btn: Button        = $BgDim/Panel/MarginContainer/VBox/Header/CloseBtn
@onready var bg_dim: ColorRect        = $BgDim

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100 # Ensure it's above other UI
	visible = false
	close_btn.pressed.connect(close_menu)
	_setup_close_button()

func _setup_close_button() -> void:
	if not close_btn:
		return
	close_btn.text = ""
	
	var texture_normal = preload("res://Art/Ui/Button_X/Icon Button Close.png")
	var texture_hover = preload("res://Art/Ui/Button_X/Icon Button Close Hover.png")
	
	var style_normal = StyleBoxTexture.new()
	style_normal.texture = texture_normal
	
	var style_hover = StyleBoxTexture.new()
	style_hover.texture = texture_hover
	
	var style_pressed = StyleBoxTexture.new()
	style_pressed.texture = texture_hover
	
	close_btn.add_theme_stylebox_override("normal", style_normal)
	close_btn.add_theme_stylebox_override("hover", style_hover)
	close_btn.add_theme_stylebox_override("pressed", style_pressed)
	close_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


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
	scrap_label.text = str(GameData.scrap)

const WEAPON_ITEM_PATHS: Array[String] = [
	"res://Art/Items/Weapons/Item1.tres",
	"res://Art/Items/Weapons/Item2.tres",
	"res://Art/Items/Weapons/Item3.tres",
	"res://Art/Items/Weapons/Item4.tres",
	"res://Art/Items/Weapons/Item5.tres",
	"res://Art/Items/Weapons/Item6.tres"
]

const BODY_ITEM_PATHS: Array[String] = [
	"res://Art/Items/Player/Arms/Item1_Arms.tres",
	"res://Art/Items/Player/Body/Item1_Chest.tres",
	"res://Art/Items/Player/Legs/Item1_Boots.tres"
]

const SHOP_ITEMS: Array[Dictionary] = [
	{
		"key": "heal",
		"label": "❤️ Recuperar Vida (25%)",
		"desc": "Restaura de inmediato un 25% de tu salud máxima.",
		"cost": 30
	},
	{
		"key": "weapon_item",
		"label": "🔫 Componente de Arma",
		"desc": "Consigue un objeto de arma aleatorio.",
		"cost": 75
	},
	{
		"key": "body_item",
		"label": "🛡️ Componente Corporal",
		"desc": "Consigue un objeto de pecho, brazos o botas aleatorio.",
		"cost": 100
	}
]

func _rebuild_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	for def in SHOP_ITEMS:
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

	var cost_container = _create_cost_container(def["cost"])
	row.add_child(cost_container)

	var buy_btn = Button.new()
	buy_btn.text = "COMPRAR"
	buy_btn.custom_minimum_size = Vector2(120, 44)
	buy_btn.pressed.connect(_on_buy_pressed.bind(def, row))
	row.add_child(buy_btn)

	var separator = HSeparator.new()
	var wrapper = VBoxContainer.new()
	wrapper.add_child(row)
	wrapper.add_child(separator)
	return wrapper


func _update_value_label(lbl: Label, key: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.get("stats"):
		lbl.text = ""
		return
	match key:
		"heal":
			lbl.text = "Vida actual: %d/%d" % [player.stats.current_health, player.stats.max_health]
		_:
			lbl.text = "Se añadirá al inventario"

func _on_buy_pressed(def: Dictionary, row: Control) -> void:
	var purchased = GameData.spend_scrap(def["cost"])
	if not purchased:
		_flash_no_scrap(row)
		return
	_handle_purchase(def["key"])
	_refresh_ui()

func _handle_purchase(key: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	match key:
		"heal":
			_apply_heal(player)
		"weapon_item":
			_give_random_item(player, WEAPON_ITEM_PATHS)
		"body_item":
			_give_random_item(player, BODY_ITEM_PATHS)

func _apply_heal(player: Node2D) -> void:
	if not player.get("stats"):
		return
	var heal_amt = int(player.stats.max_health * 0.25)
	player.stats.heal(heal_amt)

func _give_random_item(player: Node2D, paths: Array[String]) -> void:
	var path = paths.pick_random()
	var item_data = load(path) as ItemData
	var inv = player.get_node_or_null("Inventory")
	if not inv:
		return
	inv.add_item(item_data)

func _flash_no_scrap(row: Control) -> void:
	var tween = create_tween()
	tween.tween_property(row, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(row, "modulate", Color.WHITE, 0.3)

func _create_cost_container(cost: int) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 6)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://Art/Scrap/Scrap_icon.png")
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.add_child(icon)
	
	var label = Label.new()
	label.text = str(cost)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	return container
