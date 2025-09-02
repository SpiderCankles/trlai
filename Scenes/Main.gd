extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var time_manager = $TimeManager
	var player = $Player
	#var enemy1 = $Actor
	
	# Register actors
	print("registering player: ", player)
	time_manager.register_actor(player)
	print("Actors Count: ", time_manager.actors.size())
	
	#setting up UI
	setup_combat_ui()
	#test_combat_ui()
	
	#create item spawner
	setup_combat_ui()
	
	var player_controller = get_node("PlayerController")
	if player_controller and player_controller.has_method("setup_inventory_ui"):
		player_controller.setup_inventory_ui()
	
	# Start the game
	time_manager.process_turn()

func setup_combat_ui():
	print("Main: Setting up Combat UI")
	
	# Check if CombatUI already exists
	var existing_ui = get_node_or_null("CombatUI")
	if existing_ui:
		print("Main: CombatUI already exists")
		return
	
	# Create CombatUI instance
	var combat_ui = CombatUI.new()
	combat_ui.name = "CombatUI"
	add_child(combat_ui)
	
	print("Main: CombatUI created and added to scene")
	
func test_combat_ui():
	var combat_ui = CombatUI.get_instance()
	if combat_ui:
		combat_ui.add_combat_log_entry("Test message from Main!", Color.YELLOW)
		print("Test message sent to CombatUI")
	else:
		print("No CombatUI instance found")
		
func setup_item_system():
	# Create item spawner
	var item_spawner = ItemSpawner.new()
	item_spawner.name = "ItemSpawner"
	add_child(item_spawner)
