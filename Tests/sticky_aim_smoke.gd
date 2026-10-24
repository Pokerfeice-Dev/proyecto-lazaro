extends Node
class DummyEnemy extends Node2D:
	var is_dying := false
class AimHarness extends InputMode:
	func _ready() -> void:
		set_process(false)
func _ready() -> void:
	var aim := AimHarness.new()
	add_child(aim)
	var a := DummyEnemy.new()
	var b := DummyEnemy.new()
	add_child(a)
	add_child(b)
	a.add_to_group("enemy")
	b.add_to_group("enemy")
	a.position = Vector2(100, 0)
	b.position = Vector2(0, 100)
	aim._update_aim_stick(Vector2.RIGHT)
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == a.position)
	aim._update_aim_stick(Vector2.ZERO)
	a.position = Vector2(-100, 0)
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == a.position)
	aim._update_aim_stick(Vector2(0, 0.4))
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == a.position)
	aim._update_aim_stick(Vector2.DOWN)
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == b.position)
	b.position = Vector2(80, 80)
	a.position = Vector2(0, 100)
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == b.position)
	b.is_dying = true
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == a.position)
	a.free()
	assert(aim._aim_point(Vector2.ZERO, Vector2.ZERO) == Vector2.DOWN * InputMode.AIM_DISTANCE)
	print("STICKY_AIM_OK")
	get_tree().quit()
