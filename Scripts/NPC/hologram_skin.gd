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

# La zona sale del nombre de la sala ("Level2_Room13..."); si no se puede saber, la de la partida.
static func zone_of(node: Node) -> int:
	var regex := RegEx.create_from_string("Level(\\d)_")
	var room: Node = node.owner if node.owner else node.get_tree().current_scene
	var path: String = room.scene_file_path if room else ""
	var m := regex.search(path.get_file())
	var zone: int = int(m.get_string(1)) if m else GameData.current_level
	return clampi(zone, 1, 3)
