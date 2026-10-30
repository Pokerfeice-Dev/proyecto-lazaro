extends Node2D
class_name CombatRoom

@export_category("Roguelike Room Settings")
## Escena del jugador (si no hay uno en el árbol).
@export var player_scene: PackedScene = preload("res://Scenes/Player/Player.tscn")

@export_category("Ambiente de La Cripta")
## Capa de niebla suave. La escena mantiene el material y sus parámetros
## editables; se añade solamente a salas Level2.
@export var crypt_fog_scene: PackedScene = preload("res://Scenes/Effects/crypt_fog.tscn")
@export var enable_crypt_fog := true

var total_enemies_to_spawn: int = 15
var max_concurrent_enemies: int = 5
var spawn_interval: float = 1.5
var enemy_pool: Array[PackedScene] = []
var _enemy_weights: Dictionary = {}
var _special_caps: Dictionary = {}
var _elite_chance := 0.05
var _scheduled_enemies: Array[WeakRef] = []
const ENEMY_IDS := {
	"EnemyFollower": "follower", "EnemyShooter": "shooter", "EnemyTank": "tank", "EnemyTurret": "turret", "EnemySummoner": "summoner",
	"CryptGargoyle": "crypt_gargoyle", "CryptGhoul": "crypt_ghoul", "CryptDeathSquad": "crypt_death_squad", "CryptCentipede": "crypt_centipede", "CryptLaserEye": "crypt_laser_eye", "CryptDeadBeekeeperSummoner": "crypt_dead_beekeeper", "CryptBellKeeper": "crypt_bell_keeper"
}

const CRYPT_ENEMY_SCENES := {
	"crypt_bell_keeper": "res://Scenes/Enemies/Crypt/CryptBellKeeper.tscn",
	"crypt_gargoyle": "res://Scenes/Enemies/Crypt/CryptGargoyle.tscn",
	"crypt_ghoul": "res://Scenes/Enemies/Crypt/CryptGhoul.tscn",
	"crypt_centipede": "res://Scenes/Enemies/Crypt/CryptCentipede.tscn",
	"crypt_death_squad": "res://Scenes/Enemies/Crypt/CryptDeathSquad.tscn",
	"crypt_laser_eye": "res://Scenes/Enemies/Crypt/CryptLaserEye.tscn",
	"crypt_dead_beekeeper": "res://Scenes/Enemies/Crypt/CryptDeadBeekeeperSummoner.tscn",
}

@export_category("Rewards")
## Recompensa que se spawnea al limpiar la habitación (Ej. Cofre, Scrap gigante, etc.)
@export var room_reward_scene: PackedScene
@export var scrap_reward: int = 60

@export_category("Aparición de sala")
## Si está prendido, los objetos sueltos de la sala (puerta, cofres, props)
## aparecen con un rebote al cargar la sala en vez de estar ahí de una.
@export var reveal_props_on_load: bool = false
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
var _enemy_navigation: RefCounted

func _ready() -> void:
	add_to_group("combat_room")
	_setup_crypt_fog()
	_setup_zone_readability()
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

func _setup_crypt_fog() -> void:
	if not enable_crypt_fog or not _is_crypt_room() or crypt_fog_scene == null: return
	if get_node_or_null("CryptFog"): return
	var fog = crypt_fog_scene.instantiate()
	fog.name = "CryptFog"
	add_child(fog)

# Zona 2: contorno en los obstáculos (con la niebla no se veía con qué chocabas).
# Zona 3: los bordes del piso dan al vacío (son tiles de "Floor" con colisión):
# frenan a jugador y enemigos, pero las balas pasan por encima. Se usa una capa
# de colisión propia (VOID_LAYER_BIT), que solo miran los cuerpos (player.gd y
# enemy_base.gd), no los proyectiles. Las paredes de verdad ("Walls") y los
# objetos siguen frenando balas.
const VOID_LAYER_BIT := 5 # valor 16

func _setup_zone_readability() -> void:
	var file = get_scene_file_path().get_file()
	if file.begins_with("Level2_"):
		ObstacleOutline.attach(get_node_or_null("Tile_Objects") as TileMapLayer)
	elif file.begins_with("Level3_"):
		_make_layer_void(get_node_or_null("Floor") as TileMapLayer)

func _make_layer_void(layer: TileMapLayer) -> void:
	if not layer or not layer.tile_set or layer.tile_set.get_physics_layers_count() == 0: return
	var void_set: TileSet = layer.tile_set.duplicate() # el tileset compartido no se toca
	void_set.set_physics_layer_collision_layer(0, 1 << (VOID_LAYER_BIT - 1))
	void_set.set_physics_layer_collision_mask(0, 0)
	layer.tile_set = void_set

func _is_crypt_room() -> bool:
	return GameData.current_level == 2 or get_scene_file_path().get_file().begins_with("Level2_")

func _ensure_room_music_bus() -> void:
	_keep_music_playing(get_node_or_null("Ygor_music") as AudioStreamPlayer)
	var boss_music = get_node_or_null("Boss_Fight_Music") as AudioStreamPlayer
	if not boss_music: return
	boss_music.bus = "Music"
	boss_music.process_mode = Node.PROCESS_MODE_ALWAYS # sigue sonando con el inventario abierto

# La música de la tienda de Ygor se cortaba al abrir el inventario (pausa el juego).
func _keep_music_playing(music: AudioStreamPlayer) -> void:
	if not music: return
	music.bus = "Music"
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	if music.stream and "loop" in music.stream:
		music.stream.loop = true

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
	_enemy_weights = config.get("enemy_weights", {})
	_special_caps = config.get("special_caps", {})
	_elite_chance = config.get("elite_chance", 0.05)
	_build_enemy_pool(config.allowed_enemies)

func _build_enemy_pool(allowed: Array) -> void:
	var new_pool: Array[PackedScene] = []
	if GameData.current_level == 2:
		for id in allowed:
			if CRYPT_ENEMY_SCENES.has(id):
				new_pool.append(load(CRYPT_ENEMY_SCENES[id]))
		enemy_pool = new_pool
		return
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
	if not allowed.has("shooter") and not allowed.has("carpenter"): return
	pool.append(preload("res://Scenes/Enemies/EnemyShooter.tscn"))

func _add_tank_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("tank") and not allowed.has("mecha"): return
	pool.append(preload("res://Scenes/Enemies/EnemyTank.tscn"))

func _add_turret_if_allowed(allowed: Array, pool: Array[PackedScene]) -> void:
	if not allowed.has("turret") and not allowed.has("delivery"): return
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
	# Busca puntos de spawn directamente o dentro del contenedor Spawns
	var spawn_container = get_node_or_null("Spawns")
	spawn_points.clear()
	var nodes_to_check: Array = get_children()
	if spawn_container: nodes_to_check.append_array(spawn_container.get_children())
	for child in nodes_to_check:
		if child != spawn_container and child.name.begins_with("Spawn") and child is Node2D:
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

	if maxi(active_enemies, _living_encounter_enemies().size()) >= max_concurrent_enemies:
		return # Esperar a que muera un enemigo

	_spawn_single_enemy()

func _spawn_single_enemy() -> void:
	if spawn_points.is_empty() or enemy_pool.is_empty(): return

	var point = _choose_spawn_point()
	if point == null: return
	var random_enemy_scene = _pick_random_enemy_scene()

	if not random_enemy_scene: return

	var enemy = random_enemy_scene.instantiate()
	_scheduled_enemies.append(weakref(enemy))
	if _is_summoner_scene(random_enemy_scene):
		_spawned_summoners.append(enemy)
	enemy.global_position = point.global_position
	enemy.enemy_died.connect(_on_enemy_died)

	var escaner_lvl = GameData.core_upgrades.get("escaner_objetivos", 0)
	var elite_chance = minf(0.12, _elite_chance + (escaner_lvl * 0.01)) if _elite_chance > 0.0 else 0.0
	if randf() <= elite_chance:
		enemy.is_elite = true

	get_tree().current_scene.call_deferred("add_child", enemy)

	if enemy.has_method("spawn_appear"):
		enemy.call_deferred("spawn_appear")

	active_enemies += 1
	enemies_spawned_so_far += 1

func _pick_random_enemy_scene() -> PackedScene:
	if enemy_pool.is_empty(): return null
	var available_pool = _filter_available_enemy_pool()
	if available_pool.is_empty():
		return null # solo quedaban invocadores y ya hay 2: se espera al próximo turno
	var total_weight := 0.0
	for scene in available_pool: total_weight += float(_enemy_weights.get(_enemy_id(scene.resource_path), 1.0))
	var roll := randf() * total_weight
	for scene in available_pool:
		roll -= float(_enemy_weights.get(_enemy_id(scene.resource_path), 1.0))
		if roll <= 0.0: return scene
	return available_pool.back()

func _filter_available_enemy_pool() -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	var counts := {}
	for enemy in _living_encounter_enemies():
		var id := _enemy_id(enemy.scene_file_path)
		counts[id] = int(counts.get(id, 0)) + 1
	for scene in enemy_pool:
		var id := _enemy_id(scene.resource_path)
		if int(counts.get(id, 0)) >= int(_special_caps.get(id, max_concurrent_enemies)): continue
		result.append(scene)
	return result

# Invocadores de la sala que ya se crearon; incluye los que todavía no entraron
# al árbol (se agregan con call_deferred) para no pasarse del máximo.
var _spawned_summoners: Array[Node] = []

func _count_active_summoners() -> int:
	_spawned_summoners = _spawned_summoners.filter(func(e): return is_instance_valid(e) and not e.is_dying)
	var count = _spawned_summoners.size()
	for e in get_tree().get_nodes_in_group("enemy"):
		if _spawned_summoners.has(e): continue
		if (e is EnemySummoner or e.is_in_group("crypt_summoner")) and not e.is_dying:
			count += 1
	return count

func _is_summoner_scene(scene: PackedScene) -> bool:
	if not scene: return false
	return scene.resource_path.to_lower().contains("summoner")

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
	if room_cleared: return
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
			ProtocolRuntime.heal_player(player, 3)

func _award_clear_scrap() -> void:
	GameData.add_scrap(scrap_reward)
	_show_clear_scrap_text()

func _show_clear_scrap_text() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var floating_node = _create_floating_scrap_reward_node(player.global_position)
	get_tree().current_scene.call_deferred("add_child", floating_node)
	_animate_floating_reward(floating_node)

func _create_floating_scrap_reward_node(player_pos: Vector2) -> Node2D:
	var floating_node = Node2D.new()
	floating_node.global_position = player_pos + Vector2(0.0, -60.0)

	var hbox = _create_scrap_reward_hbox()
	floating_node.add_child(hbox)
	return floating_node

func _create_scrap_reward_hbox() -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 6)
	hbox.custom_minimum_size = Vector2(160, 32)
	hbox.position = Vector2(-80, -16)

	var label = _create_scrap_reward_label()
	hbox.add_child(label)

	var icon = _create_scrap_reward_icon()
	hbox.add_child(icon)
	return hbox

func _create_scrap_reward_label() -> Label:
	var label = Label.new()
	label.text = "+%d" % scrap_reward
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.15, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _create_scrap_reward_icon() -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = preload("res://Art/Scrap/Scrap_icon.png")
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon

func _animate_floating_reward(floating_node: Node2D) -> void:
	var tween = get_tree().create_tween().bind_node(floating_node).set_parallel(true)
	var target_y = floating_node.global_position + Vector2(0.0, -45.0)
	tween.tween_property(floating_node, "global_position", target_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(floating_node, "modulate:a", 0.0, 0.7).set_delay(0.4)
	tween.chain().tween_callback(floating_node.queue_free)

func _play_room_clear_effects() -> void:
	_play_room_clear_sound()
	_play_room_clear_flash()

func _play_room_clear_sound() -> void:
	var stream: AudioStream = preload("res://Audio/Sfx/Room_clear/Room_clear.wav")
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
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

func get_nav_path(from_pos: Vector2, to_pos: Vector2, clearance: float = 10.0) -> PackedVector2Array:
	if not _enemy_navigation:
		_enemy_navigation = preload("res://Scripts/World/enemy_navigation.gd").new(self)
	return _enemy_navigation.get_path(from_pos, to_pos, clearance)

func _get_legacy_nav_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
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

func _enemy_id(path: String) -> String:
	return str(ENEMY_IDS.get(path.get_file().get_basename(), "other"))

func _living_encounter_enemies() -> Array[Node]:
	var result: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.get("is_dying") != true:
			result.append(enemy)
	_scheduled_enemies = _scheduled_enemies.filter(func(ref): return is_instance_valid(ref.get_ref()))
	for ref in _scheduled_enemies:
		var enemy = ref.get_ref()
		if not enemy.is_queued_for_deletion() and not enemy.is_dying and not result.has(enemy): result.append(enemy)
	return result

func _choose_spawn_point() -> Node2D:
	var player := GameData.get_player()
	var living := _living_encounter_enemies()
	var best: Node2D = null
	var best_score := -INF
	for point in spawn_points:
		if not is_instance_valid(point): continue
		var distance: float = point.global_position.distance_to(player.global_position) if is_instance_valid(player) else 300.0
		if distance < 100.0: continue
		var clearance := 100.0
		for enemy in living: clearance = minf(clearance, point.global_position.distance_to(enemy.global_position))
		if clearance < 35.0: continue
		var score := minf(distance, 320.0) * 0.25 + clearance + randf_range(0, 30)
		if score > best_score:
			best_score = score
			best = point
	return best
