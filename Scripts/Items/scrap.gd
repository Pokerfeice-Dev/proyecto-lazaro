extends Node2D
class_name Scrap

var value: int = 1
var player: Player = null
var is_attracting: bool = false
var is_collected: bool = false
@export var attract_speed: float = 300.0

@onready var grab_area: Area2D = $Grab_area
@onready var scrap_snd: AudioStreamPlayer = $Scrap_snd

func _ready() -> void:
	add_to_group("scrap")
	_connect_grab_area()

func _connect_grab_area() -> void:
	if not grab_area: return
	grab_area.body_entered.connect(_on_grab_area_body_entered)

func _physics_process(delta: float) -> void:
	_process_attraction(delta)

func _process_attraction(delta: float) -> void:
	if not is_attracting: return
	if not player: return
	if is_collected: return
	
	_move_towards_player(delta)
	_check_collection()

func _move_towards_player(delta: float) -> void:
	var dir = (player.global_position - global_position).normalized()
	global_position += dir * attract_speed * delta

func _check_collection() -> void:
	if global_position.distance_to(player.global_position) >= 20.0: return
	_collect()

func _collect() -> void:
	is_collected = true
	_add_scrap_to_player()
	_play_sound_and_free()

func _add_scrap_to_player() -> void:
	if not player.stats.has_method("add_scrap"): return
	player.stats.add_scrap(value)

func _play_sound_and_free() -> void:
	visible = false
	if not scrap_snd:
		queue_free()
		return
	scrap_snd.finished.connect(queue_free)
	scrap_snd.play()

func _on_grab_area_body_entered(body: Node2D) -> void:
	if not _is_player(body): return
	player = body
	is_attracting = true

func _is_player(body: Node2D) -> bool:
	if body is Player: return true
	if body.is_in_group("player"): return true
	return false
