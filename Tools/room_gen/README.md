# Generador de salas del Núcleo

Arma `Level3_Room5` a `Level3_Room14` con el mismo marco que `Level3_Room3`:
plataformas con borde superior de festones, acantilado de raíces, puentes entre cámaras,
pasillos angostos, fosos, tres tipos de piso y props del atlas de Cursed Land.

- `gen.py`: la clase `Room` (plataformas, puentes, fosos, props, anillo de colisión de la capa Walls).
- `build.py`: la definición de las 10 salas. Se edita acá para cambiar una sala.
- `props.py`: catálogo de props (recortes del atlas) y su detección de tiles.

Requiere `pip install pillow scipy numpy`.

    python Tools/room_gen/build.py --preview tmp/salas      # JSON + una imagen por sala (spawns en rojo, jugador en verde, puerta en azul, barriles en amarillo)
    python Tools/room_gen/build.py --preview tmp/salas 6 9  # solo las salas 6 y 9

El JSON queda en `Tools/level3_rooms.json`. Para pasar las salas al juego, en el editor:

    load("res://Tools/level3_room_builder.gd").build_all(true)

`Floor` lleva el piso y los bordes (frenan cuerpos pero no balas), `Walls` las paredes reales
(borde superior, acantilados y un anillo de colisión casi invisible, tile (1,1) del atlas) y
`Tile_Objects` los fosos y props.
