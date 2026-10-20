extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_verify")

func _verify() -> void:
	reparent(get_tree().root)
	GameData.begin_sandbox()
	GameData.finish_first_boss_demo()
	await get_tree().create_timer(3.0).timeout
	assert(get_tree().current_scene.scene_file_path == RunEndScreen.LAB_SCENE)
	assert(not GameData.demo_completed_pending)
	assert(get_tree().paused)
	var screen: RunEndScreen
	for child in get_tree().root.get_children():
		if child is RunEndScreen:
			screen = child
	assert(is_instance_valid(screen))
	assert(screen.demo_completed)
	assert(screen._button.text == "SEGUIR")
	screen._button.pressed.emit()
	assert(not get_tree().paused)
	await get_tree().process_frame
	assert(not is_instance_valid(screen))
	screen = RunEndScreen.show_demo_completed(get_tree())
	var buttons = screen.find_children("*", "Button", true, false).filter(func(button): return button.focus_mode != Control.FOCUS_NONE)
	assert(buttons.size() == 2)
	assert(buttons[0].text == "VOLVER AL MENÚ")
	buttons[0].pressed.emit()
	assert(not get_tree().paused)
	await get_tree().create_timer(1.5).timeout
	assert(get_tree().current_scene.scene_file_path == "res://Scenes/UI/MainMenu.tscn")
	GameData.end_sandbox()
	print("DEMO_COMPLETION_OK")
	get_tree().quit()
