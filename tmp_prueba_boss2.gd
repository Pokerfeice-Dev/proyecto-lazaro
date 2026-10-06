extends Node

# Prueba temporal: carga la sala del boss 2 y le baja la vida para forzar el despertar (se borra despues).
func _ready() -> void:
	var room = load("res://Scenes/Rooms/Level2_Room14BossFight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(room)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(4.0).timeout
	var boss = room.get_node_or_null("Boss2")
	var music = room.get_node_or_null("Boss_Fight_Music")
	print("PRUEBA inicio: vida ", boss.current_health, "/", boss.max_health, " musica ", music.stream.resource_path if music and music.stream else "nada", " sonando ", music.playing if music else false)
	boss.take_damage(int(boss.max_health * 0.55))
	print("PRUEBA tras golpe: vida ", boss.current_health, " fase2 ", boss.is_phase_two, " transicion ", boss.is_transitioning_phase)
	await get_tree().create_timer(4.0).timeout
	print("PRUEBA en cinemática: musica ", music.stream.resource_path, " sonando ", music.playing, " vol ", music.volume_db, " vida ", boss.current_health)
	await get_tree().create_timer(5.0).timeout
	print("PRUEBA fin: transicion ", boss.is_transitioning_phase, " vida ", boss.current_health, " patrones cada ", boss.pattern_timer.wait_time, " musica pos ", music.get_playback_position())
