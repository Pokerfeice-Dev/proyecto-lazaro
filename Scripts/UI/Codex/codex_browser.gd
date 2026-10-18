extends VBoxContainer

const CARD = preload("res://Scenes/UI/codex_entry_card.tscn")
const LOCK = preload("res://Art/Ui/svg/icon_lock.svg")
@export var research_only := false
var category := "items"
var selected_id := ""
var _entries: Array[Dictionary] = []
var _buttons: Dictionary = {}

func _ready() -> void:
	%Search.text_changed.connect(_filter)
	%RegisteredOnly.toggled.connect(func(_value): _filter(%Search.text))
	%Recipe.allow_purchase = false
	%DetailScroll.get_v_scroll_bar().step = 36
	%EntriesScroll.get_v_scroll_bar().step = 36
	# joystick: la búsqueda no se recorre con la cruceta (escribir no tiene sentido)
	%Search.focus_mode = Control.FOCUS_CLICK

func configure(next_category: String, only_research: bool = false) -> void:
	category = next_category
	research_only = only_research
	%Search.clear()
	%RegisteredOnly.visible = not research_only
	%Eyebrow.text = "MÓDULO DE SÍNTESIS / INVESTIGACIONES DISPONIBLES" if research_only else "ARCHIVO BIOLÓGICO / CÓDICE"
	_entries.clear()
	if category == "synergies":
		for entry in OmniaCatalog._synergy_entries():
			var owned = GameData.is_synergy_unlocked(entry.id)
			if research_only and not owned: continue
			_entries.append({"id": entry.id, "name": entry.name, "icon": OmniaCatalog.synergy_ingredients(entry.id)[0].icon if owned and not GameData.is_synergy_discovered(entry.id) else entry.icon, "known": owned, "lore": entry.desc, "stats": ""})
	else:
		for id in CodexData.DATA.get(category, {}):
			var data: Dictionary = CodexData.DATA[category][id].duplicate()
			data["id"] = id
			data["known"] = GameData.is_codex_unlocked(category, id)
			if not data.known:
				data["name"] = "Registro desconocido"
				data["icon"] = LOCK
				data["lore"] = "Explora los distritos y encuentra este registro para acceder a su información."
				data["stats"] = ""
			_entries.append(data)
	_entries.sort_custom(func(a, b): return a.known and not b.known)
	_filter("")

func _filter(query: String) -> void:
	for child in %EntryGrid.get_children():
		%EntryGrid.remove_child(child)
		child.queue_free()
	_buttons.clear()
	var shown: Array[Dictionary] = []
	for entry in _entries:
		if %RegisteredOnly.button_pressed and not research_only and not entry.known: continue
		if not query.is_empty() and not entry.name.to_lower().contains(query.to_lower()): continue
		shown.append(entry)
		var card = CARD.instantiate()
		%EntryGrid.add_child(card)
		card.get_node("Margin/Body/Title").text = entry.name
		card.get_node("Margin/Body/Icon").texture = UIStyle.trimmed(entry.icon)
		card.get_node("Margin/Body/Status").text = _status(entry)
		card.pressed.connect(_select.bind(entry.id))
		card.focus_entered.connect(_select.bind(entry.id))
		_buttons[entry.id] = card
	%Count.text = "1 registro" if shown.size() == 1 else "%d registros" % shown.size()
	%Empty.visible = shown.is_empty()
	%Empty.text = "Todavía no desbloqueaste investigaciones. Visita O.M.N.I.A. en el laboratorio." if research_only and _entries.is_empty() else "No hay registros que coincidan con tu búsqueda."
	%DetailScroll.visible = not shown.is_empty()
	if shown.is_empty():
		selected_id = ""
		return
	_select(selected_id if _buttons.has(selected_id) else shown[0].id)

## Joystick: enfoca la ficha elegida (o la primera) para navegar con la cruceta.
func focus_first() -> void:
	if _buttons.has(selected_id):
		_buttons[selected_id].grab_focus()
	elif not _buttons.is_empty():
		_buttons.values()[0].grab_focus()

func _status(entry: Dictionary) -> String:
	if category == "synergies":
		if GameData.is_synergy_discovered(entry.id): return "SÍNTESIS DESCUBIERTA"
		return "LISTA PARA EXPERIMENTAR" if entry.known else "INVESTIGACIÓN BLOQUEADA"
	return "REGISTRADO" if entry.known else "SIN IDENTIFICAR"

func _select(id: String) -> void:
	selected_id = id
	for key in _buttons:
		_buttons[key].set_pressed_no_signal(key == id)
	var entry: Dictionary = {}
	for candidate in _entries:
		if candidate.id == id:
			entry = candidate
			break
	if entry.is_empty(): return
	%EntryTitle.text = entry.name
	%EntryStatus.text = _status(entry)
	%Description.text = entry.get("lore", "")
	%Statistics.text = str(entry.get("stats", "")).replace(" | ", "\n")
	%Statistics.visible = not %Statistics.text.is_empty()
	%Recipe.visible = category == "synergies" and entry.known
	%Hero.visible = category != "synergies" or GameData.is_synergy_discovered(id)
	%Mystery.visible = not %Hero.visible
	%Hero.material = null
	if category == "synergies":
		%Hero._frames = []
		%Hero.texture = UIStyle.trimmed(entry.icon)
		if entry.known: %Recipe.configure(id)
	else:
		%Hero._setup(category, id, entry.known)
		%Hero._floating = false
	%DetailScroll.scroll_vertical = 0
	%Transition.play("select")
