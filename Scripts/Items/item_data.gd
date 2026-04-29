class_name ItemData
extends Resource

enum ItemType { MAIN_WEAPON, SECONDARY_WEAPON, CHARACTER }
enum ItemSlot { 
	MAIN_W1, MAIN_W2, MAIN_W3, 
	SEC_W1, SEC_W2, SEC_W3, 
	LEG_L, LEG_R, ARM_L, ARM_R, TORSO 
}

@export var id: String
@export var item_name: String
@export var icon: Texture2D
@export var type: ItemType
@export var slot: ItemSlot
@export var stats: Dictionary = {}
