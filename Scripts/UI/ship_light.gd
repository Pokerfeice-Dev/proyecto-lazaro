extends ColorRect

@export var min_blink_time: float = 0.2
@export var max_blink_time: float = 1.5

@onready var timer: Timer = $Timer

func _ready() -> void:
	randomize_timer()

func randomize_timer() -> void:
	timer.wait_time = randf_range(min_blink_time, max_blink_time)
	timer.start()

func _on_timer_timeout() -> void:
	visible = !visible
	randomize_timer()
