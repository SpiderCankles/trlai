# EnemyActor.gd - Enhanced with combat AI, sprite sheet support, and different combat stats per enemy type
class_name EnemyActor
extends Actor

# Enemy-specific properties
@export var enemy_type: String = "goblin"
@export var detection_range: int = 6
@export var max_chase_distance: int = 15
@export var aggression: float = 0.8
@export var wander_chance: float = 0.3

# Sprite sheet configuration
#@export var sprite_sheet: Texture2D  # Assign your sprite sheet in the editor
#@export var sprite_size: Vector2i = Vector2i(32, 32)  # Size of each sprite in the sheet

# Sprite atlas coordinates for different enemy types (x, y positions in grid)
#var sprite_atlas_coords = {
	#"goblin": Vector2i(0, 0),
	#"orc": Vector2i(1, 0),
	#"skeleton": Vector2i(2, 0),
	#"rat": Vector2i(3, 0),
	#"troll": Vector2i(0, 1),
	#"default": Vector2i(4, 0)
#}

# AI state
enum AIState { IDLE, WANDERING, CHASING, LOST, COMBAT }
var ai_state: AIState = AIState.IDLE
var last_known_player_position: Vector2i = Vector2i(-999, -999)
var turns_since_player_seen: int = 0
var wander_direction: Vector2i = Vector2i.ZERO
var wander_steps_remaining: int = 0

# Sprite references
#var sprite_node: Sprite2D

func _ready():
	super._ready()
	is_player_controlled = false
	setup_sprite()
	setup_enemy_stats()
	print("Enemy ready: ", enemy_type, " at ", grid_position)

func setup_sprite():
	# Find or create sprite node
	sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node:
		sprite_node = get_node_or_null("Sprite")
		
	if not sprite_node:
		# Create sprite node if it doesn't exist
		sprite_node = Sprite2D.new()
		sprite_node.name = "Sprite2D"
		add_child(sprite_node)
		
	# Configure sprite with appropriate region from sprite sheet
	update_sprite_for_enemy_type()

func update_sprite_for_enemy_type():
	if not sprite_node:
		return
		
	# If we have a sprite sheet, use it
	if sprite_sheet:
		sprite_node.texture = sprite_sheet
		sprite_node.region_enabled = true
		
		# Get atlas coordinates for this enemy type
		var coords = sprite_atlas_coords.get(enemy_type.to_lower(), sprite_atlas_coords["default"])
		
		# Calculate pixel position in sprite sheet
		var pixel_x = coords.x * sprite_size.x
		var pixel_y = coords.y * sprite_size.y
		
		sprite_node.region_rect = Rect2(pixel_x, pixel_y, sprite_size.x, sprite_size.y)
		
		print("Set sprite region for ", enemy_type, " to: ", sprite_node.region_rect)
	else:
		# Fallback to colored squares if no sprite sheet
		sprite_node.texture = create_fallback_texture()
		sprite_node.region_enabled = false

func create_fallback_texture() -> ImageTexture:
	# Fallback colored squares (same as before)
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	var color: Color
	match enemy_type.to_lower():
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

# Function to change enemy type dynamically
func set_enemy_type(new_type: String):
	enemy_type = new_type
	update_sprite_for_enemy_type()
	setup_enemy_stats()

func setup_enemy_stats():
	# Set different stats based on enemy type
	match enemy_type.to_lower():
		"goblin":
			base_speed = 120
			detection_range = 6
			aggression = 0.8
			setup_goblin_combat()
		"orc":
			base_speed = 140
			detection_range = 5
			aggression = 0.9
			setup_orc_combat()
		"skeleton":
			base_speed = 110
			detection_range = 7
			aggression = 0.7
			setup_skeleton_combat()
		"rat":
			base_speed = 80
			detection_range = 4
			aggression = 0.6
			setup_rat_combat()
		"troll":
			base_speed = 160
			detection_range = 4
			aggression = 0.95
			setup_troll_combat()
		_:
			base_speed = 120
			detection_range = 5
			aggression = 0.7
			setup_default_combat()

func setup_goblin_combat():
	if combat_stats:
		combat_stats.max_health = 25
		combat_stats.current_health = 25
		combat_stats.base_attack = 6
		combat_stats.attack_variance = 2
		combat_stats.armor = 0
		combat_stats.crit_chance = 0.1
		combat_stats.dodge_chance = 0.15
		combat_stats.damage_resistances = {
			"physical": 1.0,
			"fire": 1.2,
			"ice": 0.8,
			"poison": 1.1,
			"magic": 1.0
		}

func setup_orc_combat():
	if combat_stats:
		combat_stats.max_health = 45
		combat_stats.current_health = 45
		combat_stats.base_attack = 12
		combat_stats.attack_variance = 3
		combat_stats.armor = 3
		combat_stats.crit_chance = 0.08
		combat_stats.dodge_chance = 0.05
		combat_stats.damage_resistances = {
			"physical": 0.9,
			"fire": 1.1,
			"ice": 1.0,
			"poison": 0.8,
			"magic": 1.2
		}

func setup_skeleton_combat():
	if combat_stats:
		combat_stats.max_health = 20
		combat_stats.current_health = 20
		combat_stats.base_attack = 8
		combat_stats.attack_variance = 2
		combat_stats.armor = 1
		combat_stats.crit_chance = 0.15
		combat_stats.dodge_chance = 0.2
		combat_stats.damage_resistances = {
			"physical": 0.7,  # Resistant to physical
			"fire": 1.3,
			"ice": 0.5,
			"poison": 0.0,    # Immune to poison
			"magic": 1.0
		}

func setup_rat_combat():
	if combat_stats:
		combat_stats.max_health = 12
		combat_stats.current_health = 12
		combat_stats.base_attack = 4
		combat_stats.attack_variance = 1
		combat_stats.armor = 0
		combat_stats.crit_chance = 0.05
		combat_stats.dodge_chance = 0.35  # Very dodgy
		combat_stats.damage_resistances = {
			"physical": 1.0,
			"fire": 1.5,
			"ice": 1.0,
			"poison": 0.5,    # Resistant to poison
			"magic": 1.1
		}

func setup_troll_combat():
	if combat_stats:
		combat_stats.max_health = 80
		combat_stats.current_health = 80
		combat_stats.base_attack = 16
		combat_stats.attack_variance = 4
		combat_stats.armor = 2
		combat_stats.crit_chance = 0.12
		combat_stats.dodge_chance = 0.02  # Very slow to dodge
		combat_stats.damage_resistances = {
			"physical": 0.8,
			"fire": 1.5,      # Weak to fire
			"ice": 0.9,
			"poison": 0.6,
			"magic": 1.0
		}
		# Trolls regenerate!
		combat_stats.add_status_effect(StatusEffect.RegenerationEffect.new(2, 999))

func setup_default_combat():
	if combat_stats:
		combat_stats.max_health = 30
		combat_stats.current_health = 30
		combat_stats.base_attack = 8
		combat_stats.attack_variance = 2
		combat_stats.armor = 1
		combat_stats.crit_chance = 0.05
		combat_stats.dodge_chance = 0.08

# Animation support for different enemy states
func set_sprite_animation_state(state: String):
	if not sprite_node:
		return
		
	# You can extend this to show different sprites based on state
	# For example, different sprites for idle, moving, attacking
	match state:
		"idle":
			# Use base sprite
			update_sprite_for_enemy_type()
		"moving":
			# Could add a small offset or different frame
			update_sprite_for_enemy_type()
		"attacking":
			# Could use different sprite region
			update_sprite_for_enemy_type()
		"hurt":
			# Flash red or use hurt sprite
			if sprite_node:
				sprite_node.modulate = Color.RED
				# You'd want to reset this after a timer
		"dead":
			# Make transparent or use death sprite
			if sprite_node:
				sprite_node.modulate = Color(1, 1, 1, 0.5)

func reset_sprite_effects():
	if sprite_node:
		sprite_node.modulate = Color.WHITE

# Rest of the AI and combat functions remain the same...
func get_ai_action() -> Action:
	print("=== AI DECISION FOR ", enemy_type.to_upper(), " ===")
	print("Current state: ", AIState.keys()[ai_state])
	print("Grid position: ", grid_position)
	
	var player = find_player()
	if not player:
		print("No player found - wandering")
		return get_wander_action()
	
	var distance_to_player = grid_position.distance_to(player.grid_position)
	var can_see_player = can_see_target(player.grid_position)
	
	print("Player at: ", player.grid_position)
	print("Distance: ", distance_to_player)
	print("Can see: ", can_see_player)
	
	# Check if player is adjacent for combat
	var adjacent_enemies = get_adjacent_enemies()
	var can_attack_player = player in adjacent_enemies
	
	if can_attack_player:
		print("Player is adjacent - attacking!")
		set_sprite_animation_state("attacking")
		return AttackAction.new(player)
	
	# Update AI state based on player visibility
	update_ai_state(player, distance_to_player, can_see_player)
	
	# Choose action based on state
	match ai_state:
		AIState.CHASING:
			set_sprite_animation_state("moving")
			return get_chase_action(player.grid_position)
		AIState.LOST:
			set_sprite_animation_state("moving")
			return get_search_action()
		AIState.WANDERING:
			set_sprite_animation_state("moving")
			return get_wander_action()
		_: # IDLE
			set_sprite_animation_state("idle")
			return get_idle_action()

func update_ai_state(player: Actor, distance: float, can_see: bool):
	if can_see and distance <= detection_range:
		ai_state = AIState.CHASING
		last_known_player_position = player.grid_position
		turns_since_player_seen = 0
		print("Player spotted! Switching to CHASING")
		
	elif ai_state == AIState.CHASING:
		if distance > max_chase_distance:
			ai_state = AIState.LOST
			turns_since_player_seen = 0
			print("Player escaped! Switching to LOST")
		elif not can_see:
			turns_since_player_seen += 1
			if turns_since_player_seen > 3:
				ai_state = AIState.LOST
				print("Lost player! Switching to LOST")
		else:
			last_known_player_position = player.grid_position
			turns_since_player_seen = 0
			
	elif ai_state == AIState.LOST:
		if can_see and distance <= detection_range:
			ai_state = AIState.CHASING
			last_known_player_position = player.grid_position
			turns_since_player_seen = 0
			print("Found player again! Switching to CHASING")
		else:
			turns_since_player_seen += 1
			if turns_since_player_seen > 5:
				ai_state = AIState.WANDERING
				print("Giving up search. Switching to WANDERING")

func get_chase_action(target_pos: Vector2i) -> Action:
	print("Chasing player at: ", target_pos)
	
	# Simple pathfinding - move toward target
	var best_direction = get_best_direction_to_target(target_pos)
	
	if best_direction != Vector2i.ZERO:
		var new_pos = grid_position + best_direction
		if is_valid_move(new_pos):
			print("Chasing: moving ", best_direction)
			return MoveAction.new(best_direction)
	
	# Can't move toward target - try alternative directions
	var alternative_dirs = get_alternative_directions(target_pos)
	for dir in alternative_dirs:
		var new_pos = grid_position + dir
		if is_valid_move(new_pos):
			print("Chasing: alternative move ", dir)
			return MoveAction.new(dir)
	
	# Can't move anywhere useful
	print("Chasing: blocked - waiting")
	return WaitAction.new(0.5)

func get_search_action() -> Action:
	print("Searching for player near: ", last_known_player_position)
	
	if grid_position != last_known_player_position:
		var direction = get_best_direction_to_target(last_known_player_position)
		if direction != Vector2i.ZERO:
			var new_pos = grid_position + direction
			if is_valid_move(new_pos):
				return MoveAction.new(direction)
	
	# Search randomly around area
	var search_directions = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i.UP + Vector2i.LEFT, Vector2i.UP + Vector2i.RIGHT,
		Vector2i.DOWN + Vector2i.LEFT, Vector2i.DOWN + Vector2i.RIGHT
	]
	
	search_directions.shuffle()
	for dir in search_directions:
		var new_pos = grid_position + dir
		if is_valid_move(new_pos):
			return MoveAction.new(dir)
	
	return WaitAction.new(0.5)

func get_wander_action() -> Action:
	print("Wandering randomly")
	
	# Continue current wander if we have steps remaining
	if wander_steps_remaining > 0 and wander_direction != Vector2i.ZERO:
		var new_pos = grid_position + wander_direction
		if is_valid_move(new_pos):
			wander_steps_remaining -= 1
			return MoveAction.new(wander_direction)
		else:
			wander_steps_remaining = 0
	
	# Choose new wander direction
	if randf() < wander_chance:
		var directions = [
			Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
		]
		directions.shuffle()
		
		for dir in directions:
			var new_pos = grid_position + dir
			if is_valid_move(new_pos):
				wander_direction = dir
				wander_steps_remaining = randi_range(2, 5)
				return MoveAction.new(dir)
	
	return WaitAction.new(1.0)

func get_idle_action() -> Action:
	if randf() < 0.1:
		return get_wander_action()
	return WaitAction.new(1.5)

func get_best_direction_to_target(target_pos: Vector2i) -> Vector2i:
	var diff = target_pos - grid_position
	var direction = Vector2i.ZERO
	
	if abs(diff.x) > abs(diff.y):
		direction.x = sign(diff.x)
	elif abs(diff.y) > abs(diff.x):
		direction.y = sign(diff.y)
	else:
		if randf() < 0.5:
			direction.x = sign(diff.x)
		else:
			direction.y = sign(diff.y)
	
	return direction

func get_alternative_directions(target_pos: Vector2i) -> Array[Vector2i]:
	var diff = target_pos - grid_position
	var alternatives: Array[Vector2i] = []
	
	if diff.x != 0:
		alternatives.append(Vector2i(0, 1))
		alternatives.append(Vector2i(0, -1))
	if diff.y != 0:
		alternatives.append(Vector2i(1, 0))
		alternatives.append(Vector2i(-1, 0))
	
	alternatives.append(Vector2i(sign(diff.x), sign(diff.y)))
	
	alternatives.shuffle()
	return alternatives

func can_see_target(target_pos: Vector2i) -> bool:
	var distance = grid_position.distance_to(target_pos)
	return distance <= detection_range

func is_valid_move(new_pos: Vector2i) -> bool:
	var grid_manager = get_grid_manager()
	if grid_manager and grid_manager.is_blocked(new_pos):
		return false
	
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if actor != self and actor.grid_position == new_pos:
			return false
	
	return true

func find_player() -> Actor:
	var actors = get_tree().get_nodes_in_group("actors")
	for actor in actors:
		if actor.is_player():
			return actor
	return null

func get_grid_manager() -> GridManager:
	var grid_manager = get_node_or_null("/root/Main/GridManager")
	if not grid_manager:
		grid_manager = get_tree().get_first_node_in_group("grid_managers")
	return grid_manager

func get_movement_time_cost() -> int:
	return base_speed

func get_ai_state_string() -> String:
	return AIState.keys()[ai_state]

# Enhanced combat behavior for different enemy types
func get_special_attack_chance() -> float:
	match enemy_type.to_lower():
		"goblin":
			return 0.1  # 10% chance for poison attack
		"orc":
			return 0.15 # 15% chance for power attack
		"skeleton":
			return 0.2  # 20% chance for drain attack
		"rat":
			return 0.25 # 25% chance for disease bite
		"troll":
			return 0.05 # 5% chance for slam attack
		_:
			return 0.0

# Override attack logic for special abilities
func perform_special_attack(target: Actor) -> Action:
	match enemy_type.to_lower():
		"goblin":
			return create_poison_attack(target)
		"orc":
			return create_power_attack(target)
		"skeleton":
			return create_drain_attack(target)
		"rat":
			return create_disease_attack(target)
		"troll":
			return create_slam_attack(target)
		_:
			return AttackAction.new(target)

func create_poison_attack(target: Actor) -> AttackAction:
	print("Goblin uses poison attack!")
	var attack = AttackAction.new(target, 1.2, 2, "poison")  # Slower but more damage
	return attack

func create_power_attack(target: Actor) -> AttackAction:
	print("Orc uses power attack!")
	var attack = AttackAction.new(target, 1.5, 5, "physical")  # Much slower but much more damage
	return attack

func create_drain_attack(target: Actor) -> AttackAction:
	print("Skeleton uses drain attack!")
	var attack = AttackAction.new(target, 1.1, 1, "magic")  # Slightly slower, magic damage
	return attack

func create_disease_attack(target: Actor) -> AttackAction:
	print("Rat uses disease bite!")
	var attack = AttackAction.new(target, 0.8, 0, "physical")  # Faster attack, normal damage
	return attack

func create_slam_attack(target: Actor) -> AttackAction:
	print("Troll uses slam attack!")
	var attack = AttackAction.new(target, 2.0, 8, "physical")  # Very slow but devastating
	return attack
	
#Loot Functions

func drop_loot_on_death():
	# Called when enemy dies to drop random loot
	if randf() < get_loot_drop_chance():
		var item_spawner = get_node("/root/Main/ItemSpawner") as ItemSpawner
		if not item_spawner:
			# Create temporary factory
			var factory = ItemFactory.new()
			var random_item = get_random_loot_for_enemy_type(factory)
			if random_item:
				factory.spawn_item_in_world(random_item, global_position)
		else:
			item_spawner.spawn_random_item_at(global_position)

func get_loot_drop_chance() -> float:
	# Different enemies have different drop rates
	match enemy_type.to_lower():
		"rat": return 0.2
		"goblin": return 0.4
		"orc": return 0.6
		"skeleton": return 0.5
		"troll": return 0.8
		_: return 0.3

func get_random_loot_for_enemy_type(factory: ItemFactory) -> Item:
	# Different enemies drop different types of loot
	match enemy_type.to_lower():
		"rat":
			# Rats mainly drop consumables
			if randf() < 0.8:
				return factory.create_consumable("healing_herb")
			else:
				return factory.create_consumable("health_potion")
		
		"goblin":
			# Goblins drop weapons and consumables
			if randf() < 0.4:
				return factory.create_weapon("rusty_sword")
			elif randf() < 0.7:
				return factory.create_consumable("health_potion")
			else:
				return factory.create_armor("leather_armor")
		
		"orc":
			# Orcs drop better weapons and armor
			if randf() < 0.5:
				return factory.create_weapon("iron_sword")
			else:
				return factory.create_armor("iron_mail")
		
		"skeleton":
			# Skeletons might drop magical items
			if randf() < 0.3:
				return factory.create_consumable("strength_elixir")
			elif randf() < 0.6:
				return factory.create_weapon("quick_dagger")
			else:
				return factory.create_armor("fire_resist_cloak")
		
		"troll":
			# Trolls drop rare items
			if randf() < 0.6:
				return factory.create_weapon("fire_blade")
			else:
				return factory.create_armor("fire_resist_cloak")
		
		_:
			# Default loot
			return factory.create_consumable("health_potion")
