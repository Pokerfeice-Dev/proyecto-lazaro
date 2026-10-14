# Inventario y presentación de sinergias

## Editar en Godot

- `Scenes/UI/inventory_ui.tscn`: estructura completa del inventario. Las columnas están bajo `WindowMargin/WindowPanel/WindowInnerMargin/WindowVBox/ContentArea/MainThreeColumns`. Incluye filtros, ficha del objeto, equipo, atributos, códice, tooltip y sonidos.
- `Scenes/UI/inventory_slot.tscn`: escena compartida por las casillas del inventario, equipamiento y entradas del códice. `Visuals` contiene los iconos, texto y cantidad. Editar esta escena cambia todas sus instancias. En una instancia se pueden ajustar tamaño, tipo de slot y texto vacío desde el Inspector.
- `Art/Ui/inventory_theme.tres`: estilos de botones, pestañas y estados de los slots. Sus variaciones `InventoryTabActive`, `InventoryPrimary` e `InventorySlotEquipped`, entre otras, se editan en el editor de temas.
- Los cinco slots del cuerpo se posicionan mediante anchors y offsets nativos. El retrato usa `PortraitCenter`. No hay código que reconstruya estas columnas o reposicione las casillas.
- Los nodos marcados como únicos (`%`) son referencias del script. Se pueden mover en la jerarquía; conservar sus nombres. Mantener también los nombres `Value` y `Delta` dentro de las filas de atributos, y los hijos de `Visuals` en los slots.

La chatarra se quitó de la cabecera de este inventario. El HUD y la economía siguen independientes.

## Animación de sinergia

Abrir `Scenes/UI/synergy_activation.tscn` y seleccionar `AnimationPlayer`:

- `activate`: entrada, convergencia de los tres componentes, circuito, pulso, chispas, barrido y revelación del texto. Dura 1,8 segundos.
- `idle`: órbita y pulso suave del indicador de sincronización mientras espera confirmación.
- `dismiss`: salida y atenuación del sonido.
- `RESET`: estado de referencia para editar.

`Root/Center/Panel` contiene el diseño. `Assembly/Ingredient1..3` son las tarjetas de componentes. `ChargeSound` y `ActivationSound` son nodos `AudioStreamPlayer`, con recursos, volumen y bus `SFX` editables. Sus momentos de reproducción son pistas de `activate`.

El código únicamente completa nombre, descripción e iconos de la receta, inicia las animaciones y administra el cierre. Los efectos y sus tiempos viven en la escena, no se construyen en ejecución.

Se celebra cuando una receta pasa de inactiva a activa, incluso si ya había sido descubierta. Actualizar el inventario o entrar en otra sala con la misma combinación no repite el aviso. Si se activan varias recetas juntas se muestran en cola. Al cerrar con el botón, E, Enter o Escape se restaura el estado de pausa anterior.

## Verificación

`Tests/inventory_ui_smoke.tscn` verifica slots, filtros, equipamiento, códice, atributos, activación real, cola y pausa. Ejecutar con Godot en un entorno de datos de usuario aislado. No escribe partidas; modifica únicamente el estado en memoria. Con renderizado también guarda capturas temporales del inventario y la sinergia.
