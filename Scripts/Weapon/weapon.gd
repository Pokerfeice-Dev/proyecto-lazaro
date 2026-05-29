extends Node2D
class_name WeaponBase

@export_category("Weapon Nodes")
@export var sprite_anim: AnimatedSprite2D
@export var shoot_sound: AudioStreamPlayer2D
@export var bullet_mark: Node2D

@export_category("Weapon Stats")
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Projectile.tscn")
@export var damage: float = 10.0
@export var projectile_speed: float = 600.0
@export var bullet_count: int = 1
@export var cone_spread_angle: float = 15.0
@export var piercing: int = 0
@export var crit_chance: float = 0.0
@export var crit_damage: float = 2.0
@export var lifetime: float = 3.0
@export var attack_speed: float = 1.0
@export var damage_multiplier: float = 1.0

func get_projectile_scene() -> PackedScene:
	return projectile_scene

func get_damage() -> float:
	return damage

func get_projectile_speed() -> float:
	return projectile_speed

func get_bullet_count() -> int:
	return bullet_count

func get_spread_angle() -> float:
	return cone_spread_angle

func get_piercing() -> int:
	return piercing

func get_crit_chance() -> float:
	return crit_chance

func get_crit_damage() -> float:
	return crit_damage

func get_lifetime() -> float:
	return lifetime

func get_attack_speed() -> float:
	return attack_speed

func get_damage_multiplier() -> float:
	return damage_multiplier

func play_shoot_effects() -> void:
	if sprite_anim:
		sprite_anim.stop()
		sprite_anim.play("shoot")
	if shoot_sound:
		shoot_sound.play()



func get_bullet_spawn_pos(fallback: Vector2) -> Vector2:
	if bullet_mark:
		return bullet_mark.global_position
	return fallback
