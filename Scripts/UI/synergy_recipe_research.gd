extends VBoxContainer

signal hint_purchased

@export var allow_purchase := true
var synergy_id: String
var _popup: OmniaRevealPopup = null

func _ready() -> void:
	for index in 3:
		$RecipeChips.get_child(index).get_node("Reveal").pressed.connect(_ask_hint.bind(index))

func configure(id: String) -> void:
	synergy_id = id
	var ingredients = OmniaCatalog.synergy_ingredients(id)
	for index in 3:
		var slot = $RecipeChips.get_child(index)
		slot.visible = index < ingredients.size()
		if not slot.visible: continue
		var revealed = OmniaCatalog.is_ingredient_revealed(id, index)
		slot.get_node("Frame/Icon").texture = ingredients[index].icon if revealed else null
		slot.get_node("Frame/Unknown").visible = not revealed
		slot.get_node("ItemName").text = ingredients[index].name if revealed else "Componente oculto"
		slot.tooltip_text = ingredients[index].name if revealed else "Investiga esta pieza"
		var eye: Button = slot.get_node("Reveal")
		eye.visible = allow_purchase and not revealed and index > 0
		eye.disabled = not GameData.is_synergy_unlocked(id)
		eye.text = "%d" % OmniaCatalog.hint_cost(index)
		eye.tooltip_text = "Ver pista por %d de chatarra" % OmniaCatalog.hint_cost(index)
	$Help.text = "Prueba combinaciones durante la partida o compra pistas para revelar los componentes." if GameData.is_synergy_unlocked(id) else "Desbloquea la investigación para ver el primer componente."
	if not allow_purchase:
		$Help.text = "Prueba combinaciones durante la partida. Puedes revelar componentes comprando pistas en O.M.N.I.A."

# La compra de la pista la hace la ventana de O.M.N.I.A. (OmniaRevealPopup),
# con el mismo estilo que el resto de la UI.
func _ask_hint(index: int) -> void:
	if not allow_purchase or is_instance_valid(_popup): return
	_popup = OmniaRevealPopup.ask_hint(synergy_id, index)
	_popup.hint_bought.connect(_on_hint_bought)

func _on_hint_bought() -> void:
	if not is_inside_tree(): return
	configure(synergy_id)
	hint_purchased.emit()

func dismiss_confirmation() -> bool:
	if not is_instance_valid(_popup): return false
	_popup.close()
	return true
