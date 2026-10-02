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
