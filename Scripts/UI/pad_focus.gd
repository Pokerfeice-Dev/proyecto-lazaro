extends CanvasLayer
class_name PadFocus

## Navegación de menús con joystick (lo crea InputMode, no hace falta ponerlo
## en ninguna escena):
## - Marco dorado que late alrededor del control con foco, solo con joystick
##   (con mouse no se ve; muchos botones no tienen estilo de foco propio).
## - Si un menú se abre sin nada enfocado, la primera vez que mueves el
##   analógico o la cruceta enfoca el primer botón del menú de más arriba.
##   Solo con el juego en pausa o en menús sin jugador, para no robar
##   el foco mientras se juega.
## - Las listas acompañan al foco: si te mueves a una ficha que quedó fuera de
##   la vista, la lista se desplaza hasta mostrarla.
## - El analógico derecho desplaza la lista (ScrollContainer) donde está el
##   foco; si la ficha enfocada sale de la vista, el foco pasa a la que quedó
##   en el borde, así nunca queda una ficha cortada marcada.
## - Ventanas modales: PadFocus.push_modal(ventana) al abrir. Mientras esté
##   abierta, el foco no puede quedar en lo de atrás (si se escapa, vuelve a
##   la ventana) y al cerrarla vuelve a donde estaba en la ventana de abajo.
##   Se saca sola al salir del árbol, o con pop_modal(ventana).

const RING_COLOR := Color("#F4C45E")
const RING_PAD := 4.0
const SCROLL_SPEED := 900.0
const SCROLL_DEADZONE := 0.35
const NAV_ACTIONS := ["ui_up", "ui_down", "ui_left", "ui_right"]

## Pila de ventanas modales: {"root": Node, "last": Control (último foco adentro)}
static var _modals: Array = []
static var _self: PadFocus

var _ring: Control
var _time := 0.0
var _rect := Rect2()
var _has_target := false
var _scroll_rest := 0.0 # parte fraccionaria del desplazamiento con el analógico
var _stick_moving := false

func _ready() -> void:
	_self = self
	layer = 1000 # por encima de todas las ventanas
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ring = Control.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	InputMode.instance().mode_changed.connect(_on_mode_changed)

# Al tocar el joystick con una ventana abierta, el foco entra en ella.
func _on_mode_changed(gamepad: bool) -> void:
	if gamepad:
		_keep_focus_inside()

# --- Ventanas modales ---

## Abre una ventana modal. "preferred" es el control que arranca con foco
## (si es null, el primero de arriba a la izquierda).
static func push_modal(root: Node, preferred: Control = null) -> void:
	pop_modal(root)
	_modals.append({"root": root, "last": preferred})
	if not root.has_meta("pad_modal"):
		root.set_meta("pad_modal", true)
		root.tree_exiting.connect(PadFocus.pop_modal.bind(root))
	if is_instance_valid(_self):
		_self._keep_focus_inside.call_deferred()

static func pop_modal(root: Node) -> void:
	var was_top = not _modals.is_empty() and _modals.back().root == root
	_modals = _modals.filter(func(m): return is_instance_valid(m.root) and m.root != root)
	if was_top and is_instance_valid(_self):
		_self._restore_top.call_deferred()

static func has_modal() -> bool:
	return _top() != null

static func _top() -> Variant:
	while not _modals.is_empty():
		var m = _modals.back()
		if is_instance_valid(m.root) and m.root.is_inside_tree():
			return m
		_modals.pop_back()
	return null

func _on_focus_changed(control: Control) -> void:
	if InputMode.is_gamepad() and not _stick_moving:
		_reveal.call_deferred(control)
	var top = _top()
	if top == null: return
	if top.root.is_ancestor_of(control):
		top.last = control
	else:
		_keep_focus_inside.call_deferred() # se escapó a lo de atrás: vuelve

# Con joystick, el foco tiene que estar dentro de la ventana de arriba.
func _keep_focus_inside() -> void:
	var top = _top()
	if top == null or not InputMode.is_gamepad(): return
	var f = get_viewport().gui_get_focus_owner()
	if f and top.root.is_ancestor_of(f): return
	_focus_in(top)

# Al cerrar una ventana, el foco vuelve a donde estaba en la de abajo.
func _restore_top() -> void:
	var top = _top()
	if top == null or not InputMode.is_gamepad(): return
	_focus_in(top)

func _focus_in(top: Dictionary) -> void:
	var last = top.last
	if is_instance_valid(last) and _can_focus(last) and top.root.is_ancestor_of(last):
		last.grab_focus()
	elif not _focus_first(top.root):
		get_viewport().gui_release_focus() # nada enfocable: que A no apriete lo de atrás

func _input(event: InputEvent) -> void:
	if not InputMode.is_gamepad(): return
	if get_viewport().gui_get_focus_owner(): return
	for action in NAV_ACTIONS:
		if event.is_action_pressed(action):
			if _menu_active() and _focus_first(_search_root()):
				get_viewport().set_input_as_handled()
			return

# Donde buscar el primer botón: la ventana modal de arriba o toda la pantalla.
func _search_root() -> Node:
	var top = _top()
	return top.root if top != null else get_tree().root

func _process(delta: float) -> void:
	_time += delta
	var target = get_viewport().gui_get_focus_owner() if InputMode.is_gamepad() else null
	_has_target = target != null and target.is_visible_in_tree()
	if _has_target:
		_rect = _screen_rect(target).grow(RING_PAD)
		_scroll_with_stick(target, delta)
	_ring.queue_redraw()

func _draw_ring() -> void:
	if not _has_target: return
	var pulse = 0.55 + 0.45 * sin(_time * 6.0)
	var box = StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = Color(RING_COLOR, 0.65 + 0.35 * pulse)
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(RING_COLOR, 0.25 * pulse)
	box.shadow_size = 6
	_ring.draw_style_box(box, _rect)

# Rectángulo del control en pantalla (contando la cámara/escala de su capa).
func _screen_rect(c: Control) -> Rect2:
	var xf = c.get_global_transform_with_canvas()
	return Rect2(xf.origin, c.size * xf.get_scale())

# Hay un menú abierto: juego en pausa o una escena sin jugador (menú principal, etc.).
func _menu_active() -> bool:
	return has_modal() or get_tree().paused or get_tree().get_first_node_in_group("player") == null

## Enfoca el primer control enfocable del menú que está más arriba (dentro de "from").
func _focus_first(from: Node) -> bool:
	var best: Control = null
	var best_layer := -INF
	var best_key := INF
	for c in _focusables(from):
		var layer_node = c.get_canvas_layer_node()
		var l = float(layer_node.layer) if layer_node else 0.0
		var pos = _screen_rect(c).position
		var key = pos.y * 10000.0 + pos.x
		if l > best_layer or (l == best_layer and key < best_key):
			best = c
			best_layer = l
			best_key = key
	if best:
		best.grab_focus()
	return best != null

func _focusables(node: Node) -> Array:
	var out := []
	if node is CanvasItem and not node.visible: return out
	if node is CanvasLayer and not node.visible: return out
	if node is Control and _can_focus(node):
		out.append(node)
	for child in node.get_children():
		out.append_array(_focusables(child))
	return out

func _can_focus(c: Control) -> bool:
	if c.focus_mode != Control.FOCUS_ALL: return false
	if c is BaseButton and c.disabled: return false
	if c is LineEdit: return false # escribir con el joystick no tiene sentido
	return c.is_visible_in_tree()

# La lista se desplaza hasta mostrar entero el control enfocado. Se respeta
# el paso de la barra (algunas listas usan pasos de 36 px y redondean).
func _reveal(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_visible_in_tree(): return
	var scroll = _scroll_of(control)
	if not scroll: return
	var view = scroll.get_global_rect()
	var r = control.get_global_rect()
	var delta := 0.0
	if r.end.y > view.end.y:
		delta = r.end.y - view.end.y + RING_PAD * 2.0
	elif r.position.y < view.position.y:
		delta = r.position.y - view.position.y - RING_PAD * 2.0
	if delta == 0.0: return
	var step = _bar_step(scroll)
	scroll.scroll_vertical += int(ceil(absf(delta) / step) * step * signf(delta))

func _bar_step(scroll: ScrollContainer) -> float:
	return maxf(scroll.get_v_scroll_bar().step, 1.0)

func _scroll_of(control: Control) -> ScrollContainer:
	var node = control.get_parent()
	while node:
		if node is ScrollContainer:
			return node
		node = node.get_parent()
	return null

# El analógico derecho mueve la lista que contiene al control enfocado.
func _scroll_with_stick(target: Control, delta: float) -> void:
	var y = Input.get_joy_axis(_pad(), JOY_AXIS_RIGHT_Y)
	if absf(y) < SCROLL_DEADZONE:
		_scroll_rest = 0.0
		return
	var scroll = _scroll_of(target)
	if not scroll: return
	_scroll_rest += y * SCROLL_SPEED * delta
	var bar_step = _bar_step(scroll)
	if absf(_scroll_rest) < bar_step: return
	var step = int(_scroll_rest / bar_step) * bar_step # de a pasos de la barra, si no redondea y no se mueve
	_scroll_rest -= step
	scroll.scroll_vertical += int(step)
	_keep_focus_in_view(scroll, target, y > 0.0)

# Si la ficha enfocada salió de la vista, el foco pasa a la que está más
# cerca, del lado hacia donde se mueve la lista.
func _keep_focus_in_view(scroll: ScrollContainer, target: Control, _down: bool) -> void:
	var view = scroll.get_global_rect()
	if _inside(view, target.get_global_rect()): return
	var best: Control = null
	var best_dist := INF
	var origin = target.get_global_rect().get_center()
	for c in _focusables(scroll):
		var r = c.get_global_rect()
		if not _inside(view, r): continue
		var d = absf(r.get_center().y - origin.y) * 4.0 + absf(r.get_center().x - origin.x)
		if d < best_dist:
			best = c
			best_dist = d
	if best:
		_stick_moving = true
		best.grab_focus()
		_stick_moving = false

func _inside(view: Rect2, r: Rect2) -> bool:
	return r.position.y >= view.position.y - 1.0 and r.end.y <= view.end.y + 1.0

func _pad() -> int:
	var pads = Input.get_connected_joypads()
	return pads[0] if not pads.is_empty() else 0
