extends Node2D
# Charco de veneno que deja el ciempiés al moverse. Dura unos segundos y
# envenena a quien lo pise (mismo veneno que el spray, con su duración propia).

var duration := 3.0
var radius := 14.0
var poison_scene: PackedScene

var _time_left := 0.0
var _check_left := 0.0

func _ready() -> void:
	z_index = -1
	_time_left = duration

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return
	_check_left -= delta
	if _check_left <= 0.0:
		_check_left = 0.2
		_poison_players()
	queue_redraw()

func _poison_players() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(player): continue
		if global_position.distance_to(player.global_position) > radius + 6.0: continue
		if player.get("is_dashing") == true or player.get("is_invulnerable") == true: continue
		var poison = player.get_node_or_null("CryptPoison")
		if poison == null:
			if poison_scene == null: continue
			poison = poison_scene.instantiate()
			player.add_child(poison)
		poison.refresh(global_position)

func _draw() -> void:
	# Se desvanece durante el último segundo.
	var fade := clampf(_time_left, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.45, 0.85, 0.15, 0.3 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(0.7, 1.0, 0.25, 0.65 * fade), 1.5)
