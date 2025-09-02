# Action.gd - Base class for all actions
class_name Action
extends RefCounted

# Override in derived classes
func get_time_cost() -> int:
	return TimeManager.BASE_TIME_UNIT

func execute(actor: Actor) -> void:
	# Override in derived classes
	pass
