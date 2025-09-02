# Enemy.gd - Basic enemy with AI behavior
class_name Enemy
extends Actor

# Enemy-specific properties
@export var enemy_type: String = "goblin"
@export var detection_range: int = 6
@export var max_chase_distance: int = 15  # Stop chasing if player gets too far
@export var aggression: float = 0.8  # Chance to move toward player when detected
@export var wander_chance: float = 0.3  # Chance to wander when not chasing

# AI state
enum AIState { IDLE, WANDERING, CHASING, LOST }
var ai_state: AIState = AIState.IDLE
var last_known_player_position: Vector2i = Vector2i(-999, -999)
var turns_since_player_seen: int = 0
var wander_direction: Vector2i = Vector2i.ZERO
var wander_steps_remaining: int = 0

func _ready():
	super._ready()  # Call parent _ready
	
	# Enemies are never player controlled
	is_player_controlled = false
	
	# Set different speeds based on enemy type
	setup_enemy_stats()
	
	print("Enemy ready: ", enemy_type, " at ", grid_position)

func setup_enemy_stats():
	match enemy_type.to_lower():
		"goblin":
			base_speed = 120  # Slightly slower than player (100)
			detection_range = 6
			aggression = 0.8
		"orc":
			base_speed = 140  # Slower but stronger
			detection_range = 5
			aggression = 0.9
		"skeleton":
			base_speed = 110  # Fast but fragile
			detection_range = 7
			aggression = 0.7
		"rat":
			base_speed = 80   # Very fast
			detection_range = 4
			aggression = 0.6
		_:
			# Default stats for unknown types
			base_speed = 120
			detection_range = 5
			aggression = 0.7

func get_ai_action() -> Action:
	print("=== AI DECISION FOR ", enemy_type.to_upper(), " ===")
	print("Current state: ", AIState.keys()[ai_state])
	print("Grid position: ", grid_position)
	
	var player = find_player()
	if not player:
		print("No player found - wandering")
		return get_wander_action()
	
	var distance_to_player = grid_position.distance_to(player.grid_position)
	var can_see_player = can_see_target(player.grid_position)
	
	print("Player at: ", player.grid_position)
	print("Distance: ", distance_to_player)
	print("Can see: ", can_see_player)
	
	# Update AI state based on player visibility
	update_ai_state(player, distance_to_player, can_see_player)
	
	# Choose action based on state
	match ai_state:
		AIState.CHASING:
			return get_chase_action(player.grid_position)
		AIState.LOST:
			return get_search_action()
		AIState.WANDERING:
			return get_wander_action()
		_: # IDLE
			return get_idle_action()

func update_ai_state(player: Actor, distance: float, can_see: bool):
	if can_see and distance <= detection_range:
		# Player spotted!
		ai_state = AIState.CHASING
		last_known_player_position = player.grid_position
		turns_since_player_seen = 0
		print("Player spotted! Switching to CHASING")
		
	elif ai_state == AIState.CHASING:
		if distance > max_chase_distance:
			# Player escaped
			ai_state = AIState.LOST
			turns_since_player_seen = 0
			print("Player escaped! Switching to LOST")
		elif not can_see:
			# Lost sight but still in range
			turns_since_player_seen += 1
			if turns_since_player_seen > 3:  # Give up after 3 turns
				ai_state = AIState.LOST
				print("Lost player! Switching to LOST")
		else:
			# Still chasing
			last_known_player_position = player.grid_position
			turns_since_player_seen = 0
			
	elif ai_state == AIState.LOST:
		if can_see and distance <= detection_range:
			# Found player again
			ai_state = AIState.CHASING
			last_known_player_position = player.grid_position
			turns_since_player_seen = 0
			print("Found player again! Switching to CHASING")
		else:
			turns_since_player_seen += 1
			if turns_since_player_seen > 5:  # Search for 5 turns then give up
				ai_state = AIState.WANDERING
				print("Giving up search. Switching to WANDERING")

func get_chase_action(target_pos: Vector2i) -> Action:
	print("Chasing player at: ", target_pos)
	
	# Simple pathfinding - move toward target
	var best_direction = get_best_direction_to_target(target_pos)
	
	if best_direction != Vector2i.ZERO:
		var new_pos = grid_position + best_direction
		if is_valid_move(new_pos):
			print("Chasing: moving ", best_direction)
			return MoveAction.new(best_direction)
	
	# Can't move toward target - try alternative directions
	var alternative_dirs = get_alternative_directions(target_pos)
	for dir in alternative_dirs:
		var new_pos = grid_position + dir
		if is_valid_move(new_pos):
			print("Chasing: alternative move ", dir)
			return MoveAction.new(dir)
	
	# Can't move anywhere useful
	print("Chasing: blocked - waiting")
	return WaitAction.new(0.5)

func get_search_action() -> Action:
	print("Searching for player near: ", last_known_player_position)
	
	# Move toward last known position
	if grid_position != last_known_player_position:
		var direction = get_best_direction_to_target(last_known_player_position)
		if direction != Vector2i.ZERO:
			var new_pos = grid_position + direction
			if is_valid_move(new_pos):
				return MoveAction.new(direction)
	
	# At last known position or can't reach it - search randomly around area
	var search_directions = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i.UP + Vector2i.LEFT, Vector2i.UP + Vector2i.RIGHT,
		Vector2i.DOWN + Vector2i.LEFT, Vector2i.DOWN + Vector2i.RIGHT
	]
	
	search_directions.shuffle()
	for dir in search_directions:
		var new_pos = grid_position + dir
		if is_valid_move(new_pos):
			return MoveAction.new(dir)
	
	return WaitAction.new(0.5)

func get_wander_action() -> Action:
	print("Wandering randomly")
	
	# Continue current wander if we have steps remaining
	if wander_steps_remaining > 0 and wander_direction != Vector2i.ZERO:
		var new_pos = grid_position + wander_direction
		if is_valid_move(new_pos):
			wander_steps_remaining -= 1
			return MoveAction.new(wander_direction)
		else:
			# Hit obstacle, choose new direction
			wander_steps_remaining = 0
	
	# Choose new wander direction
	if randf() < wander_chance:
		var directions = [
			Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
		]
		directions.shuffle()
		
		for dir in directions:
			var new_pos = grid_position + dir
			if is_valid_move(new_pos):
				wander_direction = dir
				wander_steps_remaining = randi_range(2, 5)  # Wander 2-5 steps in this direction
				return MoveAction.new(dir)
	
	# Stay idle
	return WaitAction.new(1.0)

func get_idle_action() -> Action:
	# Maybe occasionally move randomly even when idle
	if randf() < 0.1:  # 10% chance
		return get_wander_action()
	return WaitAction.new(1.5)

func get_best_direction_to_target(target_pos: Vector2i) -> Vector2i:
	var diff = target_pos - grid_position
	var direction = Vector2i.ZERO
	
	# Prioritize the axis with the larger difference
	if abs(diff.x) > abs(diff.y):
		direction.x = sign(diff.x)
	elif abs(diff.y) > abs(diff.x):
		direction.y = sign(diff.y)
	else:
		# Equal distance - choose randomly or prefer diagonal
		if randf() < 0.5:
			direction.x = sign(diff.x)
		else:
			direction.y = sign(diff.y)
	
	return direction

func get_alternative_directions(target_pos: Vector2i) -> Array[Vector2i]:
	var diff = target_pos - grid_position
	var alternatives: Array[Vector2i] = []
	
	# Add perpendicular directions
	if diff.x != 0:
		alternatives.append(Vector2i(0, 1))
		alternatives.append(Vector2i(0, -1))
	if diff.y != 0:
		alternatives.append(Vector2i(1, 0))
		alternatives.append(Vector2i(-1, 0))
	
	# Add diagonal combinations
	alternatives.append(Vector2i(sign(diff.x), sign(diff.y)))
	
	alternatives.shuffle()
	return alternatives

func can_see_target(target_pos: Vector2i) -> bool:
	# Simple line-of-sight check
	# For now, just check if target is within detection range
	var distance = grid_position.distance_to(target_pos)
	return distance <= detection_range
	
	# TODO: Add proper raycast-based line of sight when you have walls/obstacles

func is_valid_move(new_pos: Vector2i) -> bool:
	# Check if the position is valid for movement
	
	# Get grid manager if available
	var grid_manager = get_grid_manager()
	if grid_manager and grid_manager.is_blocked(new_pos):
		return false
	
	# Check for other actors at this position
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if actor != self and actor.grid_position == new_pos:
			return false
	
	return true

func find_player() -> Actor:
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if actor.is_player():
			return actor
	return null

func get_grid_manager() -> GridManager:
	# Try to find grid manager in scene
	var grid_manager = get_node_or_null("/root/Main/GridManager")
	if not grid_manager:
		grid_manager = get_tree().get_first_node_in_group("grid_managers")
	return grid_manager

# Override the time cost calculation based on enemy type
func get_movement_time_cost() -> int:
	return base_speed

# Override is_valid to check if enemy is still alive/active
func is_valid() -> bool:
	return true  # For now, all enemies are always valid
	# Later you can add health checks, status effects, etc.

# Debug function
func get_ai_state_string() -> String:
	return AIState.keys()[ai_state]
