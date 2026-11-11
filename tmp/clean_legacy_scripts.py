from pathlib import Path
p=Path('Scripts/Enemies/enemy_turret.gd');s=p.read_text(encoding='utf-8-sig')
s=s.replace('@onready var sprite_base: Sprite2D = $Sprite_BaseTurret\n','').replace('var _default_base_modulate: Color = Color.WHITE\n','')
s=s.replace('\tif sprite_base:\n\t\t_default_base_modulate = sprite_base.modulate\n\t\t_default_base_modulate.a = 1.0\n','')
for statement in ['sprite_base.modulate.a = 0.0','t.tween_property(sprite_base, "modulate:a", 1.0, 0.2)','sprite_base.hide()']:
 s=s.replace('\tif sprite_base:\n\t\t'+statement+'\n','')
s=s.replace('\tif not sprite_base:\n\t\treturn\n','').replace('\tsprite_base.modulate = Color(3.0, 3.0, 3.0, 1.0)\n','').replace('\t_turret_flash_tween.tween_property(sprite_base, "modulate", _default_base_modulate, 0.18)\n','')
s=s.replace('func _fade_in_sprite() -> void:\n','func _fade_in_sprite() -> void:\n\tif is_dying: return\n')
p.write_text(s,encoding='utf-8')
p=Path('Scripts/Enemies/enemy_base.gd');s=p.read_text(encoding='utf-8-sig')
s=s.replace('@export var use_legacy_death_fx := false\n','')
s=s.replace('\tif not use_legacy_death_fx:\n\t\t_spawn_pixel_death()','\t_spawn_pixel_death()')
start=s.index('\tif use_legacy_death_fx:',s.index('func die()'))
end=s.index('\nfunc _spawn_pixel_death()',start)
s=s[:start]+'''\t# Mantiene vivo el jefe final hasta que termine su flujo de victoria.
\tvar delay := 1.1
\tif "victory_delay" in self:
\t\tdelay = maxf(delay, get("victory_delay") + 0.5)
\tget_tree().create_timer(delay, false).timeout.connect(_check_sound_and_free)
''' +s[end:]
start=s.index('func _play_death_fx()');end=s.index('func _check_sound_and_free()',start)
s=s[:start]+s[end:]
s=s.replace('\t# La torreta tiene base y cañón separados; los demás exponen su cuerpo.','\t# El repartidor usa su sprite orientable; los demás exponen su cuerpo.').replace('if get_node_or_null("Sprite_BaseTurret") or get_node_or_null("Sprite_CannonTurret"):','if get_node_or_null("Sprite_CannonTurret"):').replace('\t\tPIXEL_DEATH.spawn_from(get_node_or_null("Sprite_BaseTurret"))\n','')
p.write_text(s,encoding='utf-8')
p=Path('Scripts/Enemies/crypt_enemy.gd');s=p.read_text(encoding='utf-8-sig').replace('# Queda el cadáver en la sala; el estallido azul (Death_fx) es el mismo del área 1.','# El cuerpo se oculta después de crear los fragmentos de muerte.').replace('\tif use_legacy_death_fx:\n\t\tart.leave_corpse()\n\telif _get_sprite():','\tif _get_sprite():');p.write_text(s,encoding='utf-8')
p=Path('Scripts/World/tutorial_dodge_cinematic.gd');s=p.read_text(encoding='utf-8-sig').replace('\tshooter.get_node("Summon_anim").hide()\n','');p.write_text(s,encoding='utf-8')
p=Path('Tests/follower_death_smoke.gd');s=p.read_text(encoding='utf-8-sig').replace('\t\t\tdog.get_node("Summon_anim").hide()\n','').replace('\t\tassert(not dog.get_node("Summon_anim").visible)\n','').replace('\t\tdog._on_summon_finished(dog.get_node("Summon_anim"))','\t\tdog._fade_in_sprite()');p.write_text(s,encoding='utf-8')
p=Path('Tests/pixel_death_smoke.gd');s=p.read_text(encoding='utf-8-sig').replace('\t\tif enemy.has_node("Sprite_BaseTurret"):\n\t\t\tenemy.get_node("Sprite_BaseTurret").show()\n','').replace('\t\tassert(not enemy.use_legacy_death_fx)\n','').replace('\t\tif enemy.has_node("Death_fx"):\n\t\t\tassert(not enemy.get_node("Death_fx").visible)\n','').replace('effects >= 4, "Follower, turret base/cannon and ghoul must fragment"','effects >= 3, "Follower, delivery driver and ghoul must fragment"');p.write_text(s,encoding='utf-8')
