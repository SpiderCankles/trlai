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
	var map_data = generator.generate_dungeon()
	generator.print_map_ascii()
	
	#render dungeon
	renderer.setup_with_generator(generator)
	renderer.render_dungeon(map_data)
	
	#spawn player at spawn point
	renderer.spawn_actor_at_spawn(player)
	
	#test_simple_map_render()
	
	#test_rendering_issue()
	
	#$TileMapRenderer.debug_tile_texture_regions()
	#$TileMapRenderer.test_single_tiles()
	
	
	## Position camera to see the test tiles
	#var camera = get_viewport().get_camera_2d()
	#camera.global_position = Vector2(320, 160)  # Center on test tiles
	#camera.zoom = Vector2(2, 2)  # Zoom in to see details
	
	#$TileMapRenderer.render_side_by_side_test()
	
	#ultra_clean_test()
	
	#$TileMapRenderer.fix_tilemap_cell_size()
	#$TileMapRenderer.test_after_cell_size_fix()
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
	

# Replace your main script dungeon generation with this debug version
func debug_dungeon_generation():
	"""Debug version of your dungeon generation"""
	print("=== Starting Debug Dungeon Generation ===")
	
	# Create generator
	var generator = DungeonGenerator.new()
	print("Generator created with settings:")
	print("  Map size: %dx%d" % [generator.map_width, generator.map_height])
	print("  Room size: %d-%d" % [generator.min_room_size, generator.max_room_size])
	print("  Max rooms: %d" % generator.max_rooms)
	
	# Generate the dungeon
	var map_data = generator.generate_dungeon()
	print("Map data generated")
	
	# Check the map data structure
	if map_data and not map_data.is_empty():
		print("Map data is valid:")
		print("  Height: %d" % map_data.size())
		print("  Width: %d" % (map_data[0].size() if map_data.size() > 0 else 0))
		
		# Sample a few tiles
		var sample_positions = [Vector2i(0, 0), Vector2i(10, 10), Vector2i(40, 40)]
		for pos in sample_positions:
			if pos.y < map_data.size() and pos.x < map_data[pos.y].size():
				var tile = map_data[pos.y][pos.x]
				print("  Sample at %s: %s (%d)" % [pos, DungeonGenerator.TileType.keys()[tile], tile])
	else:
		print("ERROR: Map data is invalid!")
		return
	
	# Get renderer
	var renderer = $TileMapRenderer
	print("Renderer found: ", renderer.name)
	
	# Setup renderer
	renderer.setup_with_generator(generator)
	print("Renderer setup complete")
	
	# Render with detailed debugging
	renderer.render_dungeon_with_detailed_debug(map_data)
	
	# Position camera to see the result
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Center camera on the dungeon
		var dungeon_center = renderer.grid_to_world(Vector2i(40, 40))
		camera.global_position = dungeon_center
		camera.zoom = Vector2(0.5, 0.5)  # Zoom out to see more
		print("Camera positioned at: %s with zoom: %s" % [camera.global_position, camera.zoom])
	
	print("=== Debug Generation Complete ===")

# Alternative: Test with a minimal dungeon first
func test_minimal_dungeon():
	"""Test with the simplest possible dungeon"""
	print("=== Testing Minimal Dungeon ===")
	
	var renderer = $TileMapRenderer
	
	# Create a minimal 5x5 dungeon manually
	var test_map: Array[Array] = []
	for y in range(5):
		var row: Array = []
		for x in range(5):
			if x == 0 or x == 4 or y == 0 or y == 4:
				row.append(DungeonGenerator.TileType.WALL)
			else:
				row.append(DungeonGenerator.TileType.FLOOR)
		test_map.append(row)
	
	# Add stairs in center
	test_map[2][2] = DungeonGenerator.TileType.STAIRS_UP
	
	print("Minimal test map created (5x5)")
	
	# Render it
	renderer.render_dungeon_with_detailed_debug(test_map)
	
	# Position camera to see it
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.global_position = Vector2(80, 80)  # Center on 5x5 grid
		camera.zoom = Vector2(4, 4)  # Zoom in close
		print("Camera positioned for minimal dungeon view")
	
	print("=== Minimal Dungeon Test Complete ===")

# Add this ultra-simple test to your main script
func ultra_clean_test():
	"""The simplest possible test to isolate the issue"""
	var renderer = $TileMapRenderer
	renderer.clear()
	
	print("=== Ultra Clean Test ===")
	
	# Place just 4 tiles in a square using only built-in methods
	renderer.set_cell(0, Vector2i(0, 0), 0, Vector2i(0, 12))  # Floor top-left
	renderer.set_cell(0, Vector2i(1, 0), 0, Vector2i(0, 2))   # Wall top-right
	renderer.set_cell(0, Vector2i(0, 1), 0, Vector2i(0, 2))   # Wall bottom-left  
	renderer.set_cell(0, Vector2i(1, 1), 0, Vector2i(0, 12))  # Floor bottom-right
	
	# Position camera to see these 4 tiles clearly
	var camera = get_viewport().get_camera_2d()
	camera.global_position = renderer.map_to_local(Vector2i(0, 0))  # Use built-in method
	camera.zoom = Vector2(4, 4)  # Zoom in close
	
	print("Placed 4 tiles in a 2x2 square")
	print("Camera position: %s" % camera.global_position)
	print("If you see 4 complete tiles in a square, coordinate system is OK")
	print("If tiles overlap or are cut off, coordinate system is broken")
	
	# Debug the actual positions
	for y in range(2):
		for x in range(2):
			var grid_pos = Vector2i(x, y)
			var world_pos = renderer.map_to_local(grid_pos)
			var source_id = renderer.get_cell_source_id(0, grid_pos)
			var atlas_coords = renderer.get_cell_atlas_coords(0, grid_pos)
			
			print("Grid (%d,%d) -> World %s -> Source: %d, Atlas: %s" % [
				x, y, world_pos, source_id, atlas_coords
			])
	
	print("========================")

# Test with manual array instead of DungeonGenerator
func test_manual_array():
	"""Test rendering a manually created array"""
	var renderer = $TileMapRenderer
	
	# Create a simple 5x5 array manually - NO DungeonGenerator
	var manual_map: Array[Array] = []
	
	for y in range(5):
		var row: Array = []
		for x in range(5):
			if x == 0 or x == 4 or y == 0 or y == 4:
				row.append(1)  # Use simple integers instead of enums
			else:
				row.append(2)
		manual_map.append(row)
	
	# Render manually without using the render_dungeon function
	renderer.clear()
	print("=== Manual Array Test ===")
	
	for y in range(manual_map.size()):
		for x in range(manual_map[y].size()):
			var value = manual_map[y][x]
			var atlas_coords = Vector2i(0, 12) if value == 2 else Vector2i(0, 2)  # Floor or Wall
			
			renderer.set_cell(0, Vector2i(x, y), 0, atlas_coords)
			
			# Debug first few
			if x < 2 and y < 2:
				print("Set manual tile at (%d,%d) with value %d -> atlas %s" % [x, y, value, atlas_coords])
	
	# Position camera
	var camera = get_viewport().get_camera_2d()
	camera.global_position = renderer.map_to_local(Vector2i(2, 2))  # Center of 5x5
	camera.zoom = Vector2(2, 2)
	
	print("Manual 5x5 array rendered")
	print("============================")
