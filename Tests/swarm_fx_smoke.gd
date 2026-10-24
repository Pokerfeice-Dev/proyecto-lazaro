extends Node2D

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true
	var target := CharacterBody2D.new()
	add_child(target)
	target.add_to_group("player")
	target.position = Vector2(650, 300)
	var summoner = load("res://Scenes/Enemies/EnemySummoner.tscn").instantiate()
	add_child(summoner)
	summoner.position = Vector2(350, 300)
	await get_tree().create_timer(1.5).timeout
	summoner.set_physics_process(false)
	summoner._start_summon()
	check(is_instance_valid(summoner._swarm_fx), "Carga crea ritual")
	await get_tree().create_timer(0.15).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://swarm_charge.png")
	summoner._on_summon_animation_finished()
	check(summoner.active_summons.size() == 1, "Invoca una abeja")
	summoner._on_summon_animation_finished()
	check(summoner.active_summons.size() == 1, "Señal duplicada no duplica abeja")
	var bee = summoner.active_summons[0]
	bee.set_physics_process(false)
	bee._face_direction(Vector2.RIGHT)
	check(not bee.anim_sprite.flip_h, "Abeja mira derecha")
	bee._face_direction(Vector2.LEFT)
	check(bee.anim_sprite.flip_h, "Abeja mira izquierda")
	bee._face_direction(Vector2.UP)
	check(bee.anim_sprite.flip_h, "Vuelo vertical conserva lado")
	bee.target = target
	target.position = bee.position + Vector2(100, 0)
	bee._start_charge()
	check(not bee.anim_sprite.flip_h, "Ataque mira hacia trayectoria")
	await get_tree().create_timer(0.8).timeout
	check(not is_instance_valid(summoner._swarm_fx), "Ritual se limpia tras liberar enjambre")
	summoner._start_summon()
	summoner.is_dying = true
	summoner._on_summon_animation_finished()
	await get_tree().process_frame
	await get_tree().process_frame
	check(summoner.active_summons.size() == 1 and not is_instance_valid(summoner._swarm_fx), "Muerte cancela ritual")
	if failures == 0: print("SWARM_FX_OK")
	get_tree().quit(failures)
