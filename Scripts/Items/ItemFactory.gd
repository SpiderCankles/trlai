# ItemFactory.gd - Creates items and handles spawning
class_name ItemFactory
extends Node

# Item templates for easy creation
var weapon_templates = {
	"rusty_sword": {
		"name": "Rusty Sword",
		"description": "A worn blade, but still sharp enough.",
		"damage_bonus": 3,
		"speed_modifier": 1.1,
		"rarity": Item.Rarity.COMMON,
		"value": 15
	},
	"iron_sword": {
		"name": "Iron Sword", 
		"description": "A reliable weapon forged from quality iron.",
		"damage_bonus": 6,
		"speed_modifier": 1.0,
		"rarity": Item.Rarity.COMMON,
		"value": 50
	},
	"fire_blade": {
		"name": "Fire Blade",
		"description": "A magical sword that burns with inner flame.",
		"damage_bonus": 8,
		"speed_modifier": 0.95,
		"damage_type": "fire",
		"special_properties": ["fire"],
		"rarity": Item.Rarity.RARE,
		"value": 200
	},
	"quick_dagger": {
		"name": "Quick Dagger",
		"description": "A nimble blade for swift strikes.",
		"damage_bonus": 4,
		"speed_modifier": 0.8,
		"crit_bonus": 0.1,
		"rarity": Item.Rarity.UNCOMMON,
		"value": 75
	}
}

var armor_templates = {
	"leather_armor": {
		"name": "Leather Armor",
		"description": "Basic protection made from tanned hide.",
		"armor_bonus": 2,
		"dodge_bonus": 0.05,
		"rarity": Item.Rarity.COMMON,
		"value": 40
	},
	"iron_mail": {
		"name": "Iron Chain Mail",
		"description": "Interlocking rings of iron provide solid defense.",
		"armor_bonus": 4,
		"dodge_bonus": -0.05,
		"rarity": Item.Rarity.COMMON,
		"value": 100
	},
	"fire_resist_cloak": {
		"name": "Fire Resistant Cloak",
		"description": "Woven with salamander hair, it protects against flames.",
		"armor_bonus": 1,
		"dodge_bonus": 0.1,
		"resistance_modifiers": {"fire": 0.5},
		"rarity": Item.Rarity.UNCOMMON,
		"value": 150
	}
}

var consumable_templates = {
	"health_potion": {
		"name": "Health Potion",
		"description": "A red liquid that restores vitality.",
		"heal_amount": 30,
		"rarity": Item.Rarity.COMMON,
		"value": 25,
		"stack_size": 5
	},
	"healing_herb": {
		"name": "Healing Herb",
		"description": "A natural remedy with regenerative properties.",
		"status_effects": [StatusEffect.RegenerationEffect.new(3, 5)],
		"rarity": Item.Rarity.COMMON,
		"value": 15,
		"stack_size": 10
	},
	"strength_elixir": {
		"name": "Strength Elixir",
		"description": "Grants temporary combat prowess.",
		"status_effects": [StatusEffect.StrengthEffect.new(5, 8)],
		"rarity": Item.Rarity.UNCOMMON,
		"value": 60,
		"stack_size": 3
	}
}

func create_weapon(template_name: String) -> Weapon:
	if not template_name in weapon_templates:
		print("Unknown weapon template: ", template_name)
		return null
	
	var template = weapon_templates[template_name]
	var weapon = Weapon.new()
	var props = template.get("special_properties", [])
	
	weapon.item_name = template.get("name", "Unknown Weapon")
	weapon.description = template.get("description", "A weapon.")
	weapon.damage_bonus = template.get("damage_bonus", 1)
	weapon.attack_speed_modifier = template.get("speed_modifier", 1.0)
	weapon.damage_type = template.get("damage_type", "physical")
	weapon.crit_bonus = template.get("crit_bonus", 0.0)
	weapon.special_properties.assign(props)
	print("weapon.special_properties ", weapon.special_properties)
	weapon.rarity = template.get("rarity", Item.Rarity.COMMON)
	weapon.value = template.get("value", 10)
	
	return weapon

func create_armor(template_name: String) -> Armor:
	if not template_name in armor_templates:
		print("Unknown armor template: ", template_name)
		return null
	
	var template = armor_templates[template_name]
	var armor = Armor.new()
	var props = template.get("special_properties", [])
	
	armor.item_name = template.get("name", "Unknown Armor")
	armor.description = template.get("description", "Protective gear.")
	armor.armor_bonus = template.get("armor_bonus", 1)
	armor.dodge_bonus = template.get("dodge_bonus", 0.0)
	armor.resistance_modifiers = template.get("resistance_modifiers", {})
	armor.special_properties.assign(props)
	print("armor.special_properties ", armor.special_properties)
	armor.rarity = template.get("rarity", Item.Rarity.COMMON)
	armor.value = template.get("value", 10)
	
	return armor

func create_consumable(template_name: String) -> Consumable:
	if not template_name in consumable_templates:
		print("Unknown consumable template: ", template_name)
		return null
	
	var template = consumable_templates[template_name]
	var consumable = Consumable.new()
	
	consumable.item_name = template.get("name", "Unknown Item")
	consumable.description = template.get("description", "A consumable item.")
	consumable.heal_amount = template.get("heal_amount", 0)
	consumable.status_effects = create_status_effects_from_template(template.get("status_effects", []))
	consumable.rarity = template.get("rarity", Item.Rarity.COMMON)
	consumable.value = template.get("value", 5)
	consumable.stack_size = template.get("stack_size", 1)
	
	return consumable

func spawn_item_in_world(item: Item, position: Vector2, parent_node: Node = null) -> WorldItem:
	if not parent_node:
		# Wait until we're in the tree if we're not already
		if not is_inside_tree():
			await tree_entered
		parent_node = get_tree().current_scene
	
	var world_item = preload("res://Scenes/WorldItem.tscn").instantiate()
	if not world_item:
		# Create manually if no scene file
		world_item = WorldItem.new()
	
	parent_node.add_child(world_item)
	world_item.setup(item, 1, position)
	
	return world_item

func set_parent_node() -> Node:
	var parent_node 
	parent_node = get_tree().current_scene
	return parent_node

func spawn_random_loot(position: Vector2, level: int = 1) -> WorldItem:
	var item_type = randi() % 3
	var item: Item
	
	match item_type:
		0: # Weapon
			var weapons = weapon_templates.keys()
			var weapon_name = weapons[randi() % weapons.size()]
			item = create_weapon(weapon_name)
		1: # Armor
			var armors = armor_templates.keys()
			var armor_name = armors[randi() % armors.size()]
			item = create_armor(armor_name)
		2: # Consumable
			var consumables = consumable_templates.keys()
			var consumable_name = consumables[randi() % consumables.size()]
			item = create_consumable(consumable_name)
	
	if item:
		return await spawn_item_in_world(item, position)
	
	return null

func create_status_effects_from_template(template_effects: Array) -> Array[StatusEffect]:
	var effects: Array[StatusEffect] = []
	for effect_data in template_effects:
		var effect = StatusEffect.new()
		# Populate effect from effect_data
		effects.append(effect)
	return effects
