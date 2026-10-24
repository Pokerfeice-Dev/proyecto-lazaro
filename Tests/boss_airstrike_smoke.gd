extends Node2D

class Target extends Node2D:
	var hits := 0
	func take_damage(_amount: int, _source: String) -> void: hits += 1
	func apply_custom_camera_shake(_strength: float, _duration: float) -> void: pass

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	GameData.event_demo_active = true
	var target := Target.new()
	target.position = Vector2(350, 350)
	add_child(target)
	target.add_to_group("player")
	var strike := BossAirstrike.new()
	strike.position = target.position
	add_child(strike)
	strike.set_process(false)
	strike._process(0.85)
	check(target.hits == 0, "Aviso no daña")
	await capture("airstrike_warning")
	strike._process(0.16)
	strike._trigger_impact()
	check(target.hits == 1, "Impacto aplica daño una sola vez")
	strike._process(0.16)
	await capture("airstrike_impact")
	var distant := BossAirstrike.new()
	distant.position = target.position + Vector2(56, 0)
	add_child(distant)
	distant._trigger_impact()
	check(target.hits == 1, "FX exteriores no amplían radio de daño")
	await get_tree().create_timer(1.2).timeout
	check(not is_instance_valid(strike) and not is_instance_valid(distant), "Limpieza de ambos bombardeos")
	if failures == 0: print("BOSS_AIRSTRIKE_OK")
	get_tree().quit(failures)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://%s.png" % label)
