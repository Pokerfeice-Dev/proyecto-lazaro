extends CanvasLayer
class_name HUD

@export var health_bar: TextureProgressBar
@export var scrap_label: Label

var dash_cd_bar: TextureProgressBar

func _ready():
	add_to_group("hud")
	_setup_dash_cooldown()
	update_scrap(GameData.scrap)
	_initialize_health()

func _initialize_health() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var p = players[0]
		if "stats" in p and p.stats:
			update_health(p.stats.current_health, p.stats.max_health)

func _setup_dash_cooldown() -> void:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in range(64):
		for y in range(64):
			var d = Vector2(x, y).distance_to(center)
			if d <= 30.0 and d >= 22.0:
				img.set_pixel(x, y, Color(0.2, 0.8, 1.0, 1.0))
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	var tex = ImageTexture.create_from_image(img)
	
	var img_bg = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for x in range(64):
		for y in range(64):
			var d = Vector2(x, y).distance_to(center)
			if d <= 30.0 and d >= 22.0:
				img_bg.set_pixel(x, y, Color(0.2, 0.2, 0.2, 0.5))
			else:
				img_bg.set_pixel(x, y, Color.TRANSPARENT)
	var tex_bg = ImageTexture.create_from_image(img_bg)
	
	dash_cd_bar = TextureProgressBar.new()
	dash_cd_bar.texture_under = tex_bg
	dash_cd_bar.texture_progress = tex
	dash_cd_bar.fill_mode = TextureProgressBar.FILL_CLOCKWISE
	dash_cd_bar.max_value = 5.0
	dash_cd_bar.step = 0.01
	dash_cd_bar.value = 5.0
	dash_cd_bar.position = Vector2(64, 120)
	
	var lbl = Label.new()
	lbl.text = "DASH"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	dash_cd_bar.add_child(lbl)
	
	var control = get_node_or_null("Control")
	if control:
		control.add_child(dash_cd_bar)

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	if "dash_cd_timer" in p and p.dash_cd_timer:
		var time_left = 0.0 if p.dash_cd_timer.is_stopped() else p.dash_cd_timer.time_left
		update_dash_cooldown(time_left, 5.0)

func update_dash_cooldown(time_left: float, max_time: float) -> void:
	if not dash_cd_bar: return
	dash_cd_bar.max_value = max_time
	dash_cd_bar.value = max_time - time_left

func update_health(new_health: int, max_health: int):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = new_health

func update_scrap(amount: int):
	if scrap_label:
		scrap_label.text = str(amount)
