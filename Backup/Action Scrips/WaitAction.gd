# WaitAction.gd - Action for waiting/doing nothing
class_name WaitAction
extends Action

var wait_multiplier: float

func _init(multiplier: float = 1.0):
	wait_multiplier = multiplier

func get_time_cost() -> int:
	return int(TimeManager.BASE_TIME_UNIT * wait_multiplier)

func execute(actor: Actor) -> void:
	# Just wait - no additional logic needed
	pass
