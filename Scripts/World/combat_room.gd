extends Node2D
class_name CombatRoom

@export_category("Roguelike Room Settings")
## Escena del jugador (si no hay uno en el árbol).
@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")

var total_enemies_to_spawn: int = 15
var max_concurrent_enemies: int = 5
var spawn_interval: float = 1.5
var enemy_pool: Array[PackedScene] = []

@export_category("Rewards")
## Recompensa que se spawnea al limpiar la habitación (Ej. Cofre, Scrap gigante, etc.)
@export var room_reward_scene: PackedScene
@export var scrap_reward: int = 20

@export_category("Aparición de sala")
## Si está prendido, los objetos sueltos de la sala (puerta, cofres, props)
## aparecen con un rebote al cargar la sala en vez de estar ahí de una.
@export var reveal_props_on_load: bool = true
## Velocidad (px/seg) a la que se expande la "ola" de aparición desde
## player_spawn hacia el resto de la sala. Más alto = aparece todo más rápido.
@export var reveal_wave_speed: float = 500.0
## Si está prendido, el tileset entero (Floor/Tile_Objects/Walls, cualquier
## TileMapLayer hijo de la sala) aparece en piezas que caen del cielo, en la
## misma ola que los props sueltos.
@export var reveal_tiles_on_load: bool = false
## Tamaño (en tiles) de cada pieza que cae. Más chico = más piezas, más
## "confeti" pero más costoso; más grande = piezas más grandes, más barato.
@export var tile_chunk_size: int = 2
## Altura (px) desde la que caen las piezas del tileset.
@export var tile_fall_height: float = 90.0
## Duración (seg) de la caída de cada pieza individual.
@export var tile_fall_duration: float = 0.22

var active_enemies: int = 0
var enemies_spawned_so_far: int = 0
var room_started: bool = false
var room_cleared: bool = false
var spawn_timer: Timer
var spawn_points: Array[Node] = []
var astar_nav: AStar2D = null
var _nav_cell_to_id: Dictionary = {}

func _ready() -> void:
	add_to_group("combat_room")
	_apply_difficulty_settings()
	_setup_player()
	_setup_spawn_points()
	_setup_spawn_timer()
	_detect_preplaced_enemies()
	_setup_navigation_grid()
	if reveal_tiles_on_load:
		_reveal_room_tiles()
	if reveal_props_on_load:
		_reveal_room_props()

	var start_area = get_node_or_null("Area_entered")
	if start_area:
		start_area.body_entered.connect(_on_start_area_entered)
	
	_ensure_room_music_bus()
	_init_adaptive_music()

func _ensure_room_music_bus() -> void:
	var boss_music = get_node_or_null("Boss_Fight_Music") as AudioStreamPlayer
	if not boss_music: return
	boss_music.bus = "Music"

func _init_adaptive_music() -> void:
	var start_area = get_node_or_null("Area_entered")
	if start_area:
		SceneTransition.set_combat_mode(false, true)
		return
	SceneTransition.set_combat_mode(true, true)

# Junta los objetos sueltos de la sala (puerta, cofres, props colocados a
# mano) y los hace aparecer con rebote via RoomReveal, en forma de ola que
# arranca en player_spawn y se expande hacia el punto más lejano de la sala.
# No incluye tilemaps (Floor/Tile_Objects/Walls, que no se pueden animar
# por-tile), marcadores invisibles (Spawn*, player_spawn) ni triggers
# (Area_entered).
func _reveal_room_props() -> void:
	var props: Array = []
	for child in get_children():
		if _is_revealable_prop(child):
			props.append(child)
	if props.is_empty(): return

	var origin_node = get_node_or_null("player_spawn")
	if origin_node:
		RoomReveal.reveal_nodes_from_origin(props, origin_node.global_position, reveal_wave_speed)
	else:
		RoomReveal.reveal_nodes(props)

func _is_revealable_prop(node: Node) -> bool:
	if not (node is Node2D): return false
	if node is TileMapLayer: return false
	if node is Marker2D: return false
	if node is Area2D: return false
	if node.name.begins_with("Spawn"): return false
	return true

# Hace caer del cielo, en piezas chicas, cualquier TileMapLayer hijo de la
# sala (Floor, Tile_Objects, Walls, etc. -- lo que haya, sin depender de sus
# nombres). Usa la misma ola/origen que _reveal_room_props para que todo
# aparezca coordinado.
func _reveal_room_tiles() -> void:
	var origin_node = get_node_or_null("player_spawn")
	var origin: Vector2 = origin_node.global_position if origin_node else global_position
	for child in get_children():
		if child is TileMapLayer:
			TileRainReveal.reveal_tilemap_layer(child, origin, tile_chunk_size, reveal_wave_speed, tile_fall_height, tile_fall_duration)

func _detect_preplaced_enemies() -> void:
	var preplaced_enemies = get_tree().get_nodes_in_group("enemy")
	var has_preplaced: bool = false
	for enemy in preplaced_enemies:
		if is_ancestor_of(enemy) and enemy.has_signal("enemy_died"):
			if not enemy.enemy_died.is_connected(_on_enemy_died):
				enemy.enemy_died.connect(_on_enemy_died)
				active_enemies += 1
				has_preplaced = true

	if has_preplaced:
		_close_door()

# El aviso de "distrito descubierto" ahora se dispara desde GameData al avanzar
# de nivel (ver get_post_boss_scene en game_data.gd), no por profundidad de sala.

func _apply_difficulty_settings() -> void:
	var config: Dictionary = GameData.get_room_config()
	total_enemies_to_spawn = config.total_enemies
	max_concurrent_enemies = config.max_concurrent
	spawn_interval = config.spawn_interval
	_build_enemy_pool(config.allowed_enemies)

func _build_enemy_pool(allowed: Array) -> void:
	var new_pool: Array[PackedScene] = []
	_add_follower_if_allowed(allowed, new_pool)
	_add_shooter_if_allowed(allowed, new_pool)
	_add_tank_if_allowed(allowed, new_pool)
	_add_turret_if_allowed(allowed, new_pool)
	_add_summoner_if_allowed(allowed, new_pool)

	if new_pool.is_empty(): return
	enemy_pool = new_pool

func _add_follower_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("follower"): return
	pool.append(preload("res://Scenes/Enemies/EnemyFollower.tscn"))

func _add_shooter_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("shooter"): return
	pool.append(preload("res://Scenes/Enemies/EnemyShooter.tscn"))

func _add_tank_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("tank"): return
	pool.append(preload("res://Scenes/Enemies/EnemyTank.tscn"))

func _add_turret_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("turret"): return
	pool.append(preload("res://Scenes/Enemies/EnemyTurret.tscn"))

func _add_summoner_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("summoner"): return
	pool.append(preload("res://Scenes/Enemies/EnemySummoner.tscn"))

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
	SceneTransition.set_combat_mode(true)
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

	var escaner_lvl = GameData.core_upgrades.get("escaner_objetivos", 0)
	var elite_chance = 0.05 + (escaner_lvl * 0.01)
	if randf() <= elite_chance:
		enemy.is_elite = true

	get_tree().current_scene.call_deferred("add_child", enemy)

	if enemy.has_method("spawn_appear"):
		enemy.call_deferred("spawn_appear")

	active_enemies += 1
	enemies_spawned_so_far += 1

func _on_enemy_died(_enemy) -> void:
	active_enemies -= 1
	var start_area = get_node_or_null("Area_entered")
	if start_area:
		if enemies_spawned_so_far >= total_enemies_to_spawn and active_enemies <= 0:
			_clear_room()
	else:
		if active_enemies <= 0:
			_clear_room()

func _clear_room() -> void:
	room_cleared = true
	room_started = false
	_open_door()
	_spawn_reward()
	_play_room_clear_effects()
	_award_clear_scrap()
	SceneTransition.set_combat_mode(false)

	if GameData.get_active_protocol() == "reparacion_autonoma":
		var player = get_tree().get_first_node_in_group("player")
		if player and "stats" in player and player.stats.has_method("heal"):
			player.stats.heal(1)

func _award_clear_scrap() -> void:
	GameData.add_scrap(scrap_reward)

func _play_room_clear_effects() -> void:
	_play_room_clear_sound()
	_play_room_clear_flash()

func _play_room_clear_sound() -> void:
	var stream: AudioStream = preload("res://Audio/Sfx/Room_clear/Room_clear.wav")
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _play_room_clear_flash() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var rect: ColorRect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat: ShaderMaterial = ShaderMaterial.new()
	var shader: Shader = Shader.new()
	shader.code = _get_green_flash_shader()
	mat.shader = shader
	mat.set_shader_parameter("border_color", Color(0.2, 1.0, 0.2, 1.0))
	mat.set_shader_parameter("intensity", 0.0)
	rect.material = mat
	canvas.add_child(rect)

	var t: Tween = create_tween()
	t.tween_method(_set_flash_intensity.bind(mat), 0.0, 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_method(_set_flash_intensity.bind(mat), 1.0, 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.finished.connect(canvas.queue_free)

func _get_green_flash_shader() -> String:
	return """
shader_type canvas_item;
uniform vec4 border_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float intensity = 0.0;
void fragment() {
	vec2 uv = UV;
	float d = distance(uv, vec2(0.5, 0.5));
	float alpha = smoothstep(0.35, 0.75, d) * intensity;
	COLOR = border_color;
	COLOR.a *= alpha;
}
"""

func _set_flash_intensity(val: float, mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("intensity", val)

func _close_door() -> void:
	var doors = get_tree().get_nodes_in_group("door")
	for door in doors:
		if door.has_method("lock_door"):
			door.lock_door()

func _open_door() -> void:
	var doors = get_tree().get_nodes_in_group("door")
	for door in doors:
		if door.has_method("unlock_door"):
			door.unlock_door()

func _spawn_reward() -> void:
	if not room_reward_scene: return
	var reward = room_reward_scene.instantiate()
	var center = get_node_or_null("player_spawn") # O algún nodo de RewardSpawn
	if center:
		reward.global_position = center.global_position
	get_tree().current_scene.call_deferred("add_child", reward)

# --- Sistema de Navegación (AStar2D) ---

func _setup_navigation_grid() -> void:
	var floor_layer = get_node_or_null("Floor") as TileMapLayer
	if not floor_layer: return
	astar_nav = AStar2D.new()
	_nav_cell_to_id.clear()
	
	var blocked_cells = _get_blocked_cells(floor_layer)
	_populate_nav_points(floor_layer, blocked_cells)
	_connect_nav_points()

func _get_blocked_cells(floor_layer: TileMapLayer) -> Dictionary:
	var blocked: Dictionary = {}
	_collect_layer_obstacles("Walls", floor_layer, blocked)
	_collect_layer_obstacles("Tile_Objects", floor_layer, blocked)
	return blocked

func _collect_layer_obstacles(layer_name: String, floor_layer: TileMapLayer, blocked: Dictionary) -> void:
	var layer = get_node_or_null(layer_name) as TileMapLayer
	if not layer: return
	var cells = layer.get_used_cells()
	for cell in cells:
		var global_pos = layer.to_global(layer.map_to_local(cell))
		var floor_cell = floor_layer.local_to_map(floor_layer.to_local(global_pos))
		blocked[floor_cell] = true

func _populate_nav_points(floor_layer: TileMapLayer, blocked_cells: Dictionary) -> void:
	var floor_cells = floor_layer.get_used_cells()
	var point_id: int = 0
	for cell in floor_cells:
		if blocked_cells.has(cell): continue
		var world_pos = floor_layer.to_global(floor_layer.map_to_local(cell))
		astar_nav.add_point(point_id, world_pos)
		_nav_cell_to_id[cell] = point_id
		point_id += 1

func _connect_nav_points() -> void:
	var offsets = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	for cell in _nav_cell_to_id.keys():
		var id_from = _nav_cell_to_id[cell]
		_connect_single_cell_neighbors(cell, id_from, offsets)

func _connect_single_cell_neighbors(cell: Vector2i, id_from: int, offsets: Array) -> void:
	for offset in offsets:
		var neighbor_cell = cell + offset
		_try_connect_neighbor(id_from, cell, neighbor_cell, offset)

func _try_connect_neighbor(id_from: int, cell: Vector2i, neighbor: Vector2i, offset: Vector2i) -> void:
	if not _nav_cell_to_id.has(neighbor): return
	var id_to = _nav_cell_to_id[neighbor]
	if astar_nav.are_points_connected(id_from, id_to): return
	if absi(offset.x) + absi(offset.y) == 2 and not _can_traverse_diagonal(cell, offset):
		return
	astar_nav.connect_points(id_from, id_to, true)

func _can_traverse_diagonal(cell: Vector2i, offset: Vector2i) -> bool:
	var adj1 = cell + Vector2i(offset.x, 0)
	var adj2 = cell + Vector2i(0, offset.y)
	return _nav_cell_to_id.has(adj1) and _nav_cell_to_id.has(adj2)

func get_nav_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	if not astar_nav or astar_nav.get_point_count() == 0:
		return PackedVector2Array()
	var start_id = astar_nav.get_closest_point(from_pos)
	var end_id = astar_nav.get_closest_point(to_pos)
	if start_id == end_id:
		return PackedVector2Array([to_pos])
	var path = astar_nav.get_point_path(start_id, end_id)
	if path.size() > 0:
		path.append(to_pos)
	return path
