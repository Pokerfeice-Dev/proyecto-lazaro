@echo off
cd /d "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro"
set PY="C:\Users\Marcos\AppData\Local\Programs\Python\Python312\python.exe"
set S=Tools\director_clips\_salida
if exist %S%\planos_listo.txt del %S%\planos_listo.txt
if not exist Tools\director_clips\_tmp mkdir Tools\director_clips\_tmp
%PY% Tools\director_clips\montaje.py Tools\director_clips\videos\FG_01_partes.json planos > %S%\planos_FG_01.txt 2>&1
%PY% Tools\director_clips\montaje.py Tools\director_clips\videos\FG_02_sinergias.json planos > %S%\planos_FG_02.txt 2>&1
%PY% Tools\director_clips\montaje.py Tools\director_clips\videos\FG_03_asphodel.json planos > %S%\planos_FG_03.txt 2>&1
%PY% Tools\director_clips\montaje.py Tools\director_clips\videos\FG_04_omnia.json planos > %S%\planos_FG_04.txt 2>&1
:esperar
if exist %S%\grabado_listo.txt goto seguir
timeout /t 10 /nobreak > nul
goto esperar
:seguir
%PY% Tools\director_clips\montaje.py Tools\director_clips\videos\FG_05_cripta.json planos > %S%\planos_FG_05.txt 2>&1
echo listo > %S%\planos_listo.txt
