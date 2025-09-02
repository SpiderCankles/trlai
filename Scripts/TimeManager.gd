# TimeManager.gd - Updated to handle variable actor speeds
class_name TimeManager
extends Node

signal turn_completed(actor)
signal all_turns_processed

# Time constants - adjust these for game balance
const BASE_TIME_UNIT = 100
const TURN_THRESHOLD = 100

var actors: Array[Actor] = []
var current_turn_time: int = 0
var is_processing_turns: bool = false

func _ready():
	set_process(false)

# Register an actor to participate in the turn system
func register_actor(actor: Actor):
	if actor not in actors:
		actors.append(actor)
		actor.time_accumulated = 0
		
		# Add actor to the "actors" group for easy finding
		if not actor.is_in_group("actors"):
			actor.add_to_group("actors")
		
		print("TimeManager: Registered ", actor.name, " (Speed: ", actor.base_speed, ")")

# Remove an actor from the turn system
func unregister_actor(actor: Actor):
	actors.erase(actor)
	if actor.is_in_group("actors"):
		actor.remove_from_group("actors")

# Main turn processing loop
func process_turn():
	print("Starting turn processing")
	if is_processing_turns:
		print("Already processing turns, returning")
		return
		
	is_processing_turns = true
	var loop_count=0
	while true:
		loop_count += 1
		print("Turn loop iteration: ", loop_count)
		
		# Safety break
		if loop_count > 1000:
			print("ERROR: Too many loops - breaking to prevent infinite loop")
			break
			
		# Find the next actor to act
		var next_actor = get_next_actor()
		if not next_actor:
			print("No next actor found")
			break
		print("Next Actor: ", next_actor.name, " (Time: ", next_actor.time_accumulated, ")")
			
		# Advance time to this actor's turn
		var time_to_advance = next_actor.time_accumulated
		advance_global_time(time_to_advance)
		
		# Process the actor's turn
		await process_actor_turn(next_actor)
		
		# Check if we should continue processing
		if should_pause_turn_processing():
			break
	
	is_processing_turns = false
	all_turns_processed.emit()

# Get the actor who should act next (lowest time accumulated)
func get_next_actor() -> Actor:
	var next_actor: Actor = null
	var lowest_time = INF
	
	for actor in actors:
		if not actor.is_valid():  # Skip dead/invalid actors
			continue
			
		if not actor.can_act():  # Skip actors who can't act (e.g., still moving)
			continue
			
		if actor.time_accumulated < lowest_time:
			lowest_time = actor.time_accumulated
			next_actor = actor
	
	return next_actor

# Advance global time and update all actors
func advance_global_time(time_amount: int):
	current_turn_time += time_amount
	
	# Subtract the advanced time from all actors
	for actor in actors:
		actor.time_accumulated -= time_amount

# Process a single actor's turn
func process_actor_turn(actor: Actor) -> void:
	# Reset actor's time accumulation
	actor.time_accumulated = 0
	
	# Let the actor take their turn
	var action = await actor.take_turn()
	
	if action:
		# Execute the action and get its time cost
		var time_cost = await execute_action(actor, action)
		
		# Add time cost to the actor
		actor.time_accumulated += time_cost
	else:
		# No action taken, add base time cost
		actor.time_accumulated += actor.base_speed
	
	print("TimeManager: Signal about to be emitted for ", actor.name)
	turn_completed.emit(actor)
	print("TimeManager: Emitted turn_completed signal for ", actor.name)

# Execute an action and return its time cost
func execute_action(actor: Actor, action: Action) -> int:
	var time_cost: int
	
	# Check if the action supports actor-specific time costs
	if action.has_method("get_time_cost_for_actor"):
		time_cost = action.get_time_cost_for_actor(actor)
	else:
		time_cost = action.get_time_cost()
	
	# Execute the action
	await action.execute(actor)
	
	return time_cost

# Check if we should pause turn processing (e.g., for player input)
func should_pause_turn_processing() -> bool:
	# Pause if it's the player's turn and they need to make a decision
	for actor in actors:
		if actor.is_player() and actor.time_accumulated <= 0:
			return true
	return false

# Utility function to get turn order for UI display
func get_turn_order() -> Array[Actor]:
	var sorted_actors = actors.duplicate()
	sorted_actors.sort_custom(func(a, b): return a.time_accumulated < b.time_accumulated)
	return sorted_actors

# Get estimated turns until an actor acts
func get_turns_until_actor_acts(target_actor: Actor) -> int:
	var turns = 0
	var temp_actors = {}
	
	# Create temporary time states
	for actor in actors:
		temp_actors[actor] = actor.time_accumulated
	
	while temp_actors[target_actor] > 0:
		# Find next actor
		var next_actor = null
		var lowest_time = INF
		
		for actor in temp_actors:
			if temp_actors[actor] < lowest_time:
				lowest_time = temp_actors[actor]
				next_actor = actor
		
		if not next_actor:
			break
			
		# Simulate time advancement
		for actor in temp_actors:
			temp_actors[actor] -= lowest_time
		
		# Add action time cost (use their base speed as default)
		temp_actors[next_actor] += next_actor.base_speed
		turns += 1
		
		if turns > 100:  # Prevent infinite loops
			break
	
	return turns

func can_actor_act(actor: Actor) -> bool:
	if not actor.is_valid():
		return false
		
	if actor.has_method("can_act"):
		return actor.can_act()
		
	return true

# Debug function to print current actor states
func debug_print_actor_states():
	print("=== ACTOR TIME STATES ===")
	for actor in actors:
		print(actor.name, ": ", actor.time_accumulated, " (Speed: ", actor.base_speed, ")")
	print("=========================")
