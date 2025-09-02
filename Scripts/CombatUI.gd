# CombatUI.gd - Fixed version that creates its own UI elements (no external dependencies)
class_name CombatUI
extends CanvasLayer

# UI nodes - will be created in code
var health_bar: ProgressBar
var health_label: Label
var combat_log: RichTextLabel
var target_info_panel: Panel
var target_health_bar: ProgressBar
var target_name_label: Label

var player_actor: Actor
var max_log_lines: int = 10

# Singleton instance for global access
static var instance: CombatUI

func _ready():
	print("CombatUI: Starting _ready()")
	
	# Set as singleton instance
	instance = self
	
	# Create UI elements first
	create_ui_elements()
	
	# Then try to find player
	call_deferred("find_and_setup_player")

# Static function to get the singleton instance
static func get_instance() -> CombatUI:
	return instance

# Static function to create and add CombatUI to the scene
static func create_combat_ui(parent: Node) -> CombatUI:
	if instance:
		print("CombatUI: Instance already exists")
		return instance
	
	print("CombatUI: Creating new CombatUI instance")
	var combat_ui = CombatUI.new()
	parent.add_child(combat_ui)
	return combat_ui

func create_ui_elements():
	print("CombatUI: Creating UI elements")
	
	# Player health bar
	health_bar = ProgressBar.new()
	health_bar.size = Vector2(200, 20)
	health_bar.position = Vector2(10, 10)
	health_bar.show_percentage = false
	add_child(health_bar)
	
	# Player health label
	health_label = Label.new()
	health_label.position = Vector2(220, 10)
	health_label.text = "HP: --/--"
	add_child(health_label)
	
	# Combat log
	combat_log = RichTextLabel.new()
	combat_log.size = Vector2(300, 150)
	combat_log.position = Vector2(10, 40)
	combat_log.bbcode_enabled = true
	combat_log.scroll_following = true
	add_child(combat_log)
	
	# Target info panel (initially hidden)
	target_info_panel = Panel.new()
	target_info_panel.size = Vector2(200, 80)
	target_info_panel.position = Vector2(get_viewport().size.x - 210, 10)
	target_info_panel.visible = false
	add_child(target_info_panel)
	
	# Target name label
	target_name_label = Label.new()
	target_name_label.position = Vector2(10, 10)
	target_name_label.text = "Target"
	target_info_panel.add_child(target_name_label)
	
	# Target health bar
	target_health_bar = ProgressBar.new()
	target_health_bar.size = Vector2(180, 20)
	target_health_bar.position = Vector2(10, 30)
	target_health_bar.show_percentage = false
	target_info_panel.add_child(target_health_bar)
	
	# Add initial log message
	add_combat_log_entry("Combat UI initialized", Color.GREEN)
	print("CombatUI: UI elements created")

func find_and_setup_player():
	print("CombatUI: Looking for player actor")
	
	# Wait a moment for actors to be registered
	await get_tree().process_frame
	
	# Try multiple ways to find the player
	var actors = get_tree().get_nodes_in_group("actors")
	print("CombatUI: Found ", actors.size(), " actors in group")
	
	for actor in actors:
		print("CombatUI: Checking actor: ", actor.name, " is_player: ", actor.is_player_controlled if actor.has_method("is_player") else "no method")
		if actor.has_method("is_player") and actor.is_player():
			player_actor = actor
			break
		elif actor.is_player_controlled:
			player_actor = actor
			break
	
	if player_actor:
		print("CombatUI: Found player: ", player_actor.name)
		setup_player_connections()
		update_player_health_display()
	else:
		print("CombatUI: No player found, will try again later")
		# Try again in 1 second
		var timer = Timer.new()
		timer.wait_time = 1.0
		timer.one_shot = true
		timer.timeout.connect(find_and_setup_player)
		add_child(timer)
		timer.start()

func setup_player_connections():
	if not player_actor:
		return
	
	var player_stats = player_actor.get_combat_stats()
	if not player_stats:
		print("CombatUI: Player has no combat stats")
		return
	
	print("CombatUI: Connecting to player combat signals")
	
	# Connect player health changes
	if not player_stats.health_changed.is_connected(_on_player_health_changed):
		player_stats.health_changed.connect(_on_player_health_changed)
		print("CombatUI: Connected health_changed signal")
	
	if not player_stats.took_damage.is_connected(_on_player_took_damage):
		player_stats.took_damage.connect(_on_player_took_damage)
		print("CombatUI: Connected took_damage signal")
	
	if not player_stats.dealt_damage.is_connected(_on_player_dealt_damage):
		player_stats.dealt_damage.connect(_on_player_dealt_damage)
		print("CombatUI: Connected dealt_damage signal")
	
	# Connect to all actors for damage numbers
	connect_all_actor_signals()

func connect_all_actor_signals():
	var all_actors = get_tree().get_nodes_in_group("actors")
	print("CombatUI: Connecting to ", all_actors.size(), " actor damage signals")
	
	for actor in all_actors:
		var stats = actor.get_combat_stats()
		if stats and not stats.took_damage.is_connected(_on_any_actor_took_damage):
			stats.took_damage.connect(_on_any_actor_took_damage)

func update_player_health_display():
	if not player_actor or not health_bar or not health_label:
		return
	
	var stats = player_actor.get_combat_stats()
	if not stats:
		return
	
	print("CombatUI: Updating health display - ", stats.current_health, "/", stats.max_health)
	
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	
	# Color coding based on health percentage
	var health_percent = stats.get_health_percentage()
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
	
	health_label.text = "HP: " + str(stats.current_health) + "/" + str(stats.max_health)

func show_target_info(target: Actor):
	if not target or not target.get_combat_stats() or not target_info_panel:
		hide_target_info()
		return
	
	var stats = target.get_combat_stats()
	target_info_panel.visible = true
	
	if target_name_label:
		target_name_label.text = target.name
	
	if target_health_bar:
		target_health_bar.max_value = stats.max_health
		target_health_bar.value = stats.current_health
		
		var health_percent = stats.get_health_percentage()
		if health_percent > 0.6:
			target_health_bar.modulate = Color.GREEN
		elif health_percent > 0.3:
			target_health_bar.modulate = Color.YELLOW
		else:
			target_health_bar.modulate = Color.RED

func hide_target_info():
	if target_info_panel:
		target_info_panel.visible = false

func add_combat_log_entry(text: String, color: Color = Color.WHITE):
	if not combat_log:
		print("CombatUI: No combat_log to write to: ", text)
		return
	
	print("CombatUI: Adding log entry: ", text)
	
	# Add colored text
	combat_log.append_text("[color=" + color.to_html() + "]" + text + "[/color]\n")
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	combat_log.scroll_to_line(combat_log.get_line_count())

# Signal handlers
func _on_player_health_changed(old_health: int, new_health: int):
	print("CombatUI: Player health changed: ", old_health, " -> ", new_health)
	update_player_health_display()
	
	if new_health < old_health:
		var damage = old_health - new_health
		add_combat_log_entry("You take " + str(damage) + " damage!", Color.RED)
		
	elif new_health > old_health:
		var healing = new_health - old_health
		add_combat_log_entry("You heal for " + str(healing) + " HP!", Color.GREEN)

func _on_player_took_damage(actor: Actor, amount: int, damage_type: String):
	if amount > 0:
		add_combat_log_entry("Took " + str(amount) + " " + damage_type + " damage!", Color.RED)

func _on_player_dealt_damage(target: Actor, amount: int, damage_type: String):
	add_combat_log_entry("You deal " + str(amount) + " " + damage_type + " damage to " + target.name + "!", Color.ORANGE)

func _on_any_actor_took_damage(actor: Actor, amount: int, damage_type: String):
	# Show simple damage number without external scene dependency
	if actor and amount > 0:
		show_simple_damage_number(actor.global_position, amount, damage_type)
	print("CombatUI: ", actor.name, " took ", amount, " ", damage_type, " damage")

# Simple damage number display without external scenes
func show_simple_damage_number(position: Vector2, damage: int, damage_type: String = "physical"):
	var damage_label = Label.new()
	damage_label.text = str(damage)
	damage_label.position = position + Vector2(-10, -10)  # Offset above the actor
	damage_label.z_index = 100  # Ensure it appears on top
	
	# Style based on damage type
	match damage_type:
		"physical":
			damage_label.modulate = Color.WHITE
		"fire":
			damage_label.modulate = Color.RED
		"ice":
			damage_label.modulate = Color.CYAN
		"poison":
			damage_label.modulate = Color.GREEN
		"magic":
			damage_label.modulate = Color.PURPLE
		_:
			damage_label.modulate = Color.WHITE
	
	# Add outline for visibility
	damage_label.add_theme_color_override("font_outline_color", Color.BLACK)
	damage_label.add_theme_constant_override("outline_size", 1)
	
	# Add to scene
	get_tree().current_scene.add_child(damage_label)
	
	# Animate the damage number
	animate_damage_number(damage_label)

func animate_damage_number(label: Label):
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Float upward
	var start_pos = label.position
	var end_pos = start_pos + Vector2(0, -50)
	tween.tween_property(label, "position", end_pos, 1.0).set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_delay(0.3)
	
	# Scale effect
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.8).set_ease(Tween.EASE_IN).set_delay(0.2)
	
	# Remove after animation
	tween.tween_callback(label.queue_free).set_delay(1.0)

# Test function you can call from the console
func test_ui():
	add_combat_log_entry("Test message!", Color.CYAN)
	if health_bar:
		health_bar.value = 75
	if health_label:
		health_label.text = "HP: 75/100"
