class_name EnemySpawner
extends Node

@export var spawn_enemies_on_ready: bool = true
@export var enemy_scene: PackedScene  # Assign your enemy scene in the editor
@export var sprite_sheet: Texture2D  # Assign your sprite sheet here

# Example spawn positions - you can customize this
var spawn_positions = [
	Vector2i(10, 5),
	Vector2i(15, 8),
	Vector2i(5, 12),
	Vector2i(20, 10),
	Vector2i(8, 15),
	Vector2i(18, 3)
]

var enemy_types = ["goblin", "orc", "skeleton", "rat", "troll"]

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
		var enemy_type = enemy_types[i % enemy_types.size()]
		var enemy = spawn_enemy_at_position(spawn_positions[i], enemy_type)
		print("Created enemy: ", enemy.name, " (", enemy_type, ") at position: ", enemy.grid_position)
	print("=== ENEMY SPAWNING COMPLETE ===")

func spawn_enemy_at_position(pos: Vector2i, type: String = "goblin") -> EnemyActor:
	var enemy_node = create_enemy_node(type)
	
	# The enemy_actor IS the enemy_node since the script is attached to the root
	var enemy_actor = enemy_node as EnemyActor
	
	# Set up the enemy properties
	enemy_actor.grid_position = pos
	enemy_actor.enemy_type = type
	enemy_actor.actor_type = type  # This sets the sprite type in the base Actor class
	enemy_actor.cell_size = 32  # Match your cell size
	
	# Set the sprite sheet if we have one
	if sprite_sheet:
		enemy_actor.sprite_sheet = sprite_sheet
	
	# Add to scene
	get_parent().add_child(enemy_node)
	
	# Register with time manager
	var time_manager = get_node("../TimeManager")
	if time_manager:
		time_manager.register_actor(enemy_actor)
		print("Spawned and registered ", type, " at ", pos)
	
	return enemy_actor

func create_enemy_node(type: String) -> Node2D:
	# Create the enemy node structure
	var enemy_root = Node2D.new()
	enemy_root.name = type.capitalize() + "_" + str(randi())
	
	# Attach the EnemyActor script to the root node
	enemy_root.set_script(preload("res://Scripts/EnemyActor.gd"))  # Adjust path as needed
	
	# Add a sprite for visualization - the EnemyActor script will configure it
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
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

# Function to spawn a single enemy at runtime
func spawn_enemy(pos: Vector2i, type: String = "goblin") -> EnemyActor:
	return spawn_enemy_at_position(pos, type)

# Function to spawn a random enemy type
func spawn_random_enemy(pos: Vector2i) -> EnemyActor:
	var random_type = enemy_types[randi() % enemy_types.size()]
	return spawn_enemy_at_position(pos, random_type)
