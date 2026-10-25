class_name BossLaserFX
extends Node2D
## Haz local en capas con distorsión térmica/blur ambiental de pantalla.
const CORE_WIDTH := 10.0
const DISTORTION_WIDTH := 44.0

var origin := Vector2.ZERO
var endpoint := Vector2.DOWN * 300.0
var normal := Vector2.UP
var charge := 0.0
var live := false
var collision := false
var power := 0.0
var clock := 0.0
var firing_age := 0.0

var _sparks: CPUParticles2D
var _muzzle: CPUParticles2D
var _distortion_mesh: MeshInstance2D
var _distortion_mat: ShaderMaterial
var _active := false
var _beam_started := false

func _ready() -> void:
	z_index = 35
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	
	_setup_particles()
	_setup_distortion_mesh()
	hide()

func _setup_particles() -> void:
	_sparks = _particles(18 if OS.has_feature("web") else 30, 0.26)
	_sparks.gravity = Vector2(0, 110)
	_sparks.initial_velocity_min = 65
	_sparks.initial_velocity_max = 165
	_sparks.spread = 65
	
	_muzzle = _particles(8 if OS.has_feature("web") else 14, 0.22)
	_muzzle.initial_velocity_min = 12
	_muzzle.initial_velocity_max = 45
	_muzzle.spread = 180

func _setup_distortion_mesh() -> void:
	var shader = load("res://Art/Effects/laser_distortion.gdshader")
	if shader:
		_distortion_mat = ShaderMaterial.new()
		_distortion_mat.shader = shader
		_distortion_mat.set_shader_parameter("distortion_strength", 0.032)
		_distortion_mat.set_shader_parameter("chromatic_aberration", 0.015)
		_distortion_mat.set_shader_parameter("blur_amount", 1.8)
		_distortion_mat.set_shader_parameter("heat_speed", 20.0)

		_distortion_mesh = MeshInstance2D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		_distortion_mesh.mesh = quad
		_distortion_mesh.material = _distortion_mat
		_distortion_mesh.z_index = -1
		_distortion_mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(_distortion_mesh)

func _particles(amount: int, lifetime: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.emitting = false
	particles.amount = amount
	particles.lifetime = lifetime
	particles.local_coords = false
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 3.0
	particles.use_parent_material = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color("fff5ca"))
	ramp.add_point(0.3, Color("ff5736"))
	ramp.add_point(0.55, Color("e259ff"))
	ramp.add_point(0.75, Color("59cfff"))
	ramp.set_color(1, Color(0.7, 0.03, 0.1, 0))
	particles.color_ramp = ramp
	add_child(particles)
	return particles

func update_beam(start: Vector2, finish: Vector2, progress: float, firing: bool, hit: bool, hit_normal: Vector2) -> void:
	origin = start
	endpoint = finish
	charge = progress
	collision = hit
	normal = hit_normal
	if firing and not live: firing_age = 0.0
	live = firing
	_beam_started = firing
	_active = true
	power = 1.0
	show()
	_sparks.position = endpoint
	_sparks.direction = normal
	_sparks.emitting = live and collision
	_muzzle.position = origin
	_muzzle.emitting = live or charge > 0.3

func stop(immediate: bool = false) -> void:
	_active = false
	live = false
	if is_instance_valid(_sparks): _sparks.emitting = false
	if is_instance_valid(_muzzle): _muzzle.emitting = false
	if is_instance_valid(_distortion_mesh): _distortion_mesh.hide()
	if immediate:
		power = 0.0
		hide()

func _process(delta: float) -> void:
	clock += delta
	if live: firing_age += delta
	if not _active:
		power = move_toward(power, 0.0, delta * 6.0)
		if power <= 0.0: hide()
	
	_update_distortion_mesh()
	if visible: queue_redraw()

func _update_distortion_mesh() -> void:
	if not is_instance_valid(_distortion_mesh):
		return
	if not live or power <= 0.0:
		_distortion_mesh.hide()
		return
	
	var length = origin.distance_to(endpoint)
	if length < 2.0:
		_distortion_mesh.hide()
		return
	
	var dir = (endpoint - origin).normalized()
	var canvas := get_global_transform_with_canvas()
	var screen_dir := ((canvas * endpoint) - (canvas * origin)).normalized()
	_distortion_mat.set_shader_parameter("screen_normal", screen_dir.orthogonal())
	_distortion_mesh.position = (origin + endpoint) * 0.5
	_distortion_mesh.rotation = dir.angle()
	_distortion_mesh.scale = Vector2(length, DISTORTION_WIDTH * power)
	_distortion_mesh.show()

func _draw() -> void:
	if power <= 0.0: return
	var direction := (endpoint - origin).normalized()
	var side := direction.orthogonal()
	var length := origin.distance_to(endpoint)
	if not _beam_started:
		# Aviso fino, discontinuo y sin daño. La trayectoria queda fija al cargar.
		var dash_count := mini(80, int(length / 14.0))
		for i in dash_count:
			var start := origin + direction * (float(i) * 14.0)
			draw_line(start.round(), (start + direction * 7.0).round(), Color(1, 0.25, 0.1, (0.3 + charge * 0.5) * power), 1.0)
		for i in 10:
			var angle := float(i) * TAU / 10.0 + clock * 2
			var point := origin + Vector2.from_angle(angle) * lerpf(28, 5, charge)
			draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(1, 0.55, 0.2, charge))
		draw_arc(origin, 7 + charge * 4, 0, TAU, 12, Color(1, 0.35, 0.15, 0.8), 2.0)
		return
	var pulse := 0.9 + sin(clock * 34.0) * 0.1
	var ignition := maxf(0, 1.0 - firing_age / 0.12)
	var energy := Color("ff6638").lerp(Color("ee48ff"), 0.5 + 0.5 * sin(clock * 4.5))
	_draw_electric_arcs(direction, side, length, energy)
	# El halo es decorativo; el núcleo es la línea peligrosa.
	draw_line(origin, endpoint, Color(energy, 0.15 * power), 29 * pulse)
	draw_line(origin, endpoint, Color(energy, 0.38 * power), 18 * pulse)
	draw_line(origin, endpoint, Color(energy, 0.95 * power), CORE_WIDTH + ignition * 3)
	draw_line(origin, endpoint, Color(1, 0.96, 0.78, power), 4.0 + pulse)
	var points := PackedVector2Array()
	var segments := clampi(int(length / 16), 2, 64)
	for i in range(segments + 1):
		var t := float(i) / segments
		var wave := sin(t * length * 0.1 - clock * 24) * 2.5 * sin(t * PI)
		points.append((origin.lerp(endpoint, t) + side * wave).round())
	draw_polyline(points, Color(1, 0.8, 0.35, power), 2.0)
	# Dos filamentos helicoidales giran alrededor del núcleo blanco.
	for strand in 2:
		var helix := PackedVector2Array()
		for i in range(segments + 1):
			var t := float(i) / segments
			var wave := sin(t * length * 0.065 - clock * 16 + strand * PI)
			helix.append((origin.lerp(endpoint, t) + side * wave * 9 * sin(t * PI)).round())
		var tint := Color("65eaff") if strand == 0 else Color("ffbaff")
		draw_polyline(helix, Color(tint, power * 0.8), 2.0)
	# Paquetes de energía que recorren el rayo sin crear nodos.
	for i in 6:
		var t := fposmod(clock * 1.8 + float(i) / 6.0, 1.0)
		var pos := origin.lerp(endpoint, t)
		draw_line(pos - side * 5, pos + side * 5, Color(1, 1, 0.85, power * 0.7), 2.0)
	_draw_flare(origin, 12 + ignition * 10, power)
	if collision:
		_draw_flare(endpoint, 8 * pulse, power)
		draw_arc(endpoint, 12 * pulse, clock * 7, clock * 7 + PI, 8, Color(1, 0.35, 0.12, power * 0.8), 2.0)
		for ring in 3:
			var phase := fposmod(clock * 3.0 + float(ring) / 3.0, 1.0)
			draw_arc(endpoint, 5 + phase * 27, clock * 4 + ring, clock * 4 + ring + PI * 1.3, 10, Color(energy, (1 - phase) * power * 0.65), 2)

func _draw_electric_arcs(direction: Vector2, side: Vector2, length: float, energy: Color) -> void:
	# Descargas cortas decorativas, con geometría escalonada a 18 Hz.
	# Cantidad acotada: no crea nodos ni partículas por fotograma.
	var count := clampi(int(length / 55), 3, 10)
	if OS.has_feature("web"): count = mini(count, 6)
	var tick := floorf(clock * 18)
	for i in count:
		var seed := float(i) * 17.13 + tick * 3.71
		var life := fposmod(clock * 5 + float(i) * 0.37, 1.0)
		var alpha := sin(life * PI) * power
		var t := (float(i) + 0.5 + sin(seed) * 0.25) / count
		var start := origin.lerp(endpoint, t)
		var sign_side := 1.0 if i % 2 == 0 else -1.0
		var reach := (14 + 20 * (0.5 + 0.5 * sin(seed * 1.7))) * sin(life * PI)
		var bolt := PackedVector2Array([start.round()])
		for step in range(1, 5):
			var progress := float(step) / 4.0
			var bend := sin(seed + step * 2.4) * 9 * sin(progress * PI)
			bolt.append((start + side * sign_side * reach * progress + direction * (progress * 12 + bend)).round())
		var tint := Color("70dcff") if i % 3 == 0 else energy.lerp(Color.WHITE, 0.35)
		draw_polyline(bolt, Color(tint, alpha * 0.18), 6)
		draw_polyline(bolt, Color(tint, alpha * 0.9), 2)
		var fork := bolt[2] + direction * (10 + sin(seed) * 5) + side * sign_side * 7
		draw_polyline(PackedVector2Array([bolt[1], bolt[2], fork.round()]), Color(tint, alpha * 0.65), 1)
		draw_rect(Rect2(bolt[4] - Vector2.ONE, Vector2(2, 2)), Color(0.9, 1, 1, alpha))

func _draw_flare(point: Vector2, radius: float, alpha: float) -> void:
	draw_circle(point, radius, Color(1, 0.15, 0.05, alpha * 0.25))
	draw_line(point - Vector2(radius, 0), point + Vector2(radius, 0), Color(1, 0.8, 0.4, alpha), 3)
	draw_line(point - Vector2(0, radius), point + Vector2(0, radius), Color(1, 0.6, 0.2, alpha), 2)
	draw_rect(Rect2(point.round() - Vector2(3, 3), Vector2(6, 6)), Color(1, 1, 0.85, alpha))
