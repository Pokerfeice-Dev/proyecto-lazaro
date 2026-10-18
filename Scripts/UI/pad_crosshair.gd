extends CanvasLayer
class_name PadCrosshair

## Mira del joystick: con mouse la mira es el cursor; con joystick el cursor se
## esconde y esta mira se dibuja donde apunta el analógico derecho
## (player.get_aim_position()). Solo se ve jugando: con jugador visible, sin
## pausa y sin ventanas abiertas (pantalla de muerte, menús, etc.).
## La crea InputMode.

const SIGHT := preload("res://Art/Mouse/Shoot_sight.png")

var _sprite: Sprite2D

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sprite = Sprite2D.new()
	_sprite.texture = SIGHT
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.5, 1.5) # un poco más grande que el cursor: con joystick es la única referencia
	_sprite.visible = false
	add_child(_sprite)
	InputMode.instance().mode_changed.connect(_on_mode_changed)

func _on_mode_changed(gamepad: bool) -> void:
	# el cursor del sistema solo estorba con joystick
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if gamepad else Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var active = InputMode.is_gamepad() and player != null and player.is_visible_in_tree() \
		and not get_tree().paused and not PadFocus.has_modal() and player.has_method("get_aim_position")
	_sprite.visible = active
	if not active: return
	var aim: Vector2 = player.get_aim_position()
	_sprite.position = player.get_viewport().get_canvas_transform() * aim
