extends Node2D
class_name WeaponBase

@export_category("Weapon Stats")
@export var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Projectile.tscn")
@export var damage: float = 10.0
@export var projectile_speed: float = 600.0
@export var bullet_count: int = 1
@export var cone_spread_angle: float = 15.0
@export var piercing: int = 0
@export var crit_chance: float = 0.0

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
