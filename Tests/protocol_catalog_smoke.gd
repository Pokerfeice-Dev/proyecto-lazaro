extends Node

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_verify")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
		push_error("PROTOCOL_CATALOG_FAILED: " + message)

func _entry(id: String) -> Dictionary:
	for entry in OmniaCatalog.entries("PROTOCOLOS"):
		if entry.id == id:
			return entry
	return {}

func _verify() -> void:
	var previous_scrap: int = GameData.scrap
	var previous_protocols: Array[String] = GameData.unlocked_protocols.duplicate()
	var previous_active: String = GameData.active_protocol
	var previous_event: bool = GameData.event_demo_active
	var previous_save_time: String = GameData.last_save_time
	# begin_sandbox conserva el progreso pero igualmente escribe el archivo.
	# Esta bandera hace que save_game salga antes de cualquier escritura; no
	# iniciamos el evento ni alteramos slots o archivos de guardado reales.
	GameData.event_demo_active = true
	GameData.unlocked_protocols.clear()
	GameData.active_protocol = ""
	GameData.scrap = 399
	var shield = _entry("circuito_emergencia")
	_check(not OmniaCatalog.can_act(shield), "Una compra sin chatarra suficiente está deshabilitada")
	_check(not OmniaCatalog.purchase(shield), "Una compra sin fondos se rechaza")
	_check(GameData.scrap == 399 and GameData.unlocked_protocols.is_empty() and GameData.active_protocol.is_empty(), "La compra fallida no cambia el progreso")
	GameData.scrap = 400
	_check(OmniaCatalog.can_act(shield), "El precio exacto permite comprar")
	_check(OmniaCatalog.purchase(shield), "Se desbloquea el primer protocolo")
	_check(GameData.scrap == 0 and GameData.active_protocol == shield.id, "Comprar cobra una vez y equipa")
	_check(GameData.unlocked_protocols.size() == 1, "Se registra un único desbloqueo")
	_check(OmniaCatalog.shown_cost(shield) == 0 and OmniaCatalog.can_act(shield), "La entrada vieja reconoce la propiedad actual sin exigir chatarra")
	_check(OmniaCatalog.purchase(shield), "Repetir la compra desde una entrada vieja es válido")
	_check(GameData.scrap == 0 and GameData.active_protocol == shield.id and GameData.unlocked_protocols.size() == 1, "Repetir no cobra, no duplica y mantiene equipado")

	var repair = _entry("reparacion_autonoma")
	# Simula datos visibles desactualizados: la propiedad y precio real mandan.
	repair.state = "comprado"
	repair.cost = 0
	GameData.scrap = 499
	_check(not OmniaCatalog.can_act(repair) and not OmniaCatalog.purchase(repair), "Un estado viejo no desbloquea gratis ni ignora el precio real")
	_check(GameData.active_protocol == shield.id and GameData.scrap == 499, "El rechazo mantiene el protocolo previo")
	GameData.scrap = 500
	_check(OmniaCatalog.purchase(repair), "Se puede comprar otro protocolo")
	_check(GameData.active_protocol == repair.id and GameData.scrap == 0, "El nuevo reemplaza al anterior por su precio real")
	_check(GameData.unlocked_protocols.has(shield.id) and GameData.unlocked_protocols.has(repair.id), "Los dos desbloqueos siguen siendo permanentes")
	_check(OmniaCatalog.purchase(shield) and GameData.active_protocol == shield.id, "Cambiar al protocolo ya comprado no cuesta chatarra")
	var equipped = _entry(shield.id)
	_check(OmniaCatalog.purchase(equipped) and GameData.active_protocol.is_empty(), "La acción desequipar deja el espacio libre")
	_check(OmniaCatalog.purchase(equipped) and GameData.active_protocol == shield.id, "Una entrada activa vieja puede reequiparse sin cobrar")
	_check(GameData.scrap == 0, "Equipar y desequipar nunca cobra")

	var invalid = {"id": "protocolo_inexistente", "kind": "protocol", "state": "comprado", "cost": 0}
	_check(not OmniaCatalog.can_act(invalid) and not OmniaCatalog.purchase(invalid), "Un ID desconocido no se puede comprar ni equipar")
	_check(GameData.active_protocol == shield.id and GameData.unlocked_protocols.size() == 2, "Un ID inválido no cambia el progreso")
	_check(GameData.last_save_time == previous_save_time, "Las pruebas no ejecutaron el guardado persistente")

	GameData.scrap = previous_scrap
	GameData.unlocked_protocols.clear()
	GameData.unlocked_protocols.append_array(previous_protocols)
	GameData.active_protocol = previous_active
	GameData.event_demo_active = previous_event
	if _failures.is_empty():
		print("PROTOCOL_CATALOG_OK")
	get_tree().quit(0 if _failures.is_empty() else 1)
