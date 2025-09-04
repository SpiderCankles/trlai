# GridManager.gd - Centralized grid management for roguelike
class_name GridManager
extends Node2D

@export var cell_size: int = 32

# Grid data
var grid_size: Vector2i
var map_data: Array[Array] = []
var dungeon_generator: DungeonGenerator

# Cache for performance
var _walkable_positions: Array[Vector2i] = []
var _walkable_positions_dirty: bool = true

signal map_changed()

func _ready():
	print("GridManager ready")

func initialize_with_generator(generator: DungeonGenerator):
	"""Initialize the grid manager with a dungeon generator"""
	dungeon_generator = generator
	generator.connect("dungeon_generated", _on_dungeon_generated)

func _on_dungeon_generated():
	"""Called when dungeon generation is complete"""
	load_map_data(dungeon_generator.map_data)

func load_map_data(data: Array[Array]):
	"""Load map data and update grid size"""
	map_data = data
	if data.is_empty():
		grid_size = Vector2i(0, 0)
	else:
		grid_size = Vector2i(data[0].size(), data.size())
	
	_walkable_positions_dirty = true
	map_changed.emit()
	print("Grid loaded: %dx%d" % [grid_size.x, grid_size.y])

# Core grid operations
func is_in_bounds(pos: Vector2i) -> bool:
	"""Check if position is within grid bounds"""
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

func get_tile_type_at(pos: Vector2i) -> DungeonGenerator.TileType:
	"""Get the tile type at a grid position"""
	if not is_in_bounds(pos) or map_data.is_empty():
		return DungeonGenerator.TileType.VOID
	return map_data[pos.y][pos.x]

func is_walkable(pos: Vector2i) -> bool:
	"""Check if a position is walkable"""
	var tile_type = get_tile_type_at(pos)
	return tile_type in [
		DungeonGenerator.TileType.FLOOR,
		DungeonGenerator.TileType.STAIRS_UP,
		DungeonGenerator.TileType.STAIRS_DOWN
	]

func is_blocked(pos: Vector2i) -> bool:
	"""Check if a position is blocked for movement"""
	return not is_walkable(pos)

# Coordinate conversion
func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid coordinates"""
	return Vector2i(world_pos / cell_size)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to world position"""
	return Vector2(grid_pos * cell_size)

func grid_to_world_centered(grid_pos: Vector2i) -> Vector2:
	"""Convert grid coordinates to centered world position"""
	return Vector2(grid_pos * cell_size) + Vector2(cell_size, cell_size) * 0.5

# Position queries
func get_walkable_positions() -> Array[Vector2i]:
	"""Get all walkable positions (cached for performance)"""
	if _walkable_positions_dirty:
		_update_walkable_positions_cache()
	return _walkable_positions.duplicate()

func _update_walkable_positions_cache():
	"""Update the walkable positions cache"""
	_walkable_positions.clear()
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var pos = Vector2i(x, y)
			if is_walkable(pos):
				_walkable_positions.append(pos)
	
	_walkable_positions_dirty = false

func get_random_walkable_position() -> Vector2i:
	"""Get a random walkable position"""
	var positions = get_walkable_positions()
	if positions.is_empty():
		return Vector2i(-1, -1)  # Invalid position
	return positions[randi() % positions.size()]

func get_spawn_position() -> Vector2i:
	"""Get the designated spawn position"""
	if dungeon_generator:
		return dungeon_generator.get_spawn_position()
	return get_random_walkable_position()

func get_positions_in_room(room_index: int = -1) -> Array[Vector2i]:
	"""Get all walkable positions in a specific room"""
	if dungeon_generator:
		return dungeon_generator.get_room_positions(room_index)
	return []

# Neighbor queries
func get_neighbors(pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	"""Get neighboring positions (4 or 8 directions)"""
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i]
	
	if diagonal:
		directions = [
			Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
			Vector2i(-1,  0),                  Vector2i(1,  0),
			Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
		]
	else:
		directions = [
			Vector2i(0, -1),  # Up
			Vector2i(1, 0),   # Right
			Vector2i(0, 1),   # Down
			Vector2i(-1, 0)   # Left
		]
	
	for dir in directions:
		var neighbor = pos + dir
		if is_in_bounds(neighbor):
			neighbors.append(neighbor)
	
	return neighbors

func get_walkable_neighbors(pos: Vector2i, diagonal: bool = false) -> Array[Vector2i]:
	"""Get walkable neighboring positions"""
	var neighbors = get_neighbors(pos, diagonal)
	return neighbors.filter(func(p): return is_walkable(p))

# Distance calculations
func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	"""Calculate Manhattan distance between two positions"""
	return abs(a.x - b.x) + abs(a.y - b.y)

func euclidean_distance(a: Vector2i, b: Vector2i) -> float:
	"""Calculate Euclidean distance between two positions"""
	return Vector2(a).distance_to(Vector2(b))

# Area queries
func get_positions_in_radius(center: Vector2i, radius: int, walkable_only: bool = true) -> Array[Vector2i]:
	"""Get positions within a radius of center point"""
	var positions: Array[Vector2i] = []
	
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var pos = Vector2i(x, y)
			if not is_in_bounds(pos):
				continue
			
			if manhattan_distance(center, pos) <= radius:
				if not walkable_only or is_walkable(pos):
					positions.append(pos)
	
	return positions

func get_positions_in_rect(rect: Rect2i, walkable_only: bool = true) -> Array[Vector2i]:
	"""Get positions within a rectangular area"""
	var positions: Array[Vector2i] = []
	
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var pos = Vector2i(x, y)
			if not is_in_bounds(pos):
				continue
			
			if not walkable_only or is_walkable(pos):
				positions.append(pos)
	
	return positions

# Line of sight / raycast
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	"""Check if there's a clear line of sight between two positions"""
	var line_points = get_line_points(from, to)
	
	# Check if all points in the line are walkable (except endpoints)
	for i in range(1, line_points.size() - 1):
		if not is_walkable(line_points[i]):
			return false
	
	return true

func get_line_points(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	"""Get all grid points along a line (Bresenham's algorithm)"""
	var points: Array[Vector2i] = []
	
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var sx = 1 if from.x < to.x else -1
	var sy = 1 if from.y < to.y else -1
	var err = dx - dy
	
	var current = from
	
	while true:
		points.append(current)
		
		if current == to:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			current.x += sx
		if e2 < dx:
			err += dx
			current.y += sy
	
	return points

# Bounds
func get_map_bounds() -> Rect2i:
	"""Get the bounds of the current map"""
	return Rect2i(0, 0, grid_size.x, grid_size.y)

# Debug
func highlight_position(pos: Vector2i, color: Color = Color.RED, duration: float = 2.0):
	"""Highlight a position for debugging"""
	var highlight = ColorRect.new()
	highlight.size = Vector2(cell_size, cell_size)
	highlight.position = grid_to_world(pos)
	highlight.color = color
	highlight.modulate.a = 0.5
	add_child(highlight)
	
	if duration > 0:
		var timer = get_tree().create_timer(duration)
		timer.timeout.connect(func(): highlight.queue_free())

func print_area_around(center: Vector2i, radius: int = 3):
	"""Print ASCII representation of area around a position"""
	print("Area around %s:" % center)
	for y in range(center.y - radius, center.y + radius + 1):
		var line = ""
		for x in range(center.x - radius, center.x + radius + 1):
			var pos = Vector2i(x, y)
			if pos == center:
				line += "@"
			elif not is_in_bounds(pos):
				line += " "
			else:
				match get_tile_type_at(pos):
					DungeonGenerator.TileType.VOID: line += " "
					DungeonGenerator.TileType.FLOOR: line += "."
					DungeonGenerator.TileType.WALL: line += "#"
					DungeonGenerator.TileType.DOOR: line += "+"
					DungeonGenerator.TileType.STAIRS_UP: line += "<"
					DungeonGenerator.TileType.STAIRS_DOWN: line += ">"
		print(line)
