extends Node2D

@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")
@onready var teleport_area: Area2D = $Teleport_run/Area2D
@onready var teleport_sprite: AnimatedSprite2D = $Teleport_run

var can_teleport: bool = false
var interaction_label: Label

func _ready() -> void:
	_spawn_or_reposition_player()
	_setup_teleport()
	_setup_interaction_label()

func _spawn_or_reposition_player() -> void:
	var p_spawn = get_node_or_null("player_spawn")
	if not p_spawn:
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		_spawn_fresh_player(p_spawn.global_position)
	else:
		_reposition_existing_player(players[0], p_spawn.global_position)

func _spawn_fresh_player(spawn_pos: Vector2) -> void:
	if not player_scene:
		return
	var p_inst = player_scene.instantiate()
	p_inst.global_position = spawn_pos
	get_tree().current_scene.call_deferred("add_child", p_inst)
	# Ensure health is max and HUD is synced after spawning
	p_inst.ready.connect(func():
		var s = p_inst.stats
		s.current_health = s.max_health
		s.health_changed.emit(s.current_health, s.max_health)
	)

func _reposition_existing_player(player: Node, spawn_pos: Vector2) -> void:
	player.global_position = spawn_pos
	# Re-enable the player in case they were disabled after death
	if player.process_mode == Node.PROCESS_MODE_DISABLED:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.show()
	# Reset health to max and re-apply upgrades/sync HUD
	if "stats" in player:
		var s = player.stats
		s.current_health = s.max_health
		s.health_changed.emit(s.current_health, s.max_health)
	if player.has_method("_apply_game_data_upgrades"):
		player._apply_game_data_upgrades()


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
		SceneTransition.change_scene("res://Scenes/Main.tscn")

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
