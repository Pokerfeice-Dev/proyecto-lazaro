extends Projectile

## Proyectil de la sinergia Relampago: ademas del dano normal, electrifica
## al enemigo impactado, que contagia el efecto en cadena a los enemigos
## cercanos (aturdimiento breve + dano).

@export var chain_damage: int = 6
@export var stun_duration: float = 0.5

func _process_body_hit(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		_handle_wall_collision()
		return
	_deal_damage(body)
	_record_player_enemy_hit(body)
	_notify_bullet_hit(body)
	ElectrifyEffect.apply_electrify(body, chain_damage, stun_duration)
	_handle_piercing_or_destroy(body)
