# Armor.gd - Armor item class  
class_name Armor
extends Item

@export var armor_bonus: int = 2
@export var dodge_bonus: float = 0.0
@export var resistance_modifiers: Dictionary = {}  # damage type -> modifier
@export var special_properties: Array[String] = []

func _init():
	item_type = "armor"
	usable = true  # Can be equipped

func get_tooltip_text() -> String:
	var text = super.get_tooltip_text()
	text += "\n--- Armor Stats ---\n"
	text += "Armor: +" + str(armor_bonus) + "\n"
	
	if dodge_bonus > 0:
		text += "Dodge: +" + str(dodge_bonus * 100) + "%\n"
	
	if not resistance_modifiers.is_empty():
		text += "Resistances:\n"
		for damage_type in resistance_modifiers:
			var modifier = resistance_modifiers[damage_type]
			var percent = (1.0 - modifier) * 100
			if modifier < 1.0:
				text += "  " + damage_type + ": +" + str(percent) + "% resist\n"
			elif modifier > 1.0:
				text += "  " + damage_type + ": -" + str(percent) + "% resist\n"
	
	return text

func use_item(user: Actor) -> bool:
	# Equip the armor
	var inventory = user.get_node("Inventory") as Inventory
	if inventory:
		return inventory.equip_armor(self)
	return false
