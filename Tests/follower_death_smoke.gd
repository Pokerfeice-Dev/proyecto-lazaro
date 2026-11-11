extends Node2D

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	for during_spawn in [false, true]:
		var dog = preload("res://Scenes/Enemies/EnemyFollower.tscn").instantiate()
		add_child(dog)
		if during_spawn:
			dog.spawn_appear()
		else:
			dog.get_node("Summon_anim").hide()
			dog._get_sprite().modulate.a = 1.0
		dog.die()
		assert(not dog.get_node("Summon_anim").visible)
		assert(not dog._get_sprite().visible)
		# Simula callbacks de aparición que llegaron después del golpe mortal.
		dog._on_summon_finished(dog.get_node("Summon_anim"))
		dog._finish_spawn()
		assert(not dog.is_physics_processing())
		await get_tree().create_timer(0.35).timeout
		for child in get_children():
			assert(child.get_script() != preload("res://Scripts/Effects/pixel_death.gd"), "Los fragmentos del perro no deben persistir")
		dog.queue_free()
		await get_tree().process_frame
	print("FOLLOWER_DEATH_OK")
	get_tree().quit()
