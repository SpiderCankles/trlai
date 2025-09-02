# Inventory.gd - Actor inventory component
class_name Inventory
extends Node

signal inventory_changed
signal item_equipped(item: Item)
signal item_unequipped(item: Item)

@export var max_slots: int = 20
@export var max_weight: float = 100.0

var item_stacks: Array[ItemStack] = []
var equipped_weapon: Weapon
var equipped_armor: Armor

# Reference to owner
var inventory_owner: Actor

func _ready():
	inventory_owner = get_parent() as Actor

func add_item(item: Item, quantity: int = 1) -> bool:
	print("Adding item: ", item.item_name, " x", quantity)
	
	var remaining_quantity = quantity
	
	# Try to stack with existing items first
	for stack in item_stacks:
		if stack.item.can_stack_with(item) and stack.can_add(remaining_quantity):
			var added = stack.add_quantity(remaining_quantity)
			remaining_quantity -= added
			if remaining_quantity <= 0:
				inventory_changed.emit()
				return true
	
	# Create new stacks for remaining items
	while remaining_quantity > 0 and item_stacks.size() < max_slots:
		var stack_size = min(remaining_quantity, item.stack_size)
		var new_stack = ItemStack.new(item, stack_size)
		item_stacks.append(new_stack)
		remaining_quantity -= stack_size
	
	inventory_changed.emit()
	return remaining_quantity <= 0

func remove_item(item: Item, quantity: int = 1) -> int:
	var removed_total = 0
	var remaining_to_remove = quantity
	
	for i in range(item_stacks.size() - 1, -1, -1):
		var stack = item_stacks[i]
		if stack.item.item_name == item.item_name:
			var removed = stack.remove_quantity(remaining_to_remove)
			removed_total += removed
			remaining_to_remove -= removed
			
			if stack.quantity <= 0:
				item_stacks.remove_at(i)
			
			if remaining_to_remove <= 0:
				break
	
	if removed_total > 0:
		inventory_changed.emit()
	
	return removed_total

func has_item(item: Item, quantity: int = 1) -> bool:
	var total_quantity = 0
	for stack in item_stacks:
		if stack.item.item_name == item.item_name:
			total_quantity += stack.quantity
			if total_quantity >= quantity:
				return true
	return false

func get_item_quantity(item: Item) -> int:
	var total = 0
	for stack in item_stacks:
		if stack.item.item_name == item.item_name:
			total += stack.quantity
	return total

func use_item(item: Item) -> bool:
	if not has_item(item):
		return false
	
	var success = item.use_item(inventory_owner)
	
	# Remove consumable items after use
	if success and item.item_type == "consumable":
		remove_item(item, 1)
	
	return success

func equip_weapon(weapon: Weapon) -> bool:
	# Unequip current weapon
	if equipped_weapon:
		unequip_weapon()
	
	equipped_weapon = weapon
	apply_weapon_stats(weapon, true)
	item_equipped.emit(weapon)
	print(inventory_owner.name, " equipped ", weapon.item_name)
	return true

func unequip_weapon():
	if equipped_weapon:
		apply_weapon_stats(equipped_weapon, false)
		item_unequipped.emit(equipped_weapon)
		equipped_weapon = null

func equip_armor(armor: Armor) -> bool:
	# Unequip current armor
	if equipped_armor:
		unequip_armor()
	
	equipped_armor = armor
	apply_armor_stats(armor, true)
	item_equipped.emit(armor)
	print(inventory_owner.name, " equipped ", armor.item_name)
	return true

func unequip_armor():
	if equipped_armor:
		apply_armor_stats(equipped_armor, false)
		item_unequipped.emit(equipped_armor)
		equipped_armor = null

func apply_weapon_stats(weapon: Weapon, equipping: bool):
	var combat_stats = inventory_owner.get_combat_stats()
	if not combat_stats:
		return
	
	var multiplier = 1 if equipping else -1
	
	# Apply damage bonus
	combat_stats.base_attack += weapon.damage_bonus * multiplier
	
	# Apply crit bonus
	combat_stats.crit_chance += weapon.crit_bonus * multiplier
	combat_stats.crit_chance = max(0.0, combat_stats.crit_chance)

func apply_armor_stats(armor: Armor, equipping: bool):
	var combat_stats = inventory_owner.get_combat_stats()
	if not combat_stats:
		return
	
	var multiplier = 1 if equipping else -1
	
	# Apply armor bonus
	combat_stats.armor += armor.armor_bonus * multiplier
	combat_stats.armor = max(0, combat_stats.armor)
	
	# Apply dodge bonus
	combat_stats.dodge_chance += armor.dodge_bonus * multiplier
	combat_stats.dodge_chance = max(0.0, combat_stats.dodge_chance)
	
	# Apply resistance modifiers
	if equipping:
		for damage_type in armor.resistance_modifiers:
			combat_stats.damage_resistances[damage_type] *= armor.resistance_modifiers[damage_type]
	else:
		for damage_type in armor.resistance_modifiers:
			combat_stats.damage_resistances[damage_type] /= armor.resistance_modifiers[damage_type]

func get_total_weight() -> float:
	var total = 0.0
	for stack in item_stacks:
		total += stack.get_total_weight()
	return total

func is_overloaded() -> bool:
	return get_total_weight() > max_weight

func get_free_slots() -> int:
	return max_slots - item_stacks.size()

func get_all_items() -> Array[ItemStack]:
	return item_stacks.duplicate()

# Get items by type
func get_items_by_type(type: String) -> Array[ItemStack]:
	var filtered: Array[ItemStack] = []
	for stack in item_stacks:
		if stack.item.item_type == type:
			filtered.append(stack)
	return filtered
