extends Control
## IntroCinematic – Pantalla de presentación del juego.
# [IA] Script nuevo (29/08): reemplaza el arranque directo al Main Menu por un video de
# presentación. Mientras se reproduce, precarga el Main Menu en segundo plano y una barra
# muestra el progreso real de esa carga. Con un click o cualquier tecla se puede saltar.

const MAIN_MENU_PATH: String = "res://Scenes/UI/MainMenu.tscn"
const VIDEO_PATH: String = "res://Art/Video/intro_teaser.ogv"

@onready var video_player: VideoStreamPlayer = $VideoPlayer
@onready var loading_bar: ProgressBar = $LoadingBar
@onready var loading_label: Label = $LoadingLabel
@onready var skip_label: Label = $SkipLabel
@onready var skip_area: Button = $SkipArea

var _loading_done: bool = false
var _video_finished: bool = false
var _skip_requested: bool = false
var _transition_started: bool = false

func _ready() -> void:
	_start_background_load()
	_start_video()
	_start_skip_blink()
	_style_skip_area()
	skip_area.pressed.connect(_on_skip_pressed)
	video_player.finished.connect(_on_video_finished)

func _start_background_load() -> void:
	ResourceLoader.load_threaded_request(MAIN_MENU_PATH)

func _start_video() -> void:
	video_player.stream = load(VIDEO_PATH)
	video_player.play()

func _start_skip_blink() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(skip_label, "modulate:a", 0.25, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(skip_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _style_skip_area() -> void:
	# [IA] Botón invisible a pantalla completa: solo capta el click, sin tinte de hover/foco.
	var empty_style = StyleBoxEmpty.new()
	skip_area.add_theme_stylebox_override("normal", empty_style)
	skip_area.add_theme_stylebox_override("hover", empty_style)
	skip_area.add_theme_stylebox_override("pressed", empty_style)
	skip_area.add_theme_stylebox_override("focus", empty_style)
	skip_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _process(_delta: float) -> void:
	_update_loading_progress()
	_check_ready_to_transition()

func _update_loading_progress() -> void:
	if _loading_done: return
	var progress: Array = []
	var status = ResourceLoader.load_threaded_get_status(MAIN_MENU_PATH, progress)
	var pct = progress[0] * 100.0 if progress.size() > 0 else 0.0
	loading_bar.value = pct
	_check_load_finished(status)

func _check_load_finished(status: ResourceLoader.ThreadLoadStatus) -> void:
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_loading_done = true
		loading_bar.value = 100.0
		_on_loading_complete() # [IA] Antes solo cambiaba el texto; ahora dispara la animación de salida.
		return
	# [IA] Salvaguarda: si la carga falla no queremos trabar al jugador en el intro para siempre.
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_loading_done = true

# [IA] Al terminar la carga real: parpadeo rápido y sutil, y después un fade prolijo que la
# hace desaparecer. Solo queda en pantalla la leyenda de saltar.
func _on_loading_complete() -> void:
	loading_label.text = "LISTO"
	_blink_and_fade(loading_bar)
	_blink_and_fade(loading_label)

func _blink_and_fade(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 0.15, 0.07)
	tween.tween_property(node, "modulate:a", 1.0, 0.07)
	tween.tween_property(node, "modulate:a", 0.15, 0.07)
	tween.tween_property(node, "modulate:a", 1.0, 0.07)
	tween.tween_interval(0.12)
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector2(0.8, 0.8), 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(node.hide)

func _check_ready_to_transition() -> void:
	if _transition_started: return
	if not _loading_done: return
	if not (_video_finished or _skip_requested): return
	_transition_started = true
	_go_to_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if _skip_requested: return
	if event is InputEventKey and event.pressed and not event.echo:
		_on_skip_pressed()
	elif event is InputEventMouseButton and event.pressed:
		_on_skip_pressed()

func _on_skip_pressed() -> void:
	if _skip_requested: return
	_skip_requested = true
	_video_finished = true
	video_player.stop()
	skip_label.hide()
	skip_area.hide()

func _on_video_finished() -> void:
	_video_finished = true

func _go_to_main_menu() -> void:
	SceneTransition.change_scene(MAIN_MENU_PATH)
