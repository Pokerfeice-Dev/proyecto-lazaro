extends Node2D
class_name YgorMachine

## Máquinas de uso múltiple de la tienda de Ygor (como las de The Binding of Isaac).
##   "vida"      -> cura un 30% de la vida máxima; cada uso cuesta más
##   "azar"      -> paga carne y sale un objeto, un poco de vida, carne de vuelta o nada
##   "reciclaje" -> se come el último objeto de la mochila y devuelve carne
## Se dibujan por código (no hay arte todavía) y las coloca ygor.gd en su sala.

const STORE_PATHS := preload("res://Scripts/NPC/hologram_ygor_store.gd")
const SFX_USE := preload("res://Audio/Sfx/Interact_reward.mp3")

const VIDA_BASE_COST := 8
const VIDA_COST_STEP := 4
const VIDA_HEAL_RATIO := 0.3
const AZAR_COST := 6
const AZAR_MAX_ITEMS := 2
const AZAR_HEAL_RATIO := 0.15
const AZAR_FLESH_BACK := 12
const RECYCLE_BODY := 10
const RECYCLE_WEAPON := 14

const COLORS := {
	"vida": Color(1.0, 0.32, 0.38),
	"azar": Color(1.0, 0.8, 0.25),
	"reciclaje": Color(0.45, 1.0, 0.55),
}
const TITLES := {
	"vida": "Máquina de vida",
	"azar": "Máquina de la suerte",
	"reciclaje": "Recicladora",
}

var kind := "vida"
var uses := 0
var items_given := 0
var broken := false
var player_in_range := false
var player_ref: Node2D = null
var label: Label
var _sfx: AudioStreamPlayer2D
var _time := 0.0
var _busy := false

static func create(machine_kind: String) -> YgorMachine:
	var m = YgorMachine.new()
	m.kind = machine_kind
	m.name = "YgorMachine_" + machine_kind
	return m

func _ready() -> void:
	add_to_group("ygor_machine")
	_build_body()
	_build_area()
	_build_label()
	_sfx = AudioStreamPlayer2D.new()
	_sfx.stream = SFX_USE
	_sfx.bus = "SFX"
	add_child(_sfx)
	DropShadow.attach_to(self, Vector2(34.0, 12.0), Vector2(0.0, 1.0), 0.4)
	_update_label()

# --- Armado ---

func _build_body() -> void:
	var body = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(26, 12)
	shape.shape = rect
	shape.position = Vector2(0, -6)
	body.add_child(shape)
	add_child(body)

func _build_area() -> void:
	var area = Area2D.new()
	area.collision_layer = 0
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 36.0
	shape.shape = circle
	shape.position = Vector2(0, -12)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _build_label() -> void:
	label = Label.new()
	label.position = Vector2(-100, -100)
	label.size = Vector2(200, 60)
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = Vector2(100, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	InteractPrompt.mirror(label)

# --- Dibujo ---

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var accent: Color = COLORS[kind]
	if broken:
		accent = Color(0.4, 0.4, 0.45)
	var glow = 0.55 + sin(_time * 3.0) * 0.2
	# gabinete
	draw_rect(Rect2(-15, -44, 30, 44), Color(0.1, 0.12, 0.16))
	draw_rect(Rect2(-15, -44, 30, 44), accent.darkened(0.35), false, 2.0)
	draw_rect(Rect2(-15, -48, 30, 6), accent.darkened(0.2))
	# pantalla
	var screen = Rect2(-11, -38, 22, 18)
	draw_rect(screen, Color(0.02, 0.05, 0.06))
	draw_rect(screen.grow(-1), Color(accent, 0.18 * glow))
	_draw_symbol(Vector2(0, -29), Color(accent, glow + 0.3))
	# bandeja y botón
	draw_rect(Rect2(-9, -12, 18, 6), Color(0.03, 0.04, 0.05))
	draw_circle(Vector2(9, -17), 2.0, accent if not broken else Color(0.3, 0.3, 0.3))
	# brillo del piso
	draw_circle(Vector2(0, -2), 4.0, Color(accent, 0.12 * glow))

func _draw_symbol(c: Vector2, col: Color) -> void:
	if broken:
		draw_line(c + Vector2(-6, -6), c + Vector2(6, 6), col, 2.0)
		draw_line(c + Vector2(6, -6), c + Vector2(-6, 6), col, 2.0)
		return
	match kind:
		"vida":
			draw_circle(c + Vector2(-3, -2), 3.4, col)
			draw_circle(c + Vector2(3, -2), 3.4, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6.3, -1), c + Vector2(6.3, -1), c + Vector2(0, 6)]), col)
		"azar":
			var font = ThemeDB.fallback_font
			draw_string(font, c + Vector2(-4, 6), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, col)
		"reciclaje":
			draw_arc(c, 6.0, PI * 0.15, PI * 1.6, 12, col, 2.0)
			var tip = c + Vector2(cos(PI * 1.6), sin(PI * 1.6)) * 6.0
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-3, -2), tip + Vector2(3, -1), tip + Vector2(0, 3)]), col)

# --- Cartel ---

func _cost() -> int:
	match kind:
		"vida": return VIDA_BASE_COST + uses * VIDA_COST_STEP
		"azar": return AZAR_COST
	return 0

func _update_label() -> void:
	if not label: return
	label.text = _label_text()

func _label_text() -> String:
	var title: String = TITLES[kind]
	if broken:
		return "%s\nAgotada" % title
	match kind:
		"vida":
			if player_in_range:
				return "%s\n+30%% de vida\n[E] Comprar (%d carne)" % [title, _cost()]
			return "%s\n%d carne" % [title, _cost()]
		"azar":
			if player_in_range:
				return "%s\nObjeto, vida o nada\n[E] Comprar (%d carne)" % [title, _cost()]
			return "%s\n%d carne" % [title, _cost()]
		_:
			var item = _recycle_target()
			if not item:
				return "%s\nMochila vacía" % title
			if player_in_range:
				return "%s\n%s\n[E] Reciclar\n+%d carne" % [title, item.item_name, _recycle_value(item)]
			return title
	return title

# --- Uso ---

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_in_range = true
	player_ref = body
	_update_label()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_in_range = false
	player_ref = null
	_update_label()

func _input(event: InputEvent) -> void:
	if broken or _busy or not player_in_range: return
	if not InputMode.is_interact(event): return
	_use()

func _use() -> void:
	match kind:
		"vida": _use_vida()
		"azar": _use_azar()
		"reciclaje": _use_reciclaje()
	_update_label()

func _pay(amount: int) -> bool:
	if not GameData.spend_flesh(amount):
		_flash_error()
		return false
	return true

func _use_vida() -> void:
	var stats = _stats()
	if not stats or stats.current_health >= stats.max_health:
		_float_text("¡Vida llena!", Color(1, 1, 1))
		_flash_error()
		_ygor_comment("vida_llena")
		return
	if not _pay(_cost()): return
	uses += 1
	_heal(VIDA_HEAL_RATIO)
	_feedback()
	_ygor_comment("vida", uses == 1)

func _use_azar() -> void:
	if not _pay(_cost()): return
	uses += 1
	_busy = true
	await _spin()
	_busy = false
	var roll = randf()
	if roll < 0.25:
		_give_random_item()
	elif roll < 0.55:
		if not _heal(AZAR_HEAL_RATIO):
			_float_text("Nada...", Color(0.7, 0.7, 0.7))
	elif roll < 0.7:
		GameData.add_flesh(AZAR_FLESH_BACK)
		_float_text("+%d carne" % AZAR_FLESH_BACK, COLORS["azar"])
	else:
		_float_text("Nada...", Color(0.7, 0.7, 0.7))
		_ygor_comment("azar_nada", uses == 1)
	_update_label()

func _use_reciclaje() -> void:
	var item = _recycle_target()
	if not item:
		_flash_error()
		return
	var inv = _inventory()
	if not inv: return
	var value = _recycle_value(item)
	inv.remove_item(item)
	GameData.add_flesh(value)
	_float_text("+%d carne" % value, COLORS["reciclaje"])
	_feedback()
	_ygor_comment("reciclaje", true)

# --- Ayudas ---

# Ygor comenta lo que pasa en sus máquinas (siempre la primera vez, después a veces)
func _ygor_comment(key: String, always: bool = false) -> void:
	var ygor = get_tree().get_first_node_in_group("ygor")
	if ygor and ygor.has_method("comment"):
		ygor.comment(key, always)

func _stats():
	if not player_ref: return null
	return player_ref.get("stats")

func _inventory() -> Node:
	if not player_ref: return null
	return player_ref.get_node_or_null("Inventory")

func _heal(ratio: float) -> bool:
	var stats = _stats()
	if not stats: return false
	var missing = stats.max_health - stats.current_health
	var amount = mini(missing, maxi(1, int(round(stats.max_health * ratio))))
	if amount <= 0: return false
	stats.heal(amount)
	if player_ref.has_method("_show_heal_text"):
		player_ref._show_heal_text(amount)
	return true

func _give_random_item() -> void:
	var inv = _inventory()
	var paths: Array = STORE_PATHS.BODY_ITEM_PATHS + STORE_PATHS.WEAPON_ITEM_PATHS
	var item = load(paths.pick_random()) as ItemData
	if not inv or not item:
		return
	inv.add_or_drop(item) # mochila llena: cae al piso
	RunLog.note_item(item)
	items_given += 1
	_float_text(item.item_name, COLORS["azar"])
	_feedback()
	if items_given >= AZAR_MAX_ITEMS:
		broken = true
		_ygor_comment("azar_rota", true)
	else:
		_ygor_comment("azar_premio")

func _recycle_target() -> ItemData:
	var inv = _inventory() if player_ref else _any_player_inventory()
	if not inv or inv.items.is_empty(): return null
	return inv.items.back()

func _any_player_inventory() -> Node:
	var p = get_tree().get_first_node_in_group("player")
	return p.get_node_or_null("Inventory") if p else null

func _recycle_value(item: ItemData) -> int:
	if item and "/Weapons/" in item.resource_path:
		return RECYCLE_WEAPON
	return RECYCLE_BODY

func _spin() -> void:
	var t = create_tween()
	for i in 4:
		t.tween_property(self, "scale", Vector2(1.06, 0.95), 0.06)
		t.tween_property(self, "scale", Vector2.ONE, 0.06)
	await t.finished

func _feedback() -> void:
	if _sfx: _sfx.play()
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1.6, 1.6, 1.6), 0.08)
	t.tween_property(self, "modulate", Color.WHITE, 0.25)

func _flash_error() -> void:
	var t = create_tween()
	t.tween_property(self, "modulate", Color(1.4, 0.4, 0.4), 0.08)
	t.tween_property(self, "modulate", Color.WHITE, 0.3)

func _float_text(text: String, color: Color) -> void:
	var l = UIStyle.label(text, 22, color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.scale = Vector2(0.45, 0.45)
	l.z_index = 70
	l.size = Vector2(200, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(-45, -70)
	add_child(l)
	var t = l.create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 26, 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.4)
	t.chain().tween_callback(l.queue_free)
