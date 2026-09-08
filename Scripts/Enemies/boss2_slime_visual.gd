extends AnimatedSprite2D
class_name Boss2SlimeVisual

## Reemplazo con arte final (sprite pack de slimes, "Slime2") del placeholder
## dibujado por código (boss2_visual.gd, que ahora queda oculto/sin usar).
## Expone los mismos métodos de squash/stretch que boss2.gd ya llama
## (play_squash_down, play_stretch_up, play_landing_impact, reset_squash)
## para no tener que tocar esa lógica, y además maneja la animación real
## (idle / movimiento / ataque) según hacia dónde está mirando el boss.
##
## El pack no trae una animación de "salto" dedicada -- se usa "Run" (que ya
## de por sí es un rebote/estiramiento) durante el salto, combinada con el
## squash/stretch existente para vender el arco del salto.

enum Facing { FRONT, BACK, SIDE }
var facing: Facing = Facing.FRONT

## Escala base del sprite (en reposo). El frame fuente es 64x64; con esto
## queda ~288x288 en pantalla (el doble de la primera versión, que eran
## ~144x144 -- Marcos pidió que se vea más grande). Retocar acá si hace falta.
const BASE_SCALE: Vector2 = Vector2(4.5, 4.5)

func _ready() -> void:
	scale = BASE_SCALE
	play_idle()

func face_towards(dir: Vector2) -> void:
	if dir.length() < 0.001: return
	if absf(dir.y) > absf(dir.x):
		facing = Facing.BACK if dir.y < 0 else Facing.FRONT
	else:
		facing = Facing.SIDE
	# El arte base mira a la derecha; se espeja para el lado izquierdo.
	flip_h = dir.x < 0

func _suffix() -> String:
	match facing:
		Facing.FRONT:
			return "front"
		Facing.BACK:
			return "back"
		_:
			return "side"

func play_idle() -> void:
	_safe_play("idle_" + _suffix())

func play_jump_motion() -> void:
	_safe_play("run_" + _suffix())

func play_attack() -> void:
	_safe_play("attack_" + _suffix())

func _safe_play(anim_name: String) -> void:
	if not sprite_frames or not sprite_frames.has_animation(anim_name): return
	if animation == anim_name and is_playing(): return
	play(anim_name)

# --- Squash/stretch (mismos nombres que boss2_visual.gd, así boss2.gd no
# tiene que cambiar cómo los llama al pasar del placeholder a este sprite) ---

func set_squash(target_scale: Vector2, duration: float = 0.15) -> void:
	var t = create_tween()
	t.tween_property(self, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func play_squash_down() -> void:
	set_squash(BASE_SCALE * Vector2(1.25, 0.7), 0.12)

func play_stretch_up() -> void:
	set_squash(BASE_SCALE * Vector2(0.75, 1.3), 0.18)
	play_jump_motion()

func play_landing_impact() -> void:
	set_squash(BASE_SCALE * Vector2(1.35, 0.6), 0.05)
	var t = create_tween()
	t.tween_interval(0.05)
	t.tween_property(self, "scale", BASE_SCALE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	play_idle()

func reset_squash() -> void:
	scale = BASE_SCALE
