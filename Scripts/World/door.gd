extends StaticBody2D
class_name Door

@export var start_locked: bool = true
@export var is_start_run_door: bool = false
@export var custom_next_scene: String = ""

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_locked: bool = true
var player_inside: bool = false
var interaction_label: Label = null

func _ready() -> void:
	add_to_group("door")
	if start_locked:
		lock_door()
	else:
		unlock_door()
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	_setup_interaction_label()

func _setup_interaction_label() -> void:
	interaction_label = Label.new()
	interaction_label.text = "Presiona E"
	interaction_label.visible = false
	add_child(interaction_label)
	interaction_label.position = anim_sprite.position + Vector2(-40, -60)
	
	interaction_label.add_theme_color_override("font_color", Color.WHITE)
	interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_label.add_theme_constant_override("outline_size", 4)

func lock_door() -> void:
	is_locked = true
	anim_sprite.play("Door_lock")
	collision_shape.set_deferred("disabled", false)
	if interaction_label:
		interaction_label.visible = false

func unlock_door() -> void:
	is_locked = false
	anim_sprite.play("Door_Unlock")
	collision_shape.set_deferred("disabled", true)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = true
	if not is_locked and interaction_label:
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"): return
	player_inside = false
	if interaction_label:
		interaction_label.visible = false

func _input(event: InputEvent) -> void:
	if is_locked or not player_inside: return
	if not event is InputEventKey: return
	if event.physical_keycode != KEY_E: return
	if not event.pressed or event.echo: return
	
	_transition_room()

func _transition_room() -> void:
	var next_scene: String
	if custom_next_scene != "":
		next_scene = custom_next_scene
	elif is_start_run_door:
		next_scene = GameData.start_new_run()
	else:
		next_scene = GameData.get_next_room()
	SceneTransition.play_teleport_sound()
	SceneTransition.change_scene(next_scene)
