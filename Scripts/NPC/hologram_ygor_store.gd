extends Node2D

@export_enum("None", "Heal", "BodyItem", "WeaponItem") var shop_item_type: String = "None"

const WEAPON_ITEM_PATHS: Array[String] = [
	"res://Art/Items/Weapons/Item1.tres",
	"res://Art/Items/Weapons/Item2.tres",
	"res://Art/Items/Weapons/Item3.tres",
	"res://Art/Items/Weapons/Item4.tres",
	"res://Art/Items/Weapons/Item5.tres",
	"res://Art/Items/Weapons/Item6.tres",
	"res://Art/Items/Weapons/Item7_Colmena.tres",
	"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
	"res://Art/Items/Weapons/Item9_SierraCircular.tres"
]

const BODY_ITEM_PATHS: Array[String] = [
	"res://Art/Items/Player/Body/Item2_TorsoBlindado.tres",
	"res://Art/Items/Player/Body/Item3_TorsoEspinado.tres",
	"res://Art/Items/Player/Body/Item4_TorsoLigero.tres",
	"res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres",
	"res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres",
	"res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres",
	"res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres",
	"res://Art/Items/Player/Arms/Item3_BrazoLigero.tres",
	"res://Art/Items/Player/Arms/Item4_BrazoArmado.tres"
]

@onready var item_sprite: Sprite2D = $Item_sprite
@onready var interact_area: Area2D = $InteractArea
@onready var label: Label = $Label

var cost: int = 20
var chosen_item_data: ItemData = null
var player_in_range: bool = false
var player_ref: Node2D = null
var time_passed: float = 0.0
var purchased: bool = false

func _ready() -> void:
	_init_default_type_from_name()
	_configure_stats_and_visuals()
	_update_label()
	_connect_signals()

func _connect_signals() -> void:
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_apply_levitation(delta)

func _init_default_type_from_name() -> void:
	if shop_item_type != "None":
		return
	_assign_type_by_name()

func _assign_type_by_name() -> void:
	if name == "Hologram_Ygor_Store":
		shop_item_type = "Heal"
	elif name == "Hologram_Ygor_Store2":
		shop_item_type = "BodyItem"
	elif name == "Hologram_Ygor_Store3":
		shop_item_type = "WeaponItem"
	elif name == "Hologram_Ygor_Store4":
		_disable_and_hide_hologram()

func _disable_and_hide_hologram() -> void:
	shop_item_type = "None"
	visible = false
	if interact_area:
		interact_area.set_deferred("monitoring", false)
		interact_area.set_deferred("monitorable", false)

func _configure_stats_and_visuals() -> void:
	match shop_item_type:
		"Heal":
			cost = 20
			_setup_heal_visuals()
		"BodyItem":
			cost = 30
			_setup_random_item(BODY_ITEM_PATHS)
		"WeaponItem":
			cost = 40
			_setup_random_item(WEAPON_ITEM_PATHS)

func _setup_heal_visuals() -> void:
	if not item_sprite:
		return
	var heart_path = "res://Art/Items/Player/Heart/Heart.png"
	if _is_asset_imported(heart_path):
		var tex = load(heart_path)
		if tex:
			item_sprite.texture = tex
			item_sprite.modulate = Color.WHITE
			return
	item_sprite.texture = preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
	item_sprite.modulate = Color(1.0, 0.2, 0.2)

func _setup_random_item(paths: Array[String]) -> void:
	if chosen_item_data:
		return
	var path = paths.pick_random()
	chosen_item_data = load(path) as ItemData
	_apply_item_data_visuals()

func _apply_item_data_visuals() -> void:
	if not chosen_item_data or not item_sprite:
		return
	var tex = chosen_item_data.icon
	if tex:
		item_sprite.texture = tex
		item_sprite.modulate = Color.WHITE
		return
	item_sprite.texture = preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
	item_sprite.modulate = Color(1.0, 0.9, 0.2)

func _apply_levitation(delta: float) -> void:
	if purchased or shop_item_type == "None" or not item_sprite:
		return
	time_passed += delta
	var y_offset = sin(time_passed * 3.0) * 4.0
	item_sprite.position.y = -26.0 + y_offset

func _update_label() -> void:
	if purchased or shop_item_type == "None" or not label:
		return
	var text_val = _get_label_text()
	label.text = text_val

func _get_label_text() -> String:
	var item_name = _get_item_display_name()
	if player_in_range:
		return "%s\n[E] Comprar (%d carne)" % [item_name, cost]
	return "%s\n%d carne" % [item_name, cost]

func _get_item_display_name() -> String:
	match shop_item_type:
		"Heal":
			return "Vida (+25% faltante)"
		_:
			return _get_custom_item_name()

func _get_custom_item_name() -> String:
	if chosen_item_data:
		return chosen_item_data.item_name
	return "Objeto"

func _on_body_entered(body: Node2D) -> void:
	if purchased or not body.is_in_group("player"):
		return
	player_in_range = true
	player_ref = body
	_update_label()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_range = false
	player_ref = null
	_update_label()

func _input(event: InputEvent) -> void:
	_check_purchase_input(event)

func _check_purchase_input(event: InputEvent) -> void:
	if purchased or not player_in_range:
		return
	if not _is_key_e_pressed(event):
		return
	_attempt_purchase()

func _is_key_e_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo

func _attempt_purchase() -> void:
	if not _has_enough_flesh():
		_flash_error_visuals()
		return
	_complete_purchase()

func _has_enough_flesh() -> bool:
	return GameData.flesh >= cost

func _complete_purchase() -> void:
	purchased = true
	GameData.spend_flesh(cost)
	_apply_item_effect()
	_play_purchase_effects()
	_disable_shop_pedestal()
	$Interact.play()

func _disable_shop_pedestal() -> void:
	if item_sprite:
		item_sprite.visible = false
	if label:
		label.visible = false
	if interact_area:
		interact_area.set_deferred("monitoring", false)
		interact_area.set_deferred("monitorable", false)

func _apply_item_effect() -> void:
	if not player_ref:
		return
	match shop_item_type:
		"Heal":
			_apply_heal_effect()
		_:
			_give_purchased_item()

func _apply_heal_effect() -> void:
	if not player_ref.get("stats"):
		return
	var stats = player_ref.stats
	var missing_health = stats.max_health - stats.current_health
	var heal_amt = int(missing_health * 0.25)
	if missing_health > 0 and heal_amt <= 0:
		heal_amt = 1
	stats.heal(heal_amt)

func _give_purchased_item() -> void:
	if not chosen_item_data:
		return
	var inv = player_ref.get_node_or_null("Inventory")
	if not inv:
		return
	inv.add_item(chosen_item_data)

func _play_purchase_effects() -> void:
	var sound = get_tree().get_first_node_in_group("teleport_sfx")
	if sound:
		sound.play()

func _flash_error_visuals() -> void:
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color.RED, 0.1)
	tween.tween_property(label, "modulate", Color.WHITE, 0.3)

func _is_asset_imported(path: String) -> bool:
	var import_path = path + ".import"
	if not FileAccess.file_exists(import_path):
		return false
	
	var file = FileAccess.open(import_path, FileAccess.READ)
	if not file:
		return false
		
	var content = file.get_as_text()
	file.close()
	
	return _check_lines_for_ctex(content)

func _check_lines_for_ctex(content: String) -> bool:
	var lines = content.split("\n")
	for line in lines:
		if line.begins_with("path="):
			return _verify_ctex_path(line)
	return false

func _verify_ctex_path(line: String) -> bool:
	var raw_path = line.split("=")[1].strip_edges().replace("\"", "")
	return FileAccess.file_exists(raw_path)
