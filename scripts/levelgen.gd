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
	draw_map()
	#print(grid)
	
	
func _process(_delta):
	pass
	


func draw_map():
	var noise = FastNoiseLite.new()
	noise.seed = 42069
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var noise_value = noise.get_noise_2d(x, y) + 0.5
			var tile_pos = Vector2i(x, y)
			if noise_value < 0.3:
				cell_node.set_cell(tile_pos, 0, black_tile)
			else:
				cell_node.set_cell(tile_pos, 0, blue_tile)
				
