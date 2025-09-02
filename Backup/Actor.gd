class_name Actor
extends Node2D  # Changed from Node to Node2D

@export var is_player_controlled: bool = false
@export var base_speed: int = 100  # Lower = faster
@export var grid_position: Vector2i = Vector2i.ZERO
@export var cell_size: int = 32
@export var move_duration: float = 0.05
@export var move_easing: Tween.EaseType = Tween.EASE_OUT
@export var move_transition: Tween.TransitionType = Tween.TRANS_QUART

var time_accumulated: int = 0
var movement_tween: Tween
var is_moving: bool = false

# References to child nodes (will be found automatically)
var sprite_node: Sprite2D
var area_node: Area2D

#screen tearing debugging
var _last_frame_position: Vector2
var _position_changes_this_frame: int = 0

func _ready():
	# Find sprite and area nodes automatically
	find_child_nodes()
	
	# Initialize grid position if not set
	if grid_position == Vector2i.ZERO:
		grid_position = Vector2i(global_position / cell_size)
	
	print("Actor ", name, " ready at grid position: ", grid_position)
	update_visual_position_immediate()

func find_child_nodes():
	# Find sprite node (could be named "Sprite2D", "Sprite", or be any Sprite2D)
	sprite_node = find_child("Sprite2D", false, false) as Sprite2D
	if not sprite_node:
		sprite_node = find_child("Sprite", false, false) as Sprite2D
	if not sprite_node:
		sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node:
		sprite_node = get_node_or_null("Sprite")
	
	# Find area node
	area_node = find_child("Area2D", false, false) as Area2D
	if not area_node:
		area_node = get_node_or_null("Area2D")
	
	print("Actor ", name, " found sprite: ", sprite_node, " area: ", area_node)

func _process(_delta):
	# Debug position changes
	if global_position != _last_frame_position:
		_position_changes_this_frame += 1
		if _position_changes_this_frame > 1:
			print("WARNING: Multiple position changes in one frame for ", name)
	_last_frame_position = global_position
	_position_changes_this_frame = 0

# Override this in derived classes or connect to signals
func take_turn() -> Action:
	if is_player_controlled:
		# Wait for player input
		return await get_player_input()
	else:
		# AI decision making
		return get_ai_action()

func get_player_input() -> Action:
	print("Actor: Waiting for player input")
	
	# Get reference to player controller
	var player_controller = get_node("/root/Main/PlayerController")  # Adjust path to match your scene
	
	if player_controller:
		# Signal the controller to start waiting for input
		player_controller.start_turn(self)
		
		# Wait for an action to be selected
		print("Actor: Waiting for action_selected signal")
		var action = await player_controller.action_selected
		print("Actor: Received action: ", action)
		return action
	else:
		print("ERROR: PlayerController not found!")
		# Return a default action to prevent infinite loop
		return WaitAction.new()

func get_ai_action() -> Action:
	# Simple AI - move randomly as an example (override in subclasses)
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var random_dir = directions[randi() % directions.size()]
	return MoveAction.new(random_dir)
	
func update_visual_position_immediate():
	var new_world_position = Vector2(grid_position * cell_size)
	global_position = new_world_position
	print("Actor ", name, " immediate position update to: ", global_position)
	
func update_visual_position_smooth():
	if is_moving:
		print("Actor ", name, " already moving, skipping animation")
		return # don't start a new animation if already moving
		
	var target_pos = Vector2(grid_position * cell_size)
	var start_pos = global_position
	
	print("=== SMOOTH MOVEMENT DEBUG FOR ", name, " ===")
	print("Grid position: ", grid_position)
	print("Cell size: ", cell_size)
	print("Calculated target: ", target_pos)
	print("Current position: ", start_pos)
	print("Distance to move: ", target_pos - start_pos)
	print("Starting smooth movement from ", start_pos, " to ", target_pos)
	
	if movement_tween:
		movement_tween.kill()
		# kills any existing tween
		
	#create new tween
	movement_tween = create_tween()
	is_moving = true
	
	#configure tween properties
	movement_tween.set_ease(move_easing)
	movement_tween.set_trans(move_transition)
	
	#animate the move - now using 'self' since we're a Node2D
	movement_tween.tween_property(self, "global_position", target_pos, move_duration)
	movement_tween.tween_callback(func(): print("Tween finished for ", name, ", final position: ", global_position)).set_delay(move_duration)
	
	#add move effects for player
	if is_player_controlled:
		add_movement_effects()
		
	#wait for animation to complete
	await movement_tween.finished
	is_moving = false
	print("Movement Complete for ", name, ", final position: ", global_position)
		
func add_movement_effects():
	if not sprite_node:
		return
		
	var scale_tween = create_tween()
	scale_tween.set_parallel(true)  # Run parallel to movement tween
	
	# Scale up slightly during movement
	scale_tween.tween_property(sprite_node, "scale", Vector2(1.1, 1.1), move_duration * 0.3)
	scale_tween.tween_property(sprite_node, "scale", Vector2(1.0, 1.0), move_duration * 0.7).set_delay(move_duration * 0.3)
	
	# Optional: Add rotation for more dynamic feel
	# var rotation_tween = create_tween()
	# rotation_tween.set_parallel(true)
	# rotation_tween.tween_property(sprite_node, "rotation", deg_to_rad(5), move_duration * 0.5)
	# rotation_tween.tween_property(sprite_node, "rotation", 0, move_duration * 0.5).set_delay(move_duration * 0.5)
	
func can_act() -> bool:
	return not is_moving
	
func is_player() -> bool:
	return is_player_controlled

func is_valid() -> bool:
	# Override this to check if actor is alive, active, etc.
	return true

# Utility functions for getting visual bounds and center
func get_visual_center() -> Vector2:
	return global_position

func get_visual_bounds() -> Rect2:
	if sprite_node and sprite_node.texture:
		var texture_size = sprite_node.texture.get_size() * sprite_node.scale
		return Rect2(global_position - texture_size / 2, texture_size)
	else:
		return Rect2(global_position - Vector2(16, 16), Vector2(32, 32))

# Debug function to print actor state
func debug_print_state():
	print("=== ACTOR DEBUG: ", name, " ===")
	print("Grid Position: ", grid_position)
	print("Global Position: ", global_position)
	print("Is Moving: ", is_moving)
	print("Is Player: ", is_player_controlled)
	print("Base Speed: ", base_speed)
	print("Time Accumulated: ", time_accumulated)
	print("Sprite Node: ", sprite_node)
	if sprite_node:
		print("  Sprite Position: ", sprite_node.global_position)
		print("  Sprite Scale: ", sprite_node.scale)
		print("  Sprite Texture: ", sprite_node.texture)
	print("===========================")
