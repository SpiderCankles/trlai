extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var time_manager = $TimeManager
	var player = $Player
	var generator = DungeonGenerator.new()
	var renderer = $TileMapRenderer
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
	
	#setting up dungeon
	#generate dungeon
	#var map_data = generator.generate_dungeon()
	#generator.print_map_ascii()
	
	#render dungeon
	#renderer.setup_with_generator(generator)
	#renderer.render_dungeon(map_data)
	
	#spawn player at spawn point
	#renderer.spawn_actor_at_spawn(player)
	
	test_simple_map_render()
	
	#test_rendering_issue()
	
	# Start the game
	time_manager.process_turn()
	

func test_simple_map_render():
	var test_map: Array[Array] = []
	for y in range(10):
		var row = []
		for x in range(10):
			if x == 0 or x == 9 or y == 0 or y == 9:
				row.append(DungeonGenerator.TileType.WALL)
			else:
				row.append(DungeonGenerator.TileType.FLOOR)
		test_map.append(row)
		
	$TileMapRenderer.render_dungeon(test_map)

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

func debug_camera_and_viewport():
	"""Debug camera and viewport settings"""
	print("=== Camera/Viewport Debug ===")
	
	# Find camera
	var camera = get_viewport().get_camera_2d()
	if camera:
		print("Camera found: ", camera.name)
		print("Camera position: ", camera.global_position)
		print("Camera zoom: ", camera.zoom)
		print("Camera enabled: ", camera.enabled)
		print("Camera is current: ", camera.is_current())
	else:
		print("No Camera2D found!")
	
	# Viewport info
	var viewport = get_viewport()
	print("Viewport size: ", viewport.get_visible_rect().size)
	print("Viewport transform: ", viewport.get_canvas_transform())
	print("Viewport scale: ", viewport.get_canvas_transform().get_scale())
	
	# Window/screen info
	if get_window():
		print("Window size: ", get_window().size)
		print("Window mode: ", get_window().mode)
	
	print("==============================")

# Test function to position camera correctly
func position_camera_for_dungeon():
	"""Position camera to show the full dungeon"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("No camera found!")
		return
	
	# Center camera on dungeon (40x40 is center of 80x80 map)
	var dungeon_center_world = $TileMapRenderer.grid_to_world(Vector2i(40, 40))
	camera.global_position = dungeon_center_world
	
	# Set zoom to show most of the dungeon
	# 80 tiles * 32 pixels = 2560 pixels wide
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom_x = viewport_size.x / (80 * 32)
	var zoom_y = viewport_size.y / (80 * 32) 
	var zoom_level = min(zoom_x, zoom_y) * 0.8  # 80% to leave some margin
	
	camera.zoom = Vector2(zoom_level, zoom_level)
	
	print("Camera positioned at: ", camera.global_position)
	print("Camera zoom set to: ", camera.zoom)
	
func test_rendering_issue():
	"""Complete test to diagnose the rendering issue"""
	print("\n=== FULL RENDERING DEBUG TEST ===")
	
	# 1. Debug camera/viewport first
	debug_camera_and_viewport()
	
	# 2. Test simple cross pattern
	print("\n--- Testing Cross Pattern ---")
	$TileMapRenderer.test_cross_pattern()
	
	# 3. Position camera
	print("\n--- Positioning Camera ---")
	position_camera_for_dungeon()
	
	print("\n=== END DEBUG TEST ===\n")
