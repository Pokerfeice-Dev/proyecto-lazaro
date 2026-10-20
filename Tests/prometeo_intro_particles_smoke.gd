extends Node

class TestBoss extends Node2D:
	func play_sfx(_sound: String) -> void:
		pass

func _ready() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var boss = TestBoss.new()
	add_child(boss)
	var intro = PrometeoIntro.new()
	add_child(intro)
	intro.boss = boss
	intro._gather_shadows(0.05)
	var particles = boss.get_child(0) as CPUParticles2D
	assert(particles != null and particles.emitting)
	await get_tree().create_timer(0.2).timeout
	assert(is_instance_valid(particles) and not particles.emitting)
	await get_tree().create_timer(1.0).timeout
	assert(not is_instance_valid(particles))
	# El tween debe cancelarse si las partículas desaparecen durante la espera.
	intro._gather_shadows(0.1)
	boss.get_child(0).queue_free()
	await get_tree().create_timer(1.2).timeout
	assert(boss.get_child_count() == 0)
	print("PROMETEO_INTRO_PARTICLES_OK")
	get_tree().quit()
