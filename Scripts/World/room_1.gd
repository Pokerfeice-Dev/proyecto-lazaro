extends Node2D

@export var enemy_pool: Array[PackedScene] = [
	preload("res://Scenes/Enemies/EnemyFollower.tscn"),
	preload("res://Scenes/Enemies/EnemyShooter.tscn"),
	preload("res://Scenes/Enemies/EnemyTank.tscn")
]
@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
@onready var teleport_area: Area2D = $Teleport_run/Area2D
@onready var teleport_sprite: AnimatedSprite2D = $Teleport_run
var interaction_label: Label
var can_teleport: bool = false
var spawned: bool = false
var active_enemies: int = 0

func _ready():
	_setup_teleport()
	_setup_interaction_label()

	if has_node("Area_entered"):
		$Area_entered.body_entered.connect(_on_area_entered_body_entered)
		
	var p_spawn = get_node_or_null("player_spawn")
	if p_spawn:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() == 0 and player_scene:
			var p_inst = player_scene.instantiate()
			p_inst.global_position = p_spawn.global_position
			get_tree().current_scene.call_deferred("add_child", p_inst)
		elif players.size() > 0:
			players[0].global_position = p_spawn.global_position

func _setup_interaction_label() -> void:
	interaction_label = Label.new()
	interaction_label.text = "Presiona E"
	interaction_label.visible = false
	interaction_label.position = teleport_sprite.position + Vector2(-40, -60)
	add_child(interaction_label)

func _on_area_entered_body_entered(body: Node2D):
	if spawned: return
	
	if body.is_in_group("player"):
		spawned = true
		_spawn_enemies()

func _spawn_enemies():
	var spawns = [$Spawn1, $Spawn2, $Spawn3, $Spawn4, $Spawn5, $Spawn6, $Spawn7, $Spawn8]
	for spawn_point in spawns:
		if spawn_point:
			var random_enemy_scene = enemy_pool.pick_random()
			if not random_enemy_scene: continue
			
			var enemy = random_enemy_scene.instantiate()
			enemy.global_position = spawn_point.global_position
			enemy.enemy_died.connect(_on_enemy_died)
			get_tree().current_scene.call_deferred("add_child", enemy)
			
			if enemy.has_method("spawn_appear"):
				enemy.call_deferred("spawn_appear")
				
			active_enemies += 1

func _on_enemy_died(_enemy):
	active_enemies -= 1
	if active_enemies <= 0:
		_open_door()

func _open_door():
	var door = get_node_or_null("Door_block")
	if door:
		# Deshabilitar colisiones para poder pasar inmediatamente
		if door is CollisionObject2D:
			door.collision_layer = 0
			door.collision_mask = 0
			
		# Si la puerta tiene colisiones anidadas internamente en la escena instanciada
		for child in door.find_children("*", "CollisionShape2D", true, false):
			child.set_deferred("disabled", true)
		
		var t = create_tween()
		t.tween_property(door, "modulate:a", 0.0, 0.5)
		await t.finished
		door.queue_free()

func _setup_teleport() -> void:
	teleport_area.body_entered.connect(_on_teleport_body_entered)
	teleport_area.body_exited.connect(_on_teleport_body_exited)

func _input(event: InputEvent) -> void:
	if not can_teleport:
		return
	if not event is InputEventKey:
		return
	if event.physical_keycode == KEY_E and event.pressed and not event.echo:
		SceneTransition.change_scene("res://Scenes/Rooms/room_ygor.tscn")

func _on_teleport_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	can_teleport = true
	if interaction_label:
		interaction_label.visible = true

func _on_teleport_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	can_teleport = false
	if interaction_label:
		interaction_label.visible = false
