# Build para Buenos Aires Game Dev

El preset **Buenos Aires Game Dev** compila el juego con la feature `event_demo`.
El ejecutable conserva el inicio, la cinemática y los menús normales. La
configuración especial se activa recién cuando se inicia una nueva run.

La demo contiene seis salas de nivel 1; la séptima es el jefe final. Enemigos,
jefe, daño y recompensas conservan los valores normales. O.M.N.I.A. se aplica
temporalmente al 50% (nivel 3 de 5, redondeado) y todas las sinergias quedan
disponibles para combinar.

La sesión usa un sandbox: no escribe slots, no conserva chatarra y restaura el
estado previo al terminar. Tras vencer al jefe muestra el agradecimiento del evento
y vuelve al laboratorio.

Para exportar desde Godot: **Proyecto → Exportar → Buenos Aires Game Dev → Exportar proyecto**.

## Probar el modo evento en el editor

En **Proyecto → Configuración del proyecto** (con *Configuración avanzada* activada) está `frankengun/modo_evento`. Prendido, el editor y cualquier exportación se comportan como el build del evento: run de 6 salas + jefe, sandbox, pantallas finales con los QR y el video, registro de runs y vuelta al menú por inactividad. Después del evento se apaga y todo vuelve a la normalidad (el preset del evento sigue usando la feature `event_demo`).

## Versión itch.io (juego completo)

Con `frankengun/modo_evento` apagado (como queda ahora) el juego es el completo:

- Runs normales (7 a 10 salas por zona), las tres zonas y sus jefes. Al vencer al primer jefe se sigue a la zona 2.
- Las armas y sinergias se desbloquean jugando (en el evento venían todas habilitadas).
- Laboratorio completo: puerta a la sala de entrenamiento visible y sin plantas tapando el paso a O.M.N.I.A.
- Sin QR, video final, registro de runs ni vuelta al menú por inactividad.

**Cheats:** `frankengun/cheats` (en la misma sección) los prende y los apaga. Apagado, no funcionan el menú U / T, las teclas F1-F12, la "ç" para limpiar la sala ni el cambio de armas con 1-6. Prenderlo solo para probar, y apagarlo antes de exportar. En el build del evento los cheats siempre están prendidos (ahí está la pestaña Registro).

Para volver al build del evento: exportar con el preset **Buenos Aires Game Dev** (tiene la feature `event_demo`) o prender `frankengun/modo_evento`.
