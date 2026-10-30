extends Player

var aim_target := Vector2(160, 0)

func get_aim_position() -> Vector2:
	return aim_target

func _physics_process(_delta: float) -> void:
	pass # Banco estacionario: la geometría y los ataques siguen siendo los reales.

func _queue_arrival_fx() -> void:
	show()

func _check_and_trigger_first_time_synergies() -> void:
	pass # No abrir ventanas ni persistir descubrimientos durante una medición.

func take_damage(_amount: int, _source: String = "", _origin: Vector2 = Vector2.ZERO) -> void:
	pass # Las explosiones propias no cambian la condición de vida del ensayo.

func benchmark_step(delta: float, mode: String) -> void:
	_update_minigun_hold_time(delta)
	_update_cerberus_hold_time(delta)
	_ensure_werewolf_mark()
	update_glock()
	if mode in ["ranged", "combo"]:
		handle_shooting()
	if mode in ["melee", "combo", "dual"]:
		_show_secondary_weapon()
		second_weapon.attack()
	if mode == "dual":
		_attack_left_melee()
	velocity = Vector2.ZERO
