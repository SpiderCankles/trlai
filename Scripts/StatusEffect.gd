# StatusEffect.gd - Base class for status effects
class_name StatusEffect
extends Resource

@export var effect_name: String = "Unknown Effect"
@export var effect_type: String = "generic"  # Used for stacking/removal
@export var duration: int = 3  # Turns remaining
@export var stackable: bool = false
@export var stacks: int = 1

# Override in derived classes
func apply_effect(actor: Actor) -> void:
	pass

func remove_effect(actor: Actor) -> void:
	pass

func process_turn(actor: Actor) -> void:
	pass

# Common status effects

class PoisonEffect extends StatusEffect:
	var damage_per_turn: int = 5
	
	func _init(poison_damage: int = 5, poison_duration: int = 5):
		effect_name = "Poisoned"
		effect_type = "poison"
		duration = poison_duration
		damage_per_turn = poison_damage
		stackable = true
	
	func process_turn(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			var total_damage = damage_per_turn * stacks
			combat_stats.take_damage(total_damage, "poison")
			print(actor.name, " takes ", total_damage, " poison damage!")

class RegenerationEffect extends StatusEffect:
	var heal_per_turn: int = 3
	
	func _init(heal_amount: int = 3, regen_duration: int = 10):
		effect_name = "Regenerating"
		effect_type = "regeneration"
		duration = regen_duration
		heal_per_turn = heal_amount
		stackable = true
	
	func process_turn(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			var total_healing = heal_per_turn * stacks
			combat_stats.heal(total_healing)

class StrengthEffect extends StatusEffect:
	var attack_bonus: int = 5
	
	func _init(bonus: int = 5, strength_duration: int = 8):
		effect_name = "Strengthened"
		effect_type = "strength"
		duration = strength_duration
		attack_bonus = bonus
		stackable = false
	
	func apply_effect(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			combat_stats.base_attack += attack_bonus
	
	func remove_effect(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			combat_stats.base_attack -= attack_bonus

class WeakenedEffect extends StatusEffect:
	var attack_penalty: int = 3
	
	func _init(penalty: int = 3, weakness_duration: int = 6):
		effect_name = "Weakened"
		effect_type = "weakness"
		duration = weakness_duration
		attack_penalty = penalty
		stackable = false
	
	func apply_effect(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			combat_stats.base_attack = max(1, combat_stats.base_attack - attack_penalty)
	
	func remove_effect(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			combat_stats.base_attack += attack_penalty

class SlowedEffect extends StatusEffect:
	var speed_penalty: int = 50
	
	func _init(penalty: int = 50, slow_duration: int = 4):
		effect_name = "Slowed"
		effect_type = "slow"
		duration = slow_duration
		speed_penalty = penalty
		stackable = false
	
	func apply_effect(actor: Actor) -> void:
		actor.base_speed += speed_penalty  # Higher = slower
	
	func remove_effect(actor: Actor) -> void:
		actor.base_speed -= speed_penalty

class HasteEffect extends StatusEffect:
	var speed_bonus: int = 30
	
	func _init(bonus: int = 30, haste_duration: int = 6):
		effect_name = "Hasted"
		effect_type = "haste"
		duration = haste_duration
		speed_bonus = bonus
		stackable = false
	
	func apply_effect(actor: Actor) -> void:
		actor.base_speed = max(10, actor.base_speed - speed_bonus)  # Lower = faster
	
	func remove_effect(actor: Actor) -> void:
		actor.base_speed += speed_bonus

class StunnedEffect extends StatusEffect:
	func _init(stun_duration: int = 2):
		effect_name = "Stunned"
		effect_type = "stun"
		duration = stun_duration
		stackable = false
	
	func apply_effect(actor: Actor) -> void:
		if actor.has_method("set_stunned"):
			actor.set_stunned(true)
	
	func remove_effect(actor: Actor) -> void:
		if actor.has_method("set_stunned"):
			actor.set_stunned(false)

class BleedingEffect extends StatusEffect:
	var bleed_damage: int = 3
	
	func _init(damage: int = 3, bleed_duration: int = 8):
		effect_name = "Bleeding"
		effect_type = "bleeding"
		duration = bleed_duration
		bleed_damage = damage
		stackable = true
	
	func process_turn(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			var total_damage = bleed_damage * stacks
			combat_stats.take_damage(total_damage, "physical")
			print(actor.name, " bleeds for ", total_damage, " damage!")

class ArmorBuffEffect extends StatusEffect:
	var armor_bonus: int = 3
	
	func _init(bonus: int = 3, armor_duration: int = 10):
		effect_name = "Armored"
		effect_type = "armor_buff"
		duration = armor_duration
		armor_bonus = bonus
		stackable = false
	
	func apply_effect(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			combat_stats.armor += armor_bonus
	
	func remove_effect(actor: Actor) -> void:
		var combat_stats = actor.get_combat_stats()
		if combat_stats:
			combat_stats.armor = max(0, combat_stats.armor - armor_bonus)
