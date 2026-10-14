extends CanvasLayer
## Layout, animation tracks and audio are authored in synergy_activation.tscn.
signal dismissed

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
		_can_dismiss = true
		%ContinueButton.disabled = false
		%ContinueButton.grab_focus()
		animation_player.play("idle")
	elif animation_name == &"dismiss":
		_restore_pause()
		dismissed.emit()
		queue_free()

func _on_continue_pressed() -> void:
	if not _can_dismiss or _closing: return
	_closing = true
	%ContinueButton.disabled = true
	animation_player.play("dismiss")

func _restore_pause() -> void:
	if _pause_restored: return
	_pause_restored = true
	get_tree().paused = _was_paused

func _exit_tree() -> void:
	_restore_pause()
