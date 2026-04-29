extends Node2D

@onready var melee_sprite: Sprite2D = $Melee_sprite
@onready var slash_attack: Area2D = $Slash_attack
@onready var attack_fx: AnimatedSprite2D = $attack_fx

@export_category("Melee Stats")
@export var damage: int = 30
@export var attack_speed: float = 1.0
@export var attack_range: float = 1.0
@export var knockback_force: float = 0.0

var _is_attacking: bool = false
var hit_enemies: Array[Node2D] = []

var attack_sounds: Array[AudioStream] = [
	preload("res://Audio/Sfx/Melee/07_human_atk_sword_1.wav"),
]
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	scale = Vector2(attack_range, attack_range)
	slash_attack.body_entered.connect(_on_body_entered)
	slash_attack.monitoring = false
	
	if attack_fx:
		attack_fx.hide()
		attack_fx.animation_finished.connect(_on_attack_fx_finished)

func _on_attack_fx_finished() -> void:
	attack_fx.hide()

func attack() -> void:
	if _is_attacking: return
	_is_attacking = true
	hit_enemies.clear()
	slash_attack.monitoring = true
	
	var tween = create_tween()
	var start_rot = rotation - deg_to_rad(60)
	var end_rot = rotation + deg_to_rad(60)
	
	var safe_speed = maxf(0.1, attack_speed)
	var swing_time = 0.3 / safe_speed
	var recovery_time = 0.4 / safe_speed
	
	audio_player.stream = attack_sounds.pick_random()
	audio_player.play()
	
	if attack_fx:
		attack_fx.show()
		attack_fx.stop()
		attack_fx.play("attack")
	
	rotation = start_rot
	tween.tween_property(self, "rotation", end_rot, swing_time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation", (start_rot + end_rot) / 2.0, recovery_time)
	tween.finished.connect(_on_attack_finished)

func _on_attack_finished() -> void:
	_is_attacking = false
	slash_attack.monitoring = false

func is_attacking() -> bool:
	return _is_attacking

func _on_body_entered(body: Node2D) -> void:
	if not _is_attacking: return
	if body in hit_enemies: return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		hit_enemies.append(body)
		body.take_damage(damage)
		if knockback_force > 0.0 and body.has_method("apply_knockback"):
			var dir = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_force, dir)
