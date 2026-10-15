# Entrada de los jefes y barra de vida

## Barra (`Scripts/UI/boss_health_bar.gd`)

`BossHealthBar.create(tree, nombre, vida_max, vida, opciones)` agrega la barra a la escena actual y devuelve el nodo. `gauge` (un `BossBarGauge`, que es un `Range`) es lo que el jefe actualiza con `value`.

Opciones:

| clave | por defecto | qué hace |
|---|---|---|
| `intro` | `true` | `true`: título grande que se convierte en la barra. `false`: la barra baja directo. |
| `eyebrow` | `ZONA N · NOMBRE` | línea chica de arriba (sale del nombre de la escena `LevelN_...` o de `GameData.current_level`). |
| `subtitle` | `JEFE DE ZONA` | línea bajo el título durante la entrada. |
| `accent` | rojo `#E5484D` | color de los filos de la franja y de la sombra del nombre. |
| `phase_marks` | `[]` | umbrales de fase (0..1) que se marcan en la barra. |

`close()` la desvanece (al morir el jefe). `BossBarHelper.create(...)` sigue existiendo y devuelve `{instance, bar}`.

## Cinemática de entrada

- `BossIntro` (`Scripts/Enemies/boss_intro.gd`): genérica. Pausa los `Timer` hijos del jefe, congela al jugador, lleva la cámara al jefe con zoom ×1.3 sobre el de la pelea, llama a `_intro_roar()` del jefe si existe, emite `roared` y vuelve.
- `PrometeoIntro`: la de Prometeo (humo que se junta y el cuerpo que emerge). También emite `roared`.

Cada jefe conecta `roared` a su `_connect_to_hud()`, así el título aparece justo cuando ruge.

Para un jefe nuevo:

```gdscript
func _ready() -> void:
	add_to_group("boss_entrance") # el HUD no muestra el cartel común de la sala
	_start_entrance.call_deferred()

func _start_entrance() -> void:
	var intro = BossIntro.new()
	add_child(intro)
	intro.roared.connect(_connect_to_hud)
	await intro.play(self, 0.6)

func _connect_to_hud() -> void:
	var created = BossBarHelper.create(get_tree(), "Nombre", max_health, current_health, {"phase_marks": [0.5]})
	boss_health_bar_node = created.get("bar")
```
