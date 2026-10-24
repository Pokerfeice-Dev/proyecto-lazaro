extends Node

class IsolatedGameData extends "res://Scripts/System/game_data.gd":
	func _ready() -> void:
		pass

	func save_game(_slot: int = -1) -> void:
		pass

	func unlock_codex_entry(_category: String, _entry_id: String, _show_toast: bool = true) -> void:
		pass

func _ready() -> void:
	assert(not GameData.is_event_build(), "El proyecto principal debe iniciar sin modo evento")
	assert(not EventOutro.should_show(), "El juego normal no debe mostrar QR")
	var data = IsolatedGameData.new()
	add_child(data)
	data.current_level = 1
	data.rooms_pool_level2.assign(["res://Scenes/Rooms/Level2_Room1.tscn"])
	data.finish_first_boss_demo()
	assert(not data.demo_completed_pending, "El primer jefe no debe terminar la run normal")
	assert(data.get_post_boss_scene() == "res://Scenes/Rooms/Level2_Room1.tscn")
	assert(data.current_level == 2)
	assert(not data.just_won_run)
	var death_screen = RunEndScreen.new()
	assert(death_screen.next_scene == "res://Scenes/Rooms/lab_room.tscn")
	death_screen.free()
	data.free()
	print("NORMAL_RUN_MODE_OK: sin QR, muerte al laboratorio, primer jefe al nivel 2")
	get_tree().quit()
