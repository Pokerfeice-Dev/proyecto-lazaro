extends Node2D
class_name DoorSign

## Cartel fijo sobre una puerta (ícono + nombre), con el estilo de la UI del
## juego: placa oscura, borde del color de la puerta y el ícono que late.
## Siempre recto. Con "reveal_radius" > 0 solo aparece cuando el jugador se
## acerca (las puertas); con 0 queda siempre a la vista (las estaciones).
## Lo crea Door cuando tiene "sign_text".

const WORLD_SCALE := 0.4 # fuente grande achicada: se ve nítida con el zoom de la cámara
const FONT_SIZE := 30

var text: String = ""
var icon: Texture2D
var color: Color = UIStyle.COLOR_TEAL
var _plate: PanelContainer
var reveal_radius := 0.0
var _icon_rect: TextureRect
var _holder: Control
var _anchor: Node2D
var _shown := true
var _time := 0.0

static func create(owner_node: Node2D, sign_text: String, sign_icon: Texture2D, sign_color: Color, offset: Vector2, p_reveal_radius := 0.0) -> DoorSign:
	var door_sign = DoorSign.new()
	door_sign.text = sign_text
	door_sign.icon = sign_icon
	door_sign.color = sign_color
	door_sign.reveal_radius = p_reveal_radius
	door_sign._anchor = owner_node
	owner_node.add_child(door_sign)
	door_sign.top_level = true
	door_sign.global_position = owner_node.global_position + offset
	door_sign.rotation = 0.0
	return door_sign

func _ready() -> void:
	z_as_relative = false
	z_index = 50
	var holder = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	add_child(holder)
	_holder = holder
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_theme_stylebox_override("panel", _style())
	holder.add_child(_plate)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate.add_child(row)
	if icon:
		_icon_rect = UIStyle.icon(icon, 36)
		_icon_rect.modulate = color
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(_icon_rect)
	var label = UIStyle.label(text, FONT_SIZE, UIStyle.COLOR_TEXT)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	_plate.reset_size()
	_plate.position = -_plate.size / 2.0
	if reveal_radius > 0.0:
		_shown = false
		modulate.a = 0.0
		_holder.scale = Vector2(WORLD_SCALE, WORLD_SCALE) * 0.7

func _process(delta: float) -> void:
	_time += delta
	_update_reveal()
	if _icon_rect:
		var k = 0.5 + 0.5 * sin(_time * 3.0)
		_icon_rect.modulate = color.lerp(Color.WHITE, 0.35 * k)
	if _plate:
		_plate.position.y = -_plate.size.y / 2.0 + sin(_time * 2.0) * 2.0

# Aparece con un saltito cuando el jugador entra en el radio y se va al alejarse.
func _update_reveal() -> void:
	if reveal_radius <= 0.0 or not is_instance_valid(_anchor): return
	var player = get_tree().get_first_node_in_group("player") as Node2D
	var near = player != null and player.global_position.distance_to(_anchor.global_position) <= reveal_radius
	if near == _shown: return
	_shown = near
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0 if near else 0.0, 0.18)
	var target = Vector2(WORLD_SCALE, WORLD_SCALE) * (1.0 if near else 0.7)
	t.tween_property(_holder, "scale", target, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.03, 0.07, 0.09, 0.9)
	s.border_color = Color(color, 0.85)
	s.set_border_width_all(2)
	s.border_width_bottom = 4
	s.set_corner_radius_all(6)
	s.content_margin_left = 18
	s.content_margin_right = 20
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_color = Color(color, 0.25)
	s.shadow_size = 8
	return s
