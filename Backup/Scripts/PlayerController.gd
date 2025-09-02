# PlayerController.gd - Handles player input and creates actions
class_name PlayerController
extends Node

signal action_selected(action: Action)

var current_actor: Actor
var is_waiting_for_input: bool = false
var grid_manager: GridManager  # Reference to your grid system

# Input mapping for movement
var movement_inputs = {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN, 
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
	# Diagonal movements
	"move_up_left": Vector2i.UP + Vector2i.LEFT,
	"move_up_right": Vector2i.UP + Vector2i.RIGHT,
	"move_down_left": Vector2i.DOWN + Vector2i.LEFT,
	"move_down_right": Vector2i.DOWN + Vector2i.RIGHT
}

func _ready():
	print("Player Controller Ready")
	print("Player Controller Parent: ", get_parent())
	print("Player Controller Scene Tree: ")
	var current = self
	while current:
		print("  ", current.name, " (", current.get_class(), ")")
		current = current.get_parent()
	
	# Connect to the time manager
	print("Player Controller: Time Manager Ready")
	var time_manager = get_node("../TimeManager")  # Adjust path as needed
	if time_manager:
		print("Found Time Manager at: ", time_manager.get_path())
		var result = time_manager.turn_completed.connect(_on_turn_completed)
		print("Signal conncetion result: ", result)
		print("Time Manager Connected")
		
	else:
		print("TimeManager not found, trying absolute path")
		time_manager = get_node("/root/Main/TimeManager")  # Adjust as needed
		if time_manager:
			print("Found TimeManager at absolute path")
			time_manager.turn_completed.connect(_on_turn_completed)
		
func _unhandled_input(event):
	print("=== INPUT EVENT ===")
	print("Event: ", event)
	print("is_waiting_for_input: ", is_waiting_for_input)
	print("current_actor: ", current_actor)
	print("Event is_pressed: ", event.is_pressed() if event.has_method("is_pressed") else "N/A")
	
	if not is_waiting_for_input or not current_actor:
		print("Not waiting for input - ignoring")
		return
		
	if not current_actor:
		print("No current actor - ignoring")
		return
		
	if current_actor.has_method("can_act") and not current_actor.can_act():
		print("actor is acting - ignoring input")
		
	if event.is_pressed():
		print("Processing pressed event")
		var action = process_input(event)
		print("Action created: ", action)
		if action:
			print("Emitting action_selected signal")
			action_selected.emit(action)
			#is_waiting_for_input = false
			print("Input processing complete")
		else:
			print("No action created")
	else:
		print("Event not pressed")

# Process input events and return appropriate actions
func process_input(event: InputEvent) -> Action:
	print("=== PROCESSING INPUT ===")
	print("Event type: ", event.get_class())
	
		# Wait action
	if Input.is_action_just_pressed("wait"):
		return WaitAction.new()
	
	# Attack in direction (without moving)
	if Input.is_action_just_pressed("attack"):
		return handle_attack_input()
	
	# Interact/use items
	if Input.is_action_just_pressed("interact"):
		return handle_interact_input()
	
	# Movement inputs
	for input_name in movement_inputs:
			var is_pressed = Input.is_action_just_pressed(input_name)
			print("Checking ", input_name, ": ", is_pressed)
			if is_pressed:
				print("Movement input detected: ", input_name)
				var direction = movement_inputs[input_name]
				return MoveAction.new(direction)
		#if Input.is_action_just_pressed(input_name):
			#var direction = movement_inputs[input_name]
			#if can_move_to(current_actor.global_position, direction):
				#return MoveAction.new(direction)
			#else:
				## Can't move there - maybe there's an enemy to attack?
				#var target = get_enemy_at_position(current_actor.global_position + Vector2(direction))
				#if target:
					#return AttackAction.new(target)
				#else:
					## Invalid move - return wait action or null
					#return WaitAction.new(0.1)  # Short wait for invalid moves
	
	
	return null

# Check if movement to a position is valid
func can_move_to(current_pos: Vector2, direction: Vector2i) -> bool:
	if not grid_manager:
		return true  # No grid constraints
		
	var target_pos = Vector2i(current_pos) + direction
	
	# Check bounds
	if not grid_manager.is_in_bounds(target_pos):
		return false
	
	# Check for walls/obstacles
	if grid_manager.is_blocked(target_pos):
		return false
		
	# Check for other actors
	if get_actor_at_position(Vector2(target_pos)):
		return false
		
	return true

# Get enemy at a specific position
func get_enemy_at_position(pos: Vector2) -> Actor:
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if actor != current_actor and Vector2i(actor.global_position) == Vector2i(pos):
			if not actor.is_player():
				return actor
	return null

# Get any actor at a specific position
func get_actor_at_position(pos: Vector2) -> Actor:
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if Vector2i(actor.global_position) == Vector2i(pos):
			return actor
	return null

# Handle attack input (attack in a direction)
func handle_attack_input() -> Action:
	# You might want to show attack direction indicators here
	# For now, just attack the first adjacent enemy
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for direction in directions:
		var target_pos = Vector2i(current_actor.global_position) + direction
		var enemy = get_enemy_at_position(Vector2(target_pos))
		if enemy:
			return AttackAction.new(enemy)
	
	# No adjacent enemies
	return WaitAction.new(0.1)

# Handle interaction input
func handle_interact_input() -> Action:
	# Check for items, doors, etc. at current position or adjacent
	# Return appropriate action (UseItemAction, OpenDoorAction, etc.)
	return WaitAction.new(0.1)  # Placeholder

# Called when it's this actor's turn
func start_turn(actor: Actor):
	print("PlayerController: Starting turn for ", actor.name)
	print("PlayerController: Previous current_actor: ", current_actor)
	
	current_actor = actor
	is_waiting_for_input = true
	print("Player Controller: Now waiting for input")

# Called when turn is completed
func _on_turn_completed(actor: Actor):
	print("PlayerController: _on_turn_completed called for: ", actor.name)
	print("PlayerController: current_actor is: ", current_actor)
	print("PlayerController: actor == current_actor: ", actor == current_actor)
	
	if actor == current_actor:
		is_waiting_for_input = false
		print("PlayerController: Reset complete - ready for next turn")
	else:
		print("PlayerController: Not resetting - different actor")
	


# Enhanced Actor.gd - Modified to work with PlayerController
# Add this to your existing Actor class or modify it

# In Actor.gd, modify the get_player_input function:
func get_player_input() -> Action:
	# Get reference to player controller
	var player_controller = get_node("../PlayerController")  # Adjust path as needed
	
	if player_controller:
		# Signal the controller to start waiting for input
		player_controller.start_turn(self)
		
		# Wait for an action to be selected
		var action = await player_controller.action_selected
		return action
	
	# Fallback - return wait if no controller found
	return WaitAction.new()
