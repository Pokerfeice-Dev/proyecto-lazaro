extends Node2D

@export var tick_damage := 4
@export var duration := 4.0
var source_position := Vector2.ZERO

func _ready() -> void:
	$Tick.timeout.connect(_tick)
	$Duration.timeout.connect(queue_free)
	$Duration.start(duration)

func refresh(origin: Vector2) -> void:
	source_position = origin
	$Duration.start(duration)

func _tick() -> void:
	var player = get_parent()
	if player.has_method("take_damage"):
		player.take_damage(tick_damage, "Veneno del cienpiés", source_position)
