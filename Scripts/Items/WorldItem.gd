# WorldItem.gd - Items that exist in the world with sprite support
class_name WorldItem
extends Node2D

var item_stack: ItemStack
var sprite: Sprite2D
var area: Area2D

# Sprite sheet configuration (similar to Actor system)
@export var sprite_sheet: Texture2D  # Assign your item sprite sheet in the editor
@export var sprite_size: Vector2i = Vector2i(32, 32)

# Item sprite atlas coordinates - you'll need to configure these based on your sprite sheet layout
var item_sprite_atlas = {
	# Weapons
	"rusty_sword": Vector2i(1, 0),
	"iron_sword": Vector2i(1, 1),
	"fire_blade": Vector2i(9, 0),
	"quick_dagger": Vector2i(0, 0),
	
	# Armor
	"leather_armor": Vector2i(1, 12),
	"iron_mail": Vector2i(4, 12),
	"fire_resist_cloak": Vector2i(2, 12),
	
	# Consumables
	"health_potion": Vector2i(1, 19),
	"healing_herb": Vector2i(0, 19),
	"strength_elixir": Vector2i(2, 19),
	
	# Misc items
	"gold": Vector2i(2, 24),
	"key": Vector2i(1, 22),
	
	# Default fallback
	"default": Vector2i(7, 7)
}

func _ready():
	create_visual_components()
	
	# Add to pickup group for easy finding
	add_to_group("world_items")

func setup(item: Item, quantity: int = 1, position: Vector2 = Vector2.ZERO):
	item_stack = ItemStack.new(item, quantity)
	global_position = position
	
	if sprite:
		setup_item_sprite()

func create_visual_components():
	# Create sprite
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	add_child(sprite)
	
	# Create pickup area
	area = Area2D.new()
	area.name = "PickupArea"
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	collision.shape = shape
	
	area.add_child(collision)
	add_child(area)
	
	# Connect pickup signal
	area.body_entered.connect(_on_body_entered)

func setup_item_sprite():
	"""Set up sprite using sprite sheet or fallback to colored square"""
	if not sprite or not item_stack or not item_stack.item:
		return
	
	# If we have a sprite sheet, use it
	if sprite_sheet:
		sprite.texture = sprite_sheet
		sprite.region_enabled = true
		update_sprite_region()
		print("Set up sprite sheet for item: ", item_stack.item.item_name)
	else:
		# Fallback to colored squares
		sprite.texture = create_fallback_texture()
		sprite.region_enabled = false
		print("Using fallback texture for item: ", item_stack.item.item_name)
	
	# Apply rarity color tint
	#sprite.modulate = item_stack.item.get_rarity_color()
	add_rarity_glow()

func update_sprite_region():
	"""Update sprite region based on item name"""
	if not sprite or not sprite_sheet or not item_stack or not item_stack.item:
		return
	
	# Convert item name to sprite key (similar to how Actor does it)
	var item_key = get_item_sprite_key()
	var coords = item_sprite_atlas.get(item_key, item_sprite_atlas["default"])
	
	# Calculate pixel position in sprite sheet
	var pixel_x = coords.x * sprite_size.x
	var pixel_y = coords.y * sprite_size.y
	
	sprite.region_rect = Rect2(pixel_x, pixel_y, sprite_size.x, sprite_size.y)
	print("Set sprite region for ", item_stack.item.item_name, " (", item_key, ") to: ", sprite.region_rect)

func get_item_sprite_key() -> String:
	"""Convert item name to sprite atlas key"""
	if not item_stack or not item_stack.item:
		return "default"
	
	# Convert item name to lowercase and replace spaces with underscores
	var key = item_stack.item.item_name.to_lower().replace(" ", "_")
	return key

func create_fallback_texture() -> ImageTexture:
	"""Create colored square fallback when no sprite sheet is available"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = get_fallback_item_color()
	image.fill(color)
	
	# Add a simple border to make items more visible
	for x in range(32):
		for y in range(32):
			if x == 0 or x == 31 or y == 0 or y == 31:
				image.set_pixel(x, y, Color.BLACK)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func add_rarity_glow():
	"""Add a glow effect around the item based on rarity"""
	if not sprite or not item_stack or not item_stack.item:
		return
	
	# Only add glow for uncommon+ items to avoid visual clutter
	if item_stack.item.rarity == Item.Rarity.COMMON:
		return
	
	# Create a duplicate sprite node for the glow effect
	var glow_sprite = Sprite2D.new()
	glow_sprite.name = "GlowSprite"
	glow_sprite.texture = sprite.texture
	glow_sprite.region_enabled = sprite.region_enabled
	glow_sprite.region_rect = sprite.region_rect
	
	# Set glow color based on rarity
	glow_sprite.modulate = item_stack.item.get_rarity_color()
	glow_sprite.z_index = sprite.z_index - 1  # Behind the main sprite
	
	# Make it slightly larger for glow effect
	glow_sprite.scale = Vector2(1.2, 1.2)
	
	# Add the glow sprite as a child
	sprite.add_child(glow_sprite)
	
	# Optional: animate the glow
	animate_glow(glow_sprite)

func animate_glow(glow_sprite: Sprite2D):
	"""Add subtle pulsing animation to the glow"""
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.set_parallel(true)
	
	# Pulse the alpha
	glow_tween.tween_property(glow_sprite, "modulate:a", 0.3, 1.5)
	glow_tween.tween_property(glow_sprite, "modulate:a", 0.8, 1.5)
	
	# Slight scale variation
	glow_tween.tween_property(glow_sprite, "scale", Vector2(1.15, 1.15), 1.5)
	glow_tween.tween_property(glow_sprite, "scale", Vector2(1.25, 1.25), 1.5)

func get_fallback_item_color() -> Color:
	"""Get color for fallback texture based on item type"""
	if not item_stack or not item_stack.item:
		return Color.WHITE
	
	match item_stack.item.item_type.to_lower():
		"weapon":
			return Color.ORANGE_RED
		"armor":
			return Color.STEEL_BLUE
		"consumable":
			return Color.GREEN
		"misc":
			return Color.YELLOW
		_:
			return Color.WHITE

func add_pickup_animation():
	"""Add subtle animation effects to make items more noticeable"""
	if not sprite:
		return
	
	# Gentle floating animation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(sprite, "position:y", -4, 2.0)
	float_tween.tween_property(sprite, "position:y", 4, 2.0)
	
	# Gentle scale pulse
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.set_parallel(true)
	scale_tween.tween_property(sprite, "scale", Vector2(1.05, 1.05), 1.5)
	scale_tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 1.5)

func pickup_animation():
	"""Animation when item is being picked up"""
	if not sprite:
		return
	
	var pickup_tween = create_tween()
	pickup_tween.set_parallel(true)
	
	# Scale up and fade out
	pickup_tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
	pickup_tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	
	# Move upward slightly
	pickup_tween.tween_property(sprite, "position", sprite.position + Vector2(0, -16), 0.2)
	
	await pickup_tween.finished

func _on_body_entered(body):
	# Check if it's a player
	if body is Actor and body.is_player():
		try_pickup(body)

func try_pickup(actor: Actor):
	var inventory = actor.get_node("Inventory") as Inventory
	if not inventory:
		print("Actor has no inventory!")
		return
	
	if inventory.add_item(item_stack.item, item_stack.quantity):
		print(actor.name, " picked up ", item_stack.get_display_name())
		
		# Play pickup animation before removing
		pickup_animation()
		await pickup_animation()
		
		queue_free()
	else:
		print("Inventory full! Cannot pick up ", item_stack.item.item_name)

# Utility function to set sprite sheet after creation (useful for ItemFactory)
func set_sprite_sheet(new_sprite_sheet: Texture2D):
	sprite_sheet = new_sprite_sheet
	if item_stack and item_stack.item:
		setup_item_sprite()
