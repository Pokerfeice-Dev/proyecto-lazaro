extends Area2D

@export var speed: float = 500.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var target_group: String = "player"
var source_name: String = "Infección Lázaro"

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
		if body.is_in_group("player") and body.has_method("_is_arrogancia_reflect_active") and body._is_arrogancia_reflect_active():
			_reflect_back()
			return
		if body.has_method("take_damage"):
			# la flecha apunta en contra de la dirección de vuelo del proyectil (de donde vino el disparo)
			var source_position = global_position - direction * 9999.0
			body.take_damage(int(damage), source_name, source_position)
		_explode()
	elif not body.is_in_group("enemy") and not body.is_in_group("projectile_pass"):
		# Colisión con pared u otro objeto sólido
		_explode()

# Sinergia Arrogancia (maza): en vez de pegarle al jugador, la bala se destruye
# y nace una bala "devuelta" (con dano reducido) viajando en direccion contraria
# hacia los enemigos. Reusa la escena base de proyectil del jugador para heredar
# su colision/dano contra enemigos ya probados.
func _reflect_back() -> void:
	var reflected_scene = load("res://Scenes/Projectiles/Projectile.tscn")
	if reflected_scene:
		var reflected = reflected_scene.instantiate()
		get_tree().current_scene.add_child(reflected)
		reflected.global_position = global_position
		reflected.setup(-direction, damage * 0.5, "enemy")
		reflected.modulate = Color(1.4, 1.1, 0.3)
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()

func _explode():
	set_physics_process(false)
	# Desactivamos monitoreo para no colisionar más de una vez
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	anim_sprite.play("explosion")
	
	# Usamos un timer o la señal de la animación para borrarlo
	if not anim_sprite.animation_finished.is_connected(queue_free):
		anim_sprite.animation_finished.connect(queue_free)
