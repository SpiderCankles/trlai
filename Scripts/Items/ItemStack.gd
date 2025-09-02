# ItemStack.gd - Represents a stack of items
class_name ItemStack
extends RefCounted

var item: Item
var quantity: int = 1

func _init(base_item: Item, qty: int = 1):
	item = base_item
	quantity = qty

func can_add(amount: int) -> bool:
	return quantity + amount <= item.stack_size

func add_quantity(amount: int) -> int:
	var can_add_amount = min(amount, item.stack_size - quantity)
	quantity += can_add_amount
	return amount - can_add_amount  # Return overflow

func remove_quantity(amount: int) -> int:
	var remove_amount = min(amount, quantity)
	quantity -= remove_amount
	return remove_amount

func split_stack(amount: int) -> ItemStack:
	if amount >= quantity:
		return null
	
	var new_stack = ItemStack.new(item, amount)
	quantity -= amount
	return new_stack

func get_total_weight() -> float:
	return item.weight * quantity

func get_display_name() -> String:
	if quantity > 1:
		return item.item_name + " (" + str(quantity) + ")"
	return item.item_name
