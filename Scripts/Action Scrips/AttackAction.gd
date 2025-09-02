# AttackAction.gd - Enhanced attack action with proper combat system integration
class_name AttackAction
extends Action

var target: Actor
var weapon_speed_modifier: float = 1.0
var weapon_damage_bonus: int = 0
var damage_type: String = "physical"

func _init(target_actor: Actor, speed_mod: float = 1.0, damage_bonus: int = 0, dmg_type: String = "physical"):
	target = target_actor
	weapon_speed_modifier = speed_mod
	weapon_damage_bonus = damage_bonus
	damage_type = dmg_type

func get_time_cost() -> int:
	# Attack takes longer than movement, modified by weapon speed
	return int(120 * weapon_speed_modifier)

func execute(actor: Actor) -> void:
	if not target or not target.is_valid():
		print("Invalid target for attack!")
		return
	
	# Get attacker's combat stats
	var attacker_stats = actor.get_combat_stats()
	if not attacker_stats:
		print("Attacker has no combat stats!")
		return
	
		# Get equipped weapon stats
	var inventory = actor.get_node("Inventory") as Inventory
	var weapon_damage = weapon_damage_bonus
	var attack_speed = weapon_speed_modifier
	var attack_damage_type = damage_type
	
	if inventory and inventory.equipped_weapon:
		var weapon = inventory.equipped_weapon
		weapon_damage += weapon.damage_bonus
		attack_speed *= weapon.attack_speed_modifier
		if weapon.damage_type != "physical":
			attack_damage_type = weapon.damage_type
	
	# Check if target is adjacent
	var distance = actor.grid_position.distance_to(target.grid_position)
	if distance > 1:
		print("Target is too far away to attack!")
		return
	
	print("=== COMBAT ===")
	print(actor.name, " attacks ", target.name)
	
	# Perform the attack
	var attack_result = attacker_stats.attack(target, weapon_damage_bonus, damage_type)
	
	# Display results
	if attack_result.dodged:
		print(target.name, " dodged the attack!")
	elif attack_result.hit:
		var damage_text = str(attack_result.damage) + " damage"
		if attack_result.critical:
			damage_text += " (CRITICAL!)"
		print(actor.name, " deals ", damage_text, " to ", target.name)
		
		# Add visual effects or animations here
		create_combat_effects(actor, target, attack_result)
	else:
		print(actor.name, " missed ", target.name)
	
	print("==============")

# Create visual/audio feedback for combat
func create_combat_effects(attacker: Actor, defender: Actor, result: Dictionary):
	# This is where you'd add particle effects, screen shake, damage numbers, etc.
	
	# Simple position-based effect for now
	if result.hit:
		create_hit_effect(defender.global_position, result.damage, result.critical)
	
	# Screen shake for critical hits
	if result.critical:
		create_screen_shake()

func create_hit_effect(position: Vector2, damage: int, is_critical: bool):
	# You could create a damage number popup here
	# For now, just print the effect
	var effect_text = str(damage)
	if is_critical:
		effect_text += "!"
	print("Hit effect at ", position, ": ", effect_text)

func create_screen_shake():
	# Add screen shake effect for dramatic impact
	#var camera = get_viewport().get_camera_2d()
	#if camera and camera.has_method("add_trauma"):
		#camera.add_trauma(0.3)
		return

# Check if the attack can be performed
func can_execute(actor: Actor) -> bool:
	if not target or not target.is_valid():
		return false
	
	# Check range
	var distance = actor.grid_position.distance_to(target.grid_position)
	if distance > 1:
		return false
	
	# Check if attacker has combat stats
	if not actor.get_combat_stats():
		return false
	
	return true

# Get preview information for UI
func get_attack_preview(actor: Actor) -> Dictionary:
	var preview = {
		"can_attack": false,
		"hit_chance": 0.0,
		"damage_range": [0, 0],
		"distance": 999
	}
	
	if not target or not target.is_valid():
		return preview
	
	var attacker_stats = actor.get_combat_stats()
	var target_stats = target.get_combat_stats()
	
	if not attacker_stats or not target_stats:
		return preview
	
	preview.distance = actor.grid_position.distance_to(target.grid_position)
	preview.can_attack = preview.distance <= 1
	
	if preview.can_attack:
		# Calculate hit chance (100% - target dodge chance)
		preview.hit_chance = 1.0 - target_stats.dodge_chance
		
		# Calculate damage range
		var base_damage = attacker_stats.base_attack + weapon_damage_bonus
		var min_damage = base_damage - attacker_stats.attack_variance
		var max_damage = base_damage + attacker_stats.attack_variance
		
		# Factor in armor for physical damage
		if damage_type == "physical":
			min_damage = max(1, min_damage - target_stats.armor)
			max_damage = max(1, max_damage - target_stats.armor)
		
		# Factor in resistances
		var resistance = target_stats.damage_resistances.get(damage_type, 1.0)
		min_damage = int(min_damage * resistance)
		max_damage = int(max_damage * resistance)
		
		preview.damage_range = [max(1, min_damage), max(1, max_damage)]
	
	return preview
