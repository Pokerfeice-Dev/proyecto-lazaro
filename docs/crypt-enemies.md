# Enemigos de La Cripta

El nivel 2 selecciona siete enemigos propios. El nivel 1 conserva su selección anterior. Las abejas carnívoras aparecen por invocación y no forman parte de la selección normal de las salas.

Las escenas están en `Scenes/Enemies/Crypt/`. Todas heredan `crypt_enemy_base.tscn`, con colisión, figuras provisionales, barra de vida, etiquetas, anticipación, efecto de ataque, escudo, temporizadores, sonidos y AnimationPlayer editables. El script común es `Scripts/Enemies/crypt_enemy.gd`.

| Escena | Comportamiento | Componente propio |
| --- | --- | --- |
| CryptGargoyle | Persigue y golpea; anticipa la petrificación, bloquea daño y empuje durante 2 segundos, luego queda vulnerable. | Corazón pétreo |
| CryptGhoul | Persigue; acelera cuando **el jugador le da la espalda** y recupera su velocidad normal al enfrentarlo. | Tendón necrótico |
| CryptCentipede | Anticipa un cono fijo y descarga gas. El veneno se renueva sin acumular instancias y termina al expirar su duración. | Glándula tóxica |
| CryptDeathSquad | Fija una dirección y dispara tres proyectiles consecutivos, separados por 0,16 segundos. | Placa funeraria |
| CryptLaserEye | Inmóvil. Sigue al jugador durante la carga inicial; fija la línea durante los últimos 0,55 segundos antes del rayo. Las paredes bloquean el rayo. | Lente sepulcral |
| CryptDeadBeekeeperSummoner | Invoca hasta tres abejas tiradoras; al morir elimina su enjambre. Las invocaciones no generan botín. | Panal cadavérico |
| CryptBellKeeper | Tres campanadas marcan posiciones sucesivas del jugador; cada eco estalla un segundo después. Luego se detiene durante la recuperación. Al morir cancela sus ecos pendientes. | Badajo de Réquiem |
| CryptFleshBee | Se acerca, anticipa y dispara un proyectil. | Mandíbula carnívora, disponible como recurso para variantes no invocadas |

Los componentes están en `Art/Items/Crypt/`, como recursos ItemData con íconos SVG provisionales. Los enemigos principales tienen 18% de probabilidad base de soltar su componente. Los efectos actuales usan estadísticas que ya soporta el juego; nombres y valores son una primera propuesta de balance. No se añadieron recetas nuevas de sinergias para estos componentes.

## Ajustes en Godot

En cada escena se pueden modificar vida, velocidad, daño, alcance, anticipación, duración del ataque y recuperación. Las secciones adicionales del Inspector contienen los parámetros de petrificación, acecho del ghoul, apertura del spray, fijación del láser e invocación. El escuadrón y el Campanero usan `BurstTimer` para separar sus disparos o campanadas.

- `Scenes/Effects/crypt_poison.tscn`: daño periódico, duración y señal de veneno.
- `Scenes/Effects/crypt_echo.tscn`: radio, espera, señal del eco y animación de explosión.
- `Scenes/Projectiles/crypt_projectile.tscn`: bala provisional, velocidad, colisión y duración. Compatible con la reflexión de Arrogancia.

El tamaño de la señal del eco está dibujado para el radio inicial de 52 píxeles; si se cambia el radio, ajustar también Boundary, Fill y Pulse en el editor.

## Validación

`Tests/crypt_enemies_smoke.tscn` verifica selección por nivel, inmunidad y vulnerabilidad de la gárgola, orientación del ghoul, ráfaga triple, fijación y evasión del láser, bloqueo por paredes, veneno sin acumulación y con expiración, límite y eliminación de invocaciones, y secuencia de ecos del Campanero.

`Tests/crypt_room_smoke.tscn` instancia una sala real del nivel 2 con el jugador y todos los enemigos para comprobar su ejecución conjunta. Activa invulnerabilidad de depuración solo dentro de esa prueba. Ejecutar las pruebas con datos de usuario aislados.

El balance de dificultad y la lectura de los placeholders todavía necesitan pruebas de juego con el equipo antes de fijar los valores definitivos.
