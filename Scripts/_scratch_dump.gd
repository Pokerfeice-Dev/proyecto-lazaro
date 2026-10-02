TOTAL: 2421
344: ## aparecemos armados). Se llama al inicializar el arma y también cada vez
345: ## que el jugador (que persiste entre salas) vuelve al laboratorio, para no
346: ## dejar visible un arma que quedó mostrada durante la run anterior.
347: func sync_weapon_visibility_for_room() -> void:
348: 	if _is_in_lab_room():
349: 		_hide_all_weapons()
350: 	else:
351: 		_show_primary_weapon()
352: 
353: func _is_in_lab_room() -> bool:
354: 	var scene = get_tree().current_scene
355: 	return scene != null and scene.name == "Lab_room"
356: 
357: func _hide_all_weapons() -> void:
358: 	if active_weapon: active_weapon.hide()
359: 	if second_weapon: second_weapon.hide()
360: 	if left_melee_weapon: left_melee_weapon.hide()
--- equip_stat area ---
749: 		if w_stats.has(stat_name):
750: 			bonus += float(w_stats[stat_name])
751: 			
752: 	var active_weapon_id = get_active_ranged_weapon_id() if is_main else get_active_melee_weapon_id()
753: 	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, is_main)
754: 	bonus += SynergyManager.get_synergies_stat_modifier(active_syns, stat_name)
755: 	
756: 	if stat_name == "attack_speed":
757: 		if is_furia_active:
758: 			bonus += 0.50
759: 		if GameData.get_active_protocol() == "furia_de_titanio" and stats.current_health <= stats.max_health * 0.3:
760: 			bonus += 0.25
761: 		
762: 	if is_main:
763: 		bonus += _get_minigun_stat_bonus(stat_name)
764: 		bonus += _get_flamethrower_range_bonus(stat_name)
--- tail synergy funcs ---
2241: 	var equip = get_node_or_null("Equipment")
2242: 	var active_weapon_id = get_active_melee_weapon_id()
2243: 	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
2244: 	return active_syns.has("daga_del_odio")
2245: 
2246: func _get_daga_del_odio_bonus(stat_name: String) -> float:
2247: 	if not _is_daga_del_odio_active():
2248: 		return 0.0
2249: 	if stats.max_health <= 0:
2250: 		return 0.0
2251: 	var health_ratio = clamp(float(stats.current_health) / float(stats.max_health), 0.0, 1.0)
2252: 	var t = 1.0 - health_ratio
2253: 	match stat_name:
2254: 		"damage":
2255: 			return 30.0 * t
2256: 		"attack_speed":
2257: 			return 1.2 * t
2258: 		"attack_range_percent":
2259: 			return 0.6 * t
2260: 		"crit_chance":
2261: 			return 0.5 * t
2262: 		"crit_damage":
2263: 			return 0.6 * t
2264: 	return 0.0
2265: 
2266: ## Tiñe la hoja de la daga de rojo (mas intenso cuanta menos vida queda)
2267: ## mientras la sinergia Daga del Odio este activa, para que el jugador
2268: ## note visualmente el cambio ademas de sentirlo en las estadisticas.
2269: func _update_daga_del_odio_visual(_delta: float = 0.0) -> void:
2270: 	if not second_weapon:
2271: 		return
2272: 	var weapon = second_weapon.get("current_weapon")
2273: 	if not weapon:
2274: 		return
2275: 	var sprite = weapon.get("melee_sprite") if "melee_sprite" in weapon else null
2276: 	if not sprite:
2277: 		return
2278: 	if not _is_daga_del_odio_active() or stats.max_health <= 0:
2279: 		sprite.modulate = Color(1.0, 1.0, 1.0)
2280: 		return
2281: 	var health_ratio = clamp(float(stats.current_health) / float(stats.max_health), 0.0, 1.0)
2282: 	var t = 1.0 - health_ratio
2283: 	sprite.modulate = Color(1.0, 1.0 - 0.85 * t, 1.0 - 0.85 * t)
2284: 
2285: ## Sinergia Arrogancia: mientras el swing de la maza esta activo, cualquier
2286: ## bala enemiga que te toque rebota devuelta (nerfeada) en vez de danarte.
2287: ## Lo consulta enemy_shooter_projectile.gd antes de aplicar su dano normal.
2288: func _is_arrogancia_reflect_active() -> bool:
2289: 	if not second_weapon:
2290: 		return false
2291: 	if not second_weapon.has_method("is_attacking") or not second_weapon.is_attacking():
2292: 		return false
2293: 	var equip = get_node_or_null("Equipment")
2294: 	var active_weapon_id = get_active_melee_weapon_id()
2295: 	var active_syns = SynergyManager.get_active_synergies(equip, active_weapon_id, false)
2296: 	return active_syns.has("arrogancia")
2297: 
2298: ## Chorro continuo del lanzallamas: en vez de disparar proyectiles, mantiene
2299: ## un unico nodo FlameStream pegado al arma mientras se mantiene presionado
2300: ## el disparo, y lo extingue (con su propia animacion de fade) al soltar.