extends Node2D
func _ready() -> void:
    call_deferred("verify")
func verify() -> void:
    var player := CharacterBody2D.new()
    player.add_to_group("player")
    add_child(player)
    var gargoyle = preload("res://Scenes/Enemies/Crypt/CryptGargoyle.tscn").instantiate()
    add_child(gargoyle)
    var sprite := gargoyle.get_node("GargoyleSprite") as AnimatedSprite2D
    assert(sprite != null, "Gárgola sin AnimatedSprite2D")
    for animation_name in [&"idle", &"walk", &"attack_cone", &"petrify", &"stone_shield"]:
        assert(sprite.sprite_frames.has_animation(animation_name), "Falta animación: " + animation_name)
    gargoyle._enter_phase(CryptEnemy.Phase.ATTACK, 0.2)
    assert(sprite.animation == &"attack_cone", "El ataque no reproduce el ciclo visual")
    gargoyle._enter_phase(CryptEnemy.Phase.STONE, 0.2)
    assert(sprite.animation == &"stone_shield", "El escudo no reproduce el ciclo visual")
    print("CRYPT_GARGOYLE_ART_PASS")
    get_tree().quit()
