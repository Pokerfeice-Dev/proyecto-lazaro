class_name CodexData
extends RefCounted

const DATA = {
	"enemies": {
		"follower": {
			"name": "Perro Mecánico",
			"lore": "Unidad canina automatizada de Asphodel Laboratories. Rastrea cualquier señal de tejido vivo y ataca cuerpo a cuerpo en manada, sin detenerse hasta destrozar a su presa.",
			"stats": "Vida: 60 | Daño: 10 | Velocidad: Alta | Persecución directa",
			"icon": preload("res://Art/Enemy_Mutation/dog_codex_icon.png")
		},
		"shooter": {
			"name": "Carpenter",
			"lore": "Antigua unidad de mantenimiento reconvertida en centinela de Asphodel. Dispara clavos a presión con su pistola neumática y se repliega mientras el objetivo se acerca.",
			"stats": "Vida: 40 | Daño: 10 | Cadencia: 1.5s | Rango: Largo",
			"icon": preload("res://Art/Enemy_Shooter/carpenter_codex_icon.png")
		},
		"tank": {
			"name": "Mecha",
			"lore": "Maquinaria pesada de demolición requisada y armada por Asphodel. Su mezcladora de cemento convertida en garra aplasta todo lo que entra en su radio de patrulla.",
			"stats": "Vida: 180 | Daño: 25 | Velocidad: Muy baja | Rango: Corto",
			"icon": preload("res://Art/Enemy_tank/mecha_codex_icon.png")
		},
		"turret": {
			"name": "Delivery",
			"lore": "Motociclista repartidor sepultado y fusionado al asfalto por la biofabricación. Inmóvil, pero dispara con una cadencia implacable a todo lo que entra en su radio de alcance.",
			"stats": "Vida: 50 | Cadencia: 1.5s | Alcance: Muy largo | Estático",
			"icon": preload("res://Art/Enemy_turret/deliverydriver_codex_icon.png")
		},
		"charger": {
			"name": "Robo-Abeja",
			"lore": "Dron de combate liberado por la Apicultora, aunque también aparece de forma natural en las salas. Se comprime antes de embestir en línea recta a máxima velocidad.",
			"stats": "Vida: 35 | Daño: 12 | Embestida: Velocidad muy alta",
			"icon": preload("res://Art/Enemy_Summoner/robobee_codex_icon.png")
		},
		"spawner": {
			"name": "Apicultora",
			"lore": "Guardiana enjambre que evita el combate directo. Mantiene la distancia con el objetivo mientras libera oleadas de Robo-Abejas para desgastarlo.",
			"stats": "Vida: 80 | Invoca Robo-Abejas cada ~3.5s | Sin ataque directo",
			"icon": preload("res://Art/Enemy_Summoner/beekeeper_codex_icon.png")
		},
		"boss": {
			"name": "Centinela Génesis",
			"lore": "Guardián del Distrito Asphodel, empotrado en la pared de su sala hasta que algo lo despierta. Barre el lugar con un par de láseres giratorios y descarga anillos de proyectiles; al caer bajo el 50% de su vida activa el Protocolo Ómega: se repara, se vuelve más rápido y suma una lluvia de misiles.",
			"stats": "Vida: 1000 | Daño: 25 (misiles: 30) | 2 fases | Fase 2 al 50%: +20% de vida, ataques más rápidos",
			"icon": preload("res://Art/Enemy_Boss_1/Boss_sprite.png")
		},
		"crypt_ghoul": {
			"name": "Ghoul",
			"lore": "Cadáver reanimado por la biomasa que se filtró a las galerías. Conserva el instinto de un cazador: te sigue a distancia y, en cuanto le das la espalda, acelera para morderte. Mirarlo de frente lo frena.",
			"stats": "Vida: 65 | Daño: 12 | Velocidad: Muy alta | Acelera si le das la espalda",
			"icon": preload("res://Art/Enemies/Crypt/Ghoul/ghoul_codex_icon.png")
		},
		"crypt_gargoyle": {
			"name": "Gárgola",
			"lore": "Estatua del viejo mausoleo del complejo, despertada por las esporas. Golpea en un abanico corto y, cuando recibe daño, se cubre de piedra: mientras está petrificada no le afectan los golpes ni el empuje. Ataca cuando abandone su defensa.",
			"stats": "Vida: 130 | Daño: 16 | Petrificación: 2 s | Anticipación: 0,55 s",
			"icon": preload("res://Art/Enemies/Crypt/Gargoyle/gargoyle_codex_icon.png")
		},
		"crypt_centipede": {
			"name": "Ciempiés tóxico",
			"lore": "Insecto gigante criado en los tanques de cultivo y abandonado en la cripta. Recorre las galerías ondulando su cuerpo segmentado y, antes de atacar, apunta las mandíbulas: el gas que suelta envenena durante varios segundos. Sal del cono marcado antes de la descarga.",
			"stats": "Vida: 95 | Daño: 10 + veneno | Alcance: Medio | Anticipación: 0,8 s",
			"icon": preload("res://Art/Enemies/Crypt/Centipede/centipede_codex_icon.png")
		},
		"crypt_death_squad": {
			"name": "Escuadrón de la muerte",
			"lore": "Restos de la guardia de seguridad del complejo, que siguen patrullando aunque ya no les quede carne. Apuntan, fijan la dirección y disparan una ráfaga de tres balas. Muévete en cuanto veas la mira.",
			"stats": "Vida: 100 | Daño: 13 por bala | Ráfaga: 3 disparos | Anticipación: 0,65 s",
			"icon": preload("res://Art/Enemies/Crypt/DeathSquad/death_squad_codex_icon.png")
		},
		"crypt_laser_eye": {
			"name": "Ojo torreta",
			"lore": "Órgano de un experimento fallido que aprendió a flotar sobre sus propios nervios. No se mueve: se encoge, carga y dispara un rayo que deja de seguirte poco antes de soltarlo. Muévete hacia un costado o busca cobertura; las paredes lo bloquean.",
			"stats": "Vida: 85 | Daño: 22 | Alcance: Muy largo | Inmóvil | Carga: 1,2 s",
			"icon": preload("res://Art/Enemies/Crypt/LaserEye/laser_eye_codex_icon.png")
		},
		"crypt_dead_beekeeper": {
			"name": "Apicultora muerta",
			"lore": "Lo que quedó de la Apicultora después de caer en la cripta. Tiene la piel verdosa y la ropa rota, pero sigue cuidando su colmena: invoca hasta tres abejas carnívoras. Si la derrotas, el enjambre muere con ella.",
			"stats": "Vida: 120 | Invoca hasta 3 abejas | Recarga: 4,5 s",
			"icon": preload("res://Art/Enemies/Crypt/DeadBeekeeper/dead_beekeeper_codex_icon.png")
		},
		"crypt_flesh_bee": {
			"name": "Abeja carnívora",
			"lore": "Robo-Abeja cubierta de carne, con alas de hueso, criada en la colmena podrida de la Apicultora muerta. Se detiene, apunta y escupe un proyectil.",
			"stats": "Vida: 22 | Daño: 6 | Velocidad: Muy alta | Ataque a distancia",
			"icon": preload("res://Art/Enemies/Crypt/FleshBee/flesh_bee_codex_icon.png")
		},
		"crypt_bell_keeper": {
			"name": "Campanero de Réquiem",
			"lore": "Un viejo custodio de la cripta que todavía toca a muerto. Cada campanada marca el suelo donde estás y, un segundo después, el eco estalla: no regreses sobre tus pasos. Tras tres campanadas queda expuesto.",
			"stats": "Vida: 95 | Daño: 16 por eco | 3 campanadas | Eco: 1 s",
			"icon": preload("res://Art/Enemies/Crypt/BellKeeper/bell_keeper_codex_icon.png")
		},
		"boss2": {
			"name": "El Primogénito",
			"lore": "El primer intento de Lázaro: un sujeto que no resistió la resurrección y fue arrojado a la cripta. Siguió vivo absorbiendo la biomasa hasta convertirse en una masa de carne cosida con grapas quirúrgicas, que todavía lleva su brazalete de paciente de Lázaro Corp. Persigue a los saltos, desaparece hacia el techo y cae sobre tu sombra soltando un anillo de huesos, escupe bilis corrosiva que deja charcos y, si lo acorralas, vomita ghouls y abejas carnívoras. Al bajar del 40% de vida el hambre lo despierta: se regenera, se vuelve más rápido y encadena sus saltos.",
			"stats": "Vida: 1400 | Daño: 22 | 2 fases (la 2 al 40%: +20% de vida) | Ataques: gran salto, anillo de huesos, bilis, invocación",
			"icon": preload("res://Art/Enemy_Boss_2/boss2_codex_icon.png")
		},
		"boss3": {
			"name": "Prometeo",
			"lore": "El reflejo oscuro de Lázaro y la última barrera del Núcleo. Pelea con todo lo que Lázaro aprendió en el camino: cambia de arma cada pocos ataques, esquiva con dash y castiga a quien gasta el suyo. Al verse herido se desdobla en un clon, y al final se prende con el fuego que robó.",
			"stats": "Vida: 2600 | Daño: 14 a distancia, 22 cuerpo a cuerpo | 3 fases (al 65% y al 30%) | Armas: todas las del jugador",
			"icon": preload("res://Art/Enemies/Prometeo/prometeo_codex_icon.png")
		}
	},
	"weapons": {
		"pistol": {
			"name": "Pistola",
			"lore": "Arma corta estándar y confiable del personal táctico. Versátil y ligera.",
			"stats": "Daño: 10 | APS: 1.0 | Precisión: Alta",
			"icon": preload("res://Art/Weapons/Distance/Pistol/weapon_revolver_sprite.png")
		},
		"shotgun": {
			"name": "Escopeta",
			"lore": "Arma principal pesada que proyecta ráfagas de perdigones a corta distancia.",
			"stats": "Daño: Alto | Dispersión: Amplia | Proyectiles: 4",
			"icon": preload("res://Art/Weapons/Distance/Shotgun/weapon_shotgun_sprite.png")
		},
		"uzi": {
			"name": "Uzi",
			"lore": "Arma compacta automática con gran cadencia de fuego para control a media distancia.",
			"stats": "Daño: Medio | APS: Alta | Dispersión: Media",
			"icon": preload("res://Art/Weapons/Distance/Uzi/weapon_uzi_sprite.png")
		},
		"daga": {
			"name": "Daga",
			"lore": "Un filo corto y mortífero tallado en cristal de sílice. Rápida pero con corto alcance.",
			"stats": "Daño: 15 | APS: 1.5 | Rango: Corto",
			"icon": preload("res://Art/Weapons/Melee/Dagger/weapon_dagger_sprite.png")
		},
		"maze": {
			"name": "Maza Pesada",
			"lore": "Un mazo pesado diseñado para fracturar corazas enemigas con pura fuerza cinética.",
			"stats": "Daño: 35 | APS: 0.7 | Empuje: Alto",
			"icon": preload("res://Art/Weapons/Melee/Mace/weapon_mace_sprite.png")
		},
		"hacha": {
			"name": "Hacha de Mano",
			"lore": "Un hacha balanceada capaz de rebanar tejidos mutantes con eficacia.",
			"stats": "Daño: 25 | APS: 1.0 | Rango: Medio",
			"icon": preload("res://Art/Weapons/Melee/Axe/weapon_axe_sprite.png")
		}
	},
	"items": {
		"badajo_requiem": {"name": "Badajo", "lore": "Badajo de la campana del Campanero de Réquiem. Todavía vibra con cada golpe.", "stats": "+30% daño crítico", "icon": preload("res://Art/Items/Crypt/badajo_requiem.png")},
		"corazon_petreo": {"name": "Corazón de Piedra", "lore": "Núcleo de piedra que late dentro de cada Gárgola. Endurece los golpes de quien lo lleva.", "stats": "+15% daño", "icon": preload("res://Art/Items/Crypt/corazon_petreo.png")},
		"tendon_necrotico": {"name": "Tendón", "lore": "Tendón del Ghoul, elástico aun después de muerto. Acelera los movimientos del arma.", "stats": "+15% cadencia", "icon": preload("res://Art/Items/Crypt/tendon_necrotico.png")},
		"glandula_toxica": {"name": "Glándula tóxica", "lore": "Glándula de gas del Ciempiés tóxico. Concentrada, vuelve letales los impactos críticos.", "stats": "+25% daño crítico", "icon": preload("res://Art/Items/Crypt/glandula_toxica.png")},
		"placa_funeraria": {"name": "Lápida", "lore": "Placa de identificación de un soldado del Escuadrón de la muerte. Pesa más de lo que parece.", "stats": "+18% daño", "icon": preload("res://Art/Items/Crypt/placa_funeraria.png")},
		"lente_sepulcral": {"name": "Lente sepulcral", "lore": "Cristalino del Ojo torreta. Enfoca los disparos hasta atravesar a un enemigo más.", "stats": "+1 perforación", "icon": preload("res://Art/Items/Crypt/lente_sepulcral.png")},
		"panal_cadaverico": {"name": "Panal Podrido", "lore": "Trozo de la colmena podrida de la Apicultora muerta. Sus celdas guían los disparos hacia los puntos débiles.", "stats": "+12% prob. crítica", "icon": preload("res://Art/Items/Crypt/panal_cadaverico.png")},
		"mandibula_carnivora": {"name": "Mandíbula", "lore": "Mandíbula de una Abeja carnívora. Desgarra la carne en los impactos críticos.", "stats": "+15% daño crítico", "icon": preload("res://Art/Items/Crypt/mandibula_carnivora.png")},

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
			"name": "Licuadora",
			"lore": "Dispositivo para procesar tejidos mutados y obtener fluidos estabilizados.",
			"stats": "+5 Daño, +30 Empuje, -50 Vel. Proyectil",
			"icon": preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
		},
		"aguijon_mecanico": {
			"name": "Aguijón",
			"lore": "Componente ofensivo que inyecta neurotoxinas desestabilizadoras.",
			"stats": "+1 Perforación, +50 Vel. Proyectil, -1 Daño",
			"icon": preload("res://Art/Items/Weapons/Item2_AguijonMecanico.png")
		},
		"cerebro": {
			"name": "Cerebro",
			"lore": "Un procesador bio-orgánico que asiste en los algoritmos de disparo del arma.",
			"stats": "-5 Dispersión, +1.0s Tiempo de Vida",
			"icon": preload("res://Art/Items/Weapons/Item3_Cerebro.png")
		},
		"cabeza_de_perro": {
			"name": "Cabeza de Perro",
			"lore": "Reliquia de combate cibernética que infunde ferocidad defensiva.",
			"stats": "+1 Proyectiles, +10% Vel. Ataque, +5 Dispersión",
			"icon": preload("res://Art/Items/Weapons/Item4_CabezaDePerro.png")
		},
		"pulmones": {
			"name": "Pulmones",
			"lore": "Implante pulmonar artificial que optimiza el flujo de oxígeno bajo estrés de combate.",
			"stats": "+20% Vel. Ataque, +50 Empuje",
			"icon": preload("res://Art/Items/Weapons/Item5_Pulmones.png")
		},
		"motocicleta": {
			"name": "Motocicleta",
			"lore": "Micro-motor de combustión adaptado para forzar la potencia del armamento.",
			"stats": "+30% Vel. Ataque, -2 Daño",
			"icon": preload("res://Art/Items/Weapons/Item6_Motocicleta.png")
		},
		"colmena": {
			"name": "Colmena",
			"lore": "Un enjambre artificial encapsulado capaz de liberar micro-drones defensivos.",
			"stats": "+10% Prob. Crítico",
			"icon": preload("res://Art/Items/Weapons/Item7_Colmena.png")
		},
		"cabeza_humana": {
			"name": "Cabeza Humana",
			"lore": "Un cerebro intacto suspendido en solución de nutrientes, optimizando la concentración táctica.",
			"stats": "+1 Proyectiles, -15% Multiplicador de Daño",
			"icon": preload("res://Art/Items/Weapons/Item8_CabezaHumana.png")
		},
		"sierra_circular": {
			"name": "Sierra",
			"lore": "Un disco de acero dentado de alta velocidad para cortar metal y carne.",
			"stats": "+20% Multiplicador de Daño, +20% Daño Crítico",
			"icon": preload("res://Art/Items/Weapons/Item9_SierraCircular.png")
		},
		"bateria": {
			"name": "Batería",
			"lore": "Condensador químico altamente inestable. Sobrecarga las balas con descargas eléctricas capaces de paralizar sistemas nerviosos y circuitos por 1 segundo.",
			"stats": "+10% Probabilidad de Stun (1s), Proyectil Eléctrico Azul",
			"icon": preload("res://Art/Items/Weapons/Item10_Bateria.png")
		},
		"gasolina": {
			"name": "Gasolina",
			"lore": "Combustible refinado altamente inflamable. Impregna los disparos para prender fuego a los objetivos durante 3 segundos.",
			"stats": "+20% Probabilidad de Quemadura (3s), Proyectil Ígneo Rojo",
			"icon": preload("res://Art/Items/Weapons/Item11_Gasolina.png")
		},
		"nitrogeno": {
			"name": "Nitrógeno",
			"lore": "Cápsula criogénica a presión extrema. Congela parcialmente las articulaciones del enemigo al impacto, reduciendo su velocidad a la mitad durante 3 segundos.",
			"stats": "+30% Probabilidad de Ralentización (3s), Proyectil Glacial Celeste",
			"icon": preload("res://Art/Items/Weapons/Item12_Nitrogeno.png")
		}
	},
	"npcs": {
		"ygor": {
			"name": "Ygor",
			"lore": "Un enigmático sobreviviente que comercia con chatarra y componentes biológicos en las ruinas del complejo Lázaro.",
			"stats": "Rol: Mercader de prótesis y órganos",
			"icon": preload("res://Art/Codex/ygor_codex_icon.tres")
		},
		"victoria": {
			"name": "Victoria",
			"lore": "La científica que liberó a Lázaro para devolverle el bienestar a la humanidad. Desde el laboratorio opera O.M.N.I.A. y convierte lo que traes de cada run en mejoras permanentes. En la sala de entrenamiento te da consejos mientras practicas.",
			"stats": "Rol: Científica / O.M.N.I.A. / Entrenamiento",
			"icon": preload("res://Art/Codex/victoria_codex_icon.tres")
		}
	},
	"levels": {
		"distrito_1": {
			"name": "Zona 1: Distrito Asphodel",
			"lore": "Sector de investigación genética de Lázaro Corp. Aquí comenzó la contaminación de los sujetos de prueba biológicos.",
			"stats": "Rango de peligro: Bajo-Medio | Amenazas: Perros Mecánicos, Carpenters, Deliverys, Mechas, Robo-Abejas, Apicultora | Jefe: Centinela Génesis",
			"icon": preload("res://Art/Codex/zona1_codex_icon.png")
		},
		"distrito_2": {
			"name": "Zona 2: La Cripta",
			"lore": "Galerías bajo el complejo donde la biomasa mutada escapó a todo control. Pocos exploradores vuelven de aquí con el mismo aspecto con el que entraron.",
			"stats": "Rango de peligro: Alto | Amenazas: Ghouls, Gárgolas, Ciempiés tóxicos, Escuadrón de la muerte, Ojos torreta, Campanero de Réquiem, Apicultora muerta, Abejas carnívoras | Jefe: El Primogénito",
			"icon": preload("res://Art/Codex/zona2_codex_icon_cripta.png")
		},
		"distrito_3": {
			"name": "Zona 3: El Núcleo",
			"lore": "El corazón del complejo, invadido por raíces que laten como venas. Aquí espera Prometeo.",
			"stats": "Rango de peligro: Extremo | Amenazas: Prometeo",
			"icon": preload("res://Art/Codex/zona3_codex_icon.png")
		}
	}
}

static func get_category_for_id(entry_id: String) -> String:
	for cat in DATA.keys():
		if DATA[cat].has(entry_id):
			return cat
	return ""
