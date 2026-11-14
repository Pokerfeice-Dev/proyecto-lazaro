@echo off
cd /d "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\"
del Tools\director_clips\_salida\grabado_listo.txt 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/oil.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma oil > Tools\director_clips\_salida\rec_oil.txt 2>&1
echo oil >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/partes_drop.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma partes_drop > Tools\director_clips\_salida\rec_partes_drop.txt 2>&1
echo partes_drop >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/partes_inventario.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma partes_inventario > Tools\director_clips\_salida\rec_partes_inventario.txt 2>&1
echo partes_inventario >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/partes_aviso.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma partes_aviso > Tools\director_clips\_salida\rec_partes_aviso.txt 2>&1
echo partes_aviso >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/partes_canino.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma partes_canino > Tools\director_clips\_salida\rec_partes_canino.txt 2>&1
echo partes_canino >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/sinergia_aviso.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma sinergia_aviso > Tools\director_clips\_salida\rec_sinergia_aviso.txt 2>&1
echo sinergia_aviso >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/avalanche.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma avalanche > Tools\director_clips\_salida\rec_avalanche.txt 2>&1
echo avalanche >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/colmena.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma colmena > Tools\director_clips\_salida\rec_colmena.txt 2>&1
echo colmena >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/minigun.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma minigun > Tools\director_clips\_salida\rec_minigun.txt 2>&1
echo minigun >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/bride.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma bride > Tools\director_clips\_salida\rec_bride.txt 2>&1
echo bride >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/holy.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma holy > Tools\director_clips\_salida\rec_holy.txt 2>&1
echo holy >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/asphodel_sala.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma asphodel_sala > Tools\director_clips\_salida\rec_asphodel_sala.txt 2>&1
echo asphodel_sala >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/asphodel_mix.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma asphodel_mix > Tools\director_clips\_salida\rec_asphodel_mix.txt 2>&1
echo asphodel_mix >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/ygor.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma ygor > Tools\director_clips\_salida\rec_ygor.txt 2>&1
echo ygor >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/tesoro.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma tesoro > Tools\director_clips\_salida\rec_tesoro.txt 2>&1
echo tesoro >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/jefe1.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma jefe1 > Tools\director_clips\_salida\rec_jefe1.txt 2>&1
echo jefe1 >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/muerte.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma muerte > Tools\director_clips\_salida\rec_muerte.txt 2>&1
echo muerte >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/lab.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma lab > Tools\director_clips\_salida\rec_lab.txt 2>&1
echo lab >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/omnia.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma omnia > Tools\director_clips\_salida\rec_omnia.txt 2>&1
echo omnia >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/cripta.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma cripta > Tools\director_clips\_salida\rec_cripta.txt 2>&1
echo cripta >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/apicultora.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma apicultora > Tools\director_clips\_salida\rec_apicultora.txt 2>&1
echo apicultora >> Tools\director_clips\_salida\grabado_progreso.txt
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --write-movie Tools/director_clips/_salida/primogenito.avi --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- toma primogenito > Tools\director_clips\_salida\rec_primogenito.txt 2>&1
echo primogenito >> Tools\director_clips\_salida\grabado_progreso.txt
echo ok > Tools\director_clips\_salida\grabado_listo.txt
