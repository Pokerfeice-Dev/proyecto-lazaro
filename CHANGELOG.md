## 2026-10-06 (zona 3 conectada, entrada de Prometeo y nombres de zonas)

- **La zona 3 ya forma parte de la run.** Al cruzar la puerta del boss 2 se pasa a la zona 3, con la misma logica de 7 a 10 salas antes del jefe.
  - Las salas salen de `Level3_Room1` a `Level3_Room3` (todo `Level3_Room*` que no sea de jefe entra solo al pool).
  - Despues va `Level3_Room4BossFight` y, al ganarle a Prometeo, se gana la run y se vuelve al Lab.
  - La zona 3 todavia no tiene tienda de Ygor ni musica propia: no aparece la tienda y las salas quedan en silencio en vez de arrastrar el tema de otra zona.
- **Entrada de Prometeo**, armada igual que la cinematica del boss 2 (`Scripts/Enemies/prometeo_intro.gd`):
  - Se congela al jugador y la camara va hasta el boss.
  - El humo se junta en un remolino, el cuerpo sale de la sombra estirandose y Prometeo ruge con brasas y el titulo "PROMETEO", sin subtitulo.
  - La camara vuelve al jugador con el zoom normal de la pelea (el que tenia antes de la cinematica), y recien ahi aparece la barra de vida y arranca la pelea.
  - Se ajusta con `intro_delay`. `intro_subtitle` queda vacio; si se le pone texto, sale debajo del nombre.
- Los carteles de cambio de fase de Prometeo dicen solo "FASE 2" y "FASE 3", sin subtitulo.
- **Zonas con nombre propio:** Zona 1 "Distrito Asphodel", Zona 2 "La Cripta" y Zona 3 "El Núcleo".
  - El cartel de inicio de sala ahora dice, por ejemplo, "LA CRIPTA / SALA - 3". En las salas de jefe dice "SALA DEL JEFE".
  - En el codice, el aviso dice "¡NUEVA ZONA DESCUBIERTA!" y la zona 3 se descubre al llegar.
  - La zona 2 ya no se llama "Núcleo de Mutación" para no chocar con la zona 3; tambien se ajusto la descripcion del boss 1, que la nombraba.
- **Iconos nuevos del codice** (archivos nuevos, los viejos siguen en el proyecto):
  - Zonas: un recorte del piso de cada zona (`Art/Codex/zona1..3_codex_icon.png`).
  - Jefe 2: el slime de verdad, en vez del placeholder (`Art/Enemy_Boss_2/boss2_codex_icon.png`).
  - Jefe 3: entrada nueva "Prometeo", con Lázaro en sombra (`Art/Enemies/Prometeo/prometeo_codex_icon.png`). Se desbloquea al vencerlo.

## 2026-10-06 (lanzallamas del jugador con la llamarada de Prometeo)

- **La sinergia Lanzallamas ahora usa la misma llamarada de particulas que el lanzallamas de Prometeo**, en vez del sprite descargado. El sprite (`Art/Effects/FlameStreamAnim.tres`) sigue en el proyecto.
  - El fuego crece junto con el alcance mientras se mantiene el disparo (de 55 a 125 px en 0,3 s, igual que antes) y deja estela al girar el arma.
  - Al soltar el disparo se corta la emision y las ultimas llamas se apagan solas antes de borrarse.
- **La zona que quema ahora es un cono del mismo tamaño que el fuego** (22 grados hacia cada lado), en vez del rectangulo finito de 22 px. Pega a todo lo que se ve adentro de la llamarada, asi que agarra mas enemigos que antes. Se puede cerrar con `cone_half_angle_degrees` en `FlameStream.tscn`.
- `use_particle_flame` en `FlameStream.tscn` vuelve al sprite viejo si hace falta.
- La llamarada quedo en un script propio, `Scripts/Effects/flame_cone_particles.gd`, que usan el jugador y Prometeo. Si se retoca ahi, cambian los dos.

## 2026-10-06 (boss 3: Prometeo)

- **Nuevo boss final, Prometeo** (`Scenes/Enemies/Boss3_Prometeo.tscn`). Es un espejo de Lazaro: usa todas las armas del jugador, cambia de arma cada 2 o 3 ataques, dashea y esquiva. La pelea esta pensada para esquivar y sobrevivir, no para pegarle a una bolsa de vida.
  - Sprite provisional: el de Lazaro teñido de negro (como una sombra) y 1,5 veces mas grande, con un aura de humo. Los frames son una copia aparte (`Art/Enemies/Prometeo/prometeo_frames.tres`), asi que cambiar el sprite del jugador no lo toca.
  - **Armas a distancia:** pistola (apunta adonde vas a estar), escopeta (se acerca con un dash y tira un abanico), uzi (rafaga moviendose), minigun (carga, despues barre con limite de giro), lanzallamas (cono de fuego) y colmena (abejas que te siguen un rato).
  - **Armas melee:** hacha (corte en arco), daga (estocadas encadenadas) y maza (salto con circulo de impacto, onda expansiva y anillo de balas).
  - Todos los ataques tienen aviso: linea naranja para los disparos y zona roja para los golpes. El dash del jugador atraviesa todo, como con cualquier daño.
- **IA:**
  - Orbita al jugador a la distancia que le conviene al arma que tiene. Elige la proxima arma segun la distancia y la fase, y nunca repite la anterior.
  - Castiga el dash: si el jugador gasta el dash, ataca enseguida.
  - Si te le pegas cuando tiene un arma de distancia, se aleja con un dash.
  - Esquiva algunas balas del jugador con un dash lateral invulnerable (35% / 50% / 65% de probabilidad segun la fase, con enfriamiento).
- **Fases (2600 de vida):**
  - **Fase 1:** pistola, escopeta, uzi, hacha y daga.
  - **Fase 2 (65%), "Espejo":** se suman minigun, lanzallamas, colmena y maza. Prometeo se desdobla y aparece un clon violeta con barra propia. El clon tiene el 18% de la vida y dura 18 s; usa solo armas de distancia, pega el 75% y ataca mas lento. Mientras el clon esta vivo, el original prefiere el cuerpo a cuerpo.
  - **Fase 3 (30%), "El fuego robado":** el clon se deshace y Prometeo se prende fuego. Va mas rapido, despues de cada golpe melee remata con la escopeta, y cada 4 acciones salta al centro y tira espirales de fuego.
  - En cada cambio de fase aparece un titulo, se borran las balas en pantalla y tiene 2 s de invulnerabilidad. Se puede poner musica distinta para las fases 2 y 3 (`phase_two_music` / `phase_three_music`).
- No recibe empuje y los golpes no lo frenan. El congelamiento le dura como mucho 0,8 s.
- Scripts nuevos:
  - `Scripts/Enemies/boss3_prometeo.gd`: el cerebro (movimiento, IA, fases y clon).
  - `Scripts/Enemies/prometeo_arsenal.gd`: las armas y sus ataques.
  - `Scripts/Enemies/boss_bar_helper.gd`: la barra grande de vida.
  - `Scripts/Effects/prometeo_telegraph.gd`: los avisos.
  - `Scripts/Effects/prometeo_flame_cone.gd`: el lanzallamas.
  - `Scripts/Projectiles/prometeo_projectile.gd` y `Scenes/Enemies/prometeo_projectile.tscn`: las balas.
- **Sala de prueba:** `Scenes/Rooms/Level3_BossPrometeo_Prueba.tscn`, una copia de la sala del boss 2 con musica provisional. Esta en el menu de debug, en teletransportes y en enemigos.
- **Pendiente:**
  - Musica propia.
  - Entrada del codice.
  - Ajustar `arena_half_extents` (por defecto 300x200 alrededor de donde aparece) a la sala final de la zona 3.

## 2026-10-04 (zona 3: colisiones del tileset)

- **Colisiones de `Tile_set_Area3_CursedLand.tres` armadas con la misma logica que las zonas 1 y 2.** Es el unico tileset que se va a usar en las salas de la zona 3. Las paredes y los objetos tienen colision de tile completo (16x16) y el piso no.
  - **Piso, sin colision (315 tiles):** la tierra plana de las plataformas, en los dos tonos (claro y oscuro), de la parte de arriba del atlas.
  - **Paredes, con colision (1078 tiles):** las caras de raices de los bordes, las raices que cuelgan debajo, los bordes de las plataformas que dan al vacio y los agujeros dentro del piso.
  - **Objetos, con colision (1117 tiles):** plantas, rocas, huevos, raices grandes y la pared con boca, de la parte de abajo del atlas (fila 35 en adelante).
  - **Sin colision:** los bordes finitos de los objetos (683 tiles con poco relleno, como puntas de raices y hojas sueltas), para que no frenen al jugador en el aire. Los 538 tiles vacios del atlas tampoco tienen colision.
- La capa de fisica del tileset pasa de layer/mask 1 a **7**, igual que `Tile_set.tres` (zona 1) y `Tile_set_Area2.tres` (zona 2), asi el jugador, los enemigos y las balas chocan igual que en el resto del juego.

## 2026-10-04 (master boss 1 fase 1)

- **Boss 1 fase 1 remezclado y masterizado.** Se armo a partir de los 7 stems del proyecto de Cakewalk y quedo en `Audio/Music/Boss1_Fase1_master.ogg`, a -14 LUFS con pico real de -1 dBTP, como el resto de los temas. El `Boss-Fight.ogg` original queda en el proyecto.
  - Graves: el bajo electrico tiene el sub y suma armonicos para que se escuche en parlantes chicos. Las cuerdas graves llevan el golpe ritmico y se les saco el barro de 250 Hz que chocaba con el piano.
  - Pianos y coro: se recorto la zona de 300-420 Hz, donde se amontonaba todo.
  - Melodia (cuerdas staccato) y leitmotiv: suben y tienen mas presencia en 2,5-3 kHz para quedar adelante.
  - Las melodias, el coro y un poco de los pianos comparten una reverb.
  - En el bus master hay compresion suave de pegamento y un poco de brillo arriba, porque el original sonaba muy oscuro.
- La pista "Instrumento" (Vista Synth, compases 5 a 12) queda afuera, igual que en el proyecto (estaba fuera del solo) y en el `.ogg` original.
- **Loop:** el tema dura 172 compases exactos (275,2 s) y repite desde el principio (`loop = true`, `loop_offset = 0`). La cola de los ultimos compases suena encima del arranque. El original duraba 0,16 s de mas y hacia un corte en cada vuelta.
- `Level1_Room15-BossFight.tscn` y `Level1_Room16-BossFight2.tscn` usan el master nuevo, a -5 dB como la sala del boss 2 (antes -6 dB, con un archivo mucho mas bajo).
- Los scripts de mezcla y de costura del loop quedaron en `Herramientas/` en la carpeta de musica (`mezcla_boss1_fase1.py`, `costura_inicio.py`).

## 2026-10-03 (boss 2: vuelta al loop)

- **Los temas del boss 2 ya no cortan de golpe al repetir.** Se agrego un remate en los dos ultimos compases que lleva de vuelta al principio del loop:
  - Redoble de taiko en crescendo (corcheas y despues semicorcheas).
  - Corrida de cuerdas que desemboca en la primera nota del loop (Sol# 4).
  - Campanada que anuncia la vuelta.
- Las notas estan en pistas nuevas de Cakewalk (Taiko 2, String Orchestra y Tubular Bells 2), asi que el resto del arreglo quedo igual.
- Se exportaron dos compases de mas para que las colas y la reverb del remate suenen encima del arranque del loop, en vez de cortarse.
- Los ultimos 10 ms de cada tema se funden con el audio que esta justo antes del `loop_offset`, asi la onda queda continua y no hace "click" en cada vuelta (`Herramientas/costura_loop.py` en la carpeta de musica).
- `Audio/Music/Boss2_Fase1.ogg` y `Boss2_Fase2.ogg` se reemplazaron por los masters nuevos, a -14 LUFS con pico real <= -1 dBTP. Los `loop_offset` no cambian: 15,238 s y 5,714 s.

## 2026-10-03 (master Ost Batalla)

- **Ost Batalla remezclada y masterizada:** se mezclo a partir de los 9 stems del proyecto de Cakewalk y quedo en `Audio/Music/Ost-Batalla_master.ogg`, a -14 LUFS con pico real de -1 dBTP, igual que el resto de los temas. Antes picaba +1 dBFS, o sea que saturaba.
- `scene_transition.gd` usa el master nuevo en la zona 1, con el mismo ajuste de -0,9 dB que Asphodel B, asi los dos temas suenan parejos. El `Ost-Batalla.ogg` original queda en el proyecto.
- **Fix (pop raro en la bateria):** la pista Electro Pop tenia 412 notas de duracion cero, que no se ven en el piano roll pero el sampler las dispara igual. Eran bombos y toms a velocidad 127 fuera de la grilla (por ejemplo el compas 16, tiempo 4.27, cada 8 compases), hi-hats y notas en C-1. Se borraron en Cakewalk con Proceso > Deglitch (duracion < 10 ms), se reexportaron las baterias y se rehizo el master. El pop tambien estaba en el `Ost-Batalla.ogg` original; con la compresion de la bateria se notaba mas.
- Se arreglo la costura del loop: el tema terminaba con la onda en -0,19 y volvia a arrancar en 0, lo que hacia un "click" en cada vuelta. Ahora tiene un micro fundido de 6 ms y la cola de la reverb suena sobre el arranque.

## 2026-10-03 (menu de slots)

- **Menu de seleccion de slot renovado** (`newgame.tscn` / `newgame.gd`):
  - Usa el mismo fondo animado que el menu principal: Lazaro respirando detras de los barrotes, con lluvia y nieve.
  - Un degrade oscuro hacia la derecha deja ver a Lazaro y hace legibles las tarjetas.
  - Respeta las opciones "Lluvia y nieve del menu" y "Fondo animado del menu".
- **Slots como tarjetas:**
  - Cada tarjeta muestra el numero grande, "PARTIDA GUARDADA" o "SLOT LIBRE", el nivel maximo, el tiempo jugado, los despliegues y la fecha de guardado.
  - Los slots libres muestran "Nueva partida" con un "+" que late.
  - Las tarjetas entran en cascada desde la derecha con un rebote y tienen los FX de boton del menu principal (`ButtonFX`): brillo, borde electrico, chispas y destello.
- **Borrar ahora pide confirmacion:** el primer click cambia el boton a "¿SEGURO?" durante 2,5 s y recien el segundo borra. La tarjeta sale hacia la derecha y vuelve como slot libre.
- **Popup del tutorial con el estilo nuevo:**
  - Panel oscuro con borde de acento, botones con FX y entrada con rebote.
  - Se puede cancelar con un click afuera o con Esc; antes no habia forma de cerrarlo.
- El titulo nuevo, "SELECCIONÁ UN SLOT", entra con una linea de acento que se estira, y "VOLVER" quedo abajo a la izquierda con FX.
- Se sacaron del `.tscn` el tinte turquesa (`ColorRect`) y el `Label` viejo del titulo, que ahora se arma por codigo.

## 2026-10-02 (boss 2: fase 2 y musica)

- **Musica nueva del boss 2** en `Audio/Music/`, masterizada a -14 LUFS. Esta en Do# frigio como la Cripta y usa recursos del boss 1: coro con acordes largos, pulso de octavas en cuerdas, arpegio de piano de 12 notas y una melodia de notas largas.
  - `Boss2_Fase1.ogg`, "La Cosa de la Cripta": 126 BPM (1,5 veces el tempo de la Cripta), pesada y a medio tiempo, con un ritmo de 3+3+2 que imita los saltos del blob. Tiene 8 compases de intro y despues repite en bucle desde el compas 9 (`loop_offset` 15,238 s).
  - `Boss2_Fase2.ogg`, "Despertar": 168 BPM (el doble que la Cripta). Abre con 4 compases que duran lo mismo que la cinematica (5,7 s) y el golpe de entrada cae justo cuando vuelve la pelea. En la seccion B aparece el motivo de Lazaro. Repite en bucle desde el compas 5 (`loop_offset` 5,714 s).
  - Los proyectos de Cakewalk, los bocetos MIDI y los masters quedaron en la carpeta de musica de Frankengun, junto con `Herramientas/masterizar_con_intro.py`, que masteriza temas con intro y bucle.
- **Boss 2 con fase 2 "Despertar"** (`boss2.gd`), con la misma logica que el boss 1 pero sin cambiar de sala:
  - Al 50% de vida se vuelve invulnerable, ruge, sacude la camara y muestra "FASE 2: DESPERTAR"; la musica de la fase 1 se apaga en 1,4 s.
  - Despues viene la misma cinematica del boss 1: jugador congelado, titulo, zoom al boss, rugido y curacion del 20% con particulas, y zoom de vuelta. Arranca la musica de la fase 2.
  - En la fase 2 todo va 1,5 veces mas rapido (patrones, persecucion, mordida), tira una tanda mas de escupitajos y los saltos tardan un poco menos en avisar, aunque siguen avisandose.
  - Durante la transicion los ataques que estaban en curso no lastiman al jugador congelado y los mutantes invocados se quedan quietos.
  - Todo se ajusta desde el inspector, en el grupo "Boss Fase 2 (Despertar)": umbral, curacion, multiplicador, musica y titulo.
- `Level2_Room14BossFight.tscn` ahora tiene su nodo `Boss_Fight_Music` (fase 1, bus Music, -5 dB como la musica de zona).

## 2026-10-02 (fix modo ventana)

- **Fix (modo ventana):** el juego ahora arranca en ventana de 1600x900 (Project Settings: `display/window/size/mode` = Ventana, con `window_width_override`/`window_height_override`) y `GameSettings` lo pasa a pantalla completa al abrir si esa es la opcion guardada (por defecto si). Antes arrancaba en pantalla completa y Windows guardaba el tamaño de la pantalla entera como "tamaño de ventana": al elegir "Ventana" el juego quedaba trabado en pantalla completa exclusiva. Probado: pantalla completa -> ventana -> pantalla completa funciona, y arrancar con "Ventana" guardado abre en ventana con barra de titulo.
- **Fix:** `game_settings.gd` tenia una linea con sangria de mas (`_center_window()`, linea 165) que impedia compilar el script y abrir el juego.

## 2026-10-02 (pantalla de opciones)

- **Pantalla de opciones nueva con pestañas** (`Scenes/UI/options_screen.tscn` + `Scripts/UI/options_screen.gd`): el boton "Opciones" del menu principal ya no abre el menu de pausa, abre esta pantalla. Tiene 4 pestañas (Video, Audio, Efectos, Juego). Cada fila se resalta al pasar el mouse y muestra abajo una descripcion de lo que hace. Abajo hay "Restablecer pestaña" (vuelve esa pestaña a los valores por defecto) y "Volver" (tambien se cierra con Esc).
  - **Video:** modo de pantalla (completa / ventana 1600x900 / ventana sin bordes), VSync, limite de FPS (sin limite, 30, 60, 120, 144) y contador de FPS.
  - **Audio:** volumen general (bus Master), musica, efectos y "silenciar al cambiar de ventana".
  - **Efectos** (para rendimiento, se prenden/apagan por separado): polvo ambiente, luces parpadeantes, viñeta, sombras, polvo y huellas al caminar, sacudida de camara, animacion de entrada a las salas, lluvia/nieve del menu y fondo animado del menu.
  - **Juego:** brujula de enemigos e indicador de direccion de daño.
- Fondo: desenfoca lo que hay atras (el menu sigue vivo pero borroso), lo oscurece con un tinte frio y suma lineas diagonales que se mueven lento, scanlines y viñeta (`Art/Menu/Animado/options_fondo.gdshader`). Entra con fade + el panel con un rebote, y las filas aparecen en cascada al cambiar de pestaña.
- **Autoload nuevo `GameSettings`** (`Scripts/System/game_settings.gd`, clase `FxSettings`, primero en el orden de autoloads): guarda todas las opciones en `user://opciones.cfg` (mismas claves de volumen que antes, no se pierde lo guardado) y las aplica al abrir el juego. Desde cualquier script: `FxSettings.on("sombras")` devuelve si esta activada, o escuchar `GameSettings.setting_changed` para reaccionar en vivo. Para sumar una opcion: clave en `DEFAULTS` + fila en `ROWS` de `options_screen.gd`.
- **Botones con los mismos FX del menu principal** en las pestañas y en el pie de la pantalla, con un helper reutilizable: `ButtonFX.attach(boton)` (`Scripts/UI/button_fx.gd`).
- Hooks de las opciones de Efectos/Juego: `drop_shadow.gd` (grupo `drop_shadows`), `footstep_fx.gd`, `room_reveal.gd`, `tile_rain_reveal.gd`, `enemy_compass.gd` (grupo `enemy_compass`), `damage_direction_indicator.gd` y `apply_camera_shake` / `apply_custom_camera_shake` en `player.gd`. Con todo activado el juego se ve y se juega exactamente igual que antes.
- **Menu de pausa:** los sliders de Musica/Efectos ahora leen y guardan a traves de `GameSettings` (quedan sincronizados con la pantalla nueva) y hay un boton nuevo "Más opciones" que abre la pantalla completa de opciones arriba de la pausa.

## 2026-10-02 (musica continua)

- **Lab <-> Omnia sin cortes:** el tema del lab (`Laboratorio.ogg`) ahora vive en `SceneTransition` (`lab_music`) en vez de un `Audio_lab` en cada escena. Al pasar del lab a Omnia (Core_Upgrade_Room) y volver, la musica sigue sin reiniciarse, igual que entre salas de una misma zona. Se sacaron los nodos `Audio_lab` de `lab_room.tscn` y `Core_Upgrade_Room.tscn`.
- **Musica durante el inventario y las opciones:** antes la musica se cortaba al pausar porque los reproductores se pausaban con el juego. Ahora toda la musica (menu, zonas, lab, boss, tienda de Ygor) sigue sonando con el juego en pausa, y al abrir el inventario o el menu de opciones se "embotella" con un filtro pasabajos propio (`set_menu_muffle`), separado del filtro de combate/sala limpia. Al cerrar vuelve a sonar normal.

## 2026-10-02 (menu animado)

- **Menu principal con vida:** el artwork de Lazaro ahora tiene un idle. Se separaron los barrotes en su propia capa fija (`Barrotes`) y el cuerpo quedo en `menu_lazaro_cuerpo.png` (lo que tapaban los barrotes se relleno). Un shader (`Art/Menu/Animado/menu_lazaro_idle.gdshader`) deforma suave por zonas pintadas en mascaras: el pecho respira, los hombros suben al inhalar, la cabeza sube y gira apenas, y los mechones se balancean. Las manos quedan quietas porque estan agarrando los barrotes.
- El fondo tiene niebla que se mueve lento y la luz de arriba a la izquierda late suave.
- El logo de Franken-Gun flota, respira al mismo ritmo y cada tanto tiene un chispazo (`main_menu.gd`).
- Respiracion mas marcada: nuevo parametro `respiracion_fuerza` en el shader (por defecto 2.2, antes equivalia a 1).
- **Botones del menu principal con FX** (`main_menu.gd` + `Art/Menu/Animado/menu_boton.gdshader`): entran en cascada con rebote, un brillo diagonal los recorre en cascada cada tanto, con el hover crecen, se inclinan apenas, se tiñen de cian, el borde titila como electricidad y saltan chispas; al hacer click se achican, destellan en blanco, saltan mas chispas y la columna de botones da un sacudon chiquito. El boton deshabilitado (Continuar sin partida) no reacciona.
- Todo se ajusta desde `menu_lazaro_idle_material.tres` (intensidad, duracion de la respiracion, giro de cabeza, fuerza de la niebla y pulso de la luz). El artwork original `lazaro artwork.jpg` no se toco.

## 2026-10-02 (fix audio)

- **Fix (slider de Efectos):** varios sonidos no iban por el bus SFX y salian directo por Master, asi que ignoraban el volumen de Efectos de Opciones. Ahora van por SFX: compra en la tienda holografica de Ygor, recoger en el holograma de tesoro, abrir cofre, recoger carne (flesh), ataque del enemigo Follower, disparo de armas por `main_weapon.gd`, sonido de sala limpia, explosion del barril de fuego, sonido del barril de hielo y explosion del ataque aereo del Boss 1.
- La musica de la tienda de Ygor (`Ygor_music`) ahora va por el bus Music, asi respeta el volumen de musica.
- **Opciones (Musica/Efectos):** los sliders ahora usan una curva de volumen al cuadrado (el 50% suena realmente a la mitad, antes casi no cambiaba hasta llegar abajo de todo), muestran el porcentaje en la etiqueta, son mas altos y van de a 5%. El volumen elegido se guarda en `user://opciones.cfg` y se aplica al abrir el juego. Al soltar el slider de Efectos suena un efecto de prueba.

## 2026-10-01 (musica)

- **Musica nueva in-game:** se sumaron 3 temas masterizados a -14 LUFS en `Audio/Music/`: `Asphodel_B.ogg` (zona 1, Tema B), `Cripta_A.ogg` (zona 2) y `Laboratorio.ogg` (lab).
- Zona 1: `scene_transition.gd` ahora elige al azar entre `Ost-Batalla.ogg` y `Asphodel_B.ogg` cada vez que arranca la musica de la zona (al entrar desde el lab, despues de la tienda de Ygor, etc.).
- Zona 2: `Cripta_A.ogg` reemplaza al placeholder `BossFight2.ogg` en las salas `Level2_Room*`.
- Lab y sala de Core Upgrades: `Laboratorio.ogg` reemplaza a `lab.ogg` (a -5 dB, igual que la musica de zona). La sala de Core Upgrades ahora tambien va por el bus Music, asi respeta el volumen de musica de Opciones.
- Ajuste fino de volumen por tema (`_music_trim_db`) para que los temas nuevos y Ost-Batalla suenen parejos, y al entrar al lab se abre el filtro pasabajos del bus Music para que no suene apagado si venias de una sala ya limpia.
- Menu principal: `Menu_Principal.ogg` (tema terminado con el motivo de Lazaro, 2:08 en loop) reemplaza a `sn2.ogg`, mismo volumen (-3 dB) porque ambos estan a -14 LUFS. `sn2.ogg` queda en el proyecto sin usar.
- `lab.ogg` queda en el proyecto sin usar por ahora (no se borro nada). `BossFight2.ogg` sigue sonando en su sala de boss como siempre.

## 2026-09-21 (feature)

- **Feature (Boss 2 -> Lab):** el nivel 2 usaba como placeholder la MISMA sala de pelea del Boss 1 (`Level1_Room15-BossFight.tscn`) para su boss fight; `Level2_Room14BossFight.tscn` (con el Boss2 real, el 'Monstro' que salta) ya estaba armada en la escena pero nunca se usaba en la progresion real.
- `GameData.get_boss_room()` ahora elige la sala segun `current_level`: nivel 1 sigue yendo a la pelea del Boss 1, nivel 2 (>=2) va a `Level2_Room14BossFight.tscn` con el Boss2.
- La puerta de esa sala tenia `is_boss_exit_door = false` y `start_locked = false` (quedaba abierta desde el inicio, sin depender de derrotar al boss). Se cambiaron a `true`/`true`, igual que la puerta de la sala del Boss 1. Con eso, el mecanismo generico que ya existia en `combat_room.gd` (detecta a Boss2 pre-colocado por su señal `enemy_died`, cierra la puerta al entrar, la abre cuando muere) queda conectado solo, sin logica nueva: al cruzar la puerta despues de vencer a Boss2, `GameData.get_post_boss_scene()` marca la run como ganada y lleva al Lab, igual que pasa con el Boss 1.

## 2026-09-21 (fix)

- **Fix (Area 3 tilesets — colisiones en Walls/Tile_Objects):** se reconstruyeron los 3 TileSets de Area 3 (Crawling Depths, Knowledge Temple, Cursed Land). Antes cada pack tenia 3 `TileSetAtlasSource` separadas (Floor/Walls/Objects como imagenes distintas) con colision asignada en bloque por fuente; eso permitia pintar cualquier tile en cualquier layer (Floor/Walls/Tile_Objects) sin relacion real con su colision, rompiendo la logica esperada.
- Ahora cada pack usa **una sola imagen combinada** (`CrawlingDepths_Atlas.png`, `KnowledgeTemple_Atlas.png`, `CursedLand_Atlas.png`) y **una sola `TileSetAtlasSource`** compartida por los 3 TileMapLayers, igual que `Tile_set_Area2.tres`. La colision ahora es **por tile individual** (no por layer ni por fuente): tiles de Floor = sin colision, tiles de Walls = con colision, tiles de Objects = sin colision (decorativos), excepto en Cursed Land donde Objects funciona como sustituto de Walls (ese pack no trae planilla de paredes propia) y sus tiles con contenido visible si tienen colision.
- Se re-detecto que `Level3_Room2` y `Level3_Room3` tenian el TileSet en memoria desactualizado (cache) apuntando a la version vieja de 2-3 fuentes; se forzo la recarga (`CACHE_MODE_REPLACE`) para que ambas salas usen la fuente unica nueva. `Level3_Room1` ya tenia piso pintado (203 tiles) y se preservo intacto: las coordenadas del piso no cambiaron de posicion dentro del atlas.
- Verificado: Area 1 y Area 2 sin cambios (mismos tamaños de `tile_map_data` y mismos `tile_set` de siempre).

# Changelog - Proyecto Lázaro

Registro corto de los cambios grandes que vamos sumando al proyecto con Claude. Cada sesión de trabajo se agrega como una entrada nueva arriba de todo, con fecha. No es detallado línea por línea, solo lo importante de cada tanda.

## 2026-09-21
- Importados 3 tilesets placeholder gratuitos para el Área 3 (Núcleo Sepulcral): Crawling Depths, Knowledge Temple y Cursed Land, cada uno como su propio TileSet (Floor sin colisión, Walls con colisión completa, Tile_Objects sin colisión por defecto).
- Level3_Room1/2/3 reasignadas cada una a un tileset distinto (antes tenían el tileset de Área 2 como placeholder duplicado); el tile_map_data viejo se limpió porque no correspondía a los nuevos atlas.
- Sumado un fondo animado psicodélico (Free Trippy Animated Backgrounds) detrás de cada sala de Área 3 vía CanvasLayer + TextureRect con AnimatedTexture, uno distinto por sala.

## 2026-09-16
- Ajuste **Relámpago**: en vez de ráfaga imprecisa, la UZI dispara normal pero cada bala tiene ~35% de chance de salir como bala relámpago. Además, ahora el enemigo se tiñe de amarillo fuerte y notorio mientras dura el aturdimiento (antes casi no se notaba), tanto en el impacto directo como en cada salto de la cadena.
- Nueva sinergia **Relámpago** (UZI + Cerebro + Aguijón Mecánico + Motocicleta): la bala relámpago electrifica al enemigo impactado; la electrificación aturde y se contagia en cadena a los enemigos cercanos (con chispazos, destello y sonido).
- Fix: `get_active_ranged_weapon_id()` nunca devolvía el id del arma a rango equipada (uzi/pistola/escopeta), así que las sinergias de arma a rango (Minigun, Mente Colmena, Roadkill, Lanzallamas, y ahora Relámpago) podían no detectarse bien; ahora sí resuelve el id correctamente.
- Fix: en la daga y el hacha, el sprite del arma (`melee_sprite`) no estaba conectado en la escena, así que los tintes de color de las sinergias (Daga del Odio, Hombre Lobo) no se veían in-game; ahora se resuelve solo si falta.
- Nueva sinergia **Hombre Lobo** (hacha + Cabeza Humana + Cabeza de Perro + Aguijón Mecánico): marca a un enemigo de la sala; el hacha le hace muchísimo más daño y, al golpearlo, la marca explota (daño en área) y aparece en otro enemigo.
- Nuevo sistema de diferenciación visual para armas con sinergia: cada una tiñe el sprite de un color distinto y lo agranda un poco (Daga del Odio: rojo pulsante según vida, Arrogancia: dorado, Hombre Lobo: violeta).
- Fix: la invulnerabilidad del 10% de vida de la sala de tutorial se quedaba activada el resto de la run; ahora se desactiva apenas salís de esa sala.
- Nueva sinergia **Arrogancia** (maza + Mezcladora + Cabeza Humana + Colmena): mientras atacás con la maza, las balas enemigas que te tocan durante el swing rebotan devueltas (nerfeadas) hacia los enemigos.
- Sinergia **Daga del Odio**: subí bastante los números (daño, velocidad, alcance, crítico) y el filo ahora se tiñe de rojo cuanta menos vida te queda.
- Fix: el popup de "sinergia desbloqueada" no se disparaba para sinergias de arma cuerpo a cuerpo (solo miraba el arma a rango); ahora sí.
- Nueva sinergia **Daga del Odio** (daga + Pulmones + Cabeza Humana + Sierra Circular): cuanto menos vida tenés, más fuerte pega la daga (daño, velocidad, alcance, crítico).
- Nueva sinergia **Lanzallamas** (escopeta + 3x Cabeza de Sabueso Metálica): quema al impactar y el alcance aumenta mientras mantenés presionado el disparo.
