extends Node2D
class TestBoss extends Boss1:
	var roars := 0
	func _ready(): set_physics_process(false)
	func _spawn_mutation_at(pos: Vector2):
		var dog := Node2D.new()
		add_child(dog)
		dog.global_position = pos
		spawned_minions.append(dog)
	func _play_spawn_roar(): roars += 1
class Pilot extends Node2D:
	var shakes := 0
	func apply_custom_camera_shake(strength: float, duration: float):
		assert(strength == 10.0 and duration == 0.65)
		shakes += 1
func _ready():
	var pilot := Pilot.new()
	add_child(pilot)
	pilot.add_to_group('player')
	var boss = load('res://Scenes/Enemies/boss1.tscn').instantiate()
	boss.set_script(TestBoss)
	add_child(boss)
	boss._spawn_minions()
	assert(boss.spawned_minions.size() == 2)
	assert(boss.roars == 1 and pilot.shakes == 1)
	boss._spawn_minions()
	assert(boss.roars == 1 and pilot.shakes == 1)
	for dog in boss.spawned_minions: dog.free()
	boss._spawn_minions()
	assert(boss.roars == 2 and pilot.shakes == 2)
	print('SUMMON_ROAR_SHAKE_OK')
	get_tree().quit()
