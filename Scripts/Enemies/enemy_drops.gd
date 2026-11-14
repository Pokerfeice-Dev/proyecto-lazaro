class_name EnemyDrops
extends RefCounted
# Qué pieza suelta cada enemigo. Cada enemigo suelta lo que tiene sentido por lo que es: la cabeza
# de perro la da el perro, la sierra el carpintero, el badajo el campanero, etc. Lo que se repite
# en una lista tiene más probabilidad. Los enemigos que no aparecen aquí (jefes, invocados) usan
# el pozo general de EnemyBase.all_items.
# La clave es el nombre del archivo de la escena del enemigo, sin extensión.

const W := "res://Art/Items/Weapons/"
const B := "res://Art/Items/Player/Body/"
const A := "res://Art/Items/Player/Arms/"
const L := "res://Art/Items/Player/Legs/"
const C := "res://Art/Items/Crypt/"

const LICUADORA := W + "Item1.tres"
const AGUIJON := W + "Item2.tres"
const CEREBRO := W + "Item3.tres"
const CABEZA_PERRO := W + "Item4.tres"
const PULMONES := W + "Item5.tres"
const MOTO := W + "Item6.tres"
const COLMENA := W + "Item7_Colmena.tres"
const CABEZA_HUMANA := W + "Item8_CabezaHumana.tres"
const SIERRA := W + "Item9_SierraCircular.tres"
const BATERIA := W + "Item10_Bateria.tres"
const GASOLINA := W + "Item11_Gasolina.tres"
const NITROGENO := W + "Item12_Nitrogeno.tres"

const TORSO_MUSCULOSO := B + "Item2_TorsoBlindado.tres"
const TORSO_CANINO := B + "Item3_TorsoEspinado.tres"
const TORSO_LIGERO := B + "Item4_TorsoLigero.tres"
const TORSO_GORDO := B + "Item5_TorsoGordo.tres"
const BRAZO_MUSCULOSO := A + "Item2_BrazoReforzado.tres"
const BRAZO_LIGERO := A + "Item3_BrazoLigero.tres"
const BRAZO_CANINO := A + "Item4_BrazoArmado.tres"
const BRAZO_GORDO := A + "Item5_BrazoGordo.tres"
const PIERNAS_LIGERAS := L + "Item2_PiernasRodantes.tres"
const PIERNAS_CANINAS := L + "Item3_PiernasCaninas.tres"
const PIERNAS_MUSCULOSAS := L + "Item4_PiernasBionicas.tres"
const PIERNAS_GORDAS := L + "Item5_PiernasGordas.tres"

const BADAJO := C + "badajo_requiem.tres"
const CORAZON := C + "corazon_petreo.tres"
const TENDON := C + "tendon_necrotico.tres"
const GLANDULA := C + "glandula_toxica.tres"
const LAPIDA := C + "placa_funeraria.tres"
const LENTE := C + "lente_sepulcral.tres"
const PANAL := C + "panal_cadaverico.tres"
const MANDIBULA := C + "mandibula_carnivora.tres"

const DROPS := {
	# Zona 1 (laboratorio)
	"EnemyFollower": [CABEZA_PERRO, CABEZA_PERRO, TORSO_CANINO, BRAZO_CANINO, PIERNAS_CANINAS],
	"EnemyShooter": [SIERRA, SIERRA, BRAZO_MUSCULOSO, PIERNAS_MUSCULOSAS],
	"EnemyTank": [MOTO, MOTO, BATERIA, TORSO_MUSCULOSO, PIERNAS_MUSCULOSAS],
	"EnemyTurret": [GASOLINA, NITROGENO, BATERIA],
	"EnemyTurretLaser": [BATERIA, BATERIA, NITROGENO],
	"EnemyTurretHoming": [GASOLINA, GASOLINA, NITROGENO],
	"EnemySummoner": [CEREBRO, CABEZA_HUMANA, PULMONES, LICUADORA, TORSO_LIGERO],
	# Enemigos nuevos
	"EnemyKamikaze": [GASOLINA, GASOLINA, NITROGENO, PIERNAS_LIGERAS],
	"EnemyKiter": [AGUIJON, AGUIJON, BRAZO_LIGERO, PIERNAS_LIGERAS, TORSO_LIGERO],
	"EnemyShielder": [TORSO_MUSCULOSO, TORSO_MUSCULOSO, BRAZO_MUSCULOSO, PIERNAS_MUSCULOSAS],
	"EnemyWanderingArm": [BRAZO_GORDO, BRAZO_GORDO, BRAZO_CANINO, BRAZO_LIGERO, BRAZO_MUSCULOSO],
	"EnemyHollowTorso": [TORSO_GORDO, TORSO_GORDO, TORSO_CANINO, TORSO_LIGERO, PULMONES],
	"EnemyLazarusEcho": [CABEZA_HUMANA, CEREBRO, PIERNAS_GORDAS],
	# Zona 2 (cripta): cada una suelta la pieza que dice su descripción en el códice; el set gordo
	# sale de las más pesadas.
	"CryptBellKeeper": [BADAJO],
	"CryptGargoyle": [CORAZON, CORAZON, PIERNAS_GORDAS],
	"CryptGhoul": [TENDON, TENDON, TORSO_GORDO, BRAZO_GORDO],
	"CryptCentipede": [GLANDULA],
	"CryptDeathSquad": [LAPIDA, LAPIDA, BRAZO_GORDO],
	"CryptLaserEye": [LENTE],
	"CryptDeadBeekeeperSummoner": [PANAL, PANAL, COLMENA, AGUIJON],
	"CryptFleshBee": [MANDIBULA],
}

static var _cache: Dictionary = {}

## Piezas que puede soltar el enemigo cuyo archivo de escena es scene_path; vacío si no tiene lista.
static func pool_for(scene_path: String) -> Array[ItemData]:
	var key := scene_path.get_file().get_basename()
	if _cache.has(key): return _cache[key]
	var result: Array[ItemData] = []
	for path in DROPS.get(key, []):
		var item := load(path) as ItemData
		if item != null: result.append(item)
	_cache[key] = result
	return result
