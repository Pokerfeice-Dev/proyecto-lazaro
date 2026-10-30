$ErrorActionPreference = 'Stop'
$reportDir = $PSScriptRoot
$data = Get-Content -LiteralPath (Join-Path $reportDir 'dps_benchmark.json') -Raw | ConvertFrom-Json
$culture = [System.Globalization.CultureInfo]::InvariantCulture
function F($value) { ([double]$value).ToString('0.##', $culture) }
function Mean($rows, $property) { ($rows | Measure-Object -Property $property -Average).Average }
$notes = @{
    'Pistola' = 'Un proyectil por disparo.'
    'UZI' = 'Un proyectil por disparo.'
    'Escopeta' = '160 px: no entran todos los perdigones.'
    'Escopeta (cerca)' = '70 px: entran los tres perdigones.'
    'Daga' = 'Contacto a 45 px.'
    'Maza' = 'Contacto a 45 px.'
    'Hacha' = 'Contacto a 45 px.'
    'Mente Colmena' = 'Tres abejas teledirigidas; incluye críticos de las piezas.'
    'Roadkill' = 'Sin paredes: los rebotes no aportan daño adicional.'
    'Heavy Metal' = 'Promedio incluye los primeros 4 s de calentamiento; ver DPS desde segundo 5. Al máximo: 20% crítico y 25% de fragmentación; los fragmentos (30% del daño del proyectil original) también cuentan en el DPS directo.'
    'Cerberus' = 'Chorro continuo a 110 px; ticks cada 0,15 s y quemadura. No multiplica el chorro por el número de proyectiles de la escena.'
    'Wolfsbane' = 'Objetivo marcado. La explosión excluye al enemigo golpeado y no hay blancos secundarios.'
    'Nemesis' = '100% de vida.'
    'Nemesis (50% HP)' = 'Vida fijada al 50%; críticos y daño aumentados.'
    'Nemesis (10% HP)' = 'Vida fijada al 10%; críticos y daño aumentados.'
    'Arrogancia' = 'Sin proyectiles enemigos: no se cuenta daño reflejado.'
    'The Bride' = 'Incluye descargas eléctricas; sin blancos adicionales para encadenar.'
    'Speed Demon' = 'Contacto sostenido sin desplazamiento del jugador: techo estacionario de cuatro pulsos por ciclo, no DPS de una pasada.'
    'Holy Fire' = 'Incluye quemaduras; no hay enemigos alrededor para las llamas radiales.'
    'Oil of the Sick' = 'Solo hacha y efectos de sus piezas; sin bala detonadora.'
    'Oil of the Sick + pistola' = 'Hacha y pistola base simultáneas, más explosiones y quemaduras. Se ignora el autodaño para mantener constante el ensayo.'
    'Avalanche' = 'Una bola de nieve por disparo; congelación no suma daño.'
    'Instinto Canino' = 'Dos dagas base, sin furia. No es un arma independiente.'
    'Instinto Canino (furia sostenida)' = 'Dos dagas y furia fijada durante todo el ensayo; techo condicional. En partida la furia dura 3 s por activación.'
    'Impulso Ligero' = 'Pistola base con las tres piezas corporales; jugador quieto, sin onda.'
    'Impulso Ligero (onda cargada)' = 'Una única activación ya cargada. Reportar daño de la onda, no DPS sostenido: cargarla requiere desplazamiento.'
    'Set Musculoso' = 'Pistola base con las tres piezas corporales.'
    'Flamethrower (escena alternativa)' = 'Escena existente sin receta activa: proyectiles de fuego, distinta del chorro continuo de Cerberus.'
}
$recipes = @{
    pistola_mente_colmena = 'Colmena + Cerebro + Cabeza humana'
    roadkill = 'Motocicleta + Sierra circular + Pulmones'
    minigun = 'Mezcladora + Motocicleta + Sierra circular'
    lanzallamas = '3 × Cabeza de perro'
    hombre_lobo = 'Cabeza humana + Cabeza de perro + Aguijón mecánico'
    daga_del_odio = 'Sierra circular + Aguijón mecánico + Cabeza de perro'
    arrogancia = 'Mezcladora + Cabeza humana + Colmena'
    relampago = 'Cabeza humana + Batería + Cerebro'
    speed_demon = 'Sierra circular + Motocicleta + Batería'
    holy_fire = 'Gasolina + Pulmones + Cabeza humana'
    alto_octanaje = 'Gasolina + Motocicleta + Glándula tóxica'
    snowman = 'Mezcladora + Cabeza humana + Nitrógeno'
    bestia_de_caza = 'Torso espinado + Brazo armado + Piernas caninas'
    trituradora_biomecanica = 'Torso ligero + Piernas rodantes + Brazo ligero'
    acorazado_muscular = 'Torso blindado + Brazo reforzado + Piernas biónicas'
}
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# DPS contra el maniquí')
$lines.Add('')
$lines.Add('Medición ejecutada sobre el código del proyecto el 28 de octubre de 2026, Godot 4.8.dev3. Tres semillas (271828–271830), 30 segundos simulados por ensayo, 60 Hz. Se usa la escena real del maniquí, registrando cada llamada a take_damage; conserva colisión, congelación, quemaduras e inmortalidad. Se omiten únicamente textos flotantes y destellos de impacto. No se modificaron estadísticas de combate.')
$lines.Add('')
$lines.Add('Las armas base no llevan piezas; las sinergias llevan exactamente su receta. Sin protocolos ni mejoras permanentes. El jugador permanece quieto y apunta al centro. Ataques a la máxima cadencia permitida por los temporizadores reales. Distancias: 160 px a distancia, 45 px melee, 110 px Cerberus y 70 px escopeta cercana. Se cuentan impactos ocurridos dentro de los 30 s, sin daño posterior al cierre. El DPS incluye fallos por dispersión, viaje inicial, críticos y efectos. Cada ensayo limpia proyectiles y efectos antes del siguiente. Las partidas guardadas no se escriben.')
$lines.Add('')
$lines.Add('No mide combate móvil, supervivencia, control de masas, rebotes contra paredes, daño reflejado ni daño a blancos secundarios. Speed Demon y furia sostenida representan condiciones ideales indicadas en sus filas. Las sinergias de cuerpo se prueban con el arma especificada, no tienen un DPS propio universal.')
$lines.Add('')
$lines.Add('## Resumen medido')
$lines.Add('')
$lines.Add('| Arma / condición | DPS medio | Mín.–máx. | Daño total medio / 30 s | Daño normal unitario* | Ataques/s* | Crítico* |')
$lines.Add('|---|---:|---:|---:|---:|---:|---:|')
$groups = $data.results | Group-Object name
foreach ($group in $groups) {
    $rows = $group.Group
    $r = $rows[0]
    $s = $r.stats_start
    $e = $r.stats_end
    $dps = F (Mean $rows 'dps')
    $span = (F (($rows | Measure-Object dps -Minimum).Minimum)) + '–' + (F (($rows | Measure-Object dps -Maximum).Maximum))
    $hit = F $s.normal_hit_damage
    $rate = F $s.attacks_per_second
    $crit = (F ($s.crit_chance * 100)) + '% ×' + (F $s.crit_multiplier)
    if ([math]::Abs($s.crit_chance - $e.crit_chance) -gt 0.001) { $crit += ' → ' + (F ($e.crit_chance * 100)) + '% ×' + (F $e.crit_multiplier) }
    if ($s.normal_hit_damage -ne $e.normal_hit_damage) { $hit += ' → ' + (F $e.normal_hit_damage) }
    if ([math]::Abs($s.attacks_per_second - $e.attacks_per_second) -gt 0.001) { $rate += ' → ' + (F $e.attacks_per_second) }
    if ($r.mode -eq 'burst') { $dps = 'No aplica'; $span = '—'; $hit = '50 / onda'; $rate = 'Carga manual'; $crit = '—' }
    if ($r.synergy -eq 'lanzallamas') { $hit = '3 / tick + 2 / quemadura'; $rate = '6,67 ticks/s'; $crit = 'No aplicado al chorro' }
    if ($r.synergy -eq 'speed_demon') { $hit = '11 / pulso'; $rate = (F $s.attacks_per_second) + ' nominal' }
    $lines.Add('| ' + $group.Name + ' | ' + $dps + ' | ' + $span + ' | ' + (F (Mean $rows 'damage')) + ' | ' + $hit + ' | ' + $rate + ' | ' + $crit + ' |')
}
$lines.Add('')
$lines.Add('*Daño normal unitario: por proyectil o golpe, sin crítico; no equivale al daño de una ráfaga. Cadencia nominal configurada, antes del redondeo a frames; el DPS se mide y no se obtiene multiplicando columnas. Las flechas indican inicio → régimen de Heavy Metal. Las excepciones de ticks y pulsos se indican expresamente. La vida de Nemesis permanece fija durante cada ensayo.')
$lines.Add('')
$lines.Add('## Estadísticas y desglose por caso')
foreach ($group in $groups) {
    $rows = $group.Group
    $r = $rows[0]
    $s = $r.stats_end
    $lines.Add('')
    $lines.Add('### ' + $group.Name)
    $lines.Add('')
    $lines.Add($notes[$group.Name])
    $lines.Add('')
    if ($r.synergy) { $lines.Add('- Receta: ' + $recipes[$r.synergy] + '.') }
    $lines.Add('- Daño base de escena: ' + (F $s.base_damage) + '; daño efectivo sin redondear: ' + (F $s.effective_damage) + '; velocidad base: ' + (F $s.base_rate) + ' ataques/s.')
    $lines.Add('- DPS desde segundo 5 hasta 30: ' + (F (Mean $rows 'dps_after_5s')) + '. Impactos medios: ' + (F (Mean $rows 'hits')) + '; críticos medios: ' + (F (Mean $rows 'critical_hits')) + '.')
    if ($null -ne $s.pellets) {
        $lines.Add('- Proyectiles por ataque: ' + $s.pellets + '; dispersión: ' + (F $s.spread) + '°; velocidad: ' + (F $s.projectile_speed) + ' px/s; duración: ' + (F $s.projectile_lifetime) + ' s; penetración: ' + $s.piercing + '. Valores de proyectil no aplican al chorro continuo de Cerberus.')
    } else {
        $lines.Add('- Escala de alcance melee: ×' + (F $s.range_scale) + '. Speed Demon añade su escalado propio de alcance y daño por cadencia.')
    }
    $parts = @()
    foreach ($source in @('direct','burn','electric','fuel_explosion','holy_fire','flame_stream')) {
        $total = 0.0
        foreach ($row in $rows) { if ($null -ne $row.sources.$source) { $total += $row.sources.$source } }
        if ($total -gt 0) { $parts += $source + ': ' + (F ($total / $rows.Count / $data.seconds)) + ' DPS' }
    }
    $lines.Add('- Orígenes de daño: ' + ($parts -join '; ') + '.')
    $bonuses = @()
    foreach ($prop in $s.PSObject.Properties) {
        if ($prop.Name.StartsWith('bonus_') -and [double]$prop.Value -ne 0) { $bonuses += $prop.Name.Substring(6) + '=' + (F $prop.Value) }
    }
    $lines.Add('- Modificadores efectivos de piezas y sinergia: ' + $(if ($bonuses.Count) { $bonuses -join '; ' } else { 'ninguno' }) + '. Los porcentajes se expresan como fracciones: 0,15 = 15%.')
    $lines.Add('- Escena: `' + $s.scene + '`.')
}
$lines.Add('')
$lines.Add('## Observaciones del código y límites')
$lines.Add('')
$lines.Add('- Wolfsbane: el código detecta la marca pero no multiplica el golpe; la explosión de 20 excluye al objetivo original. Por eso contra un solo maniquí no reproduce la promesa de «muchísimo más daño» al marcado de la descripción. No se cambió este comportamiento durante el test.')
$lines.Add('- Cerberus: 26,1 DPS configurados de chorro se convierten en ticks de 3,915, truncados a 3 por take_damage(int), más quemadura de 2 cada 0,4 s. Los críticos de las piezas no se aplican en FlameStream. El desglose muestra el resultado real.')
$lines.Add('- Los efectos de ralentizar, congelar y aturdir no infligen daño por sí solos. Arrogancia pierde su componente de reflejo contra un maniquí que no dispara; Holy Fire, Wolfsbane y The Bride no pueden explotar su daño multiblanco.')
$lines.Add('- Impulso Ligero: la onda cargada inflige 50 una vez; no asignar DPS sostenido sin especificar la ruta y el tiempo de recarga por movimiento.')
$lines.Add('')
$lines.Add('## Reproducir')
$lines.Add('')
$lines.Add('Ejecutar desde la raíz del proyecto:')
$lines.Add('')
$lines.Add('```powershell')
$lines.Add('& <ruta-a-Godot> --headless --fixed-fps 60 --path . res://Tests/dps_benchmark.tscn')
$lines.Add('./Reports/build_dps_report.ps1')
$lines.Add('```')
$lines.Add('')
$lines.Add('Opcionales: BENCH_SECONDS, BENCH_REPEATS y BENCH_FILTER (subcadena del nombre). Los resultados completos y el histograma de daño por impacto están en `dps_benchmark.json`. El informe asume la ejecución estándar de 30 s × 3 repeticiones. El generador no vuelve a ejecutar el motor.')
[System.IO.File]::WriteAllLines((Join-Path $reportDir 'dps_benchmark.md'), $lines, [System.Text.UTF8Encoding]::new($false))
Write-Output ('Generated report for ' + $groups.Count + ' cases / ' + $data.results.Count + ' runs.')
