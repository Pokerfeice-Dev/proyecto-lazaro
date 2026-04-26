extends Area2D

@export var speed: float = 500.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var target_group: String = "player"

@onready var anim_sprite = $AnimatedSprite2D

func setup(dir: Vector2, dmg: float, target: String, _is_crit: bool = false):
	direction = dir.normalized()
	damage = dmg
	target_group = target
	rotation = direction.angle()

func _ready():
	anim_sprite.play("shoot")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	global_position += direction * speed * delta

# --- Señales ---

func _on_body_entered(body: Node2D):
	if body.is_in_group(target_group):
		if body.has_method("take_damage"):
			body.take_damage(int(damage))
		_explode()
	elif not body.is_in_group("enemy"):
		# Colisión con pared u otro objeto sólido
		_explode()

func _explode():
	set_physics_process(false)
	# Desactivamos monitoreo para no colisionar más de una vez
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	anim_sprite.play("explosion")
	
	# Usamos un timer o la señal de la animación para borrarlo
	if not anim_sprite.animation_finished.is_connected(queue_free):
		anim_sprite.animation_finished.connect(queue_free)
