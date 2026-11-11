extends Node2D
func _ready() -> void:
	call_deferred('_verify')
func _verify() -> void:
	GameData.begin_sandbox()
	var ygor = load('res://Scenes/Ygor/ygor.tscn').instantiate()
	add_child(ygor)
	ygor.interact_label.show()
	for i in 4: await get_tree().process_frame
	var prompt = ygor.interact_label.get_node('InteractPrompt')
	assert(absf(prompt.global_position.x - ygor.anim_sprite.global_position.x) < 0.1)
	assert(prompt.global_position.y < ygor.anim_sprite.global_position.y - 30)
	ygor.interact_label.text = '[E] Hablar con Ygor y consultar sus productos'
	for i in 4: await get_tree().process_frame
	assert(absf(prompt.global_position.x - ygor.anim_sprite.global_position.x) < 0.1)
	print('YGOR_PROMPT_ANCHOR_OK')
	GameData.end_sandbox()
	get_tree().quit()
