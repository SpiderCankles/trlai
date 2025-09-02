# AttackAction.gd - Example attack action
class_name AttackAction
extends Action

var target: Actor
var weapon_speed_modifier: float = 1.0

func _init(target_actor: Actor, speed_mod: float = 1.0):
	target = target_actor
	weapon_speed_modifier = speed_mod

func get_time_cost() -> int:
	# Attack takes longer than movement
	return int(120 * weapon_speed_modifier)

func execute(actor: Actor) -> void:
	# Execute attack logic
	print("Actor attacks target!")
	# Add damage calculation, animation, etc.extends Action
