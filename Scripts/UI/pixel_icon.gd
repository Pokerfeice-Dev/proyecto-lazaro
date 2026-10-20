class_name PixelIcon
extends RefCounted

## Íconos de pixel art con densidad pareja en toda la UI.
## Los sprites del juego vienen en tamaños muy distintos (objetos de 32 px,
## armas en lienzos de 128 px con mucho aire, hojas con varios cuadros...).
## Si cada uno se estira para llenar su marco, uno termina con píxeles enormes
## y otro con píxeles diminutos. Acá cada ícono:
##   1. usa solo el primer cuadro si la textura es una hoja,
##   2. se recorta al dibujo (sin el borde transparente),
##   3. se agranda por un número entero fijo según el contexto (SLOT, DETAIL...),
##      así los píxeles miden lo mismo en todos los íconos de ese lugar.
## Solo si el dibujo no entra en el marco baja de escala (sigue siendo entera
## mientras se pueda).
## Uso:
##   PixelIcon.apply(texture_rect, item.icon, PixelIcon.SLOT)
##   var rect = PixelIcon.make(item.icon, 72.0, PixelIcon.DETAIL)

## Escalas por contexto (píxeles de pantalla por píxel del sprite).
## FIT: la mayor escala entera que entra (para un sprite solo en grande).
const FIT := 0
const WEAPON := 2
const SLOT := 3
const CARD := 3
const DETAIL := 3
const HERO := 4

static var _cache: Dictionary = {}

## Crea un TextureRect ya preparado de "box" x "box".
static func make(tex: Texture2D, box: float, scale: int = DETAIL) -> TextureRect:
	var rect = TextureRect.new()
	rect.custom_minimum_size = Vector2(box, box)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	apply(rect, tex, scale, Vector2(box, box))
	return rect

## Como UIStyle.icon, pero los sprites de pixel art van a escala entera.
## Los íconos vectoriales (SVG de la UI) se siguen estirando al tamaño pedido.
static func icon(tex: Texture2D, box: float, scale: int = SLOT) -> TextureRect:
	if tex and tex.resource_path.get_extension().to_lower() == "svg":
		return UIStyle.icon(tex, box)
	return make(tex, box, scale)

## Pone el ícono en un TextureRect existente sin estirarlo: el TextureRect lo
## muestra centrado a tamaño real y la escala ya viene aplicada.
## "box" es el lugar disponible; si no se pasa, se usa el tamaño del rect.
static func apply(rect: TextureRect, tex: Texture2D, scale: int = SLOT, box: Vector2 = Vector2.ZERO) -> void:
	if not rect: return
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if box == Vector2.ZERO:
		box = rect.custom_minimum_size if rect.custom_minimum_size != Vector2.ZERO else rect.size
	rect.texture = scaled(tex, scale, box)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED

## Primer cuadro recortado y agrandado por "scale" (o menos, si no entra en "box").
static func scaled(tex: Texture2D, scale: int, box: Vector2) -> Texture2D:
	if not tex: return null
	var key = "%d|%d|%d|%d" % [tex.get_rid().get_id(), scale, int(box.x), int(box.y)]
	if _cache.has(key): return _cache[key]
	var img = first_frame_image(tex)
	if not img: return tex
	var s = _fit_scale(Vector2(img.get_size()), scale, box)
	var target = (Vector2(img.get_size()) * s).round()
	img.resize(maxi(1, int(target.x)), maxi(1, int(target.y)), Image.INTERPOLATE_NEAREST)
	var out = ImageTexture.create_from_image(img)
	_cache[key] = out
	return out

## Imagen del primer cuadro, recortada al dibujo.
static func first_frame_image(tex: Texture2D) -> Image:
	var img: Image
	if tex is AtlasTexture and tex.atlas:
		var src = tex.atlas.get_image()
		if not src: return null
		img = src.get_region(Rect2i(tex.region))
	else:
		img = tex.get_image()
	if not img: return null
	img = img.duplicate()
	if img.is_compressed(): img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var frames = sheet_frames(img.get_size())
	if frames > 1:
		var w = floori(float(img.get_width()) / frames)
		img = img.get_region(Rect2i(0, 0, w, img.get_height()))
	var used = img.get_used_rect()
	if used.size != Vector2i.ZERO and used.size != img.get_size():
		img = img.get_region(used)
	return to_native(img)

## Algunos íconos del códice vienen agrandados (cada píxel del dibujo son 6x6).
## Esto los devuelve a su tamaño real, así todos parten de la misma densidad.
## La imagen tiene que venir recortada al dibujo (la grilla empieza en 0,0).
static func to_native(img: Image) -> Image:
	var k = block_size(img)
	if k <= 1: return img
	var out = img.duplicate()
	# block_size garantiza dimensiones divisibles por k; el tamaño final es entero.
	out.resize(floori(float(img.get_width()) / k), floori(float(img.get_height()) / k), Image.INTERPOLATE_NEAREST)
	return out

## Tamaño de los "bloques" del dibujo: el MCD de todas las tiras de píxeles
## iguales, por filas y por columnas. 1 = el dibujo ya está a tamaño real.
static func block_size(img: Image) -> int:
	var w = img.get_width()
	var h = img.get_height()
	if w < 24 and h < 24: return 1
	var k = 0
	for y in h:
		k = _runs_gcd(img, k, w, func(i): return img.get_pixel(i, y))
		if k == 1: return 1
	for x in w:
		k = _runs_gcd(img, k, h, func(i): return img.get_pixel(x, i))
		if k == 1: return 1
	if k <= 1 or w % k != 0 or h % k != 0: return 1
	return k

static func _runs_gcd(_img: Image, k: int, length: int, pixel: Callable) -> int:
	var run = 1
	var prev: Color = _solid(pixel.call(0))
	for i in range(1, length + 1):
		var c = _solid(pixel.call(i)) if i < length else Color(-1, -1, -1, -1)
		if i < length and c.is_equal_approx(prev):
			run += 1
			continue
		k = run if k == 0 else _gcd(k, run)
		if k == 1: return 1
		run = 1
		prev = c
	return k

# Los píxeles transparentes cuentan todos como iguales, tengan el color que tengan.
static func _solid(c: Color) -> Color:
	return Color(0, 0, 0, 0) if c.a < 0.05 else c

static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t = b
		b = a % b
		a = t
	return a

## Cuántos cuadros tiene una hoja horizontal de cuadros cuadrados
## (por ejemplo 640x128 = 5). Las imágenes normales devuelven 1.
static func sheet_frames(size: Vector2i) -> int:
	if size.y < 64 or size.x <= size.y or size.x % size.y != 0: return 1
	# La condición anterior garantiza una cantidad exacta de cuadros.
	return floori(float(size.x) / size.y)

# Escala entera pedida; si no entra, la mayor entera que entra; si ni en 1x
# entra, se achica lo justo.
static func _fit_scale(art: Vector2, scale: int, box: Vector2) -> float:
	if box.x <= 0.0 or box.y <= 0.0: return float(maxi(scale, 1))
	var room = minf(box.x / art.x, box.y / art.y)
	if scale == FIT: scale = clampi(int(room), 1, 12)
	if room >= scale: return float(scale)
	if room >= 1.0: return floorf(room)
	return room
