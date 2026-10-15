extends RefCounted
class_name BossBarHelper

## Crea la barra grande de vida de los jefes (BossHealthBar) con su entrada
## animada. Devuelve { "instance": BossHealthBar, "bar": Range } para que cada
## jefe siga actualizando "bar.value" como antes.
## options: ver BossHealthBar.create ("intro", "subtitle", "phase_marks"...).

static func create(tree: SceneTree, display_name: String, max_value: int, value: int, options: Dictionary = {}) -> Dictionary:
	var bar = BossHealthBar.create(tree, display_name, max_value, value, options)
	return {"instance": bar, "bar": bar.gauge}
