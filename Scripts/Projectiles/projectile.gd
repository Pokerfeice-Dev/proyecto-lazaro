extends Area2D
class_name Projectile

@export var speed: float = 600.0
@export var lifetime: float = 3.0
@export var piercing: int = 0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var target_group: String = ""
var is_crit: bool = false

var fragmentation_chance: float = 0.0
var is_fragment: bool = false

func setup(dir: Vector2, dmg: float, target: String, crit: bool = false):
	direction = dir.normalized()
	damage = dmg
	target_group = target
	is_crit = crit
	rotation = direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_lifetime_timer()

func _start_lifetime_timer() -> void:
	await get_tree().physics_frame
	_create_and_start_timer()

func _create_and_start_timer() -> void:
	var timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start(lifetime)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") or body.is_in_group("projectile_pass"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage, is_crit)
		if piercing > 0 and body.is_in_group("enemy"):
			piercing -= 1
		else:
			_destroy_projectile()
	else:
		_destroy_projectile()

func _destroy_projectile() -> void:
	_check_and_trigger_fragmentation()
	queue_free()

func _check_and_trigger_fragmentation() -> void:
	if is_fragment:
		return
	if randf() > fragmentation_chance:
		return
	_spawn_fragments()

func _spawn_fragments() -> void:
	var path = scene_file_path
	if path == "":
		path = "res://Scenes/Projectiles/Projectile.tscn"
	var scene = load(path)
	if not scene:
		return
	for i in range(4):
		_spawn_single_fragment(scene, i)

func _spawn_single_fragment(scene: PackedScene, idx: int) -> void:
	var frag = scene.instantiate()
	if not frag:
		return
	
	var angle_offset = (idx * PI / 2.0) + (PI / 4.0)
	var frag_dir = direction.rotated(angle_offset)
	
	frag.global_position = global_position
	
	if frag.has_method("setup"):
		frag.setup(frag_dir, damage * 0.3, target_group, is_crit)
	frag.set("is_fragment", true)
	frag.set("fragmentation_chance", 0.0)
	frag.set("lifetime", 0.3)
	if "speed" in frag:
		frag.speed = speed
		
	get_parent().call_deferred("add_child", frag)
