extends CharacterBody2D

var last_dir := "right"
var is_dashing := false
var is_invulnerable := false
var hits := 0
var damage_received := 0

func take_damage(amount: int, _source: String = "", _origin: Vector2 = Vector2.INF) -> void:
	if is_dashing or is_invulnerable: return
	hits += 1
	damage_received += amount
