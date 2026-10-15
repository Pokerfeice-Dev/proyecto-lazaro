## 2026-10-15 (Apariciones de jefes, carteles de fase y ajustes del lab y el entrenamiento)

- **El tutorial no se repite:** al completarlo queda guardado en la partida (`has_completed_tutorial`). Al volver a la sala de entrenamiento están la armería, la incubadora, Victoria y el maniquí, pero sin los pasos, la tarjeta ni las manitos.
- **Puertas del laboratorio:**
  - El cartel con el nombre (INVASIÓN, O.M.N.I.A., ENTRENAMIENTO) aparece solo cuando te acercas a la puerta, con un saltito, y se va al alejarte.
  - INVASIÓN y ENTRENAMIENTO tienen ahora un ícono fijo sobre la puerta, como el cerebro de O.M.N.I.A.: una calavera con mira y un maniquí con diana (`Art/Props/Doors/`).
  - Lo mismo vale para la puerta de salida del entrenamiento.
- **Aparición propia de cada jefe** (ganchos `_intro_prepare` / `_intro_appear` de `BossIntro`):
  - **Centinela Génesis:** se abre una grieta roja en la pared y el cuerpo sale de ella hacia abajo entre polvo y temblor (shader `Art/Effects/emerge_clip.gdshader`). Al final titilan y se le prenden los ojos.
  - **El Primogénito:** primero crece su sombra en el piso, después cae desde arriba, aplasta el suelo con onda, polvo y temblor, y da dos rebotes cada vez más chicos.
  - Recién después rugen y entra el título que se convierte en la barra.
- **Cartel de cambio de fase nuevo** (`Scripts/UI/boss_phase_banner.gd`), igual en los tres jefes: destello del color del jefe, una franja que cruza la pantalla como un tajo, el número romano que cae grande y hace temblar todo, "FASE II" y el nombre de la fase que se decodifica. La barra de vida se sacude y destella en el mismo momento.
  - Centinela Génesis, fase II: "PROTOCOLO ÓMEGA" (antes "MODO FURIA").
  - El Primogénito, fase II: "EL HAMBRE DESPIERTA" (antes "DESPERTAR").
  - Prometeo, fase II: "EL REFLEJO SE DIVIDE"; fase III: "LA LLAMA ROBADA" (antes solo "FASE 2" y "FASE 3").
  - Se borraron los textos y títulos viejos de fase de los tres jefes.
- **Códice revisado:**
  - Los nombres de las armas coinciden con los del juego: Escopeta, Uzi, Daga, Maza Pesada y Hacha de Mano.
  - Centinela Génesis: el daño real es 25 (los misiles hacen 30), se aclaran las fases y Modo Furia pasó a Protocolo Ómega.
  - Se agregaron los porcentajes de las fases de El Primogénito y Prometeo.
  - Ygor figura con su rol de mercader de prótesis y órganos. Victoria menciona la sala de entrenamiento.
  - Zona 1 suma a las Robo-Abejas. Zona 2 suma a la Apicultora muerta y las Abejas carnívoras (también en la ficha de amenazas).
  - Se verificó que todo lo que el juego desbloquea en el códice (enemigos, armas, objetos, NPC y zonas) tenga su entrada.
- El daño del Centinela figuraba como "Mutante Génesis (Boss)"; ahora dice "Centinela Génesis".
- Pantalla de partida nueva en español neutro: "¿Quieres hacer el tutorial?", "clic fuera" y el botón "NO, SOY UN EXPERTO".

## 2026-10-15 (Barras de jefe nuevas, sala de entrenamiento renovada y carteles de puertas)

- **Barra de vida de los jefes, nueva** (`Scripts/UI/boss_health_bar.gd` y `boss_bar_gauge.gd`):
  - El nombre usa una fuente nueva, Cinzel Decorative Bold (OFL, licencia en `Art/Fonts/CinzelDecorative-OFL.txt`).
  - La barra está dibujada por código: marco dorado con puntas biseladas, relleno carmesí con degradé y brillo, marcas cada 10% y muescas en los umbrales de fase (se ponen rojas al pasarlas).
  - Al recibir daño queda un tramo claro ("chip") que baja un momento después. Destella con cada golpe y late cuando al jefe le queda poca vida. Al curarse brilla turquesa.
  - Debajo de la barra aparece la zona ("ZONA 2 · LA CRIPTA") y arriba hay una sombra para que se lea sobre cualquier piso.
- **Entrada de los jefes con título que se convierte en la barra.** Cuando el jefe ruge se abre una franja como la de las salas: la zona, el nombre del jefe que se decodifica en grande, una línea dorada y "JEFE DE ZONA". Después todo sube: el nombre se achica sobre la barra, la línea se engrosa hasta ser la barra y se llena de izquierda a derecha. En las salas de jefe ya no aparece el cartel común.
  - Centinela Génesis y El Primogénito estrenan cinemática de entrada (`Scripts/Enemies/boss_intro.gd`), igual en estructura a la de Prometeo: el jefe espera, se congela al jugador, la cámara va hasta el jefe, ruge, aparece el título y la cámara vuelve.
  - Prometeo usa la barra nueva. Su cinemática ahora hace el zoom relativo al de la pelea (antes era fijo en 1.35).
  - Cuando el Centinela vuelve en la fase 2, en otra sala, la barra baja directo, sin título.
  - `BossBarHelper.create(...)` devuelve la barra nueva. Los jefes la siguen actualizando igual (`bar.value`).
- **Sala de entrenamiento:**
  - Se sacaron los NPC genéricos. Ahora hay una **armería** (estante con armas que se ilumina al acercarte) y una **incubadora de sinergias** (tubo con líquido animado), dibujadas para el juego (`Art/Props/Training/`). Cada una tiene su cartel ("ARMERÍA", "SINERGIAS").
  - La incubadora abre una ventana con el estilo del juego en vez del menú violeta.
  - **Victoria** está en la sala: da consejos y charla con el mismo cuadro de diálogo que Ygor, ahora con su retrato (`Scripts/UI/npc_dialogue_box.gd`, compartido con Ygor).
  - **Puerta "SALIR DEL ENTRENAMIENTO"** con cartel. Al volver, apareces junto a la puerta de entrenamiento del laboratorio.
  - Se sacó el cartel "Manny" del maniquí.
- **Tutorial con indicador del próximo paso** (`tutorial_hud.gd`, `tutorial_input_icon.gd`, `tutorial_pointer.gd`):
  - Abajo se muestra una tarjeta con "ENTRENAMIENTO · PASO X/8", las teclas o el mouse dibujados (se presionan solos para mostrar qué tocar), el texto corto, un contador (0/3) y puntos de progreso.
  - En los pasos de control, las mismas teclas aparecen sobre la cabeza de Lázaro.
  - Cuando hay que ir a algún lado (el maniquí, el enemigo, las piezas del suelo), aparecen un círculo que late en el piso y una manito que rebota encima. Si el objetivo queda fuera de pantalla, una flecha con la manito lo señala desde el borde.
  - El paso de sinergia se divide en dos: recoger las 3 piezas (E) y equiparlas en el inventario (I). Las piezas ahora caen en piso libre, no sobre la jardinera.
  - **Tutorial completado:** ventana nueva con el sello, "Sinergia aprendida: Mente Colmena" y la lista de lo aprendido. Ya no te saca sola de la sala: puedes seguir practicando (ESC) o volver al laboratorio (E).
- **Laboratorio:**
  - **Cartel de O.M.N.I.A.** con el estilo del juego: pestaña con ícono, título, subtítulo y cada párrafo como punto (`Scripts/UI/ui_window.gd`, ventana reutilizable).
  - **Puertas con cartel e ícono propios** (`Scripts/World/door_sign.gd`): INVASIÓN en rojo, O.M.N.I.A. en dorado y ENTRENAMIENTO en turquesa. Las luces de cada puerta toman su color. El aviso "[E]" aparece encima del cartel, sin taparlo.
- **Gárgola con sprite nuevo:** el ángel de GothicVania (CC0) en lugar del sprite hecho con IA, con animaciones de reposo, caminata, carga, ataque, petrificación y muerte. Actualizado en el códice y en `Art/Enemies/Crypt/CREDITOS.md`.
- **Arreglos:**
  - El ícono de chatarra se pedía como `scrap_icon.png` y el archivo es `Scrap_icon.png`. En Windows andaba, pero al exportar a otras plataformas no iba a cargar. Se corrigió en el HUD, las opciones, la sala de combate, O.M.N.I.A. y los avisos.
  - "Empezá desde cero, con tutorial si querés." pasó a "Empieza desde cero, con tutorial si quieres.".

## 2026-10-15 (La Cripta con arte, El Primogénito y arreglo de la cinemática de los jefes)

- **Los enemigos de La Cripta ya tienen sprites** (todos CC0, créditos en `Art/Enemies/Crypt/CREDITOS.md`):
  - **Ghoul:** zombi de Stealthix, con caminata, mordida, golpe recibido y muerte.
  - **Ciempiés tóxico:** Chain Insect. La cabeza gira hacia donde va y el cuerpo se arma por segmentos que la siguen como una cadena, con las patas moviéndose (`crypt_centipede_body.gd`). El tubo dorsal es verde tóxico.
  - **Escuadrón de la muerte:** esqueleto de Skeletons Rework con un fusil dibujado encima, en 4 direcciones; apunta, retrocede al disparar y al morir se desarma en una pila de huesos.
  - **Ojo torreta:** Flying Eye de LuizMelo. Flota, se encoge para cargar, se abre al disparar el rayo, reacciona a los golpes y cae al morir.
  - **Campanero de Réquiem:** nigromante de Cheb Gonaz con una campana en lugar del cráneo del bastón y brillo cian al tocarla.
- **Misma limpieza que en el área 1:** se sacaron los nombres sobre los enemigos, los textos de estado ("PETRIFICANDO", "INMUNE"), el "!" de alerta, el "ECO" de las campanadas y el "VENENO" sobre el jugador (ahora salen burbujas verdes). La barra de vida tiene el mismo estilo que en el área 1 y se ubica sola encima de cada sprite. Al morir explotan con el mismo efecto azul del área 1 y el cadáver queda unos segundos en la sala.
- Lo visual de estos enemigos se separó en `Scripts/Enemies/crypt_enemy_art.gd` (animaciones por dirección, giro, flotación, estelas y cadáver). Para darle arte a un enemigo nuevo basta con un `AnimatedSprite2D` llamado `ArtSprite` (ver `docs/crypt-enemies.md`).
- **Códice:**
  - El bestiario muestra los idles animados de todos los enemigos de La Cripta; el orden ahora es área 1, La Cripta y jefes.
  - Descripciones nuevas para los enemigos de La Cripta y sus componentes.
  - La zona 2 muestra sus amenazas reales (antes mostraba perros, mechas y la apicultora).
  - Se corrigieron las amenazas de la zona 1 y un "Acá" en la zona 3.
- **Jefe de La Cripta: El Primogénito** (nombre, descripción del códice y cartel de la pelea).
  - **Gran salto:** desaparece hacia arriba, su sombra (con borde rojo que late) persigue al jugador, se queda quieta un instante y cae aplastando con un anillo de huesos. Cuando estás muy lejos lo usa para acercarse.
  - **Bilis:** escupe en abanico; cada escupitajo cae en arco y deja un charco de bilis que quema (`bile_glob.gd`, `bile_puddle.gd`, mismo pixel art que los charcos de los barriles).
  - **Invocación:** vomita ghouls y abejas carnívoras; también lo hace si te quedas pegado a él unos segundos.
  - **Fase 2 al 40%** (antes al 50%): además de lo que ya hacía, la sombra te alcanza más rápido, encadena dos grandes saltos, suelta más huesos y la bilis dura más.
- **Arreglo: en la cinemática de fase 2 de los jefes 1 y 2 la cámara se alejaba de más** y se veía el vacío negro con la niebla moviéndose. El zoom era fijo (1.35 y después 1.0) pero la cámara del jugador está en 2.4; ahora se acerca un 25% sobre el zoom de la pelea y vuelve exactamente al que tenía.

## 2026-10-15 (La Cripta: avisos de ataque, arte zombi, popups de O.M.N.I.A. y arreglos)

- **Arreglo: no cargaba `Level2_Room2.tscn`.** Un merge dejó la línea del TileSet `Level2.tres` sin cerrar y con un id que no coincidía. Se restauró la línea del rediseño de Uriel. Se revisaron todas las escenas y recursos: no hay más líneas rotas.
- **Enemigos de La Cripta más pulidos** (`crypt_enemy.gd`, nuevo `Scripts/Effects/crypt_telegraph.gd`):
  - Los conos y líneas planas se reemplazaron por avisos dibujados por código, con un estilo para cada enemigo: cono que se carga (gárgola, ghoul, ciempiés), rayo que apunta, se fija y dispara (ojo), mira con casillas (escuadrón y abeja), ondas de campana (campanero) y hexágonos donde van a salir las abejas (apicultora). Detalles en `docs/crypt-enemies.md`.
  - El "¡CUIDADO!" ahora es un "!" que salta sobre la barra de vida.
  - El ciempiés suelta gas de verdad (partículas) dentro del cono.
  - Destello y retroceso en cada disparo; el campanero suelta una onda en cada campanada.
  - Persiguen girando de forma gradual en vez de cambiar de dirección de golpe. El ghoul deja una estela cuando acelera por la espalda. La abeja y el ojo flotan.
  - Los enemigos con arte ahora parpadean al recibir daño (antes la gárgola no lo hacía) y al morir el cuerpo se aplasta y se desvanece (antes la gárgola quedaba visible hasta que terminaba el sonido).
  - "Ciempiés" bien escrito en la escena, el códice, el veneno y el menú de depuración.
- **Apicultora muerta y abeja carnívora con sprite propio**, hechos a partir de los originales: piel verdosa, ropa rota y manchada, ojos que brillan; la abeja es de carne con alas de hueso. Están en `Art/Enemies/Crypt/DeadBeekeeper/` y `Art/Enemies/Crypt/FleshBee/` (los originales no se tocaron). Las escenas usan un `ArtSprite` y el script elige sola la animación de caminar, atacar o invocar.
- **Popups de O.M.N.I.A. con el estilo del juego** (`Scripts/UI/omnia_reveal_popup.gd`):
  - Comprar una pista ya no usa el diálogo nativo de Godot: aparece una ventana con la ficha secreta, "PIEZA X DE Y", el costo y tu chatarra. Al comprar, la ficha se da vuelta, se revela el componente y cae el sello "PISTA OBTENIDA".
  - Al desbloquear una investigación aparece una ventana con su nombre, la pista evocativa, las piezas ya reveladas y el sello "INVESTIGACIÓN DESBLOQUEADA".
  - ESC cierra y Enter confirma.
- **Cartel de la sala** un 15% más chico y más arriba, para que no tape a Lázaro.
- **Cartel del tutorial del inventario** con el estilo nuevo: pestaña de título, tecla "I" animada y botones ENTENDIDO / ABRIR INVENTARIO.
- Textos en español neutro en el códice de La Cripta y en las investigaciones de sinergias.
- Se borró `tmp_prueba_bugs.gd`, un archivo de prueba que se había subido por error.

## 2026-10-14 (charcos de los barriles en pixel art)

- **Los charcos de los barriles ahora son pixel art**, en vez de circulos dibujados con `draw_circle`. La mancha se arma pixel a pixel (`Scripts/Effects/puddle_visuals.gd`, `PuddleVisuals`): borde irregular con ruido, bandas de color como una paleta de tiles y tramado. Se genera a media resolucion y se dibuja al doble, asi el tamaño de pixel coincide con el de los sprites. Cada charco sale un poco distinto.
  - **Fuego:** quemado tramado alrededor, lava en bandas, brasas cuadradas que suben, un poco de humo y la luz titila. **Cada tanto sale una llamarada** con las mismas particulas del lanzallamas (`FlameConeParticles`) desde un punto al azar del charco (a veces dos juntas).
  - **Hielo:** placa limpia con borde de escarcha, dos reflejos en diagonal y grietas de pixeles; destellos que titilan y una neblina fria muy suave.
  - Las particulas son cuadraditos de tamaño fijo (2 o 4 px) para que no se mezclen tamaños.
- La logica no cambio: el fuego sigue quemando cada 0,5 s y el hielo sigue ralentizando un 40%.

## 2026-10-14 (recetas de sinergias, sinergia revelada al armarla y sala de entrenamiento de prueba)

- **Comprar una sinergia en O.M.N.I.A. ahora es comprar su receta.**
  - Antes de comprarla, la receta es secreta: solo se ve el arma, las demas piezas son "?" y el texto va tachado en bloques.
  - Al comprarla se ven las piezas y que hace, pero el sprite sigue en silueta (estado "RECETA") hasta armarla en una run. El boton dice "COMPRAR RECETA".
  - **Animacion al comprar la receta:** las piezas "?" se dan vuelta una por una, un escaneo recorre la silueta y cae un sello dorado de "RECETA OBTENIDA".
  - Se arreglo que el destello de compra a veces apuntaba al detalle viejo (`_refresh_detail` ahora saca los nodos antes de liberarlos).
- **La sinergia se revela al armarla en una run.** La animacion nueva de "nueva sinergia" (la de `synergy_activation.tscn`) suma un paso al final: las tres piezas se juntan en el centro con una onda y chispas, y aparece una ficha del mismo estilo con el sprite de la sinergia, que se revela como en O.M.N.I.A. (la silueta se aclara y la ficha salta con un destello). Desde ese momento se ve en O.M.N.I.A., en el codice, en el armamento del codice y en el menu de seleccion de armas (`GameData.is_synergy_discovered`, que usa `activated_synergies`).
- **Codice, pestaña SINERGIAS:** tres estados. Bloqueada (como antes), receta (todo menos el sprite, con una lupa y "RECETA · ÁRMALA EN UNA RUN") y descubierta. El contador ahora cuenta las sinergias descubiertas.
- **Arreglo: lo que se probaba en la sala de entrenamiento quedaba desbloqueado.** Al entrar, `GameData.begin_sandbox()` guarda una copia del progreso (sinergias, sinergias vistas, mejoras, chatarra, piezas, equipo, armas elegidas, codice y stats de armas); cualquier guardado mientras se esta adentro escribe esa copia, y al salir (`end_sandbox()`) se vuelve a ella. Esto tambien aplica al tutorial: la Mente Colmena del tutorial ya no queda desbloqueada.
- Textos en español neutro en la sala de entrenamiento y en el terminal de sinergias ("Recoge", "equípalos", "Dispárale", "Elige").

## 2026-10-14 (duplicado de objetos al equipar y cartel de sala congelado)

- **Arreglo: los objetos se duplicaban al equiparlos con E.** El objeto quedaba seleccionado despues de equiparlo y, al volver a apretar E, se equipaba otra vez: las armas ocupaban el siguiente slot libre y las partes del cuerpo volvian a la mochila sin salir del slot. Ahora solo se equipa lo que esta en la mochila (`_equip_item_to_slot` y `_on_detail_equip_pressed` en `inventory_ui.gd`) y mantener E apretada ya no repite la accion.
- **Arreglo: el cartel de entrada a la sala quedaba congelado en pantalla** si se abria el inventario o el menu de pausa mientras aparecia. El cartel (`room_title_card.gd`) ahora sigue andando con el juego en pausa y, apenas se abre un menu, se desvanece en un instante.

## 2026-10-14 (arreglo del inventario, códice nuevo y menu de seleccion de armas)

- **Arreglo: el juego crasheaba al arrancar.** En `inventory_ui.gd`, `_apply_primary_button_style` seguia llamando a `_create_9slice_style` y a las texturas `tex_btn_primary_*`, que ya no existen desde que la UI paso a `inventory_ui.tscn` con el tema. Se borraron esas lineas: ahora el boton usa solo `theme_type_variation = "InventoryPrimary"`.
- **La escena nueva del inventario no traia el boton SINERGIAS del codice.** Si falta, `_ensure_synergies_button()` lo agrega copiando el estilo de los otros botones (no hace falta tocar la escena).
- **Codice: cada pestaña tiene su propio diseño** (`Scripts/UI/Codex/`):
  - **Bestiario:** grilla de especimenes con su idle animado en miniatura y una vitrina grande a la derecha con el idle, la descripcion y los stats en chips. Los jefes tienen marco dorado.
  - **Armamento:** un estante por tipo (distancia y cuerpo a cuerpo) con fichas anchas: el arma en grande, stats en chips y los iconos de sus sinergias (en silueta las que faltan).
  - **Items:** casilleros separados en Protesis y Piezas de arma, con una ficha al costado que muestra el objeto que tengas bajo el mouse. Los "+" van en verde y los "-" en naranja.
  - **NPCs:** retratos grandes sobre un pedestal con el idle animado. Se agrego a **Victoria** (la NPC de O.M.N.I.A.): se registra al abrir la terminal por primera vez.
  - **Zonas:** una franja por zona con el numero grande, el arte, un medidor de peligro y las caras de sus enemigos y su jefe.
  - Lo bloqueado se ve en silueta con candado, el nombre cifrado y la descripcion tachada en bloques.
  - Piezas comunes en `CodexKit`; la animacion idle sale de la escena de cada enemigo/NPC (`CodexAnim`), sin duplicar sprites.
- **Menu de seleccion de armas ("PREPARACIÓN DE INVASIÓN" y el terminal de entrenamiento)** con el estilo de la UI nueva: fichas con el sprite del arma, una linea corta e iconos de sus sinergias. Las armas bloqueadas quedan en silueta con candado. ESC cancela y Enter confirma.
- **Speed Demon usa su sprite** (`Art/Weapons/Melee/Dagger/synergy_speeddemon_sprite.png`, 4 cuadros con la sierra girando), tambien en O.M.N.I.A. y en el codice.
- `UIStyle.trimmed()` recorta el borde transparente de un sprite para mostrarlo grande en un marco.

## 2026-10-13 (sinergias Speed Demon y Snowman, pestaña de sinergias y carteles in-game)

- **Speed Demon (daga):** Sierra Circular + Motocicleta + Bateria. Pega muy rapido (se puede mantener apretado el ataque) y cada golpe empuja al jugador hacia donde apunta.
- **Snowman (escopeta):** Mezcladora + Cabeza Humana + Nitrogeno Liquido. Dispara una bola de nieve grande y lenta que atraviesa enemigos y congela a cada uno que toca; se rompe contra las paredes.
- Las dos estan en O.M.N.I.A., en el menu de debug y en el terminal de sinergias.
- **Pestaña SINERGIAS en el codice:** fichas grandes que muestran para que arma es cada sinergia. Las bloqueadas quedan en silueta, con el nombre cifrado, la receta tapada y un sello de rayas encima.
- **Carteles de interaccion nuevos** (`InteractPrompt`): placa oscura con la tecla dibujada e iconos en vez de texto (mano para agarrar, candado para desbloquear, carne + precio, aviso en rojo si falta carne). Los usan cofres, puertas, carteles, terminales, Ygor, hologramas, objetos y Victoria.
- Arreglo: los carteles de los hologramas de Ygor se agrandaban al acercarse y alejarse varias veces.

## 2026-10-13 (cartel nuevo al entrar a cada sala, a prueba)

- **Cartel de entrada a la sala con el estilo de la UI nueva** (`Scripts/UI/room_title_card.gd`). Esta a prueba: se puede volver al texto de antes apagando `use_new_room_title` en el nodo raiz de `HUD.tscn`.
  - Una franja oscura con filos de color se abre en el centro de la pantalla.
  - Arriba aparece una linea dorada chica, por ejemplo "ZONA 2 · SALA 04".
  - El nombre grande se "decodifica" como en una terminal: caracteres al azar que se van fijando de izquierda a derecha.
  - Debajo se dibuja una linea turquesa con un rombo y aparece el subtitulo.
  - Al irse, el nombre tiembla como con interferencia y la franja se cierra. Dura unos 3,5 s.
- **Textos de cada sala:**
  - Salas de combate: el nombre de la zona, con "Sector hostil".
  - Tesoro: "Sala del tesoro", con "Cargamento sin vigilancia".
  - Ygor: "Tienda de Ygor", con "Comercio clandestino".
  - Jefe: la zona con "Amenaza detectada", en rojo.
  - Laboratorio: "Base de operaciones", con "Zona segura".
  - O.M.N.I.A.: "Terminal de mejoras", con "Mejoras permanentes".
  - Entrenamiento: "Simulación".
- En O.M.N.I.A., Biomasa Eficiente usa el icono minimalista del torso en vez del sprite de la carne.

## 2026-10-13 (O.M.N.I.A. con el estilo del inventario y tileset nuevo en la zona 2)

- **La terminal O.M.N.I.A. se rehizo con la misma linea visual que el inventario y el menu de pausa.**
  - Arriba hay una pestaña por categoria (Estructura, Recursos, Arsenal, Sinergias, Protocolos), la chatarra y "Esc / Cerrar". Entra desde abajo como el inventario y se cierra con Esc.
  - A la izquierda va la lista de la categoria, con el progreso (niveles comprados o cuantas hay desbloqueadas). A la derecha, el detalle de lo elegido con el boton para comprar, y abajo el protocolo activo.
  - Las mejoras muestran el nivel con una barra de pasos. Los protocolos marcan cual esta activo.
- **Sinergias y armas con sprite.** Las sinergias usan su sprite (Mente Colmena, Roadkill, Heavy Metal para la Minigun, Cerberus para el Lanzallamas, The Bride, Nemesis y Wolfsbane). Las que todavia no tienen sprite usan el arma o la pieza principal de la receta.
  - **Lo que no esta desbloqueado se ve como silueta:** oscuro y algo borroso, con un borde turquesa que late y una linea de escaneo (`Art/Ui/shaders/silueta_bloqueada.gdshader`).
  - **Al comprarlo,** la silueta se revela con un destello y la ficha da un salto.
  - En el detalle de cada sinergia se ve la receta con los iconos del arma y las piezas. Las tres de cuerpo avisan que piden tener antes Mente Colmena y Roadkill.
- Los nombres y descripciones de las sinergias ahora salen de `SynergyManager` (los mismos que se ven en la run): "Bestia de Caza" pasa a ser "Instinto Canino" y "Trituradora Biomecánica" pasa a ser "Impulso Ligero". Precios y reglas de compra iguales que antes.
- Codigo: `Scripts/UI/omnia_catalog.gd` (`OmniaCatalog`) tiene que se vende, los precios y las compras; `Scripts/UI/omnia_menu.gd` (`OmniaMenu`) es la ventana. `npc_chatarra.gd` solo abre y cierra el menu. `UIStyle` suma estilos de slot y de barra de scroll.
- **Zona 2:** de `Level2_Room2` a `Level2_Room14BossFight` (salas del tesoro y tienda de Ygor 1 incluidas) usan el tileset nuevo `Art/Tileset/Level2.tres`, igual que `Level2_Room1`. `Level2_Room13(Ygor2)` queda como estaba, con el tileset de la zona 1.

## 2026-10-13 (menu de pausa con el estilo del inventario)

- **El menu de pausa (Esc) se rehizo con la misma linea visual que el inventario nuevo:** los paneles SVG de `Art/Ui/svg`, la pestaña de titulo "PAUSA", el contador de chatarra, "Esc / Cerrar" arriba a la derecha y la barra de atajos abajo. Entra desde abajo, igual que el inventario.
  - **Columna MENÚ:** Continuar (boton principal), Guardar partida, Más opciones y, separados abajo, Volver al menú principal y Salir del juego.
  - **Columna AUDIO:** sliders de Música y Efectos con el porcentaje al lado, con la paleta de la UI.
  - **Partida actual:** zona, sala, tiempo, enemigos eliminados y chatarra de la run. Solo aparece dentro de una sala de la run; en el Lab o en los menus se oculta.
- Todo lo que hacia el menu viejo sigue igual: pausa el juego, apaga la musica con el filtro, guarda los volumenes en las opciones, abre la pantalla de "Más opciones" y le pone el sonido de hover a todos los botones del juego.
- `options_menu.tscn` ahora es solo el nodo raiz: la ventana se arma por codigo, como el inventario.
- Nuevo `Scripts/UI/ui_style.gd` (`UIStyle`): colores, paneles, botones, pestaña, teclas y sliders del estilo del inventario, para reusar en otros menus.

## 2026-10-06 (victoria al vencer a Prometeo)

- **Vencer a Prometeo gana el juego.** Unos segundos despues de que explota (`victory_delay`, 3,5 s), aparece la pantalla de victoria con las estadisticas de la run, y el boton "Volver al laboratorio" lleva al Lab.
  - Funciona igual desde la run normal, la sala de prueba o el menu de debug, porque no depende de la zona en la que estes.
- Texto de la pantalla, segun el lore del GDD: "¡GANASTE EL JUEGO!" y "Venciste a Prometeo, el androide que automatizó la justicia y lideró la rebelión. Sin su líder, la rebelión se apaga. Victoria te espera en el laboratorio."
- `show_win_screen` del jugador ahora acepta titulo y subtitulo opcionales. Si no se pasan, muestra los textos de siempre.
- `GameData.win_run()` junta en un solo lugar lo que pasa al ganar la run: marca la victoria, guarda y devuelve el Lab. La usan la puerta del ultimo jefe y Prometeo.

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
