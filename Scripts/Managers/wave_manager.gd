extends Node
class_name WaveManager

@export var enemy_follower_scene: PackedScene = preload("res://Scenes/Enemies/EnemyFollower.tscn")
@export var enemy_shooter_scene: PackedScene = preload("res://Scenes/Enemies/EnemyShooter.tscn")
@export var enemy_tank_scene: PackedScene = preload("res://Scenes/Enemies/EnemyTank.tscn")

var current_wave: int = 0
var enemies_alive: int = 0

signal wave_started(wave: int)
signal wave_cleared

func _ready():
	add_to_group("wave_manager")

func start_next_wave(spawn_points: Array):
	current_wave += 1
	wave_started.emit(current_wave)
	
	# Calculate enemies to spawn
	var total_enemies = 5 + (current_wave * 2)
	enemies_alive = total_enemies
	
	for i in range(total_enemies):
		var enemy_scene = _get_random_enemy_for_wave()
		if enemy_scene and spawn_points.size() > 0:
			var enemy = enemy_scene.instantiate()
			get_tree().current_scene.add_child(enemy)
			
			var spawn_point = spawn_points[randi() % spawn_points.size()]
			enemy.global_position = spawn_point
			
			enemy.enemy_died.connect(_on_enemy_died)

func _get_random_enemy_for_wave() -> PackedScene:
	var roll = randf()
	if current_wave <= 2:
		return enemy_follower_scene
	elif current_wave <= 4:
		if roll < 0.7: return enemy_follower_scene
		else: return enemy_shooter_scene
	else:
		if roll < 0.5: return enemy_follower_scene
		elif roll < 0.8: return enemy_shooter_scene
		else: return enemy_tank_scene

func _on_enemy_died(_enemy: EnemyBase):
	enemies_alive -= 1
	if enemies_alive <= 0:
		wave_cleared.emit()
