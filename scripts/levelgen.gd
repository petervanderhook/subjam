extends Node2D


const WIDTH = 200
const HEIGHT = 200
const CELL_SIZE = 5

@onready var cell_node : TileMapLayer = $TileMapLayer

@onready var black_tile = Vector2i(0,0)
@onready var white_tile = Vector2i(1,0)
@onready var gray_tile = Vector2i(2,0)
@onready var darker_blue_tile = Vector2i(3,0)
@onready var dark_blue_tile = Vector2i(4,0)
@onready var blue_tile = Vector2i(5,0)
@onready var light_blue_tile = Vector2i(6,0)
@onready var lighter_blue_tile = Vector2i(7,0)

var grid = []

func _ready():
	init_grid()
	generate_cave()
	draw_map()
	#print(grid)
	
	
func _process(_delta):
	pass
	
func init_grid():
	for x in range(WIDTH):
		grid.append([])
		for y in range(HEIGHT):
			grid[x].append(randf() < 0.45)
		
			
func generate_cave():
	for i in range(4):
		var new_grid = grid.duplicate(true)
		for x in range(WIDTH):
			for y in range(HEIGHT):
				var wall_count = get_neighbour(x, y)
				if grid[x][y]:
					new_grid[x][y] = wall_count > 3
				else:
					new_grid[x][y] = wall_count > 4
		grid = new_grid

func get_neighbour(x, y):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if (i == 0) and (j == 0):
				continue
			var new_x = x + i
			var new_y = y + j
			if (new_x < 0) or (new_x >= WIDTH) or (new_y < 0) or (new_y >= HEIGHT):
				count += 1
			elif grid[new_x][new_y]:
				count += 1
				
	return count

func draw_map():
	for x in range(WIDTH):
		for y in range(HEIGHT):
			if grid[x][y]:
				cell_node.set_cell(Vector2i(x, y), 0, gray_tile)
			elif not grid[x][y]:
				cell_node.set_cell(Vector2i(x, y), 0, blue_tile)
