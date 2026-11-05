extends SceneTree
func _initialize() -> void:
	var canvas := Control.new()
	root.add_child(canvas)
	var bg := ColorRect.new()
	bg.color = Color('#171D22')
	bg.size = Vector2(1600, 1000)
	canvas.add_child(bg)
	var names := DirAccess.get_files_at('res://Art/Ui/svg')
	var index := 0
	for file in names:
		if not file.begins_with('icon_') or not file.ends_with('.svg'): continue
		var origin := Vector2(24 + (index % 8) * 195, 60 + (index / 8) * 220)
		var label := Label.new()
		label.text = file.trim_prefix('icon_').trim_suffix('.svg')
		label.position = origin
		canvas.add_child(label)
		var before := Image.new()
		before.load_svg_from_string(FileAccess.get_file_as_string(OS.get_environment('TEMP').path_join('frankengun-icon-before').path_join(file)))
		var original := ImageTexture.create_from_image(before)
		var improved := load('res://Art/Ui/svg/' + file) as Texture2D
		assert(improved.get_width() == 96)
		assert(improved.get_image().has_mipmaps())
		for row in 2:
			for column in 3:
				var icon := TextureRect.new()
				icon.texture = original if row == 0 else improved
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if row == 0 else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.size = Vector2.ONE * [24, 32, 64][column]
				icon.position = origin + Vector2(column * 56, 36 + row * 80)
				canvas.add_child(icon)
		index += 1
	root.size = Vector2i(1600, 1000)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png('res://tmp/icon-quality-review.png')
	print('ICON_QUALITY_OK: ', index, ' icons, 96px + mipmaps; top original / bottom improved')
	quit()
