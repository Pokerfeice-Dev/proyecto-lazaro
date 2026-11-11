extends Node2D
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101d25"))
	var pilot = preload("res://Tests/pacemaker_smoke.gd").Pilot.new()
	add_child(pilot)
	pilot.position = Vector2(320, 230)
	var weapon = preload("res://Scenes/Weapon/PacemakerMace.tscn").instantiate()
	pilot.add_child(weapon)
	weapon.attack()
	await get_tree().create_timer(0.94).timeout
	weapon.attack()
	await get_tree().create_timer(0.17).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/pacemaker_preview.png")
	get_tree().quit()
