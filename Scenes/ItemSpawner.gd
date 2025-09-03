# ItemSpawner.gd - Handles placing items in the world
class_name ItemSpawner
extends Node

@export var item_factory: ItemFactory
@export var spawn_items_on_ready: bool = true

var spawn_positions = [
	Vector2(320, 160),   # 10, 5 in grid coords
	Vector2(480, 256),   # 15, 8
	Vector2(160, 384),   # 5, 12
	Vector2(640, 320)    # 20, 10
]

func _ready():
	if not item_factory:
		item_factory = ItemFactory.new()
		add_child(item_factory)
	
	if spawn_items_on_ready:
		call_deferred("spawn_test_items")

func spawn_test_items():
	print("=== SPAWNING TEST ITEMS ===")
	
	# Spawn a variety of items for testing
	var test_items = [
		"fire_blade",
		"health_potion", 
		"leather_armor",
		"quick_dagger"
	]
	
	for i in range(min(test_items.size(), spawn_positions.size())):
		var position = spawn_positions[i]
		var item_name = test_items[i]
		
		var item: Item
		if item_name in item_factory.weapon_templates:
			item = item_factory.create_weapon(item_name)
		elif item_name in item_factory.armor_templates:
			item = item_factory.create_armor(item_name)
		elif item_name in item_factory.consumable_templates:
			item = item_factory.create_consumable(item_name)
		
		if item:
			var world_item = await item_factory.spawn_item_in_world(item, position)
			print("Spawned ", item.item_name, " at ", position)
	
	print("=== ITEM SPAWNING COMPLETE ===")

func spawn_random_item_at(position: Vector2) -> WorldItem:
	if item_factory:
		return await item_factory.spawn_random_loot(position)
	return null
