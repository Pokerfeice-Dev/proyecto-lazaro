extends RefCounted
class_name HologramSkin

## Pedestal propio de cada zona para los hologramas de objetos (tienda de Ygor y
## recompensas de sala), para que peguen con el arte y el tile de cada lugar:
##   zona 1 -> base tecnológica con holograma cian (la de siempre)
##   zona 2 -> tumba de piedra con velas y cruz dorada, con almas flotando
##   zona 3 -> vaina carnosa con esporas luminosas, como el tileset de la Tierra Maldita
## Uso: HologramSkin.apply(sprite_del_pedestal, luz_opcional)

const SKINS := {
	1: {"texture": "res://Art/Ygor/Ygor_hologram_item.png", "light": Color(0.55, 0.95, 1.0)},
	2: {"texture": "res://Art/Ygor/Ygor_hologram_tumba.png", "light": Color(0.75, 0.8, 1.0)},
	3: {"texture": "res://Art/Ygor/Ygor_hologram_vaina.png", "light": Color(0.82, 1.0, 0.5)},
}

static func apply(pedestal: Sprite2D, light: PointLight2D = null) -> void:
	var skin: Dictionary = SKINS[zone_of(pedestal)]
	pedestal.texture = load(skin["texture"])
	if light:
		light.color = skin["light"]

# La zona sale del nombre de la sala ("Level2_Room13..."). El `owner` del sprite es la
# propia escena del pedestal, así que se sube por los padres hasta dar con la escena de la
# sala; si no aparece, se usa la escena actual y, en último caso, la zona de la partida.
static func zone_of(node: Node) -> int:
	var regex := RegEx.create_from_string("Level(\\d)_")
	var cursor: Node = node
	while cursor:
		var m := regex.search(cursor.scene_file_path.get_file())
		if m:
			return clampi(int(m.get_string(1)), 1, 3)
		cursor = cursor.get_parent()
	var tree := node.get_tree()
	if tree and tree.current_scene:
		var m2 := regex.search(tree.current_scene.scene_file_path.get_file())
		if m2:
			return clampi(int(m2.get_string(1)), 1, 3)
	return clampi(GameData.current_level, 1, 3)
