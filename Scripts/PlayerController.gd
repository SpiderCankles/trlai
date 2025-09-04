# PlayerController.gd - Enhanced with combat controls and targeting
class_name PlayerController
extends Node

signal action_selected(action: Action)

var current_actor: Actor
var is_waiting_for_input: bool = false
var grid_manager: GridManager
var is_targeting_mode: bool = false
var target_cursor_position: Vector2i
var potential_targets: Array[Actor] = []
var selected_target_index: int = 0
var inventory_ui: InventoryUI

# Input mapping for movement
var movement_inputs = {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN, 
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
	"move_up_left": Vector2i.UP + Vector2i.LEFT,
	"move_up_right": Vector2i.UP + Vector2i.RIGHT,
	"move_down_left": Vector2i.DOWN + Vector2i.LEFT,
	"move_down_right": Vector2i.DOWN + Vector2i.RIGHT
}

func _ready():
	print("Player Controller Ready")
	
	var time_manager = get_node("../TimeManager")
	if time_manager:
		print("Found Time Manager at: ", time_manager.get_path())
		var result = time_manager.turn_completed.connect(_on_turn_completed)
		print("Signal connection result: ", result)
	else:
		print("TimeManager not found, trying absolute path")
		time_manager = get_node("/root/Main/TimeManager")
		if time_manager:
			print("Found TimeManager at absolute path")
			time_manager.turn_completed.connect(_on_turn_completed)
	
	#setting up grid manager
	grid_manager = get_node("../GridManager")
	
	#set up inventory UI
	setup_inventory_ui()

func _unhandled_input(event):
	if not is_waiting_for_input or not current_actor:
		return
		
	if current_actor.has_method("can_act") and not current_actor.can_act():
		return
	
	if event.is_pressed():
		var action = process_input(event)
		if action:
			action_selected.emit(action)

func process_input(event: InputEvent) -> Action:
	#print("=== PROCESSING INPUT ===")
	#print("Event type: ", event.get_class())
	#print("Targeting mode: ", is_targeting_mode)
	
	# Handle targeting mode
	if is_targeting_mode:
		return handle_targeting_input(event)
	
	# Wait action
	if Input.is_action_just_pressed("wait"):
		return WaitAction.new()
	
	# Attack action - enter targeting mode
	if Input.is_action_just_pressed("attack"):
		return enter_targeting_mode()
	
	# Interact/use items
	if Input.is_action_just_pressed("interact"):
		return handle_interact_input()
	
	# Auto-attack adjacent enemies
	if Input.is_action_just_pressed("auto_attack"):
		return handle_auto_attack()
	
	# Show combat stats
	if Input.is_action_just_pressed("show_stats"):
		show_combat_info()
		return null
		
		# Open inventory
	if Input.is_action_just_pressed("open_inventory"):
		open_inventory()
		return null
	
	# Pick up items
	if Input.is_action_just_pressed("pickup"):
		return handle_pickup_input()
	
	# Drop items (could be implemented later)
	if Input.is_action_just_pressed("drop"):
		return handle_drop_input()
	
	# Movement inputs
	for input_name in movement_inputs:
		if Input.is_action_just_pressed(input_name):
			#print("Movement input detected: ", input_name)
			var direction = movement_inputs[input_name]
			
			# Check if there's an enemy in that direction for auto-attack
			var target_pos = current_actor.grid_position + direction
			var enemy_at_target = get_enemy_at_position(Vector2(target_pos))
			#print("&&&&&&&&Current pos: ", current_actor.grid_position, "&&&&&&&&" )
			#print("&&&&&&&&Target POS: ", target_pos, "&&&&&&&&" )
			#print("&&&&&&&&Enemy at Target: ", enemy_at_target, "&&&&&&&&" )
			#print("Input.is_action_pressed(attack_modifier) ", Input.is_action_pressed("attack_modifier"))
			#print("can_move_to(current_actor.grid_position, direction) ", can_move_to(current_actor.grid_position, direction))
			
			if enemy_at_target and Input.is_action_pressed("attack_modifier"):
				# Attack instead of move if holding attack modifier
				return AttackAction.new(enemy_at_target)
			elif can_move_to(current_actor.grid_position, direction):
				return MoveAction.new(direction)
			else:
				# Can't move there - maybe there's an enemy to auto-attack?
				if enemy_at_target:
					return AttackAction.new(enemy_at_target)
				else:
					return WaitAction.new(0.1)  # Short wait for invalid moves
	
	return null

func enter_targeting_mode() -> Action:
	print("Entering targeting mode")
	is_targeting_mode = true
	
	# Find all potential targets (adjacent enemies)
	potential_targets = current_actor.get_adjacent_enemies()
	
	if potential_targets.is_empty():
		print("No adjacent enemies to attack")
		is_targeting_mode = false
		return WaitAction.new(0.1)
	
	# Start with first target
	selected_target_index = 0
	target_cursor_position = potential_targets[0].grid_position
	
	print("Found ", potential_targets.size(), " potential targets")
	print("Current target: ", potential_targets[0].name, " at ", target_cursor_position)
	
	# Show targeting UI (you'd implement this)
	show_targeting_ui()
	
	return null  # Don't return an action yet, wait for target selection

func handle_targeting_input(event: InputEvent) -> Action:
	print("Handling targeting input")
	
	# Confirm target
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("ui_accept"):
		var target = potential_targets[selected_target_index]
		print("Target selected: ", target.name)
		exit_targeting_mode()
		return AttackAction.new(target)
	
	# Cancel targeting
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("wait"):
		print("Targeting cancelled")
		exit_targeting_mode()
		return null
	
	# Cycle through targets
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		cycle_target(-1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		cycle_target(1)
	elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
		cycle_target(-1)
	elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
		cycle_target(1)
	
	return null

func cycle_target(direction: int):
	if potential_targets.is_empty():
		return
	
	selected_target_index = (selected_target_index + direction) % potential_targets.size()
	if selected_target_index < 0:
		selected_target_index = potential_targets.size() - 1
	
	target_cursor_position = potential_targets[selected_target_index].grid_position
	print("Target cycled to: ", potential_targets[selected_target_index].name, " at ", target_cursor_position)
	
	# Update targeting UI
	update_targeting_ui()

func exit_targeting_mode():
	is_targeting_mode = false
	potential_targets.clear()
	selected_target_index = 0
	hide_targeting_ui()

func handle_auto_attack() -> Action:
	print("Auto-attack requested")
	var adjacent_enemies = current_actor.get_adjacent_enemies()
	
	if adjacent_enemies.is_empty():
		print("No adjacent enemies for auto-attack")
		return WaitAction.new(0.1)
	
	# Attack the first adjacent enemy
	var target = adjacent_enemies[0]
	print("Auto-attacking: ", target.name)
	return AttackAction.new(target)

func handle_interact_input() -> Action:
	# Check for items, doors, etc. at current position or adjacent
	print("Interact action - checking surroundings")
	
	# Look for interactable objects
	var interactables = get_interactables_nearby()
	if not interactables.is_empty():
		# For now, just interact with the first one
		print("Found interactable: ", interactables[0])
		# Return appropriate interaction action when implemented
	
	return WaitAction.new(0.1)

func show_combat_info():
	print("=== COMBAT INFORMATION ===")
	if current_actor and current_actor.get_combat_stats():
		current_actor.get_combat_stats().debug_print_stats()
	
	# Show adjacent enemies info
	var adjacent_enemies = current_actor.get_adjacent_enemies()
	if not adjacent_enemies.is_empty():
		print("Adjacent Enemies:")
		for enemy in adjacent_enemies:
			var enemy_stats = enemy.get_combat_stats()
			if enemy_stats:
				print("  ", enemy.name, ": ", enemy_stats.current_health, "/", enemy_stats.max_health, " HP")
	else:
		print("No adjacent enemies")
	print("==========================")

func show_targeting_ui():
	# This would show visual targeting indicators
	# For now, just print debug info
	print("TARGETING UI: Select target with arrow keys, confirm with attack/enter, cancel with wait/escape")
	if not potential_targets.is_empty():
		print("Current target: ", potential_targets[selected_target_index].name)

func update_targeting_ui():
	# Update visual targeting indicators
	if not potential_targets.is_empty():
		print("Target updated to: ", potential_targets[selected_target_index].name)

func hide_targeting_ui():
	# Hide visual targeting indicators
	print("TARGETING UI: Hidden")

func get_interactables_nearby() -> Array:
	# Look for interactable objects nearby
	# This would be expanded when you add items, doors, etc.
	var interactables = []
	
	# Check current position and adjacent positions for items/objects
	var positions_to_check = [current_actor.grid_position]
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for dir in directions:
		positions_to_check.append(current_actor.grid_position + dir)
	
	# You'd implement item/object detection here
	
	return interactables

# Check if movement to a position is valid
func can_move_to(current_pos: Vector2, direction: Vector2i) -> bool:
	
	#print("grid manager? ", grid_manager)
	if not grid_manager:
		#print("if not grid_manager (should be false) ", not grid_manager)
		return true
		
	var target_pos = Vector2i(current_pos) + direction
	
	#print("In bounds? ", grid_manager.is_in_bounds(target_pos))
	if not grid_manager.is_in_bounds(target_pos):
		#print("not grid_manager.is_in_bounds(target_pos) ", not grid_manager.is_in_bounds(target_pos))
		return false
	
	#print("Is blocked? ", grid_manager.is_blocked(target_pos))
	if grid_manager.is_blocked(target_pos):
		#print("grid_manager.is_blocked(target_pos) ", grid_manager.is_blocked(target_pos))
		return false
		
	#print("actor at target pos? ", get_actor_at_position(Vector2(target_pos)))
	if get_actor_at_position(Vector2(target_pos)):
		
		return false
	
	var tilemap_renderer = get_node("/root/Main/TileMapRenderer")
	
	#print("blocked by tilemap_renderer? ", tilemap_renderer.is_blocked_at(target_pos))
	#if tilemap_renderer and tilemap_renderer.is_blocked_at(target_pos):
		#return false
	
	#print("all bypassed, returing true")
	return true

# Get enemy at a specific position
func get_enemy_at_position(pos: Vector2) -> Actor:
	#print("====Testing Actors Enemy at pos===")
	var actors = get_tree().get_nodes_in_group("actors")
	#print("List of actors: ", actors)
	for actor in actors:
		#print("testing specific actor ", actor, "Current actor: ", current_actor)
		
		#print("Vector2i(actor.global_position) ",Vector2i(global_position_to_tile_position(actor.global_position)))
		#print("Vector2i(pos) ", Vector2i(pos))
		#print("Vector2i(actor.global_position) == Vector2i(pos) ", Vector2i(actor.global_position) == Vector2i(pos))
		if actor != current_actor and Vector2i(global_position_to_tile_position(actor.global_position)) == Vector2i(pos):
			#print("Testing actor ", actor, "Position: ", Vector2i(actor.global_position))
			if not actor.is_player():
				return actor
	return null

# Get any actor at a specific position
func get_actor_at_position(pos: Vector2) -> Actor:
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if Vector2i(global_position_to_tile_position(actor.global_position)) == Vector2i(pos):
			return actor
	return null

# Get attack preview for UI feedback
func get_attack_preview(attacker: Actor, target: Actor) -> Dictionary:
	var preview = {
		"can_attack": false,
		"hit_chance": 0.0,
		"damage_range": [0, 0],
		"will_kill": false
	}
	
	if not attacker or not target:
		return preview
	
	var attacker_stats = attacker.get_combat_stats()
	var target_stats = target.get_combat_stats()
	
	if not attacker_stats or not target_stats:
		return preview
	
	# Check if adjacent
	var distance = attacker.grid_position.distance_to(target.grid_position)
	preview.can_attack = distance <= 1
	
	if preview.can_attack:
		# Calculate hit chance (100% - dodge chance)
		preview.hit_chance = 1.0 - target_stats.dodge_chance
		
		# Calculate damage range
		var base_damage = attacker_stats.base_attack
		var min_damage = base_damage - attacker_stats.attack_variance
		var max_damage = base_damage + attacker_stats.attack_variance
		
		# Factor in armor for physical damage
		min_damage = max(1, min_damage - target_stats.armor)
		max_damage = max(1, max_damage - target_stats.armor)
		
		preview.damage_range = [min_damage, max_damage]
		
		# Check if attack could kill
		preview.will_kill = min_damage >= target_stats.current_health
	
	return preview

# Called when it's this actor's turn
func start_turn(actor: Actor):
	print("PlayerController: Starting turn for ", actor.name)
	current_actor = actor
	is_waiting_for_input = true
	
	# Reset any targeting mode from previous turn
	if is_targeting_mode:
		exit_targeting_mode()
	
	# Show turn start info
	if actor.get_combat_stats():
		var stats = actor.get_combat_stats()
		print("Turn started - HP: ", stats.current_health, "/", stats.max_health)
		
		# Check for low health warning
		if stats.get_health_percentage() < 0.3:
			print("WARNING: Low health!")
	
	print("PlayerController: Now waiting for input")

# Called when turn is completed
func _on_turn_completed(actor: Actor):
	print("PlayerController: _on_turn_completed called for: ", actor.name)
	
	if actor == current_actor:
		is_waiting_for_input = false
		
		# Exit targeting mode if still active
		if is_targeting_mode:
			exit_targeting_mode()
		
		print("PlayerController: Reset complete - ready for next turn")

# Enhanced Actor.gd integration functions (add these to your existing Actor.gd)
# These would go in the Actor.gd file:

# In Actor.gd, modify the get_player_input function:
func get_player_input() -> Action:
	var player_controller = get_node("../PlayerController")
	
	if player_controller:
		player_controller.start_turn(self)
		var action = await player_controller.action_selected
		return action
	
	return WaitAction.new()
	
#convert global position to tile position

func global_position_to_tile_position(pos: Vector2) -> Vector2:
	return pos/32

# Inventory Helper functions

func setup_inventory_ui():
	# Create inventory UI
	inventory_ui = InventoryUI.new()
	get_tree().current_scene.add_child.call_deferred(inventory_ui)
	inventory_ui.close_inventory.connect(_on_inventory_closed)
	
func _on_inventory_closed():
	is_waiting_for_input = true  # Resume turn processing when inventory closes
	
func open_inventory():
	if not current_actor:
		return
		
	var inventory = current_actor.get_node("Inventory") as Inventory
	if inventory and inventory_ui:
		inventory_ui.setup_inventory(inventory)
		inventory_ui.show_inventory()
		is_waiting_for_input = false  # Pause turn processing

func handle_pickup_input() -> Action:
	if not current_actor:
		return WaitAction.new()
	
	# Look for world items at current position or adjacent
	var positions_to_check = [current_actor.global_position]
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for dir in directions:
		var check_pos = current_actor.global_position + Vector2(dir * 32)  # Assuming 32px cells
		positions_to_check.append(check_pos)
	
	var world_items = get_tree().get_nodes_in_group("world_items")
	for world_item in world_items:
		for pos in positions_to_check:
			if world_item.global_position.distance_to(pos) < 32:
				world_item.try_pickup(current_actor)
				return WaitAction.new(0.5)  # Small time cost for picking up
	
	print("No items nearby to pick up")
	return WaitAction.new(0.1)

func handle_drop_input() -> Action:
	# This could open a drop item dialog
	print("Drop item functionality not yet implemented")
	return WaitAction.new(0.1)
