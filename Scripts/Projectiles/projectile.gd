extends Area2D
class_name Projectile

@export var speed: float = 600.0
@export var lifetime: float = 3.0
@export var piercing: int = 0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var target_group: String = ""
var is_crit: bool = false

func setup(dir: Vector2, dmg: float, target: String, crit: bool = false):
	direction = dir.normalized()
	damage = dmg
	target_group = target
	is_crit = crit
	rotation = direction.angle()

func _ready():
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(lifetime)
	
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D):
	if target_group != "" and body.is_in_group(target_group):
		if body.has_method("take_damage"):
			body.take_damage(damage, is_crit)
		
		if piercing > 0:
			piercing -= 1
		else:
			queue_free()
	elif not body.is_in_group("player") and not body.is_in_group("enemy"):
		# Hit a wall
		queue_free()
