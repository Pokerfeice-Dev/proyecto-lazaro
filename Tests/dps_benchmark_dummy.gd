extends Mannequin

var measuring := false
var total_damage := 0
var hits := 0
var critical_hits := 0
var sources: Dictionary = {}
var hit_damage_counts: Dictionary = {}

func take_damage(amount: int, is_crit: bool = false) -> void:
	if measuring:
		total_damage += amount
		hits += 1
		if is_crit: critical_hits += 1
		var source := "direct"
		for frame in get_stack():
			var file: String = frame.source
			if "ignite_effect" in file: source = "burn"
			elif "electrify_effect" in file: source = "electric"
			elif "fuel_explosion" in file: source = "fuel_explosion"
			elif "holy_fire_tongue" in file: source = "holy_fire"
			elif "flame_stream" in file: source = "flame_stream"
		sources[source] = sources.get(source, 0) + amount
		var key := source + ("_crit" if is_crit else "") + ":" + str(amount)
		hit_damage_counts[key] = hit_damage_counts.get(key, 0) + 1
	super.take_damage(amount, is_crit)

func _show_damage_text(_amount: int, _is_crit: bool) -> void:
	pass

func _flash_hit() -> void:
	pass
