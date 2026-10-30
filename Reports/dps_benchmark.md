# DPS contra el maniquí

Medición ejecutada sobre el código del proyecto el 28 de octubre de 2026, Godot 4.8.dev3. Tres semillas (271828–271830), 30 segundos simulados por ensayo, 60 Hz. Se usa la escena real del maniquí, registrando cada llamada a take_damage; conserva colisión, congelación, quemaduras e inmortalidad. Se omiten únicamente textos flotantes y destellos de impacto. No se modificaron estadísticas de combate.

Las armas base no llevan piezas; las sinergias llevan exactamente su receta. Sin protocolos ni mejoras permanentes. El jugador permanece quieto y apunta al centro. Ataques a la máxima cadencia permitida por los temporizadores reales. Distancias: 160 px a distancia, 45 px melee, 110 px Cerberus y 70 px escopeta cercana. Se cuentan impactos ocurridos dentro de los 30 s, sin daño posterior al cierre. El DPS incluye fallos por dispersión, viaje inicial, críticos y efectos. Cada ensayo limpia proyectiles y efectos antes del siguiente. Las partidas guardadas no se escriben.

No mide combate móvil, supervivencia, control de masas, rebotes contra paredes, daño reflejado ni daño a blancos secundarios. Speed Demon y furia sostenida representan condiciones ideales indicadas en sus filas. Las sinergias de cuerpo se prueban con el arma especificada, no tienen un DPS propio universal.

## Resumen medido

| Arma / condición | DPS medio | Mín.–máx. | Daño total medio / 30 s | Daño normal unitario* | Ataques/s* | Crítico* |
|---|---:|---:|---:|---:|---:|---:|
| Arrogancia | 21.49 | 19.13–24.43 | 644.67 | 41 | 0.46 | 19% ×2.3 |
| Avalanche | 14.77 | 13.43–16.1 | 443 | 31 | 0.41 | 11% ×2.3 |
| Cerberus | 24.83 | 24.83–24.83 | 745 | 3 / tick + 2 / quemadura | 6,67 ticks/s | No aplicado al chorro |
| Daga | 8 | 8–8 | 240 | 8 | 1 | 0% ×2 |
| Escopeta | 15 | 15–15 | 450 | 15 | 0.5 | 0% ×2 |
| Escopeta (cerca) | 22.5 | 22.5–22.5 | 675 | 15 | 0.5 | 0% ×2 |
| Flamethrower (escena alternativa) | 37.33 | 37.33–37.33 | 1120 | 3 | 6 | 0% ×2 |
| Hacha | 15 | 15–15 | 450 | 15 | 1 | 0% ×2 |
| Heavy Metal | 51.59 | 50.13–53.87 | 1547.67 | 7 → 10 | 2.34 → 3.64 | 0% ×2 → 20% ×2 |
| Holy Fire | 34.98 | 34.7–35.13 | 1049.33 | 38 | 0.59 | 7% ×2.3 |
| Impulso Ligero | 11.33 | 11.33–11.33 | 340 | 10 | 1.12 | 0% ×2 |
| Impulso Ligero (onda cargada) | No aplica | — | 50 | 50 / onda | Carga manual | — |
| Instinto Canino | 24.2 | 24–24.3 | 726 | 9 | 1.3 | 6% ×2 |
| Instinto Canino (furia sostenida) | 33.3 | 33–33.6 | 999 | 9 | 1.8 | 6% ×2 |
| Maza | 17.5 | 17.5–17.5 | 525 | 35 | 0.5 | 0% ×2 |
| Mente Colmena | 128.91 | 126.6–130.33 | 3867.33 | 13 | 2.58 | 27% ×2.3 |
| Nemesis | 17.17 | 16.5–17.5 | 515 | 15 | 1.1 | 9% ×2 |
| Nemesis (10% HP) | 801.77 | 790.3–807.5 | 24053 | 83 | 3.26 | 99% ×3.08 |
| Nemesis (50% HP) | 227.57 | 216.37–235.97 | 6827 | 53 | 2.3 | 59% ×2.6 |
| Oil of the Sick | 26.77 | 26.2–27.1 | 803 | 14 | 1.3 | 6% ×2 |
| Oil of the Sick + pistola | 52.57 | 52–53.67 | 1577 | 14 | 1.3 | 6% ×2 |
| Pistola | 10 | 10–10 | 300 | 10 | 1 | 0% ×2 |
| Roadkill | 36 | 36–36 | 1080 | 15 | 2.43 | 0% ×2 |
| Set Musculoso | 13.07 | 13.07–13.07 | 392 | 14 | 0.95 | 0% ×2 |
| Speed Demon | 90.93 | 90.93–90.93 | 2728 | 11 / pulso | 6.62 nominal | 0% ×2 |
| The Bride | 15.77 | 15.37–16.37 | 473 | 5 | 2.28 | 15% ×2.3 |
| UZI | 7.73 | 7.73–7.73 | 232 | 4 | 2 | 0% ×2 |
| Wolfsbane | 22.2 | 19.27–25.13 | 666 | 17 | 1.15 | 16% ×2.3 |

*Daño normal unitario: por proyectil o golpe, sin crítico; no equivale al daño de una ráfaga. Cadencia nominal configurada, antes del redondeo a frames; el DPS se mide y no se obtiene multiplicando columnas. Las flechas indican inicio → régimen de Heavy Metal. Las excepciones de ticks y pulsos se indican expresamente. La vida de Nemesis permanece fija durante cada ensayo.

## Estadísticas y desglose por caso

### Arrogancia

Sin proyectiles enemigos: no se cuenta daño reflejado.

- Receta: Mezcladora + Cabeza humana + Colmena.
- Daño base de escena: 38; daño efectivo sin redondear: 41; velocidad base: 0.5 ataques/s.
- DPS desde segundo 5 hasta 30: 19.45. Impactos medios: 14; críticos medios: 1.33.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 21.49 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=-0.08; crit_chance=0.19; crit_damage=0.3; damage=3. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/ArroganceMace.tscn`.

### Avalanche

Una bola de nieve por disparo; congelación no suma daño.

- Receta: Mezcladora + Cabeza humana + Nitrógeno.
- Daño base de escena: 28; daño efectivo sin redondear: 31; velocidad base: 0.45 ataques/s.
- DPS desde segundo 5 hasta 30: 15.24. Impactos medios: 13; críticos medios: 1.
- Proyectiles por ataque: 1; dispersión: 0°; velocidad: 190 px/s; duración: 2.2 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 14.77 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=-0.08; crit_chance=0.11; crit_damage=0.3; damage=3; slow_chance=0.22. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Snowman.tscn`.

### Cerberus

Chorro continuo a 110 px; ticks cada 0,15 s y quemadura. No multiplica el chorro por el número de proyectiles de la escena.

- Receta: 3 × Cabeza de perro.
- Daño base de escena: 3; daño efectivo sin redondear: 3; velocidad base: 6 ataques/s.
- DPS desde segundo 5 hasta 30: 24.88. Impactos medios: 273; críticos medios: 0.
- Proyectiles por ataque: 2; dispersión: 18°; velocidad: 260 px/s; duración: 0.3 s; penetración: 2. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: burn: 4.93 DPS; flame_stream: 19.9 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.45; crit_chance=0.15. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Cerberus.tscn`.

### Daga

Contacto a 45 px.

- Daño base de escena: 8; daño efectivo sin redondear: 8; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 8. Impactos medios: 30; críticos medios: 0.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 8 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/dagger.tscn`.

### Escopeta

160 px: no entran todos los perdigones.

- Daño base de escena: 15; daño efectivo sin redondear: 15; velocidad base: 0.5 ataques/s.
- DPS desde segundo 5 hasta 30: 14.4. Impactos medios: 30; críticos medios: 0.
- Proyectiles por ataque: 3; dispersión: 25°; velocidad: 300 px/s; duración: 0.6 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 15 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/shotgun.tscn`.

### Escopeta (cerca)

70 px: entran los tres perdigones.

- Daño base de escena: 15; daño efectivo sin redondear: 15; velocidad base: 0.5 ataques/s.
- DPS desde segundo 5 hasta 30: 21.6. Impactos medios: 45; críticos medios: 0.
- Proyectiles por ataque: 3; dispersión: 25°; velocidad: 300 px/s; duración: 0.6 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 22.5 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/shotgun.tscn`.

### Flamethrower (escena alternativa)

Escena existente sin receta activa: proyectiles de fuego, distinta del chorro continuo de Cerberus.

- Daño base de escena: 3; daño efectivo sin redondear: 3; velocidad base: 6 ataques/s.
- DPS desde segundo 5 hasta 30: 37.68. Impactos medios: 398; críticos medios: 0.
- Proyectiles por ataque: 2; dispersión: 18°; velocidad: 260 px/s; duración: 0.16 s; penetración: 2. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 32.4 DPS; burn: 4.93 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Flamethrower.tscn`.

### Hacha

Contacto a 45 px.

- Daño base de escena: 15; daño efectivo sin redondear: 15; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 15. Impactos medios: 30; críticos medios: 0.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 15 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/axe.tscn`.

### Heavy Metal

Promedio incluye los primeros 4 s de calentamiento; ver DPS desde segundo 5. Al máximo: 20% crítico y 25% de fragmentación; los fragmentos (30% del daño del proyectil original) también cuentan en el DPS directo.

- Receta: Mezcladora + Motocicleta + Sierra circular.
- Daño base de escena: 4; daño efectivo sin redondear: 10.71; velocidad base: 2 ataques/s.
- DPS desde segundo 5 hasta 30: 55.72. Impactos medios: 203; críticos medios: 36.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 500 px/s; duración: 1.5 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 51.59 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.82; crit_chance=0.2; damage=3; damage_multiplier=0.53. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Minigun.tscn`.

### Holy Fire

Incluye quemaduras; no hay enemigos alrededor para las llamas radiales.

- Receta: Gasolina + Pulmones + Cabeza humana.
- Daño base de escena: 36; daño efectivo sin redondear: 37.8; velocidad base: 0.5 ataques/s.
- DPS desde segundo 5 hasta 30: 35.65. Impactos medios: 87; críticos medios: 1.33.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 24.98 DPS; burn: 10 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.18; burn_chance=0.15; crit_chance=0.07; crit_damage=0.3; damage_multiplier=0.05. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/HolyFireMace.tscn`.

### Impulso Ligero

Pistola base con las tres piezas corporales; jugador quieto, sin onda.

- Receta: Torso ligero + Piernas rodantes + Brazo ligero.
- Daño base de escena: 10; daño efectivo sin redondear: 10; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 11.2. Impactos medios: 34; críticos medios: 0.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 400 px/s; duración: 3 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 11.33 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.12; dash_cooldown_percent=-0.42; max_health_percent=-0.08; move_speed_percent=0.32. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Revolver.tscn`.

### Impulso Ligero (onda cargada)

Una única activación ya cargada. Reportar daño de la onda, no DPS sostenido: cargarla requiere desplazamiento.

- Receta: Torso ligero + Piernas rodantes + Brazo ligero.
- Daño base de escena: 10; daño efectivo sin redondear: 10; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 0. Impactos medios: 1; críticos medios: 0.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 400 px/s; duración: 3 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 1.67 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.12; dash_cooldown_percent=-0.42; max_health_percent=-0.08; move_speed_percent=0.32. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Revolver.tscn`.

### Instinto Canino

Dos dagas base, sin furia. No es un arma independiente.

- Receta: Torso espinado + Brazo armado + Piernas caninas.
- Daño base de escena: 8; daño efectivo sin redondear: 9.2; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 23.88. Impactos medios: 78; críticos medios: 2.67.
- Escala de alcance melee: ×1.12. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 24.2 DPS.
- Modificadores efectivos de piezas y sinergia: armor=-1; attack_range_percent=0.12; attack_speed=0.3; crit_chance=0.06; damage_multiplier=0.15; max_health_percent=0.12; move_speed_percent=0.26. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/dagger.tscn`.

### Instinto Canino (furia sostenida)

Dos dagas y furia fijada durante todo el ensayo; techo condicional. En partida la furia dura 3 s por activación.

- Receta: Torso espinado + Brazo armado + Piernas caninas.
- Daño base de escena: 8; daño efectivo sin redondear: 9.2; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 32.88. Impactos medios: 106; críticos medios: 5.
- Escala de alcance melee: ×1.12. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 33.3 DPS.
- Modificadores efectivos de piezas y sinergia: armor=-1; attack_range_percent=0.12; attack_speed=0.8; crit_chance=0.06; damage_multiplier=0.15; max_health_percent=0.12; move_speed_percent=0.26. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/dagger.tscn`.

### Maza

Contacto a 45 px.

- Daño base de escena: 35; daño efectivo sin redondear: 35; velocidad base: 0.5 ataques/s.
- DPS desde segundo 5 hasta 30: 16.8. Impactos medios: 15; críticos medios: 0.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 17.5 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/mace.tscn`.

### Mente Colmena

Tres abejas teledirigidas; incluye críticos de las piezas.

- Receta: Colmena + Cerebro + Cabeza humana.
- Daño base de escena: 10; daño efectivo sin redondear: 13; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 130.49. Impactos medios: 222; críticos medios: 61.33.
- Proyectiles por ataque: 3; dispersión: 50°; velocidad: 100 px/s; duración: 7 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 128.91 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=1.58; bullet_count=1; crit_chance=0.27; crit_damage=0.3; damage=3. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/HivemindPistol.tscn`.

### Nemesis

100% de vida.

- Receta: Sierra circular + Aguijón mecánico + Cabeza de perro.
- Daño base de escena: 12; daño efectivo sin redondear: 15; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 16.8. Impactos medios: 33; críticos medios: 1.33.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 17.17 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.1; crit_chance=0.09; damage_multiplier=0.25. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/NemesisDagger.tscn`.

### Nemesis (10% HP)

Vida fijada al 10%; críticos y daño aumentados.

- Receta: Sierra circular + Aguijón mecánico + Cabeza de perro.
- Daño base de escena: 12; daño efectivo sin redondear: 82.5; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 801.21. Impactos medios: 95; críticos medios: 94.
- Escala de alcance melee: ×2.08. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 801.77 DPS.
- Modificadores efectivos de piezas y sinergia: attack_range_percent=1.08; attack_speed=2.26; crit_chance=0.99; crit_damage=1.08; damage=54; damage_multiplier=0.25. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/NemesisDagger.tscn`.

### Nemesis (50% HP)

Vida fijada al 50%; críticos y daño aumentados.

- Receta: Sierra circular + Aguijón mecánico + Cabeza de perro.
- Daño base de escena: 12; daño efectivo sin redondear: 52.5; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 225.24. Impactos medios: 67; críticos medios: 39.
- Escala de alcance melee: ×1.6. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 227.57 DPS.
- Modificadores efectivos de piezas y sinergia: attack_range_percent=0.6; attack_speed=1.3; crit_chance=0.59; crit_damage=0.6; damage=30; damage_multiplier=0.25. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/NemesisDagger.tscn`.

### Oil of the Sick

Solo hacha y efectos de sus piezas; sin bala detonadora.

- Receta: Gasolina + Motocicleta + Glándula tóxica.
- Daño base de escena: 15; daño efectivo sin redondear: 13.95; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 26.61. Impactos medios: 86.67; críticos medios: 1.33.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 18.82 DPS; burn: 7.94 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.3; burn_chance=0.27; crit_chance=0.06; damage_multiplier=-0.07. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/AltoOctanajeAxe.tscn`.

### Oil of the Sick + pistola

Hacha y pistola base simultáneas, más explosiones y quemaduras. Se ignora el autodaño para mantener constante el ensayo.

- Receta: Gasolina + Motocicleta + Glándula tóxica.
- Daño base de escena: 15; daño efectivo sin redondear: 13.95; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 53.09. Impactos medios: 157; críticos medios: 0.33.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 28.36 DPS; burn: 3.7 DPS; fuel_explosion: 20.51 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.3; burn_chance=0.27; crit_chance=0.06; damage_multiplier=-0.07. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/AltoOctanajeAxe.tscn`.

### Pistola

Un proyectil por disparo.

- Daño base de escena: 10; daño efectivo sin redondear: 10; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 10. Impactos medios: 30; críticos medios: 0.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 400 px/s; duración: 3 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 10 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Revolver.tscn`.

### Roadkill

Sin paredes: los rebotes no aportan daño adicional.

- Receta: Motocicleta + Sierra circular + Pulmones.
- Daño base de escena: 10; daño efectivo sin redondear: 15.45; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 36. Impactos medios: 72; críticos medios: 0.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 700 px/s; duración: 3 s; penetración: 3. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 36 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=1.43; damage=5; damage_multiplier=0.03; piercing=3. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/RoadkillPistol.tscn`.

### Set Musculoso

Pistola base con las tres piezas corporales.

- Receta: Torso blindado + Brazo reforzado + Piernas biónicas.
- Daño base de escena: 10; daño efectivo sin redondear: 14.4; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 12.88. Impactos medios: 28; críticos medios: 0.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 400 px/s; duración: 3 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 13.07 DPS.
- Modificadores efectivos de piezas y sinergia: armor=7; attack_speed=-0.05; damage=2; damage_multiplier=0.2; max_health_percent=0.53; move_speed_percent=-0.17. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/Revolver.tscn`.

### Speed Demon

Contacto sostenido sin desplazamiento del jugador: techo estacionario de cuatro pulsos por ciclo, no DPS de una pasada.

- Receta: Sierra circular + Motocicleta + Batería.
- Daño base de escena: 10; daño efectivo sin redondear: 10.3; velocidad base: 2 ataques/s.
- DPS desde segundo 5 hasta 30: 90.64. Impactos medios: 248; críticos medios: 0.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 90.93 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=2.31; damage_multiplier=0.03; stun_chance=0.08. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/SpeedDemonDagger.tscn`.

### The Bride

Incluye descargas eléctricas; sin blancos adicionales para encadenar.

- Receta: Cabeza humana + Batería + Cerebro.
- Daño base de escena: 5; daño efectivo sin redondear: 5; velocidad base: 2 ataques/s.
- DPS desde segundo 5 hasta 30: 15.92. Impactos medios: 79.67; críticos medios: 10.33.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 500 px/s; duración: 1.5 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 13.23 DPS; electric: 2.53 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.14; crit_chance=0.15; crit_damage=0.3; stun_chance=0.08. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/TheBride.tscn`.

### UZI

Un proyectil por disparo.

- Daño base de escena: 4; daño efectivo sin redondear: 4; velocidad base: 2 ataques/s.
- DPS desde segundo 5 hasta 30: 7.68. Impactos medios: 58; críticos medios: 0.
- Proyectiles por ataque: 1; dispersión: 15°; velocidad: 500 px/s; duración: 1.5 s; penetración: 0. Valores de proyectil no aplican al chorro continuo de Cerberus.
- Orígenes de daño: direct: 7.73 DPS.
- Modificadores efectivos de piezas y sinergia: ninguno. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/uzi.tscn`.

### Wolfsbane

Objetivo marcado. La explosión excluye al enemigo golpeado y no hay blancos secundarios.

- Receta: Cabeza humana + Cabeza de perro + Aguijón mecánico.
- Daño base de escena: 15; daño efectivo sin redondear: 16.5; velocidad base: 1 ataques/s.
- DPS desde segundo 5 hasta 30: 22.27. Impactos medios: 34; críticos medios: 4.
- Escala de alcance melee: ×1. Speed Demon añade su escalado propio de alcance y daño por cadencia.
- Orígenes de daño: direct: 22.2 DPS.
- Modificadores efectivos de piezas y sinergia: attack_speed=0.15; crit_chance=0.16; crit_damage=0.3; damage_multiplier=0.1. Los porcentajes se expresan como fracciones: 0,15 = 15%.
- Escena: `res://Scenes/Weapon/WolfsbaneAxe.tscn`.

## Observaciones del código y límites

- Wolfsbane: el código detecta la marca pero no multiplica el golpe; la explosión de 20 excluye al objetivo original. Por eso contra un solo maniquí no reproduce la promesa de «muchísimo más daño» al marcado de la descripción. No se cambió este comportamiento durante el test.
- Cerberus: 26,1 DPS configurados de chorro se convierten en ticks de 3,915, truncados a 3 por take_damage(int), más quemadura de 2 cada 0,4 s. Los críticos de las piezas no se aplican en FlameStream. El desglose muestra el resultado real.
- Los efectos de ralentizar, congelar y aturdir no infligen daño por sí solos. Arrogancia pierde su componente de reflejo contra un maniquí que no dispara; Holy Fire, Wolfsbane y The Bride no pueden explotar su daño multiblanco.
- Impulso Ligero: la onda cargada inflige 50 una vez; no asignar DPS sostenido sin especificar la ruta y el tiempo de recarga por movimiento.

## Reproducir

Ejecutar desde la raíz del proyecto:

```powershell
& <ruta-a-Godot> --headless --fixed-fps 60 --path . res://Tests/dps_benchmark.tscn
./Reports/build_dps_report.ps1
```

Opcionales: BENCH_SECONDS, BENCH_REPEATS y BENCH_FILTER (subcadena del nombre). Los resultados completos y el histograma de daño por impacto están en `dps_benchmark.json`. El informe asume la ejecución estándar de 30 s × 3 repeticiones. El generador no vuelve a ejecutar el motor.
