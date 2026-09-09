extends Node2D
class_name Torch

@onready var light_node: PointLight2D = get_node_or_null("PointLight2D")
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

@export var base_energy: float = 1.3
@export var flicker_range: float = 0.25

var _flicker_timer: float = 0.0

func _ready() -> void:
	_start_torch()

func _start_torch() -> void:
	if not anim_sprite: return
	anim_sprite.play("default")

func _process(delta: float) -> void:
	_update_torch_flicker(delta)

func _update_torch_flicker(delta: float) -> void:
	if not light_node: return
	_flicker_timer -= delta
	if _flicker_timer > 0.0: return
	_flicker_timer = randf_range(0.05, 0.12)
	var target_energy = base_energy + randf_range(-flicker_range, flicker_range)
	light_node.energy = target_energy
