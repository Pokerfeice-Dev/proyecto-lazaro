extends Node
## Director de clips para redes (9:16): monta una sala del juego, mueve a Lázaro
## con acciones guionadas y deja que el Movie Maker de Godot grabe cuadro por cuadro.
##
## Vista previa (fotos sueltas en _salida/preview):
##   Godot --path . res://Tools/director_clips/director_clip.tscn -- preview NOMBRE fotos=30,60
## Grabación de una toma (video + audio del juego):
##   Godot --path . --write-movie _salida/NOMBRE.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma NOMBRE
##
## Cada toma es una función «_toma_NOMBRE». Usa el espacio de guardado 99, que se
## borra al terminar, y no toca las opciones guardadas del jugador.

const FPS := 30
const ZOOM_JUEGO := 2.4
var _auto_apuntar := false ## la mira siempre en el enemigo más cercano
## Se graba en horizontal, como se juega de verdad (16:9). La ventana es de 3840x2160 pero el
## juego se ve igual que en 1920x1080: sale más nítido y el montaje recorta lo que necesita.
var ANCHO := 3840
var ALTO := 2160
const BASE := Vector2i(1920, 1080)
const SALIDA := "res://Tools/director_clips/_salida"

var _args: PackedStringArray
var _modo := "toma"
var _nombre := ""
var _fotos: Array[int] = [] # cuadros en los que se saca foto en vista previa
var _reg := {"fps": FPS, "marcas": [], "pos": []}
var _cuadro := 0 # cuadros desde que arrancó la toma

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_args = OS.get_cmdline_user_args()
	if _args.size() > 0: _modo = _args[0]
	if _args.size() > 1: _nombre = _args[1]
	for a in _args:
		if a.begins_with("fotos="):
			for v in a.trim_prefix("fotos=").split(","): _fotos.append(int(v))
		if a.begins_with("cada="): # una foto cada N cuadros
			var paso = int(a.trim_prefix("cada="))
			for k in range(paso, 900, paso): _fotos.append(k)
	if _modo == "preview":
		ANCHO = 1920
		ALTO = 1080
	_preparar_ventana()
	_preparar_partida()
	_correr.call_deferred()

func _preparar_ventana() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(ANCHO, ALTO))
	DisplayServer.window_set_position(Vector2i(0, 0))
	var w = get_window()
	w.content_scale_size = BASE
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# Pantalla limpia y partida de prueba (sin tocar las opciones guardadas).
func _preparar_partida() -> void:
	var gs = get_node_or_null("/root/GameSettings")
	if gs:
		_opcion(gs, "video", "mostrar_fps", false)
		_opcion(gs, "video", "calidad", 1)
		_opcion(gs, "audio", "silenciar_sin_foco", false) # la ventana de grabación puede no tener el foco
		for seccion in gs._values: # la mira va sola al enemigo (aunque el que graba la tenga apagada)
			if gs._values[seccion].has("asistencia_apuntado"): _opcion(gs, seccion, "asistencia_apuntado", true)
	GameData.current_slot = 99
	GameData.reset_data()
	GameData.has_completed_tutorial = true
	GameData.show_title_screen = false
	var dbg = get_node_or_null("/root/DebugMenu")
	if dbg: dbg.visible = false
	# la música se pone en el montaje (el tema completo, sin cortes entre tomas)
	var bus = AudioServer.get_bus_index("Music")
	if bus >= 0: AudioServer.set_bus_mute(bus, true)

func _opcion(gs: Node, seccion: String, clave: String, valor: Variant) -> void:
	if not gs._values.has(seccion): return
	gs._values[seccion][clave] = valor
	gs.setting_changed.emit(seccion, clave, valor)

func _process(_delta: float) -> void:
	_cuadro += 1
	# siempre en modo joystick: la mira apunta sola al enemigo más cercano
	var im = InputMode.instance()
	if is_instance_valid(im) and not im.gamepad:
		im._set_gamepad(true)
	var gs = get_node_or_null("/root/GameSettings")
	if gs and is_instance_valid(gs._fps_layer): gs._fps_layer.visible = false
	# sin carteles de "nuevo en el códice" tapando el HUD
	GameData._codex_toast_queue.clear()
	for n in GameData.get_children():
		if n is CodexToast: n.queue_free()
	GameData._codex_toast_active = false
	var jug = jugador()
	if jug and _auto_apuntar:
		var en = _mas_cercano(jug.global_position)
		if en:
			var im2 = InputMode.instance()
			im2._locked_target = en
			im2.aim_dir = (en.global_position - jug.global_position).normalized()
			im2._has_aimed = true
	if jug and _modo == "toma": # dónde está Lázaro en pantalla (el montaje encuadra con esto)
		var pt = get_viewport().get_canvas_transform() * jug.global_position
		_reg["pos"].append([_cuadro, snappedf(pt.x, 0.1), snappedf(pt.y, 0.1)])
	if _modo == "preview" and _cuadro in _fotos:
		_foto.call_deferred("f%04d" % _cuadro)

func _foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var dir = SALIDA + "/preview/" + _nombre
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var img = get_viewport().get_texture().get_image()
	img.resize(960, 540, Image.INTERPOLATE_BILINEAR) # fotos chicas: solo para revisar
	img.save_png(dir + "/" + nombre + ".png")

## Junta las fotos de vista previa de cada toma en una sola hoja (para revisar rápido).
func _hojas() -> void:
	var pv = SALIDA + "/preview"
	var d = DirAccess.open(pv)
	for sub in d.get_directories():
		var archivos = Array(DirAccess.open(pv + "/" + sub).get_files()).filter(func(f): return f.begins_with("f") and f.ends_with(".png"))
		archivos.sort()
		if archivos.is_empty(): continue
		var w = 480
		var h = 270
		var cols = 4
		var filas = int(ceil(archivos.size() / float(cols)))
		var hoja = Image.create(cols * w, filas * h, false, Image.FORMAT_RGB8)
		for i in archivos.size():
			var img = Image.load_from_file(ProjectSettings.globalize_path(pv + "/" + sub + "/" + archivos[i]))
			img.convert(Image.FORMAT_RGB8)
			img.resize(w, h)
			hoja.blit_rect(img, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
		hoja.save_png(ProjectSettings.globalize_path(pv + "/hoja_" + sub + ".png"))

func _correr() -> void:
	if _modo == "hojas":
		_hojas()
		get_tree().quit()
		return
	var dummy = Node.new()
	get_tree().root.add_child(dummy)
	get_tree().current_scene = dummy
	var f := Callable(self, "_toma_" + _nombre)
	if not f.is_valid():
		push_error("No existe la toma " + _nombre)
	else:
		await f.call()
	_guardar_registro()
	_limpiar_partida()
	get_tree().quit()

func _guardar_registro() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA))
	var f = FileAccess.open(SALIDA + "/" + _nombre + ".json", FileAccess.WRITE)
	f.store_string(JSON.stringify(_reg, "  "))
	f.close()

func _limpiar_partida() -> void:
	var ud = ProjectSettings.globalize_path("user://")
	var d = DirAccess.open(ud)
	if d == null: return
	for fn in d.get_files():
		if "slot_99" in fn: DirAccess.remove_absolute(ud + fn)

# --- Utilidades de toma ---------------------------------------------------------

## Marca un momento de la toma (el montaje corta y ubica textos con estas marcas).
func marca(id: String) -> void:
	_reg["marcas"].append({"id": id, "cuadro": _cuadro, "seg": float(_cuadro) / FPS})

func esperar(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func seg(s: float) -> void:
	await esperar(int(s * FPS))

func sala(ruta: String, zoom: float = 2.4) -> void:
	get_tree().change_scene_to_file(ruta)
	await esperar(3)
	GameData.debug_god_mode = true # Lázaro no muere salvo en la toma de muerte
	var p = jugador()
	if p:
		var cam = p.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.zoom = Vector2(ZOOM_JUEGO, ZOOM_JUEGO) # el zoom normal del juego (el parámetro ya no se usa)
			cam.drag_horizontal_enabled = false # Lázaro siempre al centro del cuadro
			cam.drag_vertical_enabled = false
	_auto_apuntar = true

func camara() -> Camera2D:
	var p = jugador()
	return p.get_node_or_null("Camera2D") as Camera2D if p else null

## Zoom de cámara suave durante «s» segundos (en paralelo con la toma).
func zoom_a(z: float, s: float) -> void:
	var cam = camara()
	if cam: create_tween().tween_property(cam, "zoom", Vector2(z, z), s).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func poner_jugador(pos: Vector2) -> void:
	var p = jugador()
	if p:
		p.global_position = pos
		var cam = camara()
		if cam: cam.reset_smoothing()

## Equipa una sinergia con el menú de trucos. Con aviso=false no sale la ventana
## de "sinergia activada" (para tomas de acción).
func sinergia(funcion: String, aviso: bool = false) -> void:
	var dbg = get_node_or_null("/root/DebugMenu")
	if dbg: dbg.call(funcion)
	if aviso: return
	await esperar(2)
	cerrar_avisos()

## Saca las ventanas de "sinergia activada" y los carteles de objeto nuevo.
func cerrar_avisos() -> void:
	SynergyManager._presentation_queue.clear()
	SynergyManager._presentation_active = false
	for n in get_tree().root.get_children():
		if n.scene_file_path.ends_with("synergy_activation.tscn"):
			n.queue_free()
	GameData._codex_toast_queue.clear()
	GameData._codex_toast_active = false
	for n in GameData.get_children():
		if n is CodexToast: n.queue_free()
	get_tree().paused = false

## Centro del piso de la sala (para dejar a Lázaro en el medio del cuadro).
func centro_sala() -> Vector2:
	# el punto más despejado cerca del centro del PISO: sin jardineras, cajas ni paredes alrededor
	# (los límites de cámara a veces incluyen paredes y vacío)
	var escena = get_tree().current_scene
	var piso = escena.get_node_or_null("Floor") as TileMapLayer
	if piso:
		var objetos = escena.get_node_or_null("Tile_Objects") as TileMapLayer
		var paredes = escena.get_node_or_null("Walls") as TileMapLayer
		var celdas := piso.get_used_cells()
		var centro := Vector2(piso.get_used_rect().get_center())
		var bloqueadas: Array[Vector2i] = []
		for capa in [objetos, paredes]:
			if capa == null: continue
			for c in capa.get_used_cells():
				# las paredes que están sobre el piso o fuera de él; los objetos siempre
				bloqueadas.append(piso.local_to_map(piso.to_local(capa.to_global(capa.map_to_local(c)))))
		var mejor := piso.get_used_rect().get_center()
		var mejor_puntaje := -INF
		for c in celdas:
			var libre := 6.0
			for b in bloqueadas:
				var d := Vector2(c - b).length()
				if d < libre: libre = d
			var puntaje := libre * 4.0 - (Vector2(c) - centro).length()
			if puntaje > mejor_puntaje:
				mejor_puntaje = puntaje
				mejor = c
		return piso.to_global(piso.map_to_local(mejor))
	for capa in get_tree().current_scene.find_children("*", "TileMapLayer", true, false):
		if capa.name.to_lower().begins_with("floor") or capa.name.to_lower().begins_with("piso"):
			return capa.to_global(capa.map_to_local(capa.get_used_rect().get_center()))
	var capas = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
	if capas.is_empty(): return jugador().global_position
	var c = capas[0]
	return c.to_global(c.map_to_local(c.get_used_rect().get_center()))

func arma(ruta: String, cuerpo_a_cuerpo: bool = false) -> void:
	var p = jugador()
	if not p: return
	var cont = p.get("second_weapon") if cuerpo_a_cuerpo else p.get("active_weapon")
	if cont: cont.switch_weapon(load(ruta))

func jugador() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func pulsar(accion: String, fuerza: float = 1.0) -> void:
	Input.action_press(accion, fuerza)

func soltar(accion: String) -> void:
	Input.action_release(accion)

func toque(accion: String) -> void:
	var ev = InputEventAction.new()
	ev.action = accion
	ev.pressed = true
	Input.parse_input_event(ev)
	await esperar(2)
	var ev2 = InputEventAction.new()
	ev2.action = accion
	ev2.pressed = false
	Input.parse_input_event(ev2)

## Camina en una dirección durante «s» segundos.
func caminar(dir: Vector2, s: float) -> void:
	_mover(dir)
	await seg(s)
	_mover(Vector2.ZERO)

func _mover(dir: Vector2) -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]: soltar(a)
	if dir.x < -0.1: pulsar("move_left", -dir.x)
	if dir.x > 0.1: pulsar("move_right", dir.x)
	if dir.y < -0.1: pulsar("move_up", -dir.y)
	if dir.y > 0.1: pulsar("move_down", dir.y)

func enemigo(ruta: String, pos: Vector2) -> Node2D:
	var e = load(ruta).instantiate()
	get_tree().current_scene.add_child(e)
	e.global_position = pos
	return e

func sin_enemigos() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()

## Varios enemigos en círculo alrededor de un punto.
func grupo(ruta: String, centro: Vector2, n: int, radio: float) -> Array:
	var lista = []
	for i in n:
		var a = TAU * float(i) / float(n)
		lista.append(enemigo(ruta, centro + Vector2(cos(a), sin(a)) * radio))
	return lista

func enemigos_vivos() -> int:
	var n = 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e.get("is_dying") != true: n += 1
	return n

## Ataca cuerpo a cuerpo «veces» veces, cada «cada» segundos.
func golpes(veces: int, cada: float = 0.35) -> void:
	for i in veces:
		await toque("attack_melee")
		await seg(cada)

const ENEMIGOS := {
	"perro": "res://Scenes/Enemies/EnemyFollower.tscn",
	"carpintero": "res://Scenes/Enemies/EnemyShooter.tscn",
	"invocador": "res://Scenes/Enemies/EnemySummoner.tscn",
	"mecha": "res://Scenes/Enemies/EnemyTank.tscn",
	"delivery": "res://Scenes/Enemies/EnemyTurret.tscn",
	"maniqui": "res://Scenes/Enemies/Mannequin.tscn",
	"ghoul": "res://Scenes/Enemies/Crypt/CryptGhoul.tscn",
	"gargola": "res://Scenes/Enemies/Crypt/CryptGargoyle.tscn",
	"ciempies": "res://Scenes/Enemies/Crypt/CryptCentipede.tscn",
	"apicultora": "res://Scenes/Enemies/Crypt/CryptDeadBeekeeperSummoner.tscn",
	"ojo": "res://Scenes/Enemies/Crypt/CryptLaserEye.tscn",
}

# --- Tomas ----------------------------------------------------------------------

func _toma_encuadre() -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.4)
	marca("inicio")
	await seg(2.0)
	await caminar(Vector2.RIGHT, 1.0)
	await seg(1.0)

## Para explorar una sala: `-- preview vista sala=Level1_Room2 cada=30`
func _toma_vista() -> void:
	var nombre_sala := "Level1_Room2"
	for a in _args:
		if a.begins_with("sala="): nombre_sala = a.trim_prefix("sala=")
	await sala("res://Scenes/Rooms/%s.tscn" % nombre_sala, 2.4)
	marca("inicio")
	await seg(1.0)
	var p = jugador()
	var c = centro_sala()
	print("VISTA ", nombre_sala, " jugador=", p.global_position, " centro=", c)
	await seg(1.5)

func _toma_combate_prueba() -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.4)
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c)
	await seg(0.2)
	cerrar_avisos()
	grupo(ENEMIGOS["perro"], c + Vector2(0, -20), 3, 150.0)
	enemigo(ENEMIGOS["carpintero"], c + Vector2(120, -90))
	marca("inicio")
	await combate(8.0)
	marca("fin")

# Video 2 (gancho): hachazos que dejan empapados a los enemigos y un disparo que
# los hace explotar en cadena (Oil of the Sick).
func _toma_oil() -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.8)
	await seg(0.5)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(-40, 0))
	await sinergia("_activate_synergy_alto_octanaje")
	await seg(0.3)
	grupo(ENEMIGOS["perro"], c + Vector2(20, 0), 4, 26.0)
	await seg(0.4)
	marca("inicio")
	await golpes(5, 0.32)
	marca("disparo")
	zoom_a(3.4, 0.3)
	pulsar("shoot")
	await seg(0.5)
	soltar("shoot")
	marca("explosion")
	await seg(1.0)
	zoom_a(2.8, 0.6)
	await seg(1.2)
	marca("fin")

## Combate base con el revólver hasta que no queden enemigos (o se acabe el tiempo).
func pelear(tope: float, moverse: bool = true) -> void:
	await combate(tope, moverse)

## Piloto automático que juega como una persona: apunta siempre al enemigo más cercano,
## dispara solo cuando lo tiene en la mira, lo rodea en círculos (sin pegarse a las
## paredes), se aleja si lo tiene muy encima y pega cuerpo a cuerpo si lo alcanza.
func combate(tope: float, moverse: bool = true, cuerpo_a_cuerpo: bool = true) -> void:
	var t := 0.0
	var sentido := 1.0
	var cambio := 0.0
	var golpe_en := 0.0
	while t < tope and enemigos_vivos() > 0:
		var p = jugador()
		if not p: break
		var e = _mas_cercano(p.global_position)
		if e:
			var a: Vector2 = e.global_position - p.global_position
			var d := a.length()
			var dir := a.normalized()
			var im := InputMode.instance() # la mira va sola al blanco
			im._locked_target = e
			im.aim_dir = dir
			im._has_aimed = true
			if moverse:
				cambio -= 1.0 / FPS
				if cambio <= 0.0:
					sentido = -sentido if randf() < 0.5 else sentido
					cambio = randf_range(1.2, 2.2)
				var mov := Vector2(-dir.y, dir.x) * sentido * 0.75
				if d < 80.0: mov -= dir * 1.0
				elif d > 170.0: mov += dir * 0.7
				mov += _empuje_del_borde(p.global_position)
				_mover(mov.limit_length(1.0))
			pulsar("shoot")
			golpe_en -= 1.0 / FPS
			if cuerpo_a_cuerpo and d < 38.0 and golpe_en <= 0.0:
				toque.call("attack_melee")
				golpe_en = 0.45
		else:
			soltar("shoot")
		if _modo == "preview" and _cuadro % 15 == 0 and e:
			print("COMBATE f", _cuadro, " jugador=", p.global_position, " blanco=", e.global_position, " mira=", InputMode.aim_point(p.global_position))
		await get_tree().process_frame
		t += 1.0 / FPS
	_mover(Vector2.ZERO)
	soltar("shoot")

func _mas_cercano(desde: Vector2) -> Node2D:
	var mejor: Node2D = null
	var mejor_d := 520.0
	var candidatos: Array = get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("boss")
	for e in candidatos:
		if not (e is Node2D) or not is_instance_valid(e) or e.get("is_dying") == true or not e.is_visible_in_tree(): continue
		var d := desde.distance_to(e.global_position)
		if d < mejor_d:
			mejor_d = d
			mejor = e
	return mejor

## Rectángulo del piso de la sala (en coordenadas globales).
func piso_sala() -> Rect2:
	var piso = get_tree().current_scene.get_node_or_null("Floor") as TileMapLayer
	if not piso: return Rect2(-300, -200, 600, 400)
	var r := piso.get_used_rect()
	var a := piso.to_global(piso.map_to_local(r.position))
	var b := piso.to_global(piso.map_to_local(r.end))
	return Rect2(a, b - a).abs()

## Empuja hacia adentro cuando Lázaro se acerca a una pared.
func _empuje_del_borde(pos: Vector2) -> Vector2:
	var r := piso_sala().grow(-40.0)
	var v := Vector2.ZERO
	if pos.x < r.position.x + 40: v.x += 1.5
	if pos.x > r.end.x - 40: v.x -= 1.5
	if pos.y < r.position.y + 40: v.y += 1.5
	if pos.y > r.end.y - 40: v.y -= 1.5
	return v

## Camina hacia un punto (pasando por el medio de la sala) hasta llegar o agotar el tiempo.
func ir_a(destino: Vector2, tope: float = 6.0, velocidad: float = 1.0) -> void:
	var t := 0.0
	while t < tope:
		var p = jugador()
		if not p: break
		var a: Vector2 = destino - p.global_position
		if a.length() < 14.0: break
		_mover((a.normalized() + _empuje_del_borde(p.global_position) * 0.5).limit_length(1.0) * velocidad)
		await get_tree().process_frame
		t += 1.0 / FPS
	_mover(Vector2.ZERO)

# --- Video 1: Lázaro está hecho de partes -------------------------------------

const PARTES := {
	"piernas_caninas": "res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres",
	"torso_canino": "res://Art/Items/Player/Body/Item3_TorsoEspinado.tres",
	"brazo_canino": "res://Art/Items/Player/Arms/Item4_BrazoArmado.tres",
	"cabeza_perro": "res://Art/Items/Weapons/Item4.tres",
}

# Mata a dos perros, cae una pierna nueva y Lázaro la agarra.
func _toma_partes_drop() -> void:
	await sala("res://Scenes/Rooms/Level1_Room3.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(-60, 20))
	await seg(0.2)
	cerrar_avisos()
	grupo(ENEMIGOS["perro"], c + Vector2(40, 0), 2, 20.0)
	marca("inicio")
	await pelear(4.0, false)
	marca("cae_pieza")
	Inventory.drop_on_floor(load(PARTES["piernas_caninas"]), c + Vector2(30, 10))
	await seg(1.0)
	await caminar(Vector2(1, -0.1), 0.9)
	marca("agarra")
	await toque("interact")
	await seg(1.5)
	marca("fin")

# El inventario con el cuerpo armado de piezas.
func _toma_partes_inventario() -> void:
	await sala("res://Scenes/Rooms/Level1_Room3.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	poner_jugador(centro_sala())
	await sinergia("_activate_synergy_musculoso")
	await sinergia("_activate_synergy_holy_fire")
	await seg(0.4)
	cerrar_avisos()
	marca("inicio")
	await toque("toggle_inventory")
	await seg(1.2)
	marca("abierto")
	for d in ["ui_right", "ui_right", "ui_down", "ui_down", "ui_left"]:
		await toque(d)
		await seg(0.8)
	marca("fin")

# Tres piezas de perro forman Instinto Canino: aparece la ventana de sinergia.
func _toma_partes_aviso() -> void:
	await sala("res://Scenes/Rooms/Level1_Room3.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	poner_jugador(centro_sala())
	await seg(0.3)
	cerrar_avisos()
	marca("inicio")
	sinergia("_activate_synergy_canino", true)
	await seg(4.5)
	marca("fin")

# Con Instinto Canino: dos armas cuerpo a cuerpo y el dash que activa la furia.
func _toma_partes_canino() -> void:
	await sala("res://Scenes/Rooms/Level1_Room3.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(-50, 0))
	await sinergia("_activate_synergy_canino")
	grupo(ENEMIGOS["perro"], c + Vector2(40, 0), 4, 30.0)
	await seg(0.3)
	marca("inicio")
	await toque("dash")
	for i in 8:
		await toque("shoot")
		await golpes(1, 0.2)
	marca("fin")

# --- Video 2: sinergias -----------------------------------------------------

func _toma_sinergia_aviso() -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	poner_jugador(centro_sala())
	await seg(0.3)
	cerrar_avisos()
	marca("inicio")
	sinergia("_activate_synergy_snowman", true)
	await seg(4.5)
	marca("fin")

## Una sinergia de disparo contra una fila de enemigos.
func _vitrina(funcion: String, tipo: String, n: int, mantener: float) -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.6)
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(0, 110))
	await sinergia(funcion)
	# maniquíes quietos en abanico arriba de Lázaro: el efecto de la sinergia se ve entero
	for i in n:
		var x = (float(i) - (n - 1) / 2.0) * 45.0
		enemigo(ENEMIGOS[tipo], c + Vector2(x, -60 - 25.0 * float(i % 2)))
	await seg(0.3)
	marca("inicio")
	pulsar("shoot")
	await seg(mantener)
	soltar("shoot")
	await seg(0.6)
	marca("fin")

func _toma_avalanche() -> void:
	await _vitrina("_activate_synergy_snowman", "perro", 4, 3.0)

func _toma_colmena() -> void:
	await _vitrina("_activate_synergy_mente_colmena", "maniqui", 3, 3.0)

func _toma_minigun() -> void:
	await _vitrina("_activate_synergy_minigun", "maniqui", 3, 3.5)

func _toma_bride() -> void:
	await _vitrina("_activate_synergy_the_bride", "perro", 5, 3.0)

func _toma_holy() -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(-30, 0))
	await sinergia("_activate_synergy_holy_fire")
	grupo(ENEMIGOS["perro"], c + Vector2(30, 0), 4, 35.0)
	await seg(0.3)
	marca("inicio")
	await golpes(6, 0.35)
	await seg(0.6)
	marca("fin")

# --- Video 3: Distrito Asphodel ---------------------------------------------

func _toma_asphodel_sala() -> void:
	await sala("res://Scenes/Rooms/Level1_Room1.tscn")
	marca("inicio")
	await seg(1.2) # se ve el cartel de la sala
	var c = centro_sala()
	await ir_a(c, 3.5)
	sin_enemigos()
	await seg(0.2)
	var pj = jugador().global_position # donde quedó realmente (ir_a tiene tope de tiempo)
	marca("pelea")
	grupo(ENEMIGOS["perro"], pj + Vector2(0, -130), 3, 40.0)
	enemigo(ENEMIGOS["carpintero"], pj + Vector2(150, -80))
	await pelear(7.0)
	marca("fin")

func _toma_asphodel_mix() -> void:
	await sala("res://Scenes/Rooms/Level1_Room4.tscn")
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(0, 70))
	await seg(0.2)
	cerrar_avisos()
	enemigo(ENEMIGOS["mecha"], c + Vector2(-140, -80))
	enemigo(ENEMIGOS["carpintero"], c + Vector2(140, -90))
	enemigo(ENEMIGOS["delivery"], c + Vector2(0, -150))
	enemigo(ENEMIGOS["invocador"], c + Vector2(150, 40))
	await seg(0.5)
	marca("inicio")
	await pelear(8.0)
	marca("fin")

func _toma_ygor() -> void:
	await sala("res://Scenes/Rooms/Level1_Room12(Ygor1).tscn")
	marca("inicio")
	await seg(1.5)
	var ygor = get_tree().current_scene.get_node_or_null("Ygor") as Node2D
	var meta = (ygor.global_position + Vector2(0, 60)) if ygor else centro_sala()
	await ir_a(meta, 6.0, 0.8)
	await seg(2.0)
	marca("fin")

func _toma_tesoro() -> void:
	await sala("res://Scenes/Rooms/Level1_Room11(treasure).tscn")
	marca("inicio")
	await seg(1.5)
	var cofre = get_tree().current_scene.get_node_or_null("Chest_Trap") as Node2D
	var meta = (cofre.global_position + Vector2(0, 70)) if cofre else centro_sala()
	await ir_a(meta, 6.0, 0.8)
	await seg(2.0)
	marca("fin")

func _toma_jefe1() -> void:
	await sala("res://Scenes/Rooms/Level1_Room15-BossFight.tscn")
	marca("inicio")
	await seg(5.0)
	marca("pelea")
	await pelear(8.0)
	marca("fin")

# --- Video 4: O.M.N.I.A. ----------------------------------------------------

func _toma_muerte() -> void:
	await sala("res://Scenes/Rooms/Level1_Room2.tscn", 2.8)
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c)
	GameData.add_scrap(37)
	GameData.debug_god_mode = false
	grupo(ENEMIGOS["perro"], c + Vector2(50, 0), 5, 30.0)
	var p = jugador()
	p.stats.current_health = 3
	p.stats.health_changed.emit(3, p.stats.max_health)
	marca("inicio")
	await seg(5.0)
	marca("fin")

func _toma_lab() -> void:
	await sala("res://Scenes/Rooms/lab_room.tscn")
	marca("inicio")
	await seg(1.2)
	var cartel = get_tree().current_scene.get_node_or_null("InfoSign_Omnia") as Node2D
	var meta = (cartel.global_position + Vector2(0, 60)) if cartel else centro_sala()
	await ir_a(meta, 6.0, 0.8)
	await seg(1.2)
	marca("fin")

func _toma_omnia() -> void:
	GameData.scrap = 900
	await sala("res://Scenes/Rooms/lab_room.tscn", 2.4)
	await seg(1.0)
	var menu = OmniaMenu.new()
	get_tree().root.add_child(menu)
	marca("inicio")
	await seg(1.5)
	for d in ["ui_down", "ui_down", "ui_tab_next", "ui_down", "ui_tab_next", "ui_right", "ui_tab_next"]:
		await toque(d)
		await seg(1.0)
	marca("fin")

# --- Video 5: La Cripta (en desarrollo) -----------------------------------------

func _toma_cripta() -> void:
	await sala("res://Scenes/Rooms/Level2_Room2.tscn")
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(0, 70))
	await seg(0.2)
	cerrar_avisos()
	enemigo(ENEMIGOS["ghoul"], c + Vector2(-150, -70))
	enemigo(ENEMIGOS["gargola"], c + Vector2(150, -80))
	enemigo(ENEMIGOS["ciempies"], c + Vector2(0, -150))
	enemigo(ENEMIGOS["ojo"], c + Vector2(170, 30))
	await seg(0.5)
	marca("inicio")
	await pelear(8.0)
	marca("fin")

func _toma_apicultora() -> void:
	await sala("res://Scenes/Rooms/Level2_Room3.tscn")
	await seg(0.4)
	sin_enemigos()
	var c = centro_sala()
	poner_jugador(c + Vector2(0, 80))
	await seg(0.2)
	cerrar_avisos()
	enemigo(ENEMIGOS["apicultora"], c + Vector2(0, -110))
	marca("inicio")
	await seg(2.0)
	await pelear(7.0)
	marca("fin")

func _toma_primogenito() -> void:
	await sala("res://Scenes/Rooms/Level2_Room14BossFight.tscn")
	marca("inicio")
	await seg(5.0)
	marca("pelea")
	await pelear(8.0)
	marca("fin")
