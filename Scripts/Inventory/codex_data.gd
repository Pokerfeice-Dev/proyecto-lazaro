class_name CodexData

const DATA = {
	"enemies": {
		"follower": {
			"name": "Mutante Seguidor",
			"lore": "Un humano infectado por la mutación Lázaro. Su cerebro dañado solo retiene el instinto de persecución y alimentación.",
			"stats": "Vida: 60 | Daño: 10 | Velocidad: Alta",
			"icon": preload("res://Art/Enemy_Mutation/fx/Explosion_blue_circle1.png")
		},
		"shooter": {
			"name": "Mutante Tirador",
			"lore": "Esta variante mutante posee glándulas hipertróficas que proyectan esporas ácidas altamente corrosivas a gran distancia.",
			"stats": "Vida: 40 | Daño: 10 | Rango: Largo",
			"icon": preload("res://Art/Enemy_Mutation/fx/Explosion_blue_circle3.png")
		},
		"tank": {
			"name": "Mutante Coloso (Tank)",
			"lore": "Una colosal aberración de tejido muscular endurecido. Actúa como un escudo viviente capaz de absorber cantidades masivas de daño.",
			"stats": "Vida: 180 | Daño: 25 | Resistencia: Extrema",
			"icon": preload("res://Art/Enemy_Mutation/fx/Explosion_blue_circle5.png")
		},
		"turret": {
			"name": "Torreta de Seguridad",
			"lore": "Unidad de contención automatizada de los laboratorios. Abre fuego de forma implacable ante firmas biológicas no identificadas.",
			"stats": "Vida: 50 | Daño: Variable | Rango: Área de Disparo",
			"icon": preload("res://Art/Enemy_turret/turret1.png")
		}
	},
	"weapons": {
		"pistol": {
			"name": "Pistola",
			"lore": "Arma corta estándar y confiable del personal táctico. Versátil y ligera.",
			"stats": "Daño: 10 | APS: 1.0 | Precisión: Alta",
			"icon": preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
		},
		"shotgun": {
			"name": "Escopeta de Combate",
			"lore": "Arma principal pesada que proyecta ráfagas de perdigones a corta distancia.",
			"stats": "Daño: Alto | Dispersión: Amplia | Proyectiles: 4",
			"icon": preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
		},
		"uzi": {
			"name": "Subfusil Uzi",
			"lore": "Arma compacta automática con gran cadencia de fuego para control a media distancia.",
			"stats": "Daño: Medio | APS: Alta | Dispersión: Media",
			"icon": preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
		},
		"second_weapon": {
			"name": "Bayoneta Táctica",
			"lore": "Arma de combate cuerpo a cuerpo veloz que inflige gran daño a corta distancia.",
			"stats": "Daño: 40 | APS: 1.2 | Empuje: 110",
			"icon": preload("res://Art/Weapons/Melee/Dagger/Weapon_Dagger.png")
		},
		"daga": {
			"name": "Daga de Cristal",
			"lore": "Un filo corto y mortífero tallado en cristal de sílice. Rápida pero con corto alcance.",
			"stats": "Daño: 15 | APS: 1.5 | Rango: Corto",
			"icon": preload("res://Art/Weapons/Melee/Dagger/Weapon_Dagger.png")
		},
		"maze": {
			"name": "Maza de Impacto",
			"lore": "Un mazo pesado diseñado para fracturar corazas enemigas con pura fuerza cinética.",
			"stats": "Daño: 35 | APS: 0.7 | Empuje: Alto",
			"icon": preload("res://Art/Weapons/Melee/Mace/Weapon_Mace.png")
		},
		"hacha": {
			"name": "Hacha de Choque",
			"lore": "Un hacha balanceada capaz de rebanar tejidos mutantes con eficacia.",
			"stats": "Daño: 25 | APS: 1.0 | Rango: Medio",
			"icon": preload("res://Art/Weapons/Melee/Axe/Weapon_Axe.png")
		}
	},
	"items": {
		"arms_hp": {
			"name": "Módulo de Brazos (HP)",
			"lore": "Servo-implante que optimiza la distribución de energía defensiva del agente.",
			"stats": "Incrementa la salud del agente.",
			"icon": preload("res://Art/Items/Player/Arms/Item1_Arms.png")
		},
		"chest_armor": {
			"name": "Blindaje de Torso",
			"lore": "Placa reforzada de nano-compuestos absorbentes de impactos cinéticos.",
			"stats": "Incrementa la armadura global.",
			"icon": preload("res://Art/Items/Player/Body/Item1_Chest.png")
		},
		"boots_speed": {
			"name": "Servobotas de Combate",
			"lore": "Botas equipadas con amortiguadores hidráulicos de alta presión.",
			"stats": "Incrementa la velocidad de movimiento.",
			"icon": preload("res://Art/Items/Player/Legs/Item1_Boots.png")
		},
		"mezcladora": {
			"name": "Licuadora Mezcladora",
			"lore": "Dispositivo para procesar tejidos mutados y obtener fluidos estabilizados.",
			"stats": "+Daño, +Empuje, -Vel. Proyectil",
			"icon": preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
		},
		"aguijon_mecanico": {
			"name": "Aguijón Mecánico",
			"lore": "Componente ofensivo que inyecta neurotoxinas desestabilizadoras.",
			"stats": "Aumenta la cadencia y el daño crítico.",
			"icon": preload("res://Art/Items/Weapons/Item2_AguijonMecanico.png")
		},
		"cerebro": {
			"name": "Cerebro Sintético",
			"lore": "Un procesador bio-orgánico que asiste en los algoritmos de disparo del arma.",
			"stats": "Mejora los cálculos críticos y el daño.",
			"icon": preload("res://Art/Items/Weapons/Item3_Cerebro.png")
		},
		"cabeza_de_perro": {
			"name": "Cabeza de Sabueso Metálica",
			"lore": "Reliquia de combate cibernética que infunde ferocidad defensiva.",
			"stats": "Aumenta la armadura y el daño.",
			"icon": preload("res://Art/Items/Weapons/Item4_CabezaDePerro.png")
		},
		"pulmones": {
			"name": "Pulmones Bio-Asistidos",
			"lore": "Implante pulmonar artificial que optimiza el flujo de oxígeno bajo estrés de combate.",
			"stats": "Aumenta la velocidad y el alcance de los proyectiles.",
			"icon": preload("res://Art/Items/Weapons/Item5_Pulmones.png")
		},
		"motocicleta": {
			"name": "Núcleo de Motocicleta",
			"lore": "Micro-motor de combustión adaptado para forzar la potencia del armamento.",
			"stats": "Potente aumento al daño y empuje general.",
			"icon": preload("res://Art/Items/Weapons/Item6_Motocicleta.png")
		},
		"colmena": {
			"name": "Colmena Bio-Mecánica",
			"lore": "Un enjambre artificial encapsulado capaz de liberar micro-drones defensivos.",
			"stats": "Aumenta la probabilidad de impacto crítico.",
			"icon": preload("res://Art/Items/Weapons/Item7_Colmena.png")
		},
		"cabeza_humana": {
			"name": "Cabeza Humana Preservada",
			"lore": "Un cerebro intacto suspendido en solución de nutrientes, optimizando la concentración táctica.",
			"stats": "Aumenta el conteo de proyectiles y el daño general.",
			"icon": preload("res://Art/Items/Weapons/Item8_CabezaHumana.png")
		},
		"sierra_circular": {
			"name": "Sierra Circular",
			"lore": "Un disco de acero dentado de alta velocidad para cortar metal y carne.",
			"stats": "Aumenta el daño y el daño crítico.",
			"icon": preload("res://Art/Items/Weapons/Item9_SierraCircular.png")
		}
	},
	"npcs": {
		"ygor": {
			"name": "Ygor (El Chatarrero)",
			"lore": "Un enigmático sobreviviente que comercia con chatarra y componentes biológicos en las ruinas del complejo Lázaro.",
			"stats": "Rol: Comerciante / Proveedor de Mejoras",
			"icon": preload("res://Scenes/Ygor/Ygor-removebg-preview.png")
		}
	},
	"levels": {
		"level_1": {
			"name": "Laboratorios Iniciales (Piso 1)",
			"lore": "Sector de investigación genética de Lázaro Corp. Aquí comenzó la contaminación de los sujetos de prueba biológicos.",
			"stats": "Rango de peligro: Bajo | Amenazas: Seguidores, Tiradores",
			"icon": preload("res://Art/Enemy_Mutation/fx/Explosion_blue_circle1.png")
		},
		"room_4": {
			"name": "Área de Contención (Piso 4)",
			"lore": "Sector fuertemente blindado que albergaba sistemas de torretas robotizadas para evitar fugas de especímenes mutados.",
			"stats": "Rango de peligro: Medio | Amenazas: Torreta de Seguridad",
			"icon": preload("res://Art/Enemy_turret/turret1.png")
		},
		"room_7": {
			"name": "Núcleo de Mutación (Piso 7)",
			"lore": "La sección más profunda donde reposan los tanques principales de biomasa mutada. Cuidado extremo requerido.",
			"stats": "Rango de peligro: Crítico | Amenazas: Mutante Coloso (Tank)",
			"icon": preload("res://Art/Enemy_Mutation/fx/Explosion_blue_circle5.png")
		}
	}
}

static func get_category_for_id(entry_id: String) -> String:
	for cat in DATA.keys():
		if DATA[cat].has(entry_id):
			return cat
	return ""
