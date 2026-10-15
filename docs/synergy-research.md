# Investigaciones y códice

Comprar una investigación en O.M.N.I.A. habilita la combinación durante una partida y revela el primer componente. El nombre y el sprite resultante se revelan al completar la sinergia. Las pistas opcionales revelan el nombre y la imagen del segundo o tercer componente; nunca entregan objetos al inventario.

Los precios de las pistas (400 y 600) y los textos evocativos se editan en el Inspector abriendo `Art/Ui/synergy_research_settings.tres`. Los costos de desbloqueo existentes se conservan: 300 para las primeras investigaciones y 500 para las avanzadas.

Las pistas se guardan por índice, para soportar recetas con componentes repetidos. Las partidas anteriores empiezan sin pistas compradas; las sinergias ya descubiertas conservan toda su información. Las compras verifican saldo, desbloqueo y duplicados. La sala de entrenamiento restaura las pistas al salir.

## Escenas editables

- `Scenes/UI/synergy_recipe_research.tscn`: tres componentes y diálogo de confirmación. `allow_purchase` permite usar la misma escena como consulta.
- `Scenes/UI/synergy_research_item.tscn`: ícono, nombre, incógnita y botón de ojo.
- `Scenes/UI/codex_browser.tscn`: búsqueda, filtro, lista, ficha grande, descripción, estadísticas y AnimationPlayer para la transición de selección.
- `Scenes/UI/codex_entry_card.tscn`: ficha seleccionable con estilos de foco y selección.
- `Scenes/UI/inventory_ui.tscn`: pestañas Inventario, Códice y Síntesis. Los navegadores son instancias editables de la escena anterior.

Síntesis muestra exclusivamente investigaciones desbloqueadas y respeta las pistas conocidas. Es un módulo de consulta durante la partida; las pistas se compran en O.M.N.I.A. El códice permite explorar todas las categorías, filtrar registros conocidos y consultar descripciones completas con desplazamiento independiente. La búsqueda nunca usa nombres ocultos. Los atajos de equipar/comparar solo funcionan en Inventario y escribir en el buscador no cierra la interfaz.

## Validación

Ejecutar `Tests/synergy_research_smoke.tscn` con un directorio de datos de usuario aislado: prueba compras, cancelación, saldo insuficiente, duplicados, persistencia, restauración de entrenamiento y revelado por descubrimiento.

Ejecutar `Tests/codex_browser_smoke.tscn`: prueba las pestañas en el laboratorio, catálogo de recetas desbloqueadas, ocultamiento de pistas, búsqueda vacía, todas las categorías y retorno al inventario. Con render habilitado guarda capturas en la carpeta temporal del sistema.
