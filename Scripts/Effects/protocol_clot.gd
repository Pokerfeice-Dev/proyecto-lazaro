extends Node2D
## Recompensa de Núcleo Vampírico: se recoge al acercarse, sin física adicional.
var age := 0.0

func _ready() -> void:
	z_index = 5

func _process(delta: float) -> void:
	age += delta
	var player = get_tree().get_first_node_in_group("player")
	if player and player.global_position.distance_to(global_position) < 24.0 and player.stats.current_health < player.stats.max_health:
		ProtocolRuntime.heal_player(player, 2)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var point := Vector2(0, round(sin(age * 4.0) * 2.0))
	draw_rect(Rect2(point - Vector2(5, 4), Vector2(10, 8)), Color("8b244a"))
	draw_rect(Rect2(point - Vector2(3, 6), Vector2(6, 12)), Color("ef5e88"))
	draw_rect(Rect2(point - Vector2(2, 3), Vector2(3, 3)), Color("ffd3df"))
