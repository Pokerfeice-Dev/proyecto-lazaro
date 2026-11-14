@echo off
cd /d "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\"
del Tools\director_clips\_salida\montaje_listo.txt 2>nul
"C:/Users/Marcos/AppData/Local/Programs/Python/Python312/python.exe" Tools\director_clips\montaje.py Tools\director_clips\videos\FG_02_sinergias.json > Tools\director_clips\_salida\montaje_FG_02_sinergias.txt 2>&1
echo ok > Tools\director_clips\_salida\montaje_listo.txt
