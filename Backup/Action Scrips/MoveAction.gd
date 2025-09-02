# MoveAction.gd - Updated to use actor's speed
class_name MoveAction
extends Action

var direction: Vector2i

func _init(dir: Vector2i):
	direction = dir

func get_time_cost() -> int:
	# This will be overridden by execute() to use the actor's speed
	return 100

func execute(actor: Actor) -> void:
	print("MoveAction Executing move action, direction: ", direction)
	print("MoveAction Current grid position: ", actor.grid_position)
	
	# Update grid position
	actor.grid_position += direction
	print("MoveAction New grid position: ", actor.grid_position)
	
	# Update visual position
	print("MoveAction calling update_visual_position_smooth")
	await actor.update_visual_position_smooth()
	print("MoveAction Visual position updated. Actor moved to ", actor.grid_position)

# Override get_time_cost to use the actor's base_speed when we have access to it
func get_time_cost_for_actor(actor: Actor) -> int:
	return actor.base_speed
