# GridManager.gd - Example grid management system
class_name GridManager
extends Node2D

@export var grid_size: Vector2i = Vector2i(50, 50)
@export var cell_size: int = 32

# 2D array representing the grid
var grid_data: Array[Array] = []
var blocked_positions: Array[Vector2i] = []

func _ready():
	initialize_grid()

func initialize_grid():
	grid_data.resize(grid_size.y)
	for y in range(grid_size.y):
		grid_data[y] = []
		grid_data[y].resize(grid_size.x)
		for x in range(grid_size.x):
			grid_data[y][x] = 0  # 0 = empty, 1 = wall, etc.

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

func is_blocked(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return true
	return pos in blocked_positions or grid_data[pos.y][pos.x] == 1

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(world_pos / cell_size)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos * cell_size)

func set_blocked(pos: Vector2i, blocked: bool = true):
	if blocked:
		if pos not in blocked_positions:
			blocked_positions.append(pos)
	else:
		blocked_positions.erase(pos)
