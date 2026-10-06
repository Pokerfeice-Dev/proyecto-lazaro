extends RefCounted
class_name BossBarHelper

## Crea la barra grande de vida de boss (boss_health_bar.tscn), con el mismo
## patrón que usan boss1 y boss2. Devuelve { "instance": Node, "bar": Range }.

const BAR_SCENE_PATH := "res://Scenes/UI/boss_health_bar.tscn"

static func create(tree: SceneTree, display_name: String, max_value: int, value: int) -> Dictionary:
	if not ResourceLoader.exists(BAR_SCENE_PATH):
		printerr("BossBarHelper: no se encontró boss_health_bar.tscn")
		return {}
	var inst = (load(BAR_SCENE_PATH) as PackedScene).instantiate()
	if inst is CanvasLayer:
		inst.layer = 100
	tree.current_scene.add_child(inst)
	var bar = _find_of_class(inst, "Range") as Range
	if bar:
		bar.max_value = max_value
		bar.value = value
	var label = _find_of_class(inst, "Label") as Label
	if label:
		label.text = display_name
	_play_intro(_find_of_class(inst, "AnimationPlayer") as AnimationPlayer)
	return {"instance": inst, "bar": bar}

static func _play_intro(anim: AnimationPlayer) -> void:
	if not anim: return
	for anim_name in ["Start_Fight", "start_fight"]:
		if anim.has_animation(anim_name):
			anim.play(anim_name)
			return
	if anim.get_animation_list().size() > 0:
		anim.play(anim.get_animation_list()[0])

static func _find_of_class(node: Node, cls: String) -> Node:
	if node.is_class(cls):
		return node
	for child in node.get_children():
		var found = _find_of_class(child, cls)
		if found:
			return found
	return null
