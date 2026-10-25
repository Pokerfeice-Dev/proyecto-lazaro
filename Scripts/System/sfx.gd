class_name Sfx
extends RefCounted

## Sonidos sueltos en el mundo (golpes, impactos) sin tener que agregar un
## AudioStreamPlayer a cada escena. Se crea, suena y se borra solo.
## Uso: Sfx.play_at(Sfx.HIT, global_position)

const HIT := preload("res://Audio/Sfx/IA/golpe_enemigo.wav")
const HURT := preload("res://Audio/Sfx/IA/dano_recibido.wav")

const MIN_GAP_MSEC := 45 # con la uzi pegan muchas balas juntas: no se apilan
static var _last_play := {}

static func play_at(stream: AudioStream, pos: Vector2, volume_db: float = 0.0, pitch_spread: float = 0.12) -> void:
	var now = Time.get_ticks_msec()
	var key = stream.resource_path
	if now - int(_last_play.get(key, -10000)) < MIN_GAP_MSEC: return
	_last_play[key] = now
	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree and tree.current_scene else null
	if not parent: return
	var p = AudioStreamPlayer2D.new()
	p.stream = stream
	p.bus = "SFX"
	p.volume_db = volume_db
	p.pitch_scale = randf_range(1.0 - pitch_spread, 1.0 + pitch_spread)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()
