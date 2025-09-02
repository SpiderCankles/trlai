class_name UseItemAction
extends Action

var item: Item

func _init(target_item: Item):
	item = target_item

func get_time_cost() -> int:
	if item:
		return item.use_time_cost
	return TimeManager.BASE_TIME_UNIT

func execute(actor: Actor) -> void:
	if not item:
		return
	
	var inventory = actor.get_node("Inventory") as Inventory
	if not inventory:
		print("Actor has no inventory!")
		return
	
	if inventory.use_item(item):
		print(actor.name, " used ", item.item_name)
	else:
		print("Failed to use ", item.item_name)
