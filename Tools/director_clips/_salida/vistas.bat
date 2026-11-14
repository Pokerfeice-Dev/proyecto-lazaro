@echo off
cd /d "C:\Users\Marcos\Documents\GitHub\proyecto-lazaro\"
del Tools\director_clips\_salida\vista_listo.txt 2>nul
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room1" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room1.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room1" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room1"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room2" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room2.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room2" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room2"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room3" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room3.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room3" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room3"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room4" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room4.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room4" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room4"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room12(Ygor1)" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room12(Ygor1).txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room12(Ygor1)" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room12(Ygor1)"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room11(treasure)" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room11(treasure).txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room11(treasure)" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room11(treasure)"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level1_Room15-BossFight" cada=30 > "Tools\director_clips\_salida\vista_log_Level1_Room15-BossFight.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level1_Room15-BossFight" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level1_Room15-BossFight"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=lab_room" cada=30 > "Tools\director_clips\_salida\vista_log_lab_room.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_lab_room" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_lab_room"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level2_Room2" cada=30 > "Tools\director_clips\_salida\vista_log_Level2_Room2.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level2_Room2" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level2_Room2"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level2_Room3" cada=30 > "Tools\director_clips\_salida\vista_log_Level2_Room3.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level2_Room3" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level2_Room3"
rmdir /s /q "Tools\director_clips\_salida\preview\vista" 2>nul
"C:\Program Files\Godot\Godot.exe\Godot.exe" --path . res://Tools/director_clips/director_clip.tscn -- preview vista "sala=Level2_Room14BossFight" cada=30 > "Tools\director_clips\_salida\vista_log_Level2_Room14BossFight.txt" 2>&1
rmdir /s /q "Tools\director_clips\_salida\preview\vista_Level2_Room14BossFight" 2>nul
ren "Tools\director_clips\_salida\preview\vista" "vista_Level2_Room14BossFight"
echo ok > Tools\director_clips\_salida\vista_listo.txt
