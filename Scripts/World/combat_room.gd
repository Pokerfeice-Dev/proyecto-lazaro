extends Node2D
class_name CombatRoom

@export_category("Roguelike Room Settings")
## Total de enemigos que aparecerán antes de limpiar la habitación.
@export var total_enemies_to_spawn: int = 15
## Máxima cantidad de enemigos que pueden estar vivos al mismo tiempo.
@export var max_concurrent_enemies: int = 5
## Tiempo de espera entre cada aparición de enemigo.
@export var spawn_interval: float = 1.5
## Lista de enemigos posibles que pueden spawnear.
@export var enemy_pool: Array[PackedScene] = [
	preload("res://Scenes/Enemies/EnemyFollower.tscn"),
	preload("res://Scenes/Enemies/EnemyShooter.tscn"),
	preload("res://Scenes/Enemies/EnemyTank.tscn")
]
## Escena del jugador (si no hay uno en el árbol).
@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")

@export_category("Rewards")
## Recompensa que se spawnea al limpiar la habitación (Ej. Cofre, Scrap gigante, etc.)
@export var room_reward_scene: PackedScene

var active_enemies: int = 0
var enemies_spawned_so_far: int = 0
var room_started: bool = false
var room_cleared: bool = false
var spawn_timer: Timer
var spawn_points: Array[Node] = []

@onready var teleport_area: Area2D = get_node_or_null("Teleport_run/Area2D")
@onready var teleport_sprite: AnimatedSprite2D = get_node_or_null("Teleport_run")
var interaction_label: Label
var can_teleport: bool = false

func _ready() -> void:
	_setup_player()
	_setup_spawn_points()
	_setup_spawn_timer()
	
	if teleport_area:
		_setup_teleport()
		_setup_interaction_label()
		
	var start_area = get_node_or_null("Area_entered")
	if start_area:
		start_area.body_entered.connect(_on_start_area_entered)

func _setup_player() -> void:
	var p_spawn = get_node_or_null("player_spawn")
	if p_spawn:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() == 0 and player_scene:
			var p_inst = player_scene.instantiate()
			p_inst.global_position = p_spawn.global_position
			get_tree().current_scene.call_deferred("add_child", p_inst)
		elif players.size() > 0:
			players[0].global_position = p_spawn.global_position

func _setup_spawn_points() -> void:
	# Busca todos los nodos que se llamen Spawn1, Spawn2, etc.
	for child in get_children():
		if child.name.begins_with("Spawn") and child is Node2D:
			spawn_points.append(child)

func _setup_spawn_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func _on_start_area_entered(body: Node2D) -> void:
	if room_started or room_cleared: return
	
	if body.is_in_group("player"):
		_start_room()

func _start_room() -> void:
	room_started = true
	_close_door()
	spawn_timer.start()
	# Forzar el primer spawn de inmediato
	_on_spawn_timer_timeout()

func _on_spawn_timer_timeout() -> void:
	if enemies_spawned_so_far >= total_enemies_to_spawn:
		spawn_timer.stop()
		return
		
	if active_enemies >= max_concurrent_enemies:
		return # Esperar a que muera un enemigo
		
	_spawn_single_enemy()

func _spawn_single_enemy() -> void:
	if spawn_points.is_empty() or enemy_pool.is_empty(): return
	
	var point = spawn_points.pick_random()
	var random_enemy_scene = enemy_pool.pick_random()
	
	if not random_enemy_scene: return
	
	var enemy = random_enemy_scene.instantiate()
	enemy.global_position = point.global_position
	enemy.enemy_died.connect(_on_enemy_died)
	
	get_tree().current_scene.call_deferred("add_child", enemy)
	
	if enemy.has_method("spawn_appear"):
		enemy.call_deferred("spawn_appear")
		
	active_enemies += 1
	enemies_spawned_so_far += 1

func _on_enemy_died(_enemy) -> void:
	active_enemies -= 1
	if enemies_spawned_so_far >= total_enemies_to_spawn and active_enemies <= 0:
		_clear_room()

func _clear_room() -> void:
	room_cleared = true
	room_started = false
	_open_door()
	_spawn_reward()

func _close_door() -> void:
	var door = get_node_or_null("Door_block")
	if door:
		# Si necesitas activar colisiones de una puerta que se cierra
		pass

func _open_door() -> void:
	var door = get_node_or_null("Door_block")
	if door:
		if door is CollisionObject2D:
			door.collision_layer = 0
			door.collision_mask = 0
			
		for child in door.find_children("*", "CollisionShape2D", true, false):
			child.set_deferred("disabled", true)
		
		var t = create_tween()
		t.tween_property(door, "modulate:a", 0.0, 0.5)
		await t.finished
		door.queue_free()

func _spawn_reward() -> void:
	if not room_reward_scene: return
	var reward = room_reward_scene.instantiate()
	var center = get_node_or_null("player_spawn") # O algún nodo de RewardSpawn
	if center:
		reward.global_position = center.global_position
	get_tree().current_scene.call_deferred("add_child", reward)

# --- TELEPORT LOGIC ---
func _setup_teleport() -> void:
	teleport_area.body_entered.connect(_on_teleport_body_entered)
	teleport_area.body_exited.connect(_on_teleport_body_exited)

func _setup_interaction_label() -> void:
	interaction_label = Label.new()
	interaction_label.text = "Presiona E"
	interaction_label.visible = false
	interaction_label.position = teleport_sprite.position + Vector2(-40, -60)
	add_child(interaction_label)

func _input(event: InputEvent) -> void:
	if not can_teleport:
		return
	if not event is InputEventKey:
		return
	if event.physical_keycode == KEY_E and event.pressed and not event.echo:
		SceneTransition.change_scene("res://Scenes/Rooms/room_ygor.tscn")

func _on_teleport_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	can_teleport = true
	if interaction_label:
		interaction_label.visible = true

func _on_teleport_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	can_teleport = false
	if interaction_label:
		interaction_label.visible = false
