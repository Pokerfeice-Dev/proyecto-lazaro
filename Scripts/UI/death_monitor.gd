extends Control
## Death-only, wall-clock timeline. No tweens depend on the world's time scale.
const HIT_STOP := 0.12
const SLOW_END := 0.60
const HIT_SCALE := 0.05
const SLOW_SCALE := 0.25
const TITLE_START := 0.30
const TITLE_DURATION := 0.22
const SUB_START := 0.55
const TAB_START := 0.65
const PANEL_START := 0.78
const ROW_START := 0.85
const ROW_STAGGER := 0.10
const COUNT_DURATION := 0.35
const BUTTON_START := 1.50
const OPEN_END := 1.80
const CLOSE_DURATION := 0.32
const SHAKE_PIXELS := 4.0
const TITLE_SCALE := 2.4
const ICON_SCALE := 1.25
const ROW_SLIDE := 18.0
const GLITCH_INTERVAL := 3.6
const GHOST_OFFSET := 18.0
const OVERLAY_DARKNESS := 0.88
const RED := Color('#E5484D')
const CYAN := Color('#52D8C6')
const GOLD := Color('#F4C45E')
const BACKDROP = preload('res://Scripts/UI/death_monitor.gdshader')
var host: CanvasLayer
var bg: ColorRect
var header: Control
var window: Control
var rows: Control
var button: Button
var title: Label
var subtitle: Label
var panel: Control
var tab: Control
var footer: Control
var stats: Array[Dictionary]
var ghosts: Array[Label] = []
var bases: Dictionary = {}
var elapsed := 0.0
var last_usec := 0
var previous_scale := 1.0
var closing := -1.0
var flash := 0.0
var initialized := false
var slammed := false
var revealed := 0
var restored := false

func setup(owner_screen: CanvasLayer, background: ColorRect, heading: Control, report: Control, stat_list: Control, return_button: Button, data: Array[Dictionary], corpse: Vector2) -> void:
	host = owner_screen
	bg = background
	header = heading
	window = report
	rows = stat_list
	button = return_button
	stats = data
	title = header.get_child(0)
	subtitle = header.get_child(1)
	tab = window.get_child(0)
	panel = window.get_child(1)
	footer = button.get_parent()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = BACKDROP
	bg.material = mat
	bg.color = Color.WHITE
	if corpse.x < 0: corpse = get_viewport_rect().size * 0.5
	mat.set_shader_parameter('focus', corpse / get_viewport_rect().size)
	previous_scale = Engine.time_scale
	Engine.time_scale = HIT_SCALE
	last_usec = Time.get_ticks_usec()
	header.modulate.a = 0
	window.modulate.a = 0
	for color in [RED, CYAN]:
		var ghost := Label.new()
		ghost.text = title.text
		ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ghost.add_theme_font_override('font', title.get_theme_font('font'))
		ghost.add_theme_font_size_override('font_size', 68)
		ghost.add_theme_color_override('font_color', color)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.add_child(ghost)
		ghosts.append(ghost)
	await get_tree().process_frame
	if not is_inside_tree(): return
	for control in [title, subtitle, tab, panel, footer]: bases[control] = control.position
	for item in stats: bases[item.row] = item.row.position
	initialized = true
	_render()

func is_ready() -> bool:
	return elapsed >= OPEN_END

func finish_opening() -> void:
	elapsed = OPEN_END
	flash = 0.25
	if initialized: _render()

func close_monitor() -> void:
	closing = 0.0
	flash = 0.35
	button.scale = Vector2(0.97, 0.92)

func restore_time() -> void:
	if restored: return
	restored = true
	Engine.time_scale = previous_scale

func _exit_tree() -> void:
	restore_time()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var dt := float(now - last_usec) / 1000000.0
	last_usec = now
	elapsed += dt
	flash = maxf(0, flash - dt * 2)
	if closing >= 0:
		closing += dt
		if closing >= CLOSE_DURATION:
			restore_time()
			set_process(false)
			host._leave()
			return
	if initialized: _render()

func progress(start: float, duration: float) -> float:
	return clampf((elapsed - start) / duration, 0, 1)

func cubic(t: float) -> float: return 1.0 - pow(1.0 - t, 3)
func quint(t: float) -> float: return 1.0 - pow(1.0 - t, 5)
func back(t: float) -> float:
	return 1.0 + 2.70158 * pow(t - 1.0, 3) + 1.70158 * pow(t - 1.0, 2)

func _render() -> void:
	Engine.time_scale = lerpf(HIT_SCALE, SLOW_SCALE, smoothstep(HIT_STOP, SLOW_END, elapsed))
	var mat := bg.material as ShaderMaterial
	mat.set_shader_parameter('darkness', OVERLAY_DARKNESS * progress(0, 0.65))
	mat.set_shader_parameter('pulse', maxf(flash, 1.0 - progress(0, 0.22)))
	mat.set_shader_parameter('clock', elapsed)
	mat.set_shader_parameter('shutdown', maxf(0, closing / CLOSE_DURATION))
	header.modulate.a = 1
	window.modulate.a = 1
	var slam := progress(TITLE_START, TITLE_DURATION)
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2.ONE * lerpf(TITLE_SCALE, 1.0, back(slam))
	title.modulate.a = slam
	var impact := 1.0 - progress(TITLE_START + TITLE_DURATION, 0.12)
	var discharge := Vector2(sin(elapsed * 210), cos(elapsed * 180)) * SHAKE_PIXELS * (1 - progress(0, 0.18))
	host.offset = discharge
	var shake := Vector2(sin(elapsed * 160), cos(elapsed * 130)) * SHAKE_PIXELS * impact if slam >= 1 else Vector2.ZERO
	title.position = bases[title] + shake
	title.add_theme_color_override('font_outline_color', RED.darkened(0.38 + sin(elapsed * 2.6) * 0.12))
	if slam >= 1 and not slammed:
		slammed = true
		host.notify_title_slam()
	var glitch := 1.0 if fmod(elapsed, GLITCH_INTERVAL) < 0.035 and elapsed > OPEN_END else 0.0
	for i in ghosts.size():
		var ghost := ghosts[i]
		ghost.size = title.size
		ghost.position = Vector2((1 if i == 0 else -1) * (GHOST_OFFSET * impact + glitch * 4), 0)
		ghost.modulate.a = maxf(impact * slam * 0.55, glitch * 0.65)
		# Briefly corrupt just two letters, leaving the real title readable.
		ghost.text = 'H S M ERTO' if glitch > 0 else title.text
	var decode := progress(SUB_START, 0.25)
	subtitle.modulate.a = decode
	var decoded := ''
	var symbols := '#%+01'
	for i in host.subtitle_text.length():
		decoded += host.subtitle_text[i] if float(i) / host.subtitle_text.length() < decode else symbols[(i + int(elapsed * 70)) % symbols.length()]
	subtitle.text = decoded
	tab.modulate = Color(1 + (1 - progress(TAB_START, 0.15)), 1, 1, progress(TAB_START, 0.15))
	tab.position = bases[tab] + Vector2(-70 * (1 - quint(progress(TAB_START, 0.15))), 0)
	panel.scale.y = lerpf(0.02, 1, quint(progress(PANEL_START, 0.25)))
	panel.modulate.a = progress(PANEL_START, 0.08)
	for child in rows.get_children(): child.modulate.a = progress(ROW_START, 0.25)
	for i in stats.size():
		var item := stats[i]
		var p := progress(ROW_START + i * ROW_STAGGER, 0.25)
		item.row.modulate.a = p
		item.row.position = bases[item.row] + Vector2(-ROW_SLIDE * (1 - cubic(p)), 0)
		item.icon.pivot_offset = item.icon.size * 0.5
		item.icon.scale = Vector2.ONE * lerpf(ICON_SCALE, 1, cubic(p))
		var value: Label = item.value
		if value.has_meta('count_to'):
			var count := int(round(float(value.get_meta('count_to')) * cubic(progress(ROW_START + i * ROW_STAGGER, COUNT_DURATION))))
			value.text = GameData.format_time(count) if value.has_meta('is_time') else str(count)
		if i == stats.size() - 1:
			value.pivot_offset = value.size * 0.5
			value.scale = Vector2.ONE * lerpf(1.6, 1, back(p))
			value.add_theme_color_override('font_shadow_color', CYAN)
			value.add_theme_constant_override('shadow_offset_x', int(8 * (1 - p)))
			item.icon.modulate = Color(1 + sin(p * PI) * 1.5, 1, 1)
		if p > 0 and revealed <= i:
			revealed = i + 1
			host.notify_stat_row_reveal(i)
			if i == stats.size() - 1: host.notify_killer_stamped()
	footer.modulate.a = progress(BUTTON_START, 0.20)
	footer.position = bases[footer] + Vector2(0, 12 * (1 - cubic(progress(BUTTON_START, 0.20))))
	if closing >= 0:
		var collapse := 1.0 - quint(closing / CLOSE_DURATION)
		header.scale.y = collapse
		window.scale.y = collapse
		header.modulate.a = collapse
		window.modulate.a = collapse
	queue_redraw()

func _draw() -> void:
	if not initialized or closing >= 0: return
	var rect := panel.get_global_rect()
	if elapsed >= PANEL_START and closing < 0:
		for x in range(int(rect.position.x), int(rect.end.x), 24):
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(CYAN, 0.04))
		for y in range(int(rect.position.y), int(rect.end.y), 24):
			draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(CYAN, 0.04))
		for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
			var direction: Vector2 = (rect.get_center() - corner).sign()
			draw_line(corner, corner + Vector2(direction.x * 16, 0), GOLD, 2)
			draw_line(corner, corner + Vector2(0, direction.y * 16), GOLD, 2)
		var scan := progress(PANEL_START, 0.25)
		if scan < 1:
			var scan_y := lerpf(rect.position.y, rect.end.y, scan)
			draw_line(Vector2(rect.position.x, scan_y), Vector2(rect.end.x, scan_y), CYAN, 2)
		var edge := fmod(elapsed * 180, rect.size.x)
		draw_line(rect.position + Vector2(edge, 0), rect.position + Vector2(minf(edge + 55, rect.size.x), 0), Color(CYAN, 0.6), 2)
		for i in stats.size():
			var r: Rect2 = stats[i].row.get_global_rect()
			var pulse := sin(progress(ROW_START + i * ROW_STAGGER, 0.35) * PI)
			draw_line(Vector2(r.position.x, r.end.y), r.end, Color(CYAN, pulse * 0.7), 1)
		if elapsed >= BUTTON_START:
			var r := footer.get_global_rect()
			var sweep := fmod(elapsed - BUTTON_START, 3.4) / 0.7
			if sweep < 1:
				var x := lerpf(r.position.x, r.end.x - 15, sweep)
				draw_line(Vector2(x + 15, r.position.y + 4), Vector2(x, r.end.y - 4), Color(GOLD, 0.65), 3)
	# Last violent heartbeat collapses into the report separator.
	var y := header.get_global_rect().end.y + 12
	var points := PackedVector2Array()
	for i in 161:
		var x := float(i) / 160
		var peak := exp(-pow((x - 0.5) * 40, 2)) * sin(x * 150) * 65 * (1 - progress(0.08, 0.22))
		points.append(Vector2(size.x * 0.22 + x * size.x * 0.56, y + peak))
	draw_polyline(points, Color(RED, 0.16 + 0.65 * (1 - progress(0.3, 0.35))), 4, true)
	draw_polyline(points, Color(CYAN, 0.65), 1, true)
