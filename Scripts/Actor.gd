# Actor.gd - Enhanced with combat system integration and sprite sheet support
class_name Actor
extends Node2D

@export var is_player_controlled: bool = false
@export var base_speed: int = 100  # Lower = faster
@export var grid_position: Vector2i = Vector2i.ZERO
@export var cell_size: int = 32
@export var move_duration: float = 0.05
@export var move_easing: Tween.EaseType = Tween.EASE_OUT
@export var move_transition: Tween.TransitionType = Tween.TRANS_QUART

# Sprite sheet configuration
@export var sprite_sheet: Texture2D  # Assign your sprite sheet in the editor
@export var sprite_size: Vector2i = Vector2i(32, 32)  # Size of each sprite in the sheet
@export var actor_type: String = "player"  # Type identifier for sprite lookup

var time_accumulated: int = 0
var movement_tween: Tween
var is_moving: bool = false
var is_dead: bool = false
var is_stunned: bool = false

# References to child nodes (will be found automatically)
var sprite_node: Sprite2D
var area_node: Area2D
var combat_stats: CombatStats

# Sprite atlas coordinates for different actor types
var sprite_atlas_coords = {
	# Player types
	"player": Vector2i(0, 0),
	"warrior": Vector2i(1, 0),
	"mage": Vector2i(2, 0),
	"rogue": Vector2i(3, 0),
	
	# Enemy types
	"goblin": Vector2i(7, 7),
	"orc": Vector2i(0, 7),
	"skeleton": Vector2i(0, 11),
	"rat": Vector2i(0, 16),
	"troll": Vector2i(0, 8),
	
	# Default
	"default": Vector2i(0, 0)
}

# Screen tearing debugging
var _last_frame_position: Vector2
var _position_changes_this_frame: int = 0

func _ready():
	# Find sprite and area nodes automatically
	find_child_nodes()
	
	# Find or create combat stats
	setup_combat_stats()
	
	# Set up sprite from sprite sheet
	setup_sprite_from_sheet()
	
	# Initialize grid position if not set
	if grid_position == Vector2i.ZERO:
		grid_position = Vector2i(global_position / cell_size)
		
	setup_actor_inventory()
	
	print("Actor ", name, " ready at grid position: ", grid_position)
	update_visual_position_immediate()

func find_child_nodes():
	# Find sprite node
	sprite_node = find_child("Sprite2D", false, false) as Sprite2D
	if not sprite_node:
		sprite_node = find_child("Sprite", false, false) as Sprite2D
	if not sprite_node:
		sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node:
		sprite_node = get_node_or_null("Sprite")
	
	# Create sprite node if it doesn't exist
	if not sprite_node:
		sprite_node = Sprite2D.new()
		sprite_node.name = "Sprite2D"
		add_child(sprite_node)
	
	# Find area node
	area_node = find_child("Area2D", false, false) as Area2D
	if not area_node:
		area_node = get_node_or_null("Area2D")
	
	print("Actor ", name, " found/created sprite: ", sprite_node, " area: ", area_node)

func setup_sprite_from_sheet():
	"""Set up sprite using sprite sheet or fallback to colored square"""
	if not sprite_node:
		return
		
	# If we have a sprite sheet, use it
	if sprite_sheet:
		sprite_node.texture = sprite_sheet
		sprite_node.region_enabled = true
		update_sprite_region()
		print("Set up sprite sheet for ", actor_type)
	else:
		# Fallback to colored squares if no sprite sheet
		sprite_node.texture = create_fallback_texture()
		sprite_node.region_enabled = false
		print("Using fallback texture for ", actor_type)

func update_sprite_region():
	"""Update sprite region based on actor type"""
	if not sprite_node or not sprite_sheet:
		return
		
	# Get atlas coordinates for this actor type
	var coords = sprite_atlas_coords.get(actor_type.to_lower(), sprite_atlas_coords["default"])
	
	# Calculate pixel position in sprite sheet
	var pixel_x = coords.x * sprite_size.x
	var pixel_y = coords.y * sprite_size.y
	
	sprite_node.region_rect = Rect2(pixel_x, pixel_y, sprite_size.x, sprite_size.y)
	print("Set sprite region for ", actor_type, " to: ", sprite_node.region_rect)

func create_fallback_texture() -> ImageTexture:
	"""Create a colored square fallback texture"""
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	var color: Color
	match actor_type.to_lower():
		# Player colors
		"player", "warrior":
			color = Color.BLUE
		"mage":
			color = Color.CYAN
		"rogue":
			color = Color.DARK_GRAY
			
		# Enemy colors
		"goblin":
			color = Color.GREEN
		"orc":
			color = Color.RED
		"skeleton":
			color = Color.WHITE
		"rat":
			color = Color(0.6, 0.4, 0.2)  # Brown
		"troll":
			color = Color(0.4, 0.2, 0.6)  # Purple
		_:
			color = Color.MAGENTA
	
	image.fill(color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func set_actor_type(new_type: String):
	"""Change actor type and update sprite"""
	actor_type = new_type
	setup_sprite_from_sheet()

func set_sprite_type(type: String):
	"""Alias for set_actor_type - for compatibility"""
	set_actor_type(type)

func set_sprite_animation_state(state: String):
	"""Set visual state for animation (idle, moving, attacking, etc.)"""
	if not sprite_node:
		return
		
	# You can extend this to show different sprites based on state
	# For now, we'll handle basic visual effects
	match state:
		"idle":
			# Reset to normal
			reset_sprite_effects()
		"moving":
			# Could add a subtle highlight or different frame in the future
			reset_sprite_effects()
		"attacking":
			# Brief highlight effect
			if sprite_node:
				var attack_tween = create_tween()
				attack_tween.tween_property(sprite_node, "modulate", Color.YELLOW, 0.1)
				attack_tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.1)
		"hurt":
			# Flash red
			if sprite_node:
				var hurt_tween = create_tween()
				hurt_tween.tween_property(sprite_node, "modulate", Color.RED, 0.1)
				hurt_tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.2)
		"dead":
			# Make semi-transparent
			if sprite_node:
				sprite_node.modulate = Color(1, 1, 1, 0.5)
		"heal":
			# Flash green
			if sprite_node:
				var heal_tween = create_tween()
				heal_tween.tween_property(sprite_node, "modulate", Color.GREEN, 0.1)
				heal_tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.2)

func reset_sprite_effects():
	"""Reset sprite to normal appearance"""
	if sprite_node:
		sprite_node.modulate = Color.WHITE

func setup_combat_stats():
	# Look for existing CombatStats node
	combat_stats = find_child("CombatStats", false, false) as CombatStats
	
	if not combat_stats:
		# Create default combat stats if none exist
		combat_stats = CombatStats.new()
		add_child(combat_stats)
		
		# Set default stats based on actor type
		if is_player_controlled:
			setup_player_combat_stats()
		else:
			setup_enemy_combat_stats()
	
	# Connect combat signals
	if combat_stats and not combat_stats.died.is_connected(_on_combat_death):
		combat_stats.died.connect(_on_combat_death)
		combat_stats.health_changed.connect(_on_health_changed)

func setup_player_combat_stats():
	if not combat_stats:
		return
	
	combat_stats.max_health = 100
	combat_stats.current_health = 100
	combat_stats.base_attack = 12
	combat_stats.attack_variance = 3
	combat_stats.armor = 2
	combat_stats.crit_chance = 0.08
	combat_stats.dodge_chance = 0.12

func setup_enemy_combat_stats():
	if not combat_stats:
		return
	
	# Default enemy stats - override in specific enemy classes
	combat_stats.max_health = 30
	combat_stats.current_health = 30
	combat_stats.base_attack = 8
	combat_stats.attack_variance = 2
	combat_stats.armor = 1
	combat_stats.crit_chance = 0.05
	combat_stats.dodge_chance = 0.08

func _process(_delta):
	# Debug position changes
	if global_position != _last_frame_position:
		_position_changes_this_frame += 1
		if _position_changes_this_frame > 1:
			print("WARNING: Multiple position changes in one frame for ", name)
	_last_frame_position = global_position
	_position_changes_this_frame = 0

# Main turn function - now handles status effects
func take_turn() -> Action:
	# Process status effects at the start of turn
	if combat_stats:
		combat_stats.process_status_effects()
	
	# Check if stunned
	if is_stunned:
		print(name, " is stunned and loses their turn!")
		set_sprite_animation_state("hurt")
		return WaitAction.new()
	
	# Check if dead
	if is_dead:
		return null
	
	if is_player_controlled:
		return await get_player_input()
	else:
		return get_ai_action()

func get_player_input() -> Action:
	print("Actor: Waiting for player input")
	
	var player_controller = get_node("/root/Main/PlayerController")
	
	if player_controller:
		player_controller.start_turn(self)
		print("Actor: Waiting for action_selected signal")
		var action = await player_controller.action_selected
		print("Actor: Received action: ", action)
		return action
	else:
		print("ERROR: PlayerController not found!")
		return WaitAction.new()

func get_ai_action() -> Action:
	# Simple AI - move randomly as an example (override in subclasses)
	set_sprite_animation_state("idle")
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var random_dir = directions[randi() % directions.size()]
	return MoveAction.new(random_dir)

func update_visual_position_immediate():
	var new_world_position = Vector2(grid_position * cell_size)
	global_position = new_world_position
	print("Actor ", name, " immediate position update to: ", global_position)

func update_visual_position_smooth():
	if is_moving:
		print("Actor ", name, " already moving, skipping animation")
		return
	
	var target_pos = Vector2(grid_position * cell_size)
	var start_pos = global_position
	
	if movement_tween:
		movement_tween.kill()
	
	movement_tween = create_tween()
	is_moving = true
	set_sprite_animation_state("moving")
	
	movement_tween.set_ease(move_easing)
	movement_tween.set_trans(move_transition)
	
	movement_tween.tween_property(self, "global_position", target_pos, move_duration)
	movement_tween.tween_callback(func(): print("Tween finished for ", name, ", final position: ", global_position)).set_delay(move_duration)
	
	if is_player_controlled:
		add_movement_effects()
	
	await movement_tween.finished
	is_moving = false
	set_sprite_animation_state("idle")
	print("Movement Complete for ", name, ", final position: ", global_position)

func add_movement_effects():
	if not sprite_node:
		return
	
	var scale_tween = create_tween()
	scale_tween.set_parallel(true)
	
	scale_tween.tween_property(sprite_node, "scale", Vector2(1.1, 1.1), move_duration * 0.3)
	scale_tween.tween_property(sprite_node, "scale", Vector2(1.0, 1.0), move_duration * 0.7).set_delay(move_duration * 0.3)

# Combat-related functions
func get_combat_stats() -> CombatStats:
	return combat_stats

func is_alive() -> bool:
	return not is_dead and (not combat_stats or combat_stats.is_alive())

func can_act() -> bool:
	return not is_moving and not is_dead and not is_stunned

func is_player() -> bool:
	return is_player_controlled

func is_valid() -> bool:
	return not is_dead and is_alive()

func set_dead(dead: bool):
	is_dead = dead
	if is_dead:
		set_sprite_animation_state("dead")
		# Additional death effects
		if sprite_node:
			var death_tween = create_tween()
			death_tween.set_parallel(true)
			death_tween.tween_property(sprite_node, "scale", Vector2(1.2, 1.2), 0.1)
			death_tween.tween_property(sprite_node, "scale", Vector2(0.8, 0.8), 0.3).set_delay(0.1)

func set_stunned(stunned: bool):
	is_stunned = stunned
	if stunned and sprite_node:
		# Visual feedback for stun
		var stun_tween = create_tween()
		stun_tween.set_loops()
		stun_tween.tween_property(sprite_node, "modulate", Color.YELLOW, 0.2)
		stun_tween.tween_property(sprite_node, "modulate", Color.WHITE, 0.2)
	elif not stunned:
		reset_sprite_effects()

# Combat event handlers
func _on_combat_death(dying_actor: Actor):
	print(name, " has died in combat!")
	set_dead(true)
	
	# Drop loot if this is an enemy
	if not is_player_controlled and has_method("drop_loot_on_death"):
		call_deferred("drop_loot_on_death")

func _on_health_changed(old_health: int, new_health: int):
	# Visual feedback for health changes
	if new_health < old_health:
		set_sprite_animation_state("hurt")
	elif new_health > old_health:
		set_sprite_animation_state("heal")

# Get adjacent actors for combat targeting
func get_adjacent_actors() -> Array[Actor]:
	var adjacent: Array[Actor] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
					  Vector2i.UP + Vector2i.LEFT, Vector2i.UP + Vector2i.RIGHT,
					  Vector2i.DOWN + Vector2i.LEFT, Vector2i.DOWN + Vector2i.RIGHT]
	
	var actors = get_tree().get_nodes_in_group("actors")
	
	for direction in directions:
		var check_pos = grid_position + direction
		for actor in actors:
			if actor != self and actor.grid_position == check_pos:
				adjacent.append(actor)
				break
	
	return adjacent

# Get adjacent enemies specifically
func get_adjacent_enemies() -> Array[Actor]:
	var enemies: Array[Actor] = []
	var adjacent = get_adjacent_actors()
	
	for actor in adjacent:
		if actor.is_player() != self.is_player():  # Different team
			enemies.append(actor)
	
	return enemies

# Utility functions for getting visual bounds and center
func get_visual_center() -> Vector2:
	return global_position

func get_visual_bounds() -> Rect2:
	if sprite_node and sprite_node.texture:
		var texture_size = sprite_node.texture.get_size() * sprite_node.scale
		return Rect2(global_position - texture_size / 2, texture_size)
	else:
		return Rect2(global_position - Vector2(16, 16), Vector2(32, 32))
		
# Handling Inventory

func setup_actor_inventory():
	# Create inventory for actors (mainly player, but enemies could have loot)
	
	#create inventory for all actors
	var inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	
	if is_player_controlled:
		inventory.max_slots = 20
		inventory.max_weight = 100.0
		
		# Give player some starting equipment
		call_deferred("give_starting_equipment")
		
	else:
		inventory.max_slots = 5
		inventory.max_weight = 50

func give_starting_equipment():
	var inventory = get_node("Inventory") as Inventory
	if not inventory:
		return
	
	# Create item factory to give starting gear
	var factory = ItemFactory.new()
	
	# Starting weapon
	var starting_weapon = factory.create_weapon("rusty_sword")
	if starting_weapon:
		inventory.add_item(starting_weapon)
		inventory.equip_weapon(starting_weapon)
	
	# Starting healing item
	var healing_potion = factory.create_consumable("health_potion")
	if healing_potion:
		inventory.add_item(healing_potion, 3)  # Give 3 potions

# Debug function to print actor state
func debug_print_state():
	print("=== ACTOR DEBUG: ", name, " ===")
	print("Grid Position: ", grid_position)
	print("Global Position: ", global_position)
	print("Is Moving: ", is_moving)
	print("Is Player: ", is_player_controlled)
	print("Actor Type: ", actor_type)
	print("Base Speed: ", base_speed)
	print("Time Accumulated: ", time_accumulated)
	print("Is Dead: ", is_dead)
	print("Is Stunned: ", is_stunned)
	if combat_stats:
		print("Health: ", combat_stats.current_health, "/", combat_stats.max_health)
		print("Attack: ", combat_stats.base_attack, " (±", combat_stats.attack_variance, ")")
		print("Armor: ", combat_stats.armor)
	print("Sprite Node: ", sprite_node)
	if sprite_node:
		print("  Sprite Position: ", sprite_node.global_position)
		print("  Sprite Scale: ", sprite_node.scale)
		print("  Sprite Modulate: ", sprite_node.modulate)
		print("  Sprite Sheet: ", sprite_sheet)
		if sprite_node.region_enabled:
			print("  Sprite Region: ", sprite_node.region_rect)
	print("===========================")
