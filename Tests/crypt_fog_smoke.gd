extends Node

func _ready() -> void:
	call_deferred("verify")

func verify() -> void:
	var fog = preload("res://Scenes/Effects/crypt_fog.tscn").instantiate()
	add_child(fog)
	var overlay := fog.get_node("FogOverlay") as ColorRect
	assert(overlay != null, "La niebla no tiene una capa visual")
	var material := overlay.material as ShaderMaterial
	assert(material != null, "La niebla no tiene ShaderMaterial")
	assert(float(material.get_shader_parameter("density")) <= 0.05, "La niebla debe ser sutil")
	assert(float(material.get_shader_parameter("drift_speed")) <= 0.02, "La niebla debe desplazarse lentamente")
	var crypt_room = preload("res://Scenes/Rooms/Level2_Room1.tscn").instantiate()
	add_child(crypt_room)
	await get_tree().process_frame
	assert(crypt_room.get_node_or_null("CryptFog") != null, "Las salas de la Cripta deben incorporar la niebla")
	print("CRYPT_FOG_PASS")
	get_tree().quit()
