extends Node
class_name FootstepFX

# Sistema unificado de huellas y partículas de polvo (Footsteps FX).
# Genera partículas sutiles de polvo dirigidas en contra de la marcha
# y huellas efímeras alternadas entre el pie izquierdo y derecho.

static func spawn_footstep(tree: SceneTree, foot_pos: Vector2, move_dir: Vector2, is_heavy: bool = false, side: int = 1) -> void:
	if not tree: return
	if not tree.current_scene: return
	var parent = tree.current_scene
	_spawn_dust(parent, foot_pos, move_dir, is_heavy)
	_spawn_footprint(parent, foot_pos, move_dir, is_heavy, side)

static func _spawn_dust(parent: Node, foot_pos: Vector2, move_dir: Vector2, is_heavy: bool) -> void:
	var dust = CPUParticles2D.new()
	dust.z_as_relative = false
	dust.z_index = 2
	dust.global_position = foot_pos
	dust.emitting = false
	dust.one_shot = true
	dust.explosiveness = 0.85
	dust.lifetime = 0.35
	dust.direction = -move_dir
	dust.spread = 45.0
	dust.gravity = Vector2(0, -10)
	_configure_dust_dynamics(dust, is_heavy)
	_configure_dust_gradient(dust)
	parent.add_child(dust)
	dust.emitting = true
	dust.finished.connect(dust.queue_free)

static func _configure_dust_dynamics(dust: CPUParticles2D, is_heavy: bool) -> void:
	if is_heavy:
		dust.amount = 5
		dust.initial_velocity_min = 22.0
		dust.initial_velocity_max = 42.0
		dust.damping_min = 70.0
		dust.damping_max = 110.0
		dust.scale_amount_min = 3.0
		dust.scale_amount_max = 5.0
		return
	dust.amount = 3
	dust.initial_velocity_min = 14.0
	dust.initial_velocity_max = 28.0
	dust.damping_min = 50.0
	dust.damping_max = 90.0
	dust.scale_amount_min = 1.8
	dust.scale_amount_max = 3.2

static func _configure_dust_gradient(dust: CPUParticles2D) -> void:
	var grad = Gradient.new()
	grad.set_color(0, Color(0.85, 0.81, 0.75, 0.45))
	grad.set_color(1, Color(0.80, 0.76, 0.70, 0.0))
	dust.color_ramp = grad

static func _spawn_footprint(parent: Node, foot_pos: Vector2, move_dir: Vector2, is_heavy: bool, side: int) -> void:
	var perp = Vector2(-move_dir.y, move_dir.x)
	var lateral_offset = 5.0 if is_heavy else 3.5
	var offset_pos = foot_pos + perp * (float(side) * lateral_offset)
	var footprint = FootprintMark.new(move_dir.angle(), is_heavy)
	footprint.global_position = offset_pos
	parent.add_child(footprint)

# Marca de pisada efímera que se atenúa suavemente en el suelo
class FootprintMark extends Node2D:
	var is_heavy: bool = false

	func _init(target_angle: float, heavy: bool = false) -> void:
		rotation = target_angle
		is_heavy = heavy
		z_as_relative = false
		z_index = 1

	func _ready() -> void:
		_start_fade_tween()

	func _start_fade_tween() -> void:
		var tween = create_tween()
		tween.tween_interval(0.5)
		tween.tween_property(self, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(queue_free)

	func _draw() -> void:
		_draw_footprint_pads()

	func _draw_footprint_pads() -> void:
		var color = _get_mark_color()
		var front_r = 3.0 if is_heavy else 1.9
		var rear_r = 2.2 if is_heavy else 1.3
		var front_x = 2.5 if is_heavy else 1.8
		var rear_x = -2.2 if is_heavy else -1.6
		draw_circle(Vector2(front_x, 0.0), front_r, color)
		draw_circle(Vector2(rear_x, 0.0), rear_r, color)

	func _get_mark_color() -> Color:
		if is_heavy:
			return Color(0.08, 0.07, 0.10, 0.28)
		return Color(0.10, 0.09, 0.12, 0.20)
