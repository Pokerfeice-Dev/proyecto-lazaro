extends Node2D

class Room extends Node2D:
	var room_cleared := false
	var room_started := true

class ExitDoorStub extends Node2D:
	var is_locked := false

func _ready() -> void:
	var room := Room.new()
	add_child(room)
	room.add_to_group("combat_room")
	var door := ExitDoorStub.new()
	room.add_child(door)
	door.add_to_group("door")
	door.position = Vector2(800, 400)
	var compass := EnemyCompass.new()
	add_child(compass)
	compass.set_process(false)
	compass._update_compass(10.0)
	assert(compass._cleared_seconds == 0.0 and compass.exit_arrow.attention == 0.0)
	room.room_cleared = true
	compass._update_compass(3.99)
	assert(compass.exit_arrow.scale == Vector2.ONE)
	compass._update_compass(0.02)
	assert(compass.exit_arrow.attention > 0.0)
	compass._update_compass(0.5)
	assert(compass.exit_arrow.scale.x >= 1.65 and compass.exit_arrow.scale.x <= 2.0)
	assert(compass.exit_arrow.visible)
	var size_before := compass.exit_arrow.scale.x
	compass._update_compass(0.2)
	assert(not is_equal_approx(size_before, compass.exit_arrow.scale.x), "La flecha debe pulsar")
	get_tree().paused = true
	var timer_before := compass._cleared_seconds
	compass._update_compass(10.0)
	assert(compass._cleared_seconds == timer_before)
	get_tree().paused = false
	# El HUD puede sobrevivir al cambio de sala: el ID reinicia el énfasis.
	room.remove_from_group("combat_room")
	var next_room := Room.new()
	next_room.room_cleared = true
	add_child(next_room)
	next_room.add_to_group("combat_room")
	compass._update_compass(0.1)
	assert(is_equal_approx(compass._cleared_seconds, 0.1))
	assert(compass.exit_arrow.attention == 0.0 and compass.exit_arrow.scale == Vector2.ONE)
	next_room.room_cleared = false
	compass._update_compass(0.1)
	assert(compass._cleared_seconds == 0.0)
	print("EXIT_ARROW_ATTENTION_OK: demora, pulso, pausa y cambio de sala")
	get_tree().quit()
