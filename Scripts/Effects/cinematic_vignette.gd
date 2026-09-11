extends CanvasLayer
class_name CinematicVignette

static var is_globally_enabled: bool = true

@export var inner_radius: float = 0.55
@export var outer_radius: float = 1.10
@export var base_alpha: float = 0.30
@export var vignette_color: Color = Color(0.01, 0.02, 0.05, 0.30)

var vignette_rect: ColorRect = null
var vignette_material: ShaderMaterial = null

func _ready() -> void:
	add_to_group("cinematic_vignette")
	layer = 15
	_setup_vignette_rect()
	_apply_visibility_state()

func _setup_vignette_rect() -> void:
	vignette_rect = ColorRect.new()
	vignette_rect.name = "VignetteRect"
	vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_shader_material()
	vignette_rect.material = vignette_material
	add_child(vignette_rect)

func _setup_shader_material() -> void:
	vignette_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = _get_vignette_shader_code()
	vignette_material.shader = shader
	_update_shader_parameters()

func _get_vignette_shader_code() -> String:
	return """
shader_type canvas_item;

uniform vec4 vignette_color : source_color = vec4(0.01, 0.02, 0.05, 0.30);
uniform float inner_radius : hint_range(0.0, 1.0) = 0.55;
uniform float outer_radius : hint_range(0.0, 1.5) = 1.10;

void fragment() {
	vec2 uv = UV;
	vec2 dist_vec = (uv - vec2(0.5)) * vec2(1.0, 0.85);
	float d = length(dist_vec) * 2.0;
	float factor = smoothstep(inner_radius, outer_radius, d);
	COLOR = vec4(vignette_color.rgb, vignette_color.a * factor);
}
"""

func _update_shader_parameters() -> void:
	if not vignette_material:
		return
	vignette_material.set_shader_parameter("vignette_color", vignette_color)
	vignette_material.set_shader_parameter("inner_radius", inner_radius)
	vignette_material.set_shader_parameter("outer_radius", outer_radius)

func _apply_visibility_state() -> void:
	visible = is_globally_enabled

static func toggle_global_vignette(tree: SceneTree) -> bool:
	is_globally_enabled = not is_globally_enabled
	_update_all_vignettes_in_tree(tree, is_globally_enabled)
	return is_globally_enabled

static func _update_all_vignettes_in_tree(tree: SceneTree, enabled: bool) -> void:
	if not tree:
		return
	var nodes = tree.get_nodes_in_group("cinematic_vignette")
	for node in nodes:
		_set_vignette_node_visibility(node as CinematicVignette, enabled)

static func _set_vignette_node_visibility(vignette: CinematicVignette, enabled: bool) -> void:
	if not vignette:
		return
	vignette.visible = enabled
