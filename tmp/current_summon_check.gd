extends Node2D
func _ready():
	GameData.begin_sandbox()
	var summoner = load('res://Scenes/Enemies/EnemySummoner.tscn').instantiate()
	add_child(summoner)
	summoner.set_physics_process(false)
	summoner._start_summon()
	await get_tree().create_timer(3.0).timeout
	assert(summoner.active_summons.size() > 0, 'El reemplazo de invocación debe crear abejas')
	GameData.end_sandbox()
	print('CURRENT_SUMMON_OK')
	get_tree().quit()
