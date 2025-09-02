class_name Actor
extends Node

@export var is_player_controlled: bool = false
@export var base_speed: int = 100  # Lower = faster
@export var grid_position: Vector2i = Vector2i.ZERO
@export var cell_size: int = 32
@export var global_position: Vector2 = Vector2.ZERO
@export var move_duration: float = 0.2
@export var move_easing: Tween.EaseType = Tween.EASE_OUT
@export var move_transition: Tween.TransitionType = Tween.TRANS_QUART

var time_accumulated: int = 0
var movement_tween: Tween
var is_moving: bool = false

#screen tearing debuging
var _last_frame_position: Vector2
var _position_changes_this_frame: int = 0

func _process(_delta):
	if get_parent().global_position != _last_frame_position:
		_position_changes_this_frame += 1
		if _position_changes_this_frame > 1:
			print("WARNING: Multiple position changes in one frame!")
	_last_frame_position = get_parent().global_position
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
	# Simple AI - move randomly as an example
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var random_dir = directions[randi() % directions.size()]
	return MoveAction.new(random_dir)
	
func update_visual_position_immeadiate():
	var new_world_position = Vector2(grid_position * cell_size)
	get_parent().global_position = new_world_position
	print("new global position: ", global_position)
	
func update_visual_position_smooth():
	if is_moving:
		print("already moving, skipping animation")
		return # don't start a new animiation if already moving
		
	var target_pos = Vector2(grid_position * cell_size)
	var start_pos = get_parent().global_position
	
	print("=== SMOOTH MOVEMENT DEBUG ===")
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
	
	#animate the move
	
	movement_tween.tween_property(get_parent(), "global_position", target_pos, move_duration)
	movement_tween.tween_callback(func(): print("Tween finished, final position: ", global_position)).set_delay(move_duration)
	
	
	#todo: add move effects
	if is_player_controlled:
		add_movement_effects()
		
	#wait for animation to complete
	await movement_tween.finished
	is_moving = false
	print("Movement Complete, final position: ", get_parent().global_position)
		
	
func add_movement_effects():
	var scale_tween = create_tween()
	scale_tween.set_parallel(true)  # Run parallel to movement tween
	
	# Scale up slightly during movement
	movement_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	scale_tween.tween_property(self, "scale", Vector2(1.1, 1.1), move_duration * 0.3)
	scale_tween.tween_property(self, "scale", Vector2(1.0, 1.0), move_duration * 0.7).set_delay(move_duration * 0.3)
	
	# Optional: Add rotation for more dynamic feel
	# var rotation_tween = create_tween()
	# rotation_tween.set_parallel(true)
	# rotation_tween.tween_property(self, "rotation", deg_to_rad(5), move_duration * 0.5)
	# rotation_tween.tween_property(self, "rotation", 0, move_duration * 0.5).set_delay(move_duration * 0.5)
	
func can_act() -> bool:
	return not is_moving
	
func is_player() -> bool:
	return is_player_controlled

func is_valid() -> bool:
	# Override this to check if actor is alive, active, etc.
	return true
	
func _ready():
	if grid_position == Vector2i.ZERO:
		grid_position = Vector2i(global_position / cell_size)
	
	print("initial grid position: ", grid_position)
	update_visual_position_immeadiate()
