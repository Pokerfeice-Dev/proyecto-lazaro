extends Node
class_name QualityManager

## Calidad gráfica: Alta, Media o Baja (Opciones > Video > Calidad gráfica).
## En "Automática" se elige según la placa de video: las integradas (Intel UHD,
## Vega, etc.) arrancan en Baja.
## Lo que más pesa en placas chicas son las luces 2D, después la niebla de la Cripta:
##  - Alta: todo como está diseñado.
##  - Media: sin niebla, sin luces de proyectiles/objetos y solo las 3 luces de
##    ambiente más cercanas al jugador.
##  - Baja: igual que Media pero sin luces de ambiente, y la sala se aclara un poco
##    (CanvasModulate) para compensar y que se siga viendo bien.
## Lo crea GameSettings (autoload) al arrancar.

const HIGH := 1
const MEDIUM := 2
const LOW := 3
const MEDIUM_MAX_LIGHTS := 3
const LOW_BRIGHTEN := 0.5 # cuánto se acerca el color de la sala al blanco en Baja
const DECOR_NAMES := ["torch", "candle", "lampara", "chest", "hologram", "door"]

var level := HIGH
var _timer: Timer

static func detect_level() -> int:
	var gpu := RenderingServer.get_video_adapter_name().to_lower()
	if gpu.contains("geforce") or gpu.contains("nvidia") or gpu.contains("radeon rx") or gpu.contains("rtx"):
		return HIGH
	if gpu.contains("arc"):
		return MEDIUM
	for weak in ["intel", "uhd", "iris", "vega", "radeon(tm)", "graphics", "llvmpipe", "mesa", "basic render", "adreno", "mali"]:
		if gpu.contains(weak): return LOW
	return HIGH

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var gs = get_parent()
	_set_level_from(int(gs.get_value("video", "calidad")))
	gs.setting_changed.connect(_on_setting_changed)
	get_tree().node_added.connect(_on_node_added)
	_timer = Timer.new()
	_timer.wait_time = 0.4
	_timer.timeout.connect(_update_light_budget)
	add_child(_timer)
	_timer.start()
	_apply_to_tree()

func _set_level_from(setting: int) -> void:
	level = detect_level() if setting == 0 else clampi(setting, HIGH, LOW)

func _on_setting_changed(_section: String, key: String, value: Variant) -> void:
	if key != "calidad": return
	_set_level_from(int(value))
	_apply_to_tree()

func _on_node_added(node: Node) -> void:
	if node is PointLight2D or node is CanvasModulate or node.name == "FogOverlay":
		_apply_node.call_deferred(node)

func _apply_to_tree() -> void:
	var stack: Array = [get_tree().root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is PointLight2D or node is CanvasModulate or node.name == "FogOverlay":
			_apply_node(node)
		stack.append_array(node.get_children())
	_update_light_budget()

func _apply_node(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	if node is CanvasModulate:
		_apply_modulate(node)
	elif node is PointLight2D:
		_apply_light(node)
	elif node is CanvasItem:
		node.visible = level == HIGH # niebla

func _apply_modulate(node: CanvasModulate) -> void:
	if not node.has_meta("q_color"): node.set_meta("q_color", node.color)
	var original: Color = node.get_meta("q_color")
	node.color = original.lerp(Color.WHITE, LOW_BRIGHTEN) if level == LOW else original

func _apply_light(light: PointLight2D) -> void:
	if _is_hud_light(light): return
	if not light.has_meta("q_enabled"): light.set_meta("q_enabled", light.enabled)
	var allowed := level == HIGH or (level == MEDIUM and _is_decor(light))
	light.enabled = bool(light.get_meta("q_enabled")) and allowed

# Las luces del HUD (ojos rojos con poca vida) no cuentan.
func _is_hud_light(light: Node) -> bool:
	var p := light.get_parent()
	while p:
		if p is CanvasLayer: return true
		p = p.get_parent()
	return false

# Luces de ambiente: antorchas, velas, lámparas, puertas, cofres, hologramas.
func _is_decor(light: Node) -> bool:
	var p := light.get_parent()
	while p:
		if p.name == "Iluminacion": return true
		p = p.get_parent()
	var path: String = light.owner.scene_file_path.to_lower() if light.owner else ""
	for key in DECOR_NAMES:
		if path.contains(key): return true
	return false

# Media: solo quedan prendidas las MEDIUM_MAX_LIGHTS (3) luces de ambiente más cercanas al jugador.
func _update_light_budget() -> void:
	if level != MEDIUM: return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null: return
	var lights: Array = []
	var stack: Array = [get_tree().current_scene] if get_tree().current_scene else []
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is PointLight2D and node.get_meta("q_enabled", true) and not _is_hud_light(node) and _is_decor(node):
			lights.append(node)
		stack.append_array(node.get_children())
	lights.sort_custom(func(a, b): return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	for i in lights.size():
		lights[i].enabled = i < MEDIUM_MAX_LIGHTS
