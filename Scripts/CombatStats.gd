# CombatStats.gd - Component for handling combat-related statistics
class_name CombatStats
extends Node

signal health_changed(old_health: int, new_health: int)
signal died(actor: Actor)
signal took_damage(actor:Actor, amount: int, damage_type: String)
signal dealt_damage(target: Actor, amount: int, damage_type: String)

# Core stats
@export var max_health: int = 100
@export var current_health: int = 100
@export var armor: int = 0
@export var dodge_chance: float = 0.1  # 10% base dodge chance

# Attack stats
@export var base_attack: int = 10
@export var attack_variance: int = 3  # +/- variance in damage
@export var crit_chance: float = 0.05  # 5% base crit chance
@export var crit_multiplier: float = 2.0

# Damage resistances/weaknesses (0.0 = immune, 1.0 = normal, 2.0 = double damage)
var damage_resistances: Dictionary = {
	"physical": 1.0,
	"fire": 1.0,
	"ice": 1.0,
	"poison": 1.0,
	"magic": 1.0
}

# Status effects
var status_effects: Array[StatusEffect] = []

# Reference to owner actor
var owner_actor: Actor

func _ready():
	current_health = max_health
	owner_actor = get_parent() as Actor
	
	# Ensure we don't exceed max health
	current_health = min(current_health, max_health)

# Take damage and return actual damage dealt
func take_damage(amount: int, damage_type: String = "physical", attacker: Actor = null) -> int:
	if is_dead():
		return 0
	
	# Check for dodge
	if randf() < dodge_chance:
		print(owner_actor.name, " dodged the attack!")
		return 0
	
	# Apply damage resistance
	var resistance = damage_resistances.get(damage_type, 1.0)
	var modified_damage = int(amount * resistance)
	
	# Apply armor reduction (only for physical damage)
	if damage_type == "physical":
		modified_damage = max(1, modified_damage - armor)  # Always at least 1 damage
	
	# Apply damage
	var old_health = current_health
	current_health = max(0, current_health - modified_damage)
	
	print(owner_actor.name, " takes ", modified_damage, " ", damage_type, " damage (", old_health, " -> ", current_health, ")")
	
	# Emit signals
	health_changed.emit(old_health, current_health)
	took_damage.emit(owner_actor, modified_damage, damage_type)
	
	# Check for death
	if current_health <= 0:
		die()
	
	return modified_damage

# Heal and return actual healing done
func heal(amount: int) -> int:
	if is_dead():
		return 0
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var healing_done = current_health - old_health
	
	if healing_done > 0:
		print(owner_actor.name, " heals for ", healing_done, " HP (", old_health, " -> ", current_health, ")")
		health_changed.emit(old_health, current_health)
	
	return healing_done

# Perform an attack on a target
func attack(target: Actor, weapon_damage: int = 0, damage_type: String = "physical") -> Dictionary:
	var result = {
		"hit": false,
		"damage": 0,
		"critical": false,
		"dodged": false
	}
	
	if not target or not target.has_method("get_combat_stats"):
		return result
	
	var target_stats = target.get_combat_stats()
	if not target_stats:
		return result
	
	# Calculate damage
	var total_damage = base_attack + weapon_damage
	total_damage += randi_range(-attack_variance, attack_variance)
	
	# Check for critical hit
	var is_critical = randf() < crit_chance
	if is_critical:
		total_damage = int(total_damage * crit_multiplier)
		result.critical = true
		print("CRITICAL HIT!")
	
	# Deal damage to target
	var damage_dealt = target_stats.take_damage(total_damage, damage_type, owner_actor)
	
	result.hit = damage_dealt > 0
	result.damage = damage_dealt
	result.dodged = total_damage > 0 and damage_dealt == 0
	
	if damage_dealt > 0:
		dealt_damage.emit(target, damage_dealt, damage_type)
	
	return result

# Handle death
func die():
	print(owner_actor.name, " has died!")
	died.emit(owner_actor)
	
	# Remove from actor groups and time system
	if owner_actor.is_in_group("actors"):
		owner_actor.remove_from_group("actors")
	
	# Unregister from time manager
	var time_manager = get_tree().get_first_node_in_group("time_managers")
	if not time_manager:
		time_manager = get_node_or_null("/root/Main/TimeManager")
	if time_manager and time_manager.has_method("unregister_actor"):
		time_manager.unregister_actor(owner_actor)
	
	# Mark as invalid
	if owner_actor.has_method("set_dead"):
		owner_actor.set_dead(true)

# Status effect management
func add_status_effect(effect: StatusEffect):
	# Check if we already have this effect type
	for existing_effect in status_effects:
		if existing_effect.effect_type == effect.effect_type:
			# Refresh duration or stack if stackable
			if effect.stackable:
				existing_effect.stacks += 1
			existing_effect.duration = effect.duration
			return
	
	# Add new effect
	status_effects.append(effect)
	effect.apply_effect(owner_actor)
	print(owner_actor.name, " gains ", effect.effect_name)

func remove_status_effect(effect_type: String):
	for i in range(status_effects.size() - 1, -1, -1):
		var effect = status_effects[i]
		if effect.effect_type == effect_type:
			effect.remove_effect(owner_actor)
			status_effects.remove_at(i)
			print(owner_actor.name, " loses ", effect.effect_name)

# Process status effects each turn
func process_status_effects():
	for i in range(status_effects.size() - 1, -1, -1):
		var effect = status_effects[i]
		effect.process_turn(owner_actor)
		
		effect.duration -= 1
		if effect.duration <= 0:
			effect.remove_effect(owner_actor)
			status_effects.remove_at(i)
			print(owner_actor.name, " recovers from ", effect.effect_name)

# Utility functions
func is_dead() -> bool:
	return current_health <= 0

func is_alive() -> bool:
	return current_health > 0

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_at_full_health() -> bool:
	return current_health >= max_health

func has_status_effect(effect_type: String) -> bool:
	for effect in status_effects:
		if effect.effect_type == effect_type:
			return true
	return false

# Get damage output for UI/debugging
func get_damage_range() -> Array[int]:
	var min_damage = base_attack - attack_variance
	var max_damage = base_attack + attack_variance
	return [max(1, min_damage), max(1, max_damage)]

# Modify stats temporarily (for equipment, spells, etc.)
func modify_stat(stat_name: String, modifier: int, duration: int = -1):
	# This could be expanded for temporary stat modifications
	match stat_name:
		"attack":
			base_attack += modifier
		"armor":
			armor += modifier
		"max_health":
			max_health += modifier
			if modifier > 0:  # If increasing max health, also heal
				current_health += modifier

# Debug function
func debug_print_stats():
	print("=== COMBAT STATS: ", owner_actor.name, " ===")
	print("Health: ", current_health, "/", max_health)
	print("Attack: ", base_attack, " (±", attack_variance, ")")
	print("Armor: ", armor)
	print("Crit: ", crit_chance * 100, "% (", crit_multiplier, "x)")
	print("Dodge: ", dodge_chance * 100, "%")
	print("Status Effects: ", status_effects.size())
	for effect in status_effects:
		print("  - ", effect.effect_name, " (", effect.duration, " turns)")
	print("=============================")
