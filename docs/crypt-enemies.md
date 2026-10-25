# Enemigos de La Cripta

El nivel 2 selecciona siete enemigos propios. El nivel 1 conserva su selección anterior. Las abejas carnívoras aparecen por invocación y no forman parte de la selección normal de las salas.

Las escenas están en `Scenes/Enemies/Crypt/`. Todas heredan `crypt_enemy_base.tscn`, con colisión, figuras de respaldo (se ocultan cuando hay arte), barra de vida, avisos de ataque, escudo, temporizadores, sonidos, efecto de muerte y AnimationPlayer editables. El script común es `Scripts/Enemies/crypt_enemy.gd`; lo visual del arte está en `Scripts/Enemies/crypt_enemy_art.gd`.

| Escena | Comportamiento | Componente propio |
| --- | --- | --- |
| CryptGargoyle | Persigue y golpea; anticipa la petrificación, bloquea daño y empuje durante 2 segundos, luego queda vulnerable. | Corazón de Piedra |
| CryptGhoul | Persigue; acelera cuando **el jugador le da la espalda** y recupera su velocidad normal al enfrentarlo. | Tendón |
| CryptCentipede | Anticipa un cono fijo y descarga gas. El veneno se renueva sin acumular instancias y termina al expirar su duración. | Glándula tóxica |
| CryptDeathSquad | Fija una dirección y dispara tres proyectiles consecutivos, separados por 0,16 segundos. | Lápida |
| CryptLaserEye | Inmóvil. Sigue al jugador durante la carga inicial; fija la línea durante los últimos 0,55 segundos antes del rayo. Las paredes bloquean el rayo. | Lente sepulcral |
| CryptDeadBeekeeperSummoner | Invoca hasta tres abejas tiradoras; al morir elimina su enjambre. Las invocaciones no generan botín. | Panal Podrido |
| CryptBellKeeper | Tres campanadas marcan posiciones sucesivas del jugador; cada eco estalla un segundo después. Luego se detiene durante la recuperación. Al morir cancela sus ecos pendientes. | Badajo |
| CryptFleshBee | Se acerca, anticipa y dispara un proyectil. | Mandíbula, disponible como recurso para variantes no invocadas |

Los componentes están en `Art/Items/Crypt/`, como recursos ItemData con íconos SVG provisionales. Los enemigos principales tienen 18% de probabilidad base de soltar su componente. Los efectos actuales usan estadísticas que ya soporta el juego; nombres y valores son una primera propuesta de balance. No se añadieron recetas nuevas de sinergias para estos componentes.

## Avisos, movimiento y arte

`Telegraph` (en `crypt_enemy_base.tscn`) usa `Scripts/Effects/crypt_telegraph.gd` y dibuja cada aviso por código. El enemigo elige el estilo según su tipo y le pasa el avance de la anticipación en cada frame:

| Estilo | Enemigos | Qué se ve |
| --- | --- | --- |
| Cono | Gárgola, Ghoul, Ciempiés | Cono tenue con bordes punteados, un relleno que crece desde el enemigo, el frente de carga y chevrones que avanzan. Parpadea en el último 30%. Al golpear sale una onda blanca; el gas del ciempiés deja el cono verde encendido mientras dura. |
| Rayo | Ojo torreta | Mientras apunta, línea punteada ámbar con mira. Al fijarse, línea roja que engrosa y marca el ancho real del rayo. El rayo tiene halo, cuerpo y núcleo blanco, y termina donde choca. |
| Mira | Escuadrón, Abeja | Línea punteada con flecha y casillas que se encienden (3 para la ráfaga del escuadrón). Cada disparo hace un destello en la boca y un pequeño retroceso. |
| Ondas | Campanero | Anillos azules que se expanden; cada campanada suelta una onda. |
| Invocación | Apicultora | Hexágonos en los dos puntos donde aparecerán las abejas; al invocar, cada punto suelta una onda. |

`GasParticles` (solo en el ciempiés) dispara el gas dentro del cono. No hay textos sobre los enemigos: igual que en el área 1, solo se ven el sprite, la barra de vida y los avisos.

En el Inspector, la sección **Arte** de cada escena tiene:

- `art_faces_left`: activarlo si el sprite original mira hacia la izquierda (como las abejas).
- `art_rotates` y `art_forward_degrees`: girar el sprite hacia donde va en vez de espejarlo, e indicar hacia dónde mira el dibujo original (el ciempiés usa 135°).
- `hover_amplitude`: flotación en píxeles (abeja y ojo).
- `turn_rate`: qué tan rápido gira al perseguir; con valores bajos traza curvas más amplias.

Para darle arte a un enemigo, agregar un `AnimatedSprite2D` llamado `ArtSprite`. `Scripts/Enemies/crypt_enemy_art.gd` se encarga de lo visual y busca estas animaciones: `idle`, `walk`, `attack_windup` (o `attack`) para la anticipación, `attack_cone` (o `attack`) para el golpe, `hurt`, `death`, `summon`, `petrify` y `stone_shield`. Si existen versiones por dirección (`walk_down`, `walk_side`, `walk_up`, etc.) elige sola la que corresponde. Si hay `death`, el cadáver queda en la sala; si no, el cuerpo se aplasta y se desvanece. En los dos casos explota con el efecto azul del área 1 (`Death_fx`). La barra de vida se ubica sola encima del sprite.

El ciempiés tiene además `CentipedeBody` (`Scripts/Enemies/crypt_centipede_body.gd`): las piezas siguen el camino de la cabeza; en el Inspector se cambian la cantidad y el orden de las piezas, la separación y el paso de las patas.

Las hojas de sprites salen de packs CC0 (ver `Art/Enemies/Crypt/CREDITOS.md`). La gárgola usa `GargoyleSprite`; la apicultora muerta y la abeja carnívora usan versiones zombis de los sprites originales del nivel 1.

El ghoul deja una estela rosa cuando acelera por la espalda.

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
