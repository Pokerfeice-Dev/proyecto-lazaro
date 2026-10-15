extends Node2D
class_name Torch

@onready var light_node: PointLight2D = get_node_or_null("PointLight2D")
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

## Variación sutil: una llama real respira; no salta de brillo cuadro a cuadro.
@export_range(0.0, 0.15, 0.005) var flicker_range: float = 0.035
@export_range(0.1, 1.0, 0.05) var min_flicker_interval: float = 0.18
@export_range(0.1, 1.0, 0.05) var max_flicker_interval: float = 0.42
@export_range(1.0, 20.0, 0.5) var energy_smoothing: float = 5.5

var _flicker_timer: float = 0.0
var _base_energy: float = 0.0
var _target_energy: float = 0.0

func _ready() -> void:
	if light_node:
		_base_energy = light_node.energy
		_target_energy = _base_energy
		_flicker_timer = randf_range(min_flicker_interval, max_flicker_interval)
	_start_torch()

func _start_torch() -> void:
	if not anim_sprite: return
	anim_sprite.play("default")

func _process(delta: float) -> void:
	_update_torch_flicker(delta)

func _update_torch_flicker(delta: float) -> void:
	if not light_node: return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(min_flicker_interval, max_flicker_interval)
		_target_energy = _base_energy + randf_range(-flicker_range, flicker_range)
	light_node.energy = move_toward(light_node.energy, _target_energy, energy_smoothing * delta * flicker_range)
