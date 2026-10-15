extends VBoxContainer

signal hint_purchased

@export var allow_purchase := true
var synergy_id: String
var _pending_index := -1
@onready var confirmation: ConfirmationDialog = $HintConfirmation

func _ready() -> void:
	confirmation.confirmed.connect(_buy_hint)
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
		slot.tooltip_text = ingredients[index].name if revealed else "Investigá esta pieza"
		var eye: Button = slot.get_node("Reveal")
		eye.visible = allow_purchase and not revealed and index > 0
		eye.disabled = not GameData.is_synergy_unlocked(id)
		eye.text = "%d" % OmniaCatalog.hint_cost(index)
		eye.tooltip_text = "Ver pista por %d de chatarra" % OmniaCatalog.hint_cost(index)
	$Help.text = "Probá combinaciones durante la partida o comprá pistas para revelar los componentes." if GameData.is_synergy_unlocked(id) else "Desbloqueá la investigación para ver el primer componente."
	if not allow_purchase:
		$Help.text = "Probá combinaciones durante la partida. Podés revelar componentes comprando pistas en O.M.N.I.A."

func _ask_hint(index: int) -> void:
	if not allow_purchase: return
	_pending_index = index
	var cost = OmniaCatalog.hint_cost(index)
	confirmation.dialog_text = "¿Querés ver una pista de este ítem?\nRevela su nombre e imagen de forma permanente.\n\nCosto: %d de chatarra · Disponible: %d" % [cost, GameData.scrap]
	confirmation.get_ok_button().disabled = GameData.scrap < cost
	confirmation.ok_button_text = "Comprar pista" if GameData.scrap >= cost else "Chatarra insuficiente"
	confirmation.popup_centered()

func _buy_hint() -> void:
	if OmniaCatalog.purchase_hint(synergy_id, _pending_index):
		configure(synergy_id)
		hint_purchased.emit()

func dismiss_confirmation() -> bool:
	if not confirmation.visible: return false
	confirmation.hide()
	return true
