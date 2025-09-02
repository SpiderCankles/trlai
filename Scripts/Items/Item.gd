# Item.gd - Base item class
class_name Item
extends RefCounted

@export var item_name: String = "Unknown Item"
@export var description: String = "A mysterious item."
@export var item_type: String = "misc"  # weapon, armor, consumable, misc
@export var stack_size: int = 1  # Maximum stack size (1 for unique items)
@export var weight: float = 1.0
@export var value: int = 10

# Item rarity affects color coding and drop chances
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
@export var rarity: Rarity = Rarity.COMMON

# Can this item be used/activated?
@export var usable: bool = false
@export var use_time_cost: int = 100  # Time cost to use item

# Visual representation
@export var icon_texture: Texture2D
@export var world_sprite_color: Color = Color.WHITE

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color.LIGHT_GRAY
		Rarity.UNCOMMON: return Color.GREEN
		Rarity.RARE: return Color.BLUE
		Rarity.EPIC: return Color.PURPLE
		Rarity.LEGENDARY: return Color.ORANGE
		_: return Color.WHITE

# Override in derived classes
func use_item(user: Actor) -> bool:
	return false

func get_tooltip_text() -> String:
	var text = "[color=" + get_rarity_color().to_html() + "]" + item_name + "[/color]\n"
	text += description + "\n"
	text += "Type: " + item_type.capitalize() + "\n"
	text += "Weight: " + str(weight) + "\n"
	text += "Value: " + str(value) + " gold"
	return text

func can_stack_with(other: Item) -> bool:
	if stack_size <= 1:
		return false
	return item_name == other.item_name and item_type == other.item_type
