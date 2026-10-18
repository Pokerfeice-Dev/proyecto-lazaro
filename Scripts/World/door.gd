extends StaticBody2D
class_name Door

@export var start_locked: bool = true
@export var is_start_run_door: bool = false
@export var custom_next_scene: String = ""
@export var is_open: bool = false
## Puerta de salida tras vencer al boss: en vez de ir siempre al mismo custom_next_scene,
## le pregunta a GameData a donde corresponde ir (siguiente nivel, o Lab si ya se gano la run).
@export var is_boss_exit_door: bool = false

@export_group("Cartel")
## Nombre que se muestra siempre sobre la puerta (vacío = sin cartel).
@export var sign_text: String = ""
@export var sign_icon: Texture2D
## Color del cartel y de las luces de la puerta, para distinguirla de las demás.
@export var sign_color: Color = Color("#52D8C6")
@export var sign_offset: Vector2 = Vector2(0, -62)
## Distancia a la que aparece el cartel (0 = siempre visible).
@export var sign_reveal_radius: float = 130.0
## Ícono fijo sobre la puerta, como el cerebro de O.M.N.I.A. (vacío = sin ícono).
@export var door_icon: Texture2D
@export var door_icon_offset: Vector2 = Vector2(0, -52)
## Texto del cartel de interacción al acercarse.
@export var prompt_text: String = "Presiona E"

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_locked: bool = true
var player_inside: bool = false
var interaction_label: Label = null
var base_close_energy: float = 1.0
var base_open_energy: float = 1.1

@onready var close_light: PointLight2D = get_node_or_null("Close")
@onready var open_light: PointLight2D = get_node_or_null("Open")

func _ready() -> void:
	add_to_group("door")
	_init_lights_base_energy()
	_apply_initial_door_state()
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	_setup_interaction_label()
	# cartel de interacción con el estilo de la UI nueva (copia este Label)
	InteractPrompt.mirror(interaction_label)
	_setup_sign()

# Cartel fijo con ícono y luces del mismo color, para que cada puerta se reconozca.
func _setup_sign() -> void:
	_setup_door_icon()
	if sign_text == "": return
	DoorSign.create(self, sign_text, sign_icon, sign_color, sign_offset, sign_reveal_radius)
	for light in [close_light, open_light]:
		if light: light.color = sign_color

# Ícono siempre recto (top_level), con un leve tinte del color de la puerta.
func _setup_door_icon() -> void:
	if not door_icon: return
	var icon_sprite = Sprite2D.new()
	icon_sprite.texture = door_icon
	icon_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(icon_sprite)
	icon_sprite.top_level = true
	icon_sprite.global_position = global_position + door_icon_offset
	icon_sprite.scale = Vector2(0.7, 0.7)
	icon_sprite.modulate = Color.WHITE.lerp(sign_color, 0.25)

func _init_lights_base_energy() -> void:
	if close_light:
		base_close_energy = close_light.energy
	if open_light:
		base_open_energy = open_light.energy

func _apply_initial_door_state() -> void:
	if _should_start_unlocked():
		unlock_door()
		return
	lock_door()

func _should_start_unlocked() -> bool:
	if is_open:
		return true
	if name.to_lower() == "door_coreupgrades":
		return GameData.has_died_once
	if not start_locked:
		return true
	return false

func _process(_delta: float) -> void:
	if not is_locked:
		return
	if not close_light:
		return
	_pulse_close_light()

func _pulse_close_light() -> void:
	var t = Time.get_ticks_msec() / 1000.0
	close_light.energy = base_close_energy * (0.85 + sin(t * 3.5) * 0.15)

func lock_door() -> void:
	is_locked = true
	anim_sprite.play("Door_lock")
	collision_shape.set_deferred("disabled", false)
	_hide_interaction_label()
	_update_door_lights()

func unlock_door() -> void:
	is_locked = false
	anim_sprite.play("Door_Unlock")
	collision_shape.set_deferred("disabled", true)
	_update_door_lights()

func _update_door_lights() -> void:
	if is_locked:
		_show_close_light()
		return
	_show_open_light()

func _show_close_light() -> void:
	_set_node_visible(close_light, true)
	_set_node_visible(open_light, false)

func _show_open_light() -> void:
	_set_node_visible(close_light, false)
	_set_node_visible(open_light, true)
	_fade_in_open_light()

func _set_node_visible(node: CanvasItem, is_vis: bool) -> void:
	if not node:
		return
	node.visible = is_vis

func _fade_in_open_light() -> void:
	if not open_light:
		return
	open_light.energy = 0.0
	var tween = create_tween()
	tween.tween_property(open_light, "energy", base_open_energy, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _setup_interaction_label() -> void:
	interaction_label = get_node_or_null("Label") as Label
	if not interaction_label:
		interaction_label = Label.new()
		interaction_label.name = "Label"
		add_child(interaction_label)
		interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interaction_label.custom_minimum_size = Vector2(200, 30)
		interaction_label.add_theme_color_override("font_color", Color.WHITE)
		interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
		interaction_label.add_theme_constant_override("outline_size", 4)
	
	# top_level hace que el Label ignore la rotación/escala del Door padre,
	# asi el texto siempre se muestra recto y legible sin importar la orientación de la puerta
	interaction_label.top_level = true
	interaction_label.rotation = 0.0
	interaction_label.scale = Vector2.ONE
	# con cartel, el aviso de interacción va justo encima del cartel (no se pisan)
	var prompt_y = -70.0 if sign_text == "" else sign_offset.y - 40.0
	interaction_label.position = global_position + Vector2(-100, prompt_y)
	interaction_label.text = prompt_text
	interaction_label.visible = false

func _hide_interaction_label() -> void:
	if not interaction_label:
		return
	interaction_label.visible = false

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
	if not InputMode.is_interact(event): return # E o X del joystick
	
	_transition_room()

func _transition_room() -> void:
	if is_start_run_door:
		_show_weapon_selection_popup()
		return
		
	if is_boss_exit_door:
		_handle_boss_exit()
		return
		
	var next_scene: String
	if custom_next_scene != "":
		next_scene = custom_next_scene
	else:
		next_scene = GameData.get_next_room()
	GameData.last_room_name = get_tree().current_scene.name
	SceneTransition.play_teleport_sound()
	SceneTransition.change_scene(next_scene)

func _handle_boss_exit() -> void:
	var next_scene = GameData.get_post_boss_scene()
	GameData.last_room_name = get_tree().current_scene.name
	
	if GameData.just_won_run:
		GameData.just_won_run = false
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("show_win_screen"):
			player.show_win_screen(next_scene)
			return
		
	SceneTransition.play_teleport_sound()
	SceneTransition.change_scene(next_scene)

func _show_weapon_selection_popup() -> void:
	WeaponSelectionMenu.show_popup(
		self,
		"PREPARACIÓN DE INVASIÓN",
		"Selecciona el equipamiento para comenzar la run",
		"INICIAR RUN",
		func(_selections):
			var next_scene = GameData.start_new_run()
			SceneTransition.play_teleport_sound()
			SceneTransition.change_scene(next_scene)
	)
