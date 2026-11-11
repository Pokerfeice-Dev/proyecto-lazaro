extends Node
var total := 0
func _ready():
	_scan('res://Scenes')
	print('SCENE_RESOURCE_AUDIT_OK: ', total)
	get_tree().quit()
func _scan(path: String):
	for directory in DirAccess.get_directories_at(path): _scan(path.path_join(directory))
	for file in DirAccess.get_files_at(path):
		if not file.ends_with('.tscn'): continue
		var resource = load(path.path_join(file))
		assert(resource is PackedScene, path.path_join(file))
		var instance = resource.instantiate()
		assert(instance != null, path.path_join(file))
		instance.free()
		total += 1
