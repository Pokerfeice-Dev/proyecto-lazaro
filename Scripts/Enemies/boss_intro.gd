extends Node
class_name BossIntro

## Cinemática de entrada de los jefes que no tienen una propia (Centinela
## Génesis y El Primogénito), con la misma estructura que la de Prometeo:
## el jefe queda quieto (sus timers en pausa), se congela al jugador, la
## cámara va hasta el jefe con un zoom relativo al de la pelea, el jefe ruge
## (señal "roared": ahí cada jefe crea su barra, que entra con el título) y
## la cámara vuelve. Ganchos opcionales del jefe:
##   _intro_prepare()  -> lo esconde antes de empezar (por ejemplo, arriba del cuadro).
##   _intro_appear()   -> su aparición propia (corrutina); se espera antes de rugir.
##   _intro_roar()     -> lo que hace al rugir.
## Uso: var intro = BossIntro.new(); add_child(intro); intro.roared.connect(...); await intro.play(self, 0.6)

signal roared

const ZOOM_FACTOR := 1.3
const TRAVEL_TIME := 1.0
const HOLD_AFTER_ROAR := 2.3

var boss: Node2D
var _player: Node
var _camera: Camera2D
var _base_zoom := Vector2.ONE
var _base_position := Vector2.ZERO
var _paused_timers: Array[Timer] = []

func play(p_boss: Node2D, start_delay: float) -> void:
	boss = p_boss
	_pause_boss_timers(true)
	if boss.has_method("_intro_prepare"):
		boss._intro_prepare()
	# espera el fundido de entrada a la sala
	await _wait(start_delay)
	if not _boss_alive():
		_finish()
		return
	_player = get_tree().get_first_node_in_group("player")
	_set_player_frozen(true)
	_capture_camera()
	_move_camera(_boss_offset(), _base_zoom * ZOOM_FACTOR, TRAVEL_TIME, Tween.EASE_OUT)
	await _wait(TRAVEL_TIME * 0.9)
	if boss.has_method("_intro_appear"):
		await boss._intro_appear()
	if not _boss_alive():
		_finish()
		return
	_roar()
	await _wait(HOLD_AFTER_ROAR)
	_move_camera(_base_position, _base_zoom, TRAVEL_TIME * 0.9, Tween.EASE_IN_OUT)
	await _wait(TRAVEL_TIME * 0.9)
	_finish()

func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, false).timeout

func _boss_alive() -> bool:
	return is_instance_valid(boss) and not boss.is_dying

# Los ataques de los jefes salen de Timers hijos: en pausa hasta que termina la entrada.
func _pause_boss_timers(on: bool) -> void:
	if on:
		for child in boss.get_children():
			if child is Timer and not child.paused:
				child.paused = true
				_paused_timers.append(child)
		return
	for timer in _paused_timers:
		if is_instance_valid(timer):
			timer.paused = false
	_paused_timers.clear()

func _roar() -> void:
	if not _boss_alive(): return
	if boss.has_method("_intro_roar"):
		boss._intro_roar()
	if _player and _player.has_method("apply_custom_camera_shake"):
		_player.apply_custom_camera_shake(16.0, 1.2)
	roared.emit()

# --- Cámara y jugador ---

func _capture_camera() -> void:
	_camera = get_viewport().get_camera_2d()
	if not _camera: return
	_base_zoom = _camera.zoom
	_base_position = _camera.position

func _boss_offset() -> Vector2:
	if not _camera or not _camera.get_parent(): return _base_position
	return boss.global_position - _camera.get_parent().global_position

func _move_camera(to_position: Vector2, to_zoom: Vector2, duration: float, ease_type: Tween.EaseType) -> void:
	if not is_instance_valid(_camera): return
	var t = create_tween().set_parallel(true)
	t.tween_property(_camera, "zoom", to_zoom, duration).set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)
	t.tween_property(_camera, "position", to_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)

func _set_player_frozen(frozen: bool) -> void:
	if not _player or not is_instance_valid(_player): return
	var method = "freeze_player" if frozen else "unfreeze_player"
	if _player.has_method(method):
		_player.call(method)

func _finish() -> void:
	if is_instance_valid(_camera):
		_camera.zoom = _base_zoom
		_camera.position = _base_position
	_set_player_frozen(false)
	if is_instance_valid(boss):
		_pause_boss_timers(false)
	queue_free()
