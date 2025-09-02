# WorldItem.gd - Items that exist in the world
class_name WorldItem
extends Node2D

var item_stack: ItemStack
var sprite: Sprite2D
var area: Area2D

func _ready():
	create_visual_components()
	
	# Add to pickup group for easy finding
	add_to_group("world_items")

func setup(item: Item, quantity: int = 1, position: Vector2 = Vector2.ZERO):
	item_stack = ItemStack.new(item, quantity)
	global_position = position
	
	if sprite:
		sprite.modulate = item.world_sprite_color
		# You could set item.icon_texture here if you have item icons
		create_item_texture()

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

func create_item_texture():
	if not item_stack or not item_stack.item:
		return
		
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color = get_item_color()
	image.fill(color)
	
	# Add a simple border
	for x in range(32):
		for y in range(32):
			if x == 0 or x == 31 or y == 0 or y == 31:
				image.set_pixel(x, y, Color.BLACK)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func get_item_color() -> Color:
	if not item_stack or not item_stack.item:
		return Color.WHITE
	
	match item_stack.item.item_type:
		"weapon": return Color.ORANGE_RED
		"armor": return Color.STEEL_BLUE
		"consumable": return Color.GREEN
		_: return item_stack.item.get_rarity_color()

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
		queue_free()
	else:
		print("Inventory full! Cannot pick up ", item_stack.item.item_name)
