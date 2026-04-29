class_name ItemDropWorld
extends Node2D

@export var item_data: ItemData

@export var attract_speed: float = 300.0

var player: Node2D = null
var is_attracting: bool = false
var is_collected: bool = false
var target_inventory: Inventory = null

func _ready() -> void:
	var grab = get_node_or_null("Grab_area")
	if grab:
		grab.body_entered.connect(_on_grab_area_body_entered)

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
	if target_inventory:
		target_inventory.add_item(item_data)
	_play_sound_and_free()

func _play_sound_and_free() -> void:
	visible = false
	var snd = get_node_or_null("Scrap_snd")
	if not snd:
		queue_free()
		return
	snd.finished.connect(queue_free)
	snd.play()

func _on_grab_area_body_entered(body: Node2D) -> void:
	check_player_collision(body)

func check_player_collision(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	var inv = body.get_node_or_null("Inventory")
	if not inv: return
	player = body
	target_inventory = inv
	is_attracting = true
