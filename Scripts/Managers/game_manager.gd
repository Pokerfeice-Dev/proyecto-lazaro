extends Node
class_name GameManager

var current_player: Player

signal game_over

func _ready() -> void:
	call_deferred("start_game")

func start_game() -> void:
	current_player = get_tree().get_first_node_in_group("player") as Player
	var hud = get_tree().get_first_node_in_group("hud") as HUD

	if not current_player:
		return

	current_player.stats.player_died.connect(_on_player_died)
	_connect_hud(hud)
	_sync_hud_initial(hud)

func _connect_hud(hud: HUD) -> void:
	if not hud:
		return
	current_player.stats.health_changed.connect(hud.update_health)
	GameData.scrap_changed.connect(hud.update_scrap)

func _sync_hud_initial(hud: HUD) -> void:
	if not current_player:
		return
	var s = current_player.stats
	if hud:
		hud.update_health(s.current_health, s.max_health)
		hud.update_scrap(GameData.scrap)

func _on_player_died() -> void:
	game_over.emit()
