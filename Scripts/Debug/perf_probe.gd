extends Node
class_name PerfProbe
# Sonda de rendimiento temporal: cada 2 segundos escribe una línea en res://perf_probe.log con FPS,
# tiempos de proceso/física, llamadas de dibujo, nodos y enemigos. Solo en builds de debug.
# Se borra cuando termine la optimización.

const LOG_PATH := "res://perf_probe.log"
const INTERVAL := 2.0

var _elapsed := 0.0
var _frames := 0
var _worst := 0.0
var _file: FileAccess

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1000
	if not OS.is_debug_build():
		queue_free()
		return
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file:
		_file.store_line("t | fps | frame_ms_avg | frame_ms_max | proceso_ms | fisica_ms | draw_calls | prims | nodos | huerfanos | enemigos | balas | capas_sync_us | escena")

func _process(delta: float) -> void:
	if _file == null: return
	_elapsed += delta
	_frames += 1
	_worst = maxf(_worst, delta)
	if _elapsed < INTERVAL: return
	var tree := get_tree()
	var scene_name := String(tree.current_scene.name) if tree.current_scene else "?"
	var bullets := tree.get_nodes_in_group("enemy_bullet").size() + tree.get_nodes_in_group("bullet").size()
	var sync_us := 0.0
	if BodyLayers.sync_calls > 0:
		sync_us = float(BodyLayers.sync_usec) / float(BodyLayers.sync_calls)
	_file.store_line("%.0f | %.1f | %.2f | %.2f | %.2f | %.2f | %d | %d | %d | %d | %d | %d | %.1f | %s" % [
		Time.get_ticks_msec() / 1000.0, _frames / _elapsed, _elapsed / _frames * 1000.0, _worst * 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		tree.get_nodes_in_group("enemy").size(), bullets, sync_us, scene_name])
	_file.flush()
	BodyLayers.sync_usec = 0
	BodyLayers.sync_calls = 0
	_elapsed = 0.0
	_frames = 0
	_worst = 0.0
