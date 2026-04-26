extends SceneTree

func _init():
	print("Generating SpriteFrames...")
	var sf = SpriteFrames.new()
	sf.remove_animation("default") # clean up default
	
	var anim_map = {
		"idle_south": "res://ProjectFrankenstein/Art/Player_art/animatios/breathing-idle/south/",
		"idle_north": "res://ProjectFrankenstein/Art/Player_art/animatios/breathing-idle/north/",
		"idle_east": "res://ProjectFrankenstein/Art/Player_art/animatios/breathing-idle/east/",
		"idle_west": "res://ProjectFrankenstein/Art/Player_art/animatios/breathing-idle/west/",
		"run_south": "res://ProjectFrankenstein/Art/Player_art/animatios/running-4-frames/south/",
		"run_north": "res://ProjectFrankenstein/Art/Player_art/animatios/running-4-frames/north/",
		"run_east": "res://ProjectFrankenstein/Art/Player_art/animatios/running-4-frames/east/",
		"run_west": "res://ProjectFrankenstein/Art/Player_art/animatios/running-4-frames/west/"
	}
	
	for anim_name in anim_map.keys():
		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, true)
		sf.set_animation_speed(anim_name, 5.0)
		
		var dirpath = anim_map[anim_name]
		var dir = DirAccess.open(dirpath)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			var files = []
			while file_name != "":
				if file_name.ends_with(".png") and not file_name.ends_with(".import"):
					files.append(file_name)
				file_name = dir.get_next()
			files.sort()
			for f in files:
				var tex = load(dirpath + f) as Texture2D
				if tex:
					sf.add_frame(anim_name, tex)
		else:
			print("Error opening dir: ", dirpath)
					
	ResourceSaver.save(sf, "res://Scenes/Player/player_sprites.tres")
	print("SpriteFrames generated!")
	quit()
