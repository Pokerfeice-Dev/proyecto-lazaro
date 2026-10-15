extends Area2D

@export var speed := 300.0
@export var damage := 12
@export var source_name := "Escuadrón de la muerte"
var direction := Vector2.RIGHT
var _spent := false

func _ready() -> void:
	rotation = direction.angle()
	$Lifetime.timeout.connect(queue_free)
	body_entered.connect(_hit)

func _physics_process(delta: float) -> void:
	if _spent: return
	var next_position = global_position + direction * speed * delta
	var query = PhysicsRayQueryParameters2D.create(global_position, next_position, collision_mask)
	var result = get_world_2d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		global_position = result.position
		_hit(result.collider)
	else:
		global_position = next_position

func _hit(body: Node) -> void:
	if _spent or body.is_in_group("enemy") or body.is_in_group("projectile_pass"): return
	_spent = true
	if body.is_in_group("player"):
		if body.has_method("_is_arrogancia_reflect_active") and body._is_arrogancia_reflect_active():
			var reflected = load("res://Scenes/Projectiles/Projectile.tscn").instantiate()
			get_parent().add_child(reflected)
			reflected.global_position = global_position
			reflected.setup(-direction, damage * 0.5, "enemy")
		elif body.has_method("take_damage"):
			body.take_damage(damage, source_name, global_position - direction * 100.0)
	queue_free()
