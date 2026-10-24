extends CharacterBody2D
class_name AlliedBee

var target_player: CharacterBody2D = null
var attack_cooldown: float = 1.5
var cooldown_timer: float = 0.0
var damage: float = 12.0

@onready var sprite: Sprite2D = Sprite2D.new()

func _ready() -> void:
	add_to_group("allied_bee")
	var tex = load("res://Art/Weapons/Distance/Pistol/Projectile_Bee.png")
	if tex:
		sprite.texture = tex
		sprite.hframes = 5
	add_child(sprite)
	
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -8.0, 0.4).as_relative().set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 8.0, 0.4).as_relative().set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	_update_target_player()
	if not target_player:
		return
		
	_follow_player(delta)
	_animate_sprite()
	_handle_attack(delta)

func _update_target_player() -> void:
	if not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0]

func _follow_player(delta: float) -> void:
	var dist = global_position.distance_to(target_player.global_position)
	if dist > 60.0:
		var target_pos = target_player.global_position + Vector2(-30, -30)
		var dir = global_position.direction_to(target_pos)
		velocity = velocity.lerp(dir * 180.0, 5.0 * delta)
		move_and_slide()
		if sprite:
			sprite.flip_h = velocity.x < 0

func _animate_sprite() -> void:
	if sprite and sprite.texture:
		if Engine.get_physics_frames() % 6 == 0:
			sprite.frame = (sprite.frame + 1) % sprite.hframes

func _handle_attack(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		_attack_nearest_enemy()

func _attack_nearest_enemy() -> void:
	if not is_instance_valid(target_player) or target_player.get("is_cutscene_frozen") == true: return
	if GameData.active_protocol != "enjambre_residual":
		queue_free()
		return
	var enemies = get_tree().get_nodes_in_group("enemy").filter(ProtocolRuntime.valid_enemy)
	if enemies.is_empty():
		return
	
	var nearest = enemies[0]
	var min_d = global_position.distance_to(nearest.global_position)
	for e in enemies:
		var d = global_position.distance_to(e.global_position)
		if d < min_d:
			nearest = e
			min_d = d
	var protocols = target_player.get("protocols")
	if protocols:
		var preferred = protocols.preferred_target()
		if preferred and global_position.distance_to(preferred.global_position) < 300.0:
			nearest = preferred
			min_d = global_position.distance_to(preferred.global_position)
			
	if min_d < 300.0:
		cooldown_timer = attack_cooldown
		var bee_proj_scene = load("res://Scenes/Projectiles/BeeProjectile.tscn")
		if bee_proj_scene:
			var proj = bee_proj_scene.instantiate()
			proj.set_meta("protocol_metric", "bee_damage")
			get_tree().current_scene.add_child(proj)
			proj.global_position = global_position
			var dir = global_position.direction_to(nearest.global_position)
			var scaled_damage := damage
			if target_player.has_method("_get_weapon_damage"):
				scaled_damage += clampf(target_player._get_weapon_damage() * 0.2, 0.0, 12.0)
			proj.setup(dir, scaled_damage, "enemy", false)
			proj.set_homing_target(nearest)
