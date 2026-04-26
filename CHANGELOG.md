# Changelog

Todas las novedades, cambios y correcciones de Project Frankenstein.

## [WIP] - 2026-04-11

### Agregado (Added)
- **Sistema de Armas Mejorado:** El arma del jugador ahora orbita a su alrededor y apunta directamente al cursor del mouse (estilo "Enter the Gungeon").
- **Lógica de Enemigos:** Se implementó un sistema de ataques para el enemigo "follower".
- **Efectos Visuales (Game Feel):**
  - Camera shake (temblor de cámara) al recibir daño.
  - Efectos visuales en los bordes de la pantalla cuando el jugador recibe daño.
  - Generador de fundidos (fade-in / fade-out) para transiciones suaves entre escenas.
- **Sistema de Habitaciones:** Las puertas ahora se bloquean y solo se abren luego de derrotar a todos los enemigos de la sala. Se automatizó el *spawn* del jugador.
- **Economía y Recolección:** Sistema de "Scrap" (chatarra) implementado. Los enemigos sueltan Scrap al ser derrotados, y el jugador cuenta con un área de recolección para atraer los ítems con suavidad.

### Cambiado (Changed)
- **HUD / Interfaz:** La barra de vida original fue reemplazada por un sistema de `TextureProgressBar`. Se sumó el contador del Scrap al HUD.
- **Ciclo de Juego:** Se reemplazó el sistema original de "oleadas" por el nuevo sistema de progresión y recolección de Scrap en salas instanciadas.
- **Sistema de Proyectiles:** Se actualizaron los proyectiles para usar su propio Sprite2D en lugar de dibujado procedural, spawneando limpiamente desde el cañón (muzzle) del arma.

### Arreglado (Fixed)
- Lógica de animación del jugador (Flipping correcto al hacer "dash" hacia la izquierda del jugador).
- Spawneado de salas y arenas al inicio del juego.
