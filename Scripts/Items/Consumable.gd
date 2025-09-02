# Consumable.gd - Consumable item class
class_name Consumable
extends Item

@export var heal_amount: int = 0
@export var restore_type: String = "health"  # health, mana, stamina
@export var status_effects: Array[StatusEffect] = []
@export var instant_use: bool = true

func _init():
	item_type = "consumable" 
	usable = true

func get_tooltip_text() -> String:
	var text = super.get_tooltip_text()
	text += "\n--- Effects ---\n"
	
	if heal_amount > 0:
		text += "Restores " + str(heal_amount) + " " + restore_type + "\n"
	
	for effect in status_effects:
		text += "Applies: " + effect.effect_name + " (" + str(effect.duration) + " turns)\n"
	
	return text

func use_item(user: Actor) -> bool:
	print("Using ", item_name, " on ", user.name)
	
	# Apply healing
	if heal_amount > 0 and restore_type == "health":
		var combat_stats = user.get_combat_stats()
		if combat_stats:
			combat_stats.heal(heal_amount)
			print(user.name, " healed for ", heal_amount, " HP")
	
	# Apply status effects
	var combat_stats = user.get_combat_stats()
	if combat_stats:
		for effect in status_effects:
			combat_stats.add_status_effect(effect)
	
	return true  # Item is consumed
