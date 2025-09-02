# Weapon.gd - Weapon item class
class_name Weapon
extends Item

@export var damage_bonus: int = 5
@export var attack_speed_modifier: float = 1.0  # 1.0 = normal, 0.8 = faster, 1.2 = slower
@export var damage_type: String = "physical"
@export var crit_bonus: float = 0.0  # Additional crit chance
@export var special_properties: Array[String] = []  # "fire", "poison", "vampire", etc.

func _init():
	item_type = "weapon"
	usable = true  # Can be equipped

func get_tooltip_text() -> String:
	var text = super.get_tooltip_text()
	text += "\n--- Weapon Stats ---\n"
	text += "Damage: +" + str(damage_bonus) + " " + damage_type + "\n"
	
	if attack_speed_modifier != 1.0:
		var speed_text = "faster" if attack_speed_modifier < 1.0 else "slower"
		var percent = abs(1.0 - attack_speed_modifier) * 100
		text += "Speed: " + str(percent) + "% " + speed_text + "\n"
	
	if crit_bonus > 0:
		text += "Critical: +" + str(crit_bonus * 100) + "%\n"
	
	if not special_properties.is_empty():
		text += "Properties: " + ", ".join(special_properties) + "\n"
	
	return text

func use_item(user: Actor) -> bool:
	# Equip the weapon
	var inventory = user.get_node("Inventory") as Inventory
	if inventory:
		return inventory.equip_weapon(self)
	return false
