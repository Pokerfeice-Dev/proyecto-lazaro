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
			"stats": "+10% Vida Max",
			"icon": preload("res://Art/Items/Player/Arms/Item1_Arms.png")
		},
		"chest_armor": {
			"name": "Blindaje de Torso",
			"lore": "Placa reforzada de nano-compuestos absorbentes de impactos cinéticos.",
			"stats": "+2 Defensa, +5% Vida Max",
			"icon": preload("res://Art/Items/Player/Body/Item1_Chest.png")
		},
		"boots_speed": {
			"name": "Servobotas de Combate",
			"lore": "Botas equipadas con amortiguadores hidráulicos de alta presión.",
			"stats": "+12% Vel. Movimiento",
			"icon": preload("res://Art/Items/Player/Legs/Item1_Boots.png")
		},
		"torso_blindado": {
			"name": "Torso Musculoso",
			"lore": "Un torso injertado con tejido muscular denso y placas subdérmicas acorazadas.",
			"stats": "+25% Vida Max, +2 Defensa, -5% Vel. Movimiento",
			"icon": preload("res://Art/Items/Player/Body/Item2_TorsoBlindado.png")
		},
		"torso_espinado": {
			"name": "Torso Canino",
			"lore": "Estructura espinada salvaje y placas cinéticas que canalizan instintos primordiales.",
			"stats": "+10% Vida Max, +1 Defensa, Refleja empuje al ser dañado",
			"icon": preload("res://Art/Items/Player/Body/Item3_TorsoEspinado.png")
		},
		"torso_ligero": {
			"name": "Torso Ligero",
			"lore": "Carcasa aerodinámica ultra delgada de fibra de carbono para máxima flexibilidad.",
			"stats": "+10% Vel. Movimiento, +15% Vel. Dash, -20% CD Dash, -15% Vida Max, -1 Defensa",
			"icon": preload("res://Art/Items/Player/Body/Item4_TorsoLigero.png")
		},
		"piernas_rodantes": {
			"name": "Piernas Ligeras",
			"lore": "Prótesis cibernéticas dotadas de ruedas de alta aceleración para desplazamiento continuo.",
			"stats": "+15% Vel. Movimiento, +20% Vel. Dash, -30% CD Dash",
			"icon": preload("res://Art/Items/Player/Legs/Item2_PiernasRodantes.png")
		},
		"piernas_caninas": {
			"name": "Piernas Caninas",
			"lore": "Extremidades híbridas canino-cibernéticas diseñadas para reflejos feroces.",
			"stats": "+10% Vel. Movimiento, +25% Vel. Ataque, +1 Defensa",
			"icon": preload("res://Art/Items/Player/Legs/Item3_PiernasCaninas.png")
		},
		"piernas_bionicas": {
			"name": "Piernas Musculosas",
			"lore": "Extremidades inferiores servo-asistidas con núcleos de potencia muscular.",
			"stats": "+15% Vida Max, +1 Defensa, +1 Vida al juntar flesh, -5% Vel. Movimiento",
			"icon": preload("res://Art/Items/Player/Legs/Item4_PiernasBionicas.png")
		},
		"brazo_reforzado": {
			"name": "Brazo Musculoso",
			"lore": "Implante de brazo potenciado con tendones sintéticos de alta presión y fibras densas.",
			"stats": "+3 Daño Base, +15% Empuje Melee, +1 Defensa",
			"icon": preload("res://Art/Items/Player/Arms/Item2_BrazoReforzado.png")
		},
		"brazo_ligero": {
			"name": "Brazo Ligero",
			"lore": "Brazo estilizado de fibra de carbono optimizado para movimientos veloces.",
			"stats": "+15% Vel. Ataque, +5% Vel. Movimiento",
			"icon": preload("res://Art/Items/Player/Arms/Item3_BrazoLigero.png")
		},
		"brazo_armado": {
			"name": "Brazo Canino",
			"lore": "Hojas retráctiles afiladas de titanio integradas que imitan garras salvajes.",
			"stats": "+20% Alcance Melee, +15% Vel. Ataque, -1 Defensa",
			"icon": preload("res://Art/Items/Player/Arms/Item4_BrazoArmado.png")
		},
		"mezcladora": {
			"name": "Licuadora Mezcladora",
			"lore": "Dispositivo para procesar tejidos mutados y obtener fluidos estabilizados.",
			"stats": "+5 Daño, +30 Empuje, -50 Vel. Proyectil",
			"icon": preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
		},
		"aguijon_mecanico": {
			"name": "Aguijón Mecánico",
			"lore": "Componente ofensivo que inyecta neurotoxinas desestabilizadoras.",
			"stats": "+1 Perforación, +50 Vel. Proyectil, -1 Daño",
			"icon": preload("res://Art/Items/Weapons/Item2_AguijonMecanico.png")
		},
		"cerebro": {
			"name": "Cerebro Sintético",
			"lore": "Un procesador bio-orgánico que asiste en los algoritmos de disparo del arma.",
			"stats": "-5 Dispersión, +1.0s Tiempo de Vida",
			"icon": preload("res://Art/Items/Weapons/Item3_Cerebro.png")
		},
		"cabeza_de_perro": {
			"name": "Cabeza de Sabueso Metálica",
			"lore": "Reliquia de combate cibernética que infunde ferocidad defensiva.",
			"stats": "+1 Proyectiles, +10% Vel. Ataque, +5 Dispersión",
			"icon": preload("res://Art/Items/Weapons/Item4_CabezaDePerro.png")
		},
		"pulmones": {
			"name": "Pulmones Bio-Asistidos",
			"lore": "Implante pulmonar artificial que optimiza el flujo de oxígeno bajo estrés de combate.",
			"stats": "+20% Vel. Ataque, +50 Empuje",
			"icon": preload("res://Art/Items/Weapons/Item5_Pulmones.png")
		},
		"motocicleta": {
			"name": "Núcleo de Motocicleta",
			"lore": "Micro-motor de combustión adaptado para forzar la potencia del armamento.",
			"stats": "+30% Vel. Ataque, -2 Daño",
			"icon": preload("res://Art/Items/Weapons/Item6_Motocicleta.png")
		},
		"colmena": {
			"name": "Colmena Bio-Mecánica",
			"lore": "Un enjambre artificial encapsulado capaz de liberar micro-drones defensivos.",
			"stats": "+10% Prob. Crítico",
			"icon": preload("res://Art/Items/Weapons/Item7_Colmena.png")
		},
		"cabeza_humana": {
			"name": "Cabeza Humana Preservada",
			"lore": "Un cerebro intacto suspendido en solución de nutrientes, optimizando la concentración táctica.",
			"stats": "+1 Proyectiles, -15% Multiplicador de Daño",
			"icon": preload("res://Art/Items/Weapons/Item8_CabezaHumana.png")
		},
		"sierra_circular": {
			"name": "Sierra Circular",
			"lore": "Un disco de acero dentado de alta velocidad para cortar metal y carne.",
			"stats": "+20% Multiplicador de Daño, +20% Daño Crítico",
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
