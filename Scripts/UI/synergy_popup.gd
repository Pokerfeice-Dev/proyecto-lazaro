extends CanvasLayer
## Layout, animation tracks and audio are authored in synergy_activation.tscn.
signal dismissed

## Al terminar "activate", las tres piezas se juntan en el centro y aparece una
## ficha del mismo estilo con el sprite de la sinergia, que se revela como en
## O.M.N.I.A. (silueta que se aclara + salto con destello).
const LOCKED_SHADER := preload("res://Art/Ui/shaders/silueta_bloqueada.gdshader")
const RESULT_SIZE := Vector2(176, 168)
const MERGE_TIME := 0.3
const REVEAL_TIME := 0.7

var synergy_id: String = ""
var first_discovery: bool = false
var _was_paused: bool = false
var _pause_restored: bool = false
var _closing: bool = false
var _can_dismiss: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func setup(id: String, is_first_discovery: bool = false) -> void:
	synergy_id = id
	first_discovery = is_first_discovery

func _ready() -> void:
	_was_paused = get_tree().paused
	get_tree().paused = true
	var definition: Dictionary = SynergyManager.SYNERGIES.get(synergy_id, {})
	if not definition.is_empty():
		%SynergyName.text = str(definition.get("name", synergy_id)).to_upper()
		%Description.text = str(definition.get("description", ""))
		%DiscoveryLabel.text = "NUEVA SINERGIA DESCUBIERTA" if first_discovery else "SINERGIA REACTIVADA"
		var ingredients: Array = definition.get("required_items", [])
		for index in range(3):
			var card = get_node("Root/Center/Panel/Assembly/Ingredient%d" % (index + 1))
			card.visible = index < ingredients.size()
			if not card.visible: continue
			var entry: Dictionary = CodexData.DATA["items"].get(ingredients[index], {})
			card.get_node("Icon").texture = entry.get("icon")
			card.get_node("Caption").text = str(entry.get("name", ingredients[index]))
	animation_player.play("activate")

func _input(event: InputEvent) -> void:
	# Stop keyboard input reaching the paused inventory below the presentation.
	if event is InputEventKey or event is InputEventMouseButton:
		# Mouse events must still reach ContinueButton through GUI dispatch.
		if event is InputEventKey: get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"activate":
		animation_player.play("idle")
		await _play_fusion()
		_can_dismiss = true
		%ContinueButton.disabled = false
		%ContinueButton.grab_focus()
	elif animation_name == &"dismiss":
		_restore_pause()
		dismissed.emit()
		queue_free()

func _on_continue_pressed() -> void:
	if not _can_dismiss or _closing: return
	_closing = true
	%ContinueButton.disabled = true
	animation_player.play("dismiss")

# --- Fusión: las piezas se vuelven la sinergia ---

func _play_fusion() -> void:
	var assembly: Control = $Root/Center/Panel/Assembly
	var center: Vector2 = $Root/Center/Panel/Assembly/Ingredient2.position
	var cards: Array[Control] = []
	for i in range(3):
		var card: Control = assembly.get_node("Ingredient%d" % (i + 1))
		if card.visible: cards.append(card)
	if cards.is_empty(): return
	var t = create_tween().set_parallel(true)
	for card in cards:
		t.tween_property(card, "position", center, MERGE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		t.tween_property(card, "scale", Vector2(0.55, 0.55), MERGE_TIME)
		t.tween_property(card, "modulate:a", 0.0, MERGE_TIME * 0.6).set_delay(MERGE_TIME * 0.4)
	await t.finished
	_burst(assembly)
	var result = _build_result_card(cards[0])
	assembly.add_child(result)
	await _reveal(result)

# Ficha nueva con el mismo panel y la misma letra que las piezas.
func _build_result_card(style_source: Control) -> Control:
	var card = Panel.new()
	card.name = "SynergyResult"
	card.add_theme_stylebox_override("panel", style_source.get_theme_stylebox("panel"))
	card.size = RESULT_SIZE
	card.position = -RESULT_SIZE / 2.0
	card.pivot_offset = RESULT_SIZE / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = UIStyle.trimmed(OmniaCatalog.synergy_icon(synergy_id))
	icon.self_modulate = OmniaCatalog.synergy_tint(synergy_id)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(18, 14)
	icon.size = Vector2(RESULT_SIZE.x - 36, 104)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	var caption: Label = style_source.get_node("Caption").duplicate()
	caption.text = str(SynergyManager.SYNERGIES.get(synergy_id, {}).get("name", synergy_id))
	caption.position = Vector2(8, 124)
	caption.size = Vector2(RESULT_SIZE.x - 16, 36)
	caption.add_theme_color_override("font_color", Color(0.96, 0.77, 0.37, 1))
	card.add_child(caption)
	return card

# Igual que al comprar en O.M.N.I.A.: salta con destello y la silueta se aclara.
func _reveal(card: Control) -> void:
	var icon: TextureRect = card.get_node("Icon")
	var mat = ShaderMaterial.new()
	mat.shader = LOCKED_SHADER
	icon.material = mat
	card.scale = Vector2(1.12, 1.12)
	card.modulate = Color(1.8, 1.8, 1.8)
	var pop = create_tween().set_parallel(true)
	pop.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(card, "modulate", Color.WHITE, 0.45)
	var reveal = create_tween()
	reveal.tween_method(func(v: float): mat.set_shader_parameter("reveal", v), 0.0, 1.0, REVEAL_TIME).set_trans(Tween.TRANS_SINE)
	await reveal.finished
	icon.material = null

# Onda y chispas al juntarse las piezas (reusa los nodos de la escena).
func _burst(assembly: Node) -> void:
	var pulse: Node2D = assembly.get_node_or_null("Pulse")
	if pulse:
		pulse.scale = Vector2(0.25, 0.25)
		pulse.modulate = Color(1, 1, 1, 0.9)
		var t = create_tween().set_parallel(true)
		t.tween_property(pulse, "scale", Vector2(1.6, 1.6), 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(pulse, "modulate:a", 0.0, 0.6)
	var sparks: CPUParticles2D = assembly.get_node_or_null("Sparks")
	if sparks:
		sparks.restart()
		sparks.emitting = true
	var sound: AudioStreamPlayer = get_node_or_null("ActivationSound")
	if sound:
		sound.play()

func _restore_pause() -> void:
	if _pause_restored: return
	_pause_restored = true
	get_tree().paused = _was_paused

func _exit_tree() -> void:
	_restore_pause()
