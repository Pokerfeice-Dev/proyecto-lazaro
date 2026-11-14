@echo off
cd /d "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\"
del Tools\director_clips\_salida\prueba_listo.txt 2>nul
rmdir /s /q Tools\director_clips\_salida\preview\combate_prueba 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview combate_prueba cada=15 > Tools\director_clips\_salida\log_prueba.txt 2>&1
echo ok > Tools\director_clips\_salida\prueba_listo.txt
