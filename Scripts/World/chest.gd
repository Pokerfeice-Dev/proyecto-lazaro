class_name Chest
extends Node2D

## Cofre interactivo con recompensa (vida, item de cuerpo o de arma para el
## jugador). Soporta 3 tipos via la propiedad chest_type, seleccionable desde
## el inspector:
##
## - "normal": se abre directo con [E], sin sorpresas (GravitoCapsule: se
##   activa con un crossfade de azul a verde).
## - "trap": al abrirlo aparecen enemigos y las puertas de la sala se
##   bloquean; hay que eliminarlos a todos para poder agarrar la recompensa
##   (estilo cofre trampa de The Binding of Isaac). TantalusCapsule: tiene
##   estado desactivado y activado (con los enemigos afuera); al limpiarlo se
##   desactiva de nuevo antes de entregar la recompensa.
## - "locked": hay que pagar Carne (GameData.flesh) para abrirlo. Nunca da
##   curacion de premio, siempre un item, para que valga la inversion
##   (MidasCapsule: no tiene estado activado propio, solo el flash de
##   interaccion).
##
## Secuencia visual al abrirse (los 3 tipos): capsula cerrada -> crossfade de
## activacion + flash de color -> sale el item -> el cofre desaparece. El
## item queda oculto hasta que se abre.
##
## Para usarlo en una sala nueva: copiá el nodo "Chest" de
## Chest_Showcase.tscn (res://Scenes/World/) y pegalo en tu sala, después
## elegí el chest_type que quieras desde el inspector.

const WEAPON_ITEM_PATHS: Array[String] = [
	"res://Art/Items/Weapons/Item1.tres",
	"res://Art/Items/Weapons/Item2.tres",
	"res://Art/Items/Weapons/Item3.tres",
	"res://Art/Items/Weapons/Item4.tres",
	"res://Art/Items/Weapons/Item5.tres",
	"res://Art/Items/Weapons/Item6.tres",
	"res://Art/Items/Weapons/Item7_Colmena.tres",
	"res://Art/Items/Weapons/Item8_CabezaHumana.tres",
	"res://Art/Items/Weapons/Item9_SierraCircular.tres"
]

const BODY_ITEM_PATHS: Array[String] = [
	"res://Art/Items/Player/Body/Item2_TorsoBlindado.tres",
	"res://Art/Items/Player/Body/Item3_TorsoEspinado.tres",
	"res://Art/Items/Player/Body/Item4_TorsoLigero.tres",
	"res://Art/Items/Player/Legs/Item2_PiernasRodantes.tres",
	"res://Art/Items/Player/Legs/Item3_PiernasCaninas.tres",
	"res://Art/Items/Player/Legs/Item4_PiernasBionicas.tres",
	"res://Art/Items/Player/Arms/Item2_BrazoReforzado.tres",
	"res://Art/Items/Player/Arms/Item3_BrazoLigero.tres",
	"res://Art/Items/Player/Arms/Item4_BrazoArmado.tres"
]

# Enemigos que aparecen al abrir un cofre trampa (ambush estilo Isaac).
const TRAP_ENEMY_PATHS: Array[String] = [
	"res://Scenes/Enemies/EnemyFollower.tscn"
]

# Textura por defecto (desactivada) y activada de cada capsula. Las que no
# tienen variante activada (MidasCapsule) usan "" y solo se benefician del
# flash de interaccion.
const CAPSULE_TEXTURES: Dictionary = {
	"normal": {
		"default": "res://Art/Scenario_objects/gravitocapsule_sprite.png",
		"active": "res://Art/Scenario_objects/gravitocapsule_active_sprite.png",
	},
	"trap": {
		"default": "res://Art/Scenario_objects/tantaluscapsule_sprite.png",
		"active": "res://Art/Scenario_objects/tantaluscapsule_active_sprite.png",
	},
	"locked": {
		"default": "res://Art/Scenario_objects/midascapsule_sprite.png",
		"active": "",
	},
}

# Posiciones (locales) del item durante la animacion de revelado: arranca
# "espiando" apenas por encima del centro de la capsula y termina flotando
# por encima de ella. Proporcionales al tamaño de las nuevas capsulas
# (~22-30x26-29px), mas chicas que el chest_base/chest_lid viejo (32x32).
const ITEM_PEEK_POS_Y: float = -6.0
const ITEM_HOVER_POS_Y: float = -21.0

# Tinte aditivo del flash breve que marca que la capsula fue activada.
const FLASH_COLOR: Color = Color(1.6, 1.6, 1.9, 1.0)

@export_enum("normal", "trap", "locked") var chest_type: String = "normal"
## Costo en Carne para abrir un cofre de tipo "locked".
@export var locked_flesh_cost: int = 15

@onready var item_sprite: Sprite2D = $Item_sprite
@onready var interact_area: Area2D = $InteractArea
@onready var label: Label = $Label
@onready var capsule_sprite: Sprite2D = $CapsuleSprite
@onready var capsule_active_sprite: Sprite2D = $CapsuleActiveSprite
@onready var flash_overlay: Sprite2D = $FlashOverlay

var reward_type: String = "Heal" # "Heal", "BodyItem", "WeaponItem"
var chosen_item_data: ItemData = null
var player_in_range: bool = false
var player_ref: Node2D = null
var time_passed: float = 0.0

var collected: bool = false # la recompensa ya se entrego, el cofre esta cerrando el ciclo
var is_animating: bool = false # bloquea input mientras corre alguna animacion
var chest_opened: bool = false # la capsula ya se activo (para no reactivarla al agarrar el item)
var item_revealed: bool = false # el item ya salio del cofre y puede flotar

# Estado del cofre trampa: "none" (todavia no se activo), "active" (enemigos
# vivos, hay que limpiarlos), "cleared" (ya se puede agarrar la recompensa).
var trap_state: String = "none"
var trap_enemies_alive: int = 0

func _ready() -> void:
	_roll_random_reward()
	_configure_reward_visuals()
	_configure_chest_type_visuals()
	if item_sprite:
		item_sprite.visible = false # el item no se ve hasta que se abre el cofre
	_update_label()
	_connect_signals()

func _connect_signals() -> void:
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	_apply_levitation(delta)

# ── Recompensa: se decide una sola vez al crear el cofre ───────────────────

func _roll_random_reward() -> void:
	if chest_type == "locked":
		reward_type = "BodyItem" if randf() < 0.5 else "WeaponItem"
		return
	var roll = randf()
	if roll < 0.33:
		reward_type = "Heal"
		return
	if roll < 0.66:
		reward_type = "BodyItem"
		return
	reward_type = "WeaponItem"

func _configure_reward_visuals() -> void:
	match reward_type:
		"Heal":
			_setup_heal_visuals()
		"BodyItem":
			_setup_random_item(BODY_ITEM_PATHS)
		"WeaponItem":
			_setup_random_item(WEAPON_ITEM_PATHS)

func _setup_heal_visuals() -> void:
	if not item_sprite:
		return
	var heart_path = "res://Art/Items/Player/Heart/Heart.png"
	if ResourceLoader.exists(heart_path):
		var tex = load(heart_path)
		if tex:
			item_sprite.texture = tex
			item_sprite.modulate = Color.WHITE
			return
	item_sprite.texture = preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
	item_sprite.modulate = Color(1.0, 0.2, 0.2)

func _setup_random_item(paths: Array[String]) -> void:
	var path = paths.pick_random()
	chosen_item_data = load(path) as ItemData
	_apply_item_data_visuals()

func _apply_item_data_visuals() -> void:
	if not chosen_item_data or not item_sprite:
		return
	var tex = chosen_item_data.icon
	if tex:
		item_sprite.texture = tex
		item_sprite.modulate = Color.WHITE
		return
	item_sprite.texture = preload("res://Art/Items/Weapons/Item1_Mezcladora.png")
	item_sprite.modulate = Color(1.0, 0.9, 0.2)

# ── Visual segun el tipo de cofre ────────────────────────────────────────────

func _configure_chest_type_visuals() -> void:
	# Cada tipo de cofre usa su propio par de sprites (GravitoCapsule,
	# TantalusCapsule, MidasCapsule), asi que no hace falta tintear nada a
	# mano: el arte ya distingue el tipo (el MidasCapsule ya es dorado).
	var tex_paths: Dictionary = CAPSULE_TEXTURES.get(chest_type, CAPSULE_TEXTURES["normal"])
	var default_path: String = tex_paths.get("default", "")
	var active_path: String = tex_paths.get("active", "")

	if capsule_sprite and ResourceLoader.exists(default_path):
		capsule_sprite.texture = load(default_path)

	if capsule_active_sprite:
		if active_path != "" and ResourceLoader.exists(active_path):
			capsule_active_sprite.texture = load(active_path)
			capsule_active_sprite.modulate.a = 0.0
		else:
			# Este tipo no tiene variante activada (MidasCapsule): la ocultamos,
			# solo se usa el flash de interaccion para dar feedback.
			capsule_active_sprite.visible = false

	if flash_overlay and capsule_sprite:
		flash_overlay.texture = capsule_sprite.texture
		flash_overlay.modulate.a = 0.0

func _apply_levitation(delta: float) -> void:
	if collected or not item_revealed or not item_sprite:
		return
	time_passed += delta
	var y_offset = sin(time_passed * 3.0) * 4.0
	item_sprite.position.y = ITEM_HOVER_POS_Y + y_offset

# ── Cartel de interaccion ────────────────────────────────────────────────────

func _update_label() -> void:
	if collected or not label:
		return
	label.text = _get_label_text()

func _get_label_text() -> String:
	# El nombre del item NUNCA se muestra aca: es sorpresa hasta que sale del
	# cofre (ver _play_item_reveal_anim). Antes de abrir solo se ve un cartel
	# generico de interaccion.
	if chest_type == "trap":
		match trap_state:
			"active":
				return "¡TRAMPA!\nEliminá a los enemigos"
			"cleared":
				return "[E] Agarrar" if player_in_range else "Recompensa"
			_:
				pass # "none": se ve y se comporta como un cofre normal hasta que lo abren

	if chest_type == "locked":
		if player_in_range:
			return "Costo: %d Carne\n[E] Desbloquear" % locked_flesh_cost
		return "Cofre bloqueado (%d Carne)" % locked_flesh_cost

	if player_in_range:
		return "[E] Agarrar"
	return "Cofre"

func _get_item_display_name() -> String:
	if reward_type == "Heal":
		return "Vida (+25% faltante)"
	if chosen_item_data:
		return chosen_item_data.item_name
	return "Objeto"

# ── Deteccion del jugador ────────────────────────────────────────────────────

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	player_in_range = true
	player_ref = body
	_update_label()

func _on_body_exited(body: Node2D) -> void:
	# Si ya se inicio la secuencia de recoleccion (collected=true), ignorar:
	# al apagar el Area2D (interact_area.monitoring=false en _stop_interaction)
	# Godot dispara igual este "exited" para el cuerpo que seguia superpuesto,
	# lo cual antes vaciaba player_ref y hacia que _apply_reward_effect() no
	# tuviera a quien darle el item/la curacion. Este es el bug que reportaste.
	if collected:
		return
	if not body.is_in_group("player"):
		return
	player_in_range = false
	player_ref = null
	_update_label()

func _input(event: InputEvent) -> void:
	_check_collection_input(event)

func _check_collection_input(event: InputEvent) -> void:
	if collected or is_animating or not player_in_range:
		return
	if not _is_key_e_pressed(event):
		return
	match chest_type:
		"trap":
			_handle_trap_interact()
		"locked":
			_handle_locked_interact()
		_:
			_handle_normal_interact()

func _is_key_e_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.physical_keycode == KEY_E and event.pressed and not event.echo

# ── Cofre normal: abrir y agarrar en el mismo gesto ─────────────────────────

func _handle_normal_interact() -> void:
	_run_open_and_collect_sequence()

# ── Cofre trampa: al abrirlo aparecen enemigos, hay que limpiarlos ──────────

func _handle_trap_interact() -> void:
	match trap_state:
		"none":
			_trigger_trap()
		"active":
			return # sigue trabado hasta que se elimine a todos los enemigos
		"cleared":
			_run_open_and_collect_sequence() # ya esta activada, solo sale el item

func _trigger_trap() -> void:
	trap_state = "active"
	_update_label()
	_lock_room_doors()
	_play_activate_crossfade() # no se espera: los enemigos aparecen mientras se activa la capsula
	_spawn_trap_enemies()

func _spawn_trap_enemies() -> void:
	var enemy_count = randi_range(3, 4)
	trap_enemies_alive = 0
	for i in range(enemy_count):
		_spawn_trap_enemy(i, enemy_count)

func _spawn_trap_enemy(i: int, total: int) -> void:
	var scene_path: String = TRAP_ENEMY_PATHS.pick_random()
	var scene: PackedScene = load(scene_path)
	if not scene:
		return
	var enemy = scene.instantiate()
	var angle = (TAU / float(total)) * i
	var offset = Vector2(cos(angle), sin(angle)) * 90.0
	enemy.global_position = global_position + offset
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_trap_enemy_died)
	get_tree().current_scene.call_deferred("add_child", enemy)
	if enemy.has_method("spawn_appear"):
		enemy.call_deferred("spawn_appear")
	trap_enemies_alive += 1

func _on_trap_enemy_died(_enemy = null) -> void:
	trap_enemies_alive -= 1
	if trap_enemies_alive <= 0:
		_unlock_after_trap()

func _unlock_after_trap() -> void:
	trap_state = "cleared"
	_unlock_room_doors()
	_update_label()
	_play_deactivate_crossfade() # la capsula vuelve a su color por defecto antes de entregar el item

func _lock_room_doors() -> void:
	for door in get_tree().get_nodes_in_group("door"):
		if door.has_method("lock_door"):
			door.lock_door()

func _unlock_room_doors() -> void:
	for door in get_tree().get_nodes_in_group("door"):
		if door.has_method("unlock_door"):
			door.unlock_door()

# ── Cofre bloqueado: hay que pagar carne para abrirlo ───────────────────────

func _handle_locked_interact() -> void:
	if GameData.spend_flesh(locked_flesh_cost):
		_run_open_and_collect_sequence()
	else:
		_flash_insufficient_flesh()

func _flash_insufficient_flesh() -> void:
	if not label:
		return
	label.text = "Te falta Carne (%d)" % locked_flesh_cost
	label.modulate = Color(1.0, 0.35, 0.35)
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(label):
		return
	label.modulate = Color.WHITE
	_update_label()

# ── Secuencia: cerrado -> activandose -> activado -> sale el item -> desaparece ─

func _run_open_and_collect_sequence() -> void:
	collected = true
	is_animating = true
	_stop_interaction()
	if not chest_opened:
		await _play_activate_crossfade()
	await _play_item_reveal_anim()
	_apply_reward_effect()
	_play_collection_effects()
	await get_tree().create_timer(0.7).timeout
	await _play_disappear_anim()
	queue_free()

func _stop_interaction() -> void:
	if label:
		label.visible = false
	if interact_area:
		interact_area.set_deferred("monitoring", false)
		interact_area.set_deferred("monitorable", false)

# ── Animaciones de activacion de la capsula ─────────────────────────────────

func _play_activation_flash() -> void:
	# Pulso de color aditivo breve, comun a los 3 tipos de capsula, para
	# remarcar que la interaccion registro (incluso en el MidasCapsule, que
	# no tiene un sprite "activado" propio).
	if not flash_overlay:
		return
	if capsule_active_sprite and capsule_active_sprite.visible and capsule_active_sprite.modulate.a > 0.5:
		flash_overlay.texture = capsule_active_sprite.texture
	elif capsule_sprite:
		flash_overlay.texture = capsule_sprite.texture
	flash_overlay.modulate = FLASH_COLOR
	flash_overlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(flash_overlay, "modulate:a", 0.85, 0.05)
	tw.tween_property(flash_overlay, "modulate:a", 0.0, 0.25)
	await tw.finished

func _play_activate_crossfade() -> void:
	# GravitoCapsule (normal): crossfade de azul a verde al activarse.
	# TantalusCapsule (trap): crossfade al estado activado (con enemigos).
	# MidasCapsule (locked): no tiene variante activada, solo el flash.
	_play_activation_flash()
	if capsule_active_sprite and capsule_active_sprite.texture:
		var tw = create_tween()
		tw.tween_property(capsule_active_sprite, "modulate:a", 1.0, 0.35)
		await tw.finished
	chest_opened = true

func _play_deactivate_crossfade() -> void:
	# Usado solo por el TantalusCapsule: vuelve a su color por defecto cuando
	# se limpia la trampa, justo antes de que salga el item.
	_play_activation_flash()
	if capsule_active_sprite and capsule_active_sprite.texture:
		var tw = create_tween()
		tw.tween_property(capsule_active_sprite, "modulate:a", 0.0, 0.35)
		await tw.finished

func _play_item_reveal_anim() -> void:
	if not item_sprite:
		return
	item_sprite.visible = true
	item_sprite.scale = Vector2(0.2, 0.2)
	item_sprite.position = Vector2(0, ITEM_PEEK_POS_Y)
	item_sprite.modulate.a = 0.0

	# Recien aca se revela el nombre real del item, en el mismo momento en que
	# sale del cofre. Se desvanece solo mas tarde junto con todo el cofre en
	# _play_disappear_anim (el Label es hijo de Chest, hereda el modulate:a).
	if label:
		label.text = _get_item_display_name()
		label.modulate = Color(1, 1, 1, 0)
		label.visible = true

	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(item_sprite, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(item_sprite, "modulate:a", 1.0, 0.18)
	tw.tween_property(item_sprite, "position:y", ITEM_HOVER_POS_Y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if label:
		tw.tween_property(label, "modulate:a", 1.0, 0.25)
	await tw.finished
	item_revealed = true

func _play_disappear_anim() -> void:
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_property(self, "scale", scale * 0.8, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tw.finished

# ── Recompensa (compartida por los 3 tipos) ─────────────────────────────────

func _apply_reward_effect() -> void:
	if not player_ref:
		return
	if reward_type == "Heal":
		_apply_heal_effect()
	else:
		_give_reward_item()

func _apply_heal_effect() -> void:
	if not player_ref.get("stats"):
		return
	var stats = player_ref.stats
	var missing_health = stats.max_health - stats.current_health
	var heal_amt = int(missing_health * 0.25)
	if missing_health > 0 and heal_amt <= 0:
		heal_amt = 1
	stats.heal(heal_amt)

func _give_reward_item() -> void:
	if not chosen_item_data:
		return
	var inv = player_ref.get_node_or_null("Inventory")
	if not inv:
		return
	inv.add_item(chosen_item_data)

func _play_collection_effects() -> void:
	var interact_sound = get_node_or_null("Interact") as AudioStreamPlayer2D
	if interact_sound:
		interact_sound.play()
