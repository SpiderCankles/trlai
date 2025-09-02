# EnemySpawner.gd - Helper script to spawn and register enemies
class_name EnemySpawner
extends Node

@export var spawn_enemies_on_ready: bool = true
@export var enemy_scene: PackedScene  # Assign your enemy scene in the editor

# Example spawn positions - you can customize this
var spawn_positions = [
	Vector2i(10, 5),
	Vector2i(15, 8),
	Vector2i(5, 12),
	Vector2i(20, 10)
]

var enemy_types = ["goblin", "orc", "skeleton", "rat"]

func _ready():
	if spawn_enemies_on_ready:
		call_deferred("spawn_test_enemies")

func spawn_test_enemies():
	var time_manager = get_node("../TimeManager")
	if not time_manager:
		print("ERROR: TimeManager not found!")
		return
	
	print("=== SPAWNING TEST ENEMIES ===")
	for i in range(spawn_positions.size()):
		var enemy = spawn_enemy_at_position(spawn_positions[i], enemy_types[i % enemy_types.size()])
		print("Created enemy: ", enemy.name, " at position: ", enemy.grid_position)
		
		# Debug: Print the enemy's sprite
		var sprite = enemy.get_node("Sprite")
		if sprite:
			print("  - Sprite texture: ", sprite.texture)
			print("  - Sprite modulate: ", sprite.modulate)
		else:
			print("  - ERROR: No sprite found!")
	print("=== ENEMY SPAWNING COMPLETE ===")

func spawn_enemy_at_position(pos: Vector2i, type: String = "goblin") -> EnemyActor:
	var enemy_node = create_enemy_node(type)
	
	# The enemy_actor IS the enemy_node since the script is attached to the root
	var enemy_actor = enemy_node
	
	enemy_actor.grid_position = pos
	enemy_actor.enemy_type = type
	enemy_actor.cell_size = 32  # Match your cell size
	
	# Add to scene
	get_parent().add_child(enemy_node)
	
	# Register with time manager
	var time_manager = get_node("../TimeManager")
	if time_manager:
		time_manager.register_actor(enemy_actor)
		print("Spawned and registered ", type, " at ", pos)
	
	return enemy_actor

func create_enemy_node(type: String) -> Node2D:
	# Create a simple enemy node structure
	var enemy_root = Node2D.new()
	enemy_root.name = type.capitalize() + "_" + str(randi())
	
	# Attach the EnemyActor script to the root node
	enemy_root.set_script(preload("res://Scripts/EnemyActor.gd"))  # Adjust path as needed
	
	# Add a sprite for visualization
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = create_enemy_texture(type)
	enemy_root.add_child(sprite)
	
	# Add collision area if needed
	var area = Area2D.new()
	area.name = "Area2D"
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = RectangleShape2D.new()
	shape.size = Vector2(28, 28)  # Slightly smaller than cell
	collision.shape = shape
	area.add_child(collision)
	enemy_root.add_child(area)
	
	return enemy_root

func create_enemy_texture(type: String) -> ImageTexture:
	# Create a simple colored square for each enemy type
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	var color: Color
	match type.to_lower():
		"goblin":
			color = Color.GREEN
		"orc":
			color = Color.RED
		"skeleton":
			color = Color.WHITE
		"rat":
			color = Color(0.6, 0.4, 0.2)  # Brown color
		_:
			color = Color.PURPLE
	
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Function to spawn a single enemy at runtime
func spawn_enemy(pos: Vector2i, type: String = "goblin") -> EnemyActor:
	return spawn_enemy_at_position(pos, type)
