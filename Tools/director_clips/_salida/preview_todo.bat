@echo off
set EXE="C:\Program Files\Godot\Godot.exe\Godot.exe"
set PRJ="C:\Users\Marcos\Documents\GitHub\proyecto-lazaro"
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview oil cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_oil.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview partes_drop cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_partes_drop.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview partes_inventario cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_partes_inventario.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview partes_aviso cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_partes_aviso.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview partes_canino cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_partes_canino.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview sinergia_aviso cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_sinergia_aviso.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview avalanche cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_avalanche.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview colmena cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_colmena.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview minigun cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_minigun.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview bride cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_bride.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview holy cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_holy.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview asphodel_sala cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_asphodel_sala.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview asphodel_mix cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_asphodel_mix.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview ygor cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_ygor.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview tesoro cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_tesoro.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview jefe1 cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_jefe1.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview muerte cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_muerte.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview lab cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_lab.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview omnia cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_omnia.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview cripta cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_cripta.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview apicultora cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_apicultora.txt" 2>&1
%EXE% --path %PRJ% --fixed-fps 30 res://Tools/director_clips/director_clip.tscn -- preview primogenito cada=20 > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\log_primogenito.txt" 2>&1
echo listo > "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\Tools\director_clips\_salida\preview_listo.txt"