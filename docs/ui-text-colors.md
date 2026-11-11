# Colores semánticos de texto

La paleta compartida vive en `UIStyle.TEXT_ROLES`. Usar `style_text` para controles y `colored_text` para fragmentos de RichTextLabel.

| Rol | Uso |
| --- | --- |
| normal | Descripciones y lectura principal |
| muted | Metadatos, información secundaria y estados deshabilitados |
| selected | Acción principal disponible, objeto seleccionado y sus valores |
| positive | Mejoras, equipo activo, sinergias y guardado |
| warning | Capacidad llena y salida de una partida |
| negative | Pérdidas en comparaciones y borrado de partidas |

Resaltar títulos, estados o valores concretos; mantener los párrafos neutros. Conservar palabras como EQUIPADA, BLOQUEADO y LLENA, además de signos +/− y flechas de comparación, para no depender exclusivamente del color. Los botones principales con fondo dorado conservan texto oscuro por contraste; los roles de texto se aplican a botones de fondo oscuro.
