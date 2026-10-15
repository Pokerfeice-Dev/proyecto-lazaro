extends Node2D

func _ready() -> void:
	call_deferred("verify")

func verify() -> void:
	var wall_scene = load("res://Scenes/World/Wall_candle.tscn") as PackedScene
	var floor_scene = load("res://Scenes/World/Floor_candle.tscn") as PackedScene
	var standing_lamp_scene = load("res://Scenes/Objects/lampara_pie.tscn") as PackedScene
	var wall_lamp_scene = load("res://Scenes/Objects/lampara_pared.tscn") as PackedScene
	for index in 8:
		var candle = (wall_scene if index % 2 == 0 else floor_scene).instantiate()
		add_child(candle)
		candle.position = Vector2(220 + index * 82, 340)
		var light: PointLight2D = candle.get_node("PointLight2D")
		assert(light.texture.resource_path == "res://Art/Lights/candle_light_mask.svg", "candle uses radial light mask")
		assert(is_equal_approx(light.texture_scale, 0.72), "shared light radius is authored")
		assert(light.energy > 0.0 and light.energy < 1.0, "candle energy stays below clipping range")
		_assert_natural_torch_flicker(candle, light)
	for index in 8:
		var lamp = (standing_lamp_scene if index % 2 == 0 else wall_lamp_scene).instantiate()
		add_child(lamp)
		lamp.position = Vector2(220 + index * 82, 500)
		var light: PointLight2D = lamp.get_node("PointLight2D")
		assert(light.texture.resource_path == "res://Art/Lights/candle_light_mask.svg", "level one lamp uses radial light mask")
		assert(light.energy > 0.0 and light.energy < 1.0, "level one lamp energy stays below clipping range")
	for frame in 10:
		await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("lazaro-candle-lights.png"))
	print("CANDLE_LIGHTING_PASS")
	get_tree().quit()

func _assert_natural_torch_flicker(torch: Torch, light: PointLight2D) -> void:
	assert(torch.flicker_range <= 0.035, "torch flicker stays subtle")
	assert(torch.min_flicker_interval >= 0.18, "torch does not jitter every frame")
	var starting_energy = light.energy
	torch._flicker_timer = 0.0
	torch._update_torch_flicker(0.016)
	assert(absf(light.energy - starting_energy) <= 0.004, "torch brightness transitions smoothly")
