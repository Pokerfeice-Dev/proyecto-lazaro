extends RefCounted
class_name PuddleVisuals

## Arte de los charcos de los barriles (fuego y hielo) con el estilo pixel del
## juego: la mancha se arma pixel a pixel en una imagen chica (borde irregular
## con ruido, bandas de color como una paleta de tiles y tramado), y las
## partículas son cuadraditos de 1-3 px. Cada charco sale un poco distinto.
## Lo usa ElementalPuddle; acá solo está lo visual.

## La mancha se arma a media resolución y se dibuja al doble (PIXEL), así cada
## pixel del charco mide lo mismo que los de los sprites.
const PIXEL := 2
const SIZE := Vector2i(50, 42)

# Paletas de afuera hacia adentro: [quemado/borde, anillo, cuerpo, centro, brillo]
const FIRE_PALETTE := [
	Color("#2a110c"), Color("#6e2010"), Color("#b83d16"), Color("#e8782a"), Color("#ffd36a"),
]
const ICE_PALETTE := [
	Color("#2f6f9e"), Color("#4fa3d6"), Color("#93d9f2"), Color("#c9f1fb"), Color("#ffffff"),
]
## Bilis del jefe de La Cripta (El Primogénito).
const BILE_PALETTE := [
	Color("#1d2a0e"), Color("#3e5a14"), Color("#6f9a1c"), Color("#a6cf2e"), Color("#e4f78a"),
]

## Textura de la mancha. fire = true para el charco de fuego.
static func build_texture(fire: bool, seed_value: int) -> ImageTexture:
	var img = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.14
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var pal = FIRE_PALETTE if fire else ICE_PALETTE
	for y in SIZE.y:
		for x in SIZE.x:
			var c = _pixel_color(x, y, noise, pal, fire)
			if c.a > 0.0:
				img.set_pixel(x, y, c)
	if fire:
		_add_speckles(img, rng, pal[4], 6, 0.45)
	else:
		_add_cracks(img, rng, pal[4])
		_add_speckles(img, rng, pal[4], 4, 0.4)
	return ImageTexture.create_from_image(img)

## Mancha de bilis: mismas bandas que el fuego, con burbujas claras sueltas.
static func build_bile_texture(seed_value: int) -> ImageTexture:
	var img = Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var noise = FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.16
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in SIZE.y:
		for x in SIZE.x:
			var c = _pixel_color(x, y, noise, BILE_PALETTE, true)
			if c.a > 0.0:
				img.set_pixel(x, y, c)
	_add_speckles(img, rng, BILE_PALETTE[4], 9, 0.42)
	return ImageTexture.create_from_image(img)

# Banda de color según qué tan adentro del charco está el pixel (con un poco de
# ruido en el borde para que no sea un óvalo perfecto).
static func _pixel_color(x: int, y: int, noise: FastNoiseLite, pal: Array, fire: bool) -> Color:
	var dx = x - SIZE.x / 2.0
	var dy = y - SIZE.y / 2.0
	var d = Vector2(dx / (SIZE.x * 0.42), dy / (SIZE.y * 0.42)).length()
	var edge = d + noise.get_noise_2d(x, y) * (0.2 if fire else 0.12)
	var checker = (x + y) % 2 == 0
	if fire:
		if edge > 1.14: return Color(0, 0, 0, 0)
		if edge > 1.0: return Color(pal[0], 0.5) if checker else Color(0, 0, 0, 0) # quemado tramado
		if edge > 0.88: return Color(pal[0], 0.85)
		if edge > 0.72: return pal[1]
		if edge > 0.45: return pal[2]
		if edge > 0.16: return pal[3]
		return pal[4] if checker else pal[3]
	if edge > 1.04: return Color(0, 0, 0, 0)
	if edge > 0.95: return Color(pal[3], 0.85) # escarcha del borde
	if edge > 0.84: return Color(pal[0], 0.8)
	if edge > 0.6: return Color(pal[1], 0.85)
	# placa de hielo con dos reflejos en diagonal
	var glare = dx + dy * 1.2
	if absf(glare + 6.0) < 1.2 or absf(glare + 2.0) < 0.6:
		return Color(pal[3], 0.95)
	return Color(pal[2], 0.85)

# Pixeles sueltos más claros (chispitas en el fuego, reflejos en el hielo).
static func _add_speckles(img: Image, rng: RandomNumberGenerator, color: Color, count: int, max_radius: float) -> void:
	for i in count:
		var p = _random_inside(rng, max_radius)
		if img.get_pixelv(p).a > 0.5:
			img.set_pixelv(p, color)

# Grietas del hielo: líneas de pixeles que salen del centro y se quiebran.
static func _add_cracks(img: Image, rng: RandomNumberGenerator, color: Color) -> void:
	var center = Vector2(SIZE) / 2.0
	for i in 2:
		var pos = center + Vector2(rng.randf_range(-6, 6), rng.randf_range(-5, 5))
		var angle = rng.randf_range(0, TAU)
		for step in rng.randi_range(4, 8):
			angle += rng.randf_range(-0.5, 0.5)
			pos += Vector2.from_angle(angle)
			var p = Vector2i(pos.round())
			if p.x < 0 or p.y < 0 or p.x >= SIZE.x or p.y >= SIZE.y: break
			if img.get_pixelv(p).a < 0.5: break
			img.set_pixelv(p, Color(color, 0.95))

static func _random_inside(rng: RandomNumberGenerator, max_radius: float) -> Vector2i:
	var a = rng.randf_range(0, TAU)
	var r = sqrt(rng.randf()) * max_radius
	return Vector2i(int(SIZE.x / 2.0 + cos(a) * r * SIZE.x), int(SIZE.y / 2.0 + sin(a) * r * SIZE.y))

# --- Partículas (cuadraditos, sin textura, así quedan pixel) ---

static func fire_embers() -> CPUParticles2D:
	var p = _base_particles(16, 0.9, Vector2(34, 22))
	p.direction = Vector2.UP
	p.spread = 30.0
	p.gravity = Vector2(0, -40)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 20.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 2.0
	p.color_ramp = _gradient([Color("#ffe27a"), Color("#ff9a2e"), Color(0.8, 0.15, 0.05, 0.0)])
	p.material = _additive()
	return p

static func fire_smoke() -> CPUParticles2D:
	var p = _base_particles(6, 1.5, Vector2(26, 16))
	p.direction = Vector2.UP
	p.spread = 20.0
	p.gravity = Vector2(0, -18)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 10.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 4.0
	p.color_ramp = _gradient([Color(0.15, 0.1, 0.1, 0.0), Color(0.18, 0.12, 0.12, 0.3), Color(0.2, 0.2, 0.2, 0.0)])
	return p

static func ice_glints() -> CPUParticles2D:
	var p = _base_particles(7, 1.3, Vector2(34, 24))
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 2.0
	p.color_ramp = _gradient([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(0.8, 0.95, 1.0, 0.0)])
	p.material = _additive()
	return p

static func ice_mist() -> CPUParticles2D:
	var p = _base_particles(10, 1.8, Vector2(36, 24))
	p.direction = Vector2.UP
	p.spread = 25.0
	p.gravity = Vector2(0, -5)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 4.0
	p.scale_amount_max = 4.0
	p.color_ramp = _gradient([Color(0.8, 0.95, 1.0, 0.0), Color(0.8, 0.95, 1.0, 0.28), Color(0.6, 0.85, 1.0, 0.0)])
	return p

## Llamarada corta como la del lanzallamas, apuntando hacia arriba.
static func flame_burst() -> FlameConeParticles:
	var f = FlameConeParticles.new()
	f.amount = 48
	f.lifetime = 0.42
	f.scale_amount_min = 6.0
	f.scale_amount_max = 6.0
	f.z_index = 4
	f.rotation = -PI / 2.0
	f.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 7.0
	f.set_cone(randf_range(48.0, 72.0), randf_range(18.0, 26.0))
	return f

## Burbujas que suben de la bilis.
static func bile_bubbles() -> CPUParticles2D:
	var p = _base_particles(12, 0.8, Vector2(30, 18))
	p.direction = Vector2(0, -1)
	p.spread = 12.0
	p.gravity = Vector2(0, -18)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 16.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.color_ramp = _gradient([Color(BILE_PALETTE[4], 0.0), Color(BILE_PALETTE[3], 0.9), Color(BILE_PALETTE[2], 0.0)])
	return p

static func _base_particles(amount: int, lifetime: float, extents: Vector2) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.z_as_relative = false
	p.z_index = 3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return p

static func _gradient(colors: Array) -> Gradient:
	var g = Gradient.new()
	g.set_color(0, colors[0])
	g.set_color(1, colors[colors.size() - 1])
	for i in range(1, colors.size() - 1):
		g.add_point(float(i) / (colors.size() - 1), colors[i])
	return g

static func _additive() -> CanvasItemMaterial:
	var m = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m
