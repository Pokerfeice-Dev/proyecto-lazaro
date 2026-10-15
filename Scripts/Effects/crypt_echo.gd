extends Node2D

@export var damage := 16
@export var radius := 52.0
@export var warning_duration := 1.0

func _ready() -> void:
	$Warning.timeout.connect(_explode)
	$Lifetime.timeout.connect(queue_free)
	$Warning.start(warning_duration)
	$AnimationPlayer.play("warning", -1, 1.0 / maxf(warning_duration, 0.01))

func _explode() -> void:
	$AnimationPlayer.play("burst")
	for player in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(player.global_position) > radius: continue
		var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 5, [player.get_rid()])
		if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			player.take_damage(damage, "Campanero de Réquiem", global_position)
	$Lifetime.start()
