class_name IgniteEffect
extends Node

## Sistema de quemadura (dano en el tiempo) estilo "ignite".
## No usa charcos ni fuego en el piso: solo aplica el efecto sobre el enemigo impactado.

const IGNITE_META_KEY := "ignite_timer"

static func apply_ignite(target: Node, damage_per_tick: int, tick_interval: float, duration: float) -> void:
	if not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return

	var ticks_total := int(round(duration / tick_interval))
	if ticks_total <= 0:
		return

	# Si ya esta ardiendo, refresca la quemadura en vez de duplicarla.
	if target.has_meta(IGNITE_META_KEY):
		var existing: Timer = target.get_meta(IGNITE_META_KEY)
		if is_instance_valid(existing):
			existing.set_meta("ticks_left", ticks_total)
			existing.set_meta("burn_damage", damage_per_tick)
			return

	var timer := Timer.new()
	timer.wait_time = tick_interval
	timer.set_meta("ticks_left", ticks_total)
	timer.set_meta("burn_damage", damage_per_tick)
	timer.set_meta("target", target)
	timer.timeout.connect(_on_ignite_tick.bind(timer))
	target.add_child(timer)
	target.set_meta(IGNITE_META_KEY, timer)
	timer.start()

	_spawn_embers(timer)

static func _on_ignite_tick(timer: Timer) -> void:
	if not is_instance_valid(timer):
		return
	var target: Node = timer.get_meta("target", null)
	var ticks_left: int = timer.get_meta("ticks_left", 0)
	var burn_damage: int = timer.get_meta("burn_damage", 0)

	var target_dying: bool = is_instance_valid(target) and bool(target.get("is_dying"))
	if is_instance_valid(target) and not target_dying:
		if target.has_method("take_damage"):
			target.take_damage(burn_damage, false)

	ticks_left -= 1
	if ticks_left <= 0 or not is_instance_valid(target):
		if is_instance_valid(target) and target.has_meta(IGNITE_META_KEY):
			target.remove_meta(IGNITE_META_KEY)
		timer.queue_free()
		return

	timer.set_meta("ticks_left", ticks_left)

static func _spawn_embers(timer: Timer) -> void:
	var embers := CPUParticles2D.new()
	embers.emitting = true
	embers.amount = 8
	embers.lifetime = 0.5
	embers.one_shot = false
	embers.explosiveness = 0.1
	embers.direction = Vector2(0, -1)
	embers.spread = 35.0
	embers.gravity = Vector2(0, -40)
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 28.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.0
	embers.color = Color(1.0, 0.55, 0.15, 0.9)
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	embers.material = mat
	timer.add_child(embers)
