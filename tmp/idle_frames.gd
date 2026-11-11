extends Node2D
func _ready():
	var source = load("res://Scenes/Player/Player.tscn").instantiate()
	var original = source.get_node("AnimatedSprite2D")
	for i in 8:
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = original.sprite_frames
		sprite.animation = "idle_down"
		sprite.frame = i
		sprite.position = Vector2(120 + i * 240, 500)
		sprite.scale = Vector2.ONE * 6
		add_child(sprite)
		var label = Label.new()
		label.position = Vector2(100 + i * 240, 700)
		label.text = str(i)
		add_child(label)
	source.free()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tmp/idle-frames.png")
	get_tree().quit()
