@tool
extends Node


const WIDTH = 500
const HEIGHT = 500
const CELL_SIZE = 5
const SMOOTH_CYCLES = 4

@onready var cell_node : TileMapLayer = $TileMapLayer
@onready var player_node : Node2D = $Player
@onready var sonar_node : Node2D = $SonarLayer/Sonar
@onready var projectile_node : Node2D = $Projectiles
@onready var black_tile = Vector2i(0,0)
@onready var white_tile = Vector2i(1,0)
@onready var gray_tile = Vector2i(2,0)
@onready var darker_blue_tile = Vector2i(3,0)
@onready var dark_blue_tile = Vector2i(4,0)
@onready var blue_tile = Vector2i(5,0)
@onready var light_blue_tile = Vector2i(6,0)
@onready var lighter_blue_tile = Vector2i(7,0)
@onready var scene_root = get_parent().get_parent()
@onready var tile_map_layer = $TileMapLayer
@onready var player_scene = preload("res://scenes/sub_player/submarine.tscn")
@onready var stations_node = $Stations
var assembled_truss = false
var grid = []

@export var preview_map_in_editor := false:
	set(value):
		if not Engine.is_editor_hint():
			return
		if not value:
			return

		preview_map_in_editor = false
		rebuild_editor_preview()

func rebuild_editor_preview() -> void:
	if FileAccess.file_exists("res://scenes/world/saved_map.json"):
		load_map()
	else:
		generate_map()
		smooth_map()
		fill_isolated(50, 0)
		fill_isolated(50, 1)
		add_border(3)

	$TileMapLayer.clear()
	draw_map()
	
func _ready():
	#if FileAccess.file_exists("res://scenes/world/saved_map.json"):
		#load_map()
	#else:
		#generate_map()
		#smooth_map()
		#fill_isolated(50, 0)
		#fill_isolated(50, 1)
		#add_border(3)
		#save_map()
	
	#draw_map()
	print("Loading player")
	load_player()
	
	
func _process(_delta):
	if not assembled_truss:
		assembled_truss = true
		build_all_station_truss()


func load_player():
	var sub = player_scene.instantiate()
	player_node.add_child(sub)
	sub.global_position = Vector2i(3000,1500)
	sub.set_sonar_node(sonar_node)
	scene_root.ui_node.game_panel.set_player(sub)


func build_all_station_truss():
	for station in stations_node.get_children():
		station.build_truss()
		
func generate_map():
	grid.clear()
	var noise = FastNoiseLite.new()
	noise.seed = 42069
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.06
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	
	for x in range(WIDTH):
		grid.append([])
		for y in range(HEIGHT):
			var noise_value = noise.get_noise_2d(x, y) + 0.5
			if noise_value > 0.45:	 
				grid[x].append(0)
			else:
				grid[x].append(1)
	
func draw_map():
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var tile_pos = Vector2i(x, y)
			if grid[x][y] < 0.3:
				cell_node.set_cell(tile_pos, 0, gray_tile) 
			else:
				if y < 90:
					cell_node.set_cell(tile_pos, 0, lighter_blue_tile)
				if y < 110:
					var threshold = 100
					var blend_range = 10
					
					var dist = y - threshold
					
					if abs(dist) <= blend_range:
						var transition = float(dist + blend_range) / (blend_range * 2.0)
						if randf() < transition:
							cell_node.set_cell(tile_pos, 0, light_blue_tile)
						else:
							cell_node.set_cell(tile_pos, 0, lighter_blue_tile)
				elif y < 190:
					cell_node.set_cell(tile_pos, 0, light_blue_tile)
					
				elif y < 210:
					var threshold = 200
					var blend_range = 10
					
					var dist = y - threshold
					
					if abs(dist) <= blend_range:
						var transition = float(dist + blend_range) / (blend_range * 2.0)
						if randf() < transition:
							cell_node.set_cell(tile_pos, 0, blue_tile)
						else:
							cell_node.set_cell(tile_pos, 0, light_blue_tile)
				elif y < 290:
					cell_node.set_cell(tile_pos, 0, blue_tile)
				elif y < 310:
					var threshold = 300
					var blend_range = 10
					
					var dist = y - threshold
					
					if abs(dist) <= blend_range:
						var transition = float(dist + blend_range) / (blend_range * 2.0)
						if randf() < transition:
							cell_node.set_cell(tile_pos, 0, dark_blue_tile)
						else:
							cell_node.set_cell(tile_pos, 0, blue_tile)
					
				elif y < 390:
					cell_node.set_cell(tile_pos, 0, dark_blue_tile)
				elif y < 410:
					var threshold = 400
					var blend_range = 10
					
					var dist = y - threshold
					
					if abs(dist) <= blend_range:
						var transition = float(dist + blend_range) / (blend_range * 2.0)
						if randf() < transition:
							cell_node.set_cell(tile_pos, 0, darker_blue_tile)
						else:
							cell_node.set_cell(tile_pos, 0, dark_blue_tile)
					
				else:
					cell_node.set_cell(tile_pos, 0, darker_blue_tile)

func smooth_map():
	for i in range(SMOOTH_CYCLES):
		var new_grid = []
		for x in range(WIDTH):
			new_grid.append([])
			for y in range(HEIGHT):
				var wall_neighbours = get_wall_neighbours(x, y)
				
				if wall_neighbours > 4:
					new_grid[x].append(0)
				elif wall_neighbours < 4:
					new_grid[x].append(1)
				else:
					new_grid[x].append(grid[x][y])
		grid = new_grid

func save_map():
	print("SAVING MAP")
	var path = "res://scenes/world/saved_map.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save map.")
		return
	
	var data = {
		"width": WIDTH,
		"height": HEIGHT,
		"grid": grid
	}
	
	file.store_string(JSON.stringify(data))
	file.close()

	
func load_map():
	print("LOADING MAP")
	var file = FileAccess.open("res://scenes/world/saved_map.json", FileAccess.READ)
	if file == null:
		push_error("No baked map found.")
		return
	
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	
	grid = parsed["grid"]

func fill_isolated(min_size, tile_type):
	var visited = {}
	for x in range(WIDTH):
		for y in range(HEIGHT):
			var tile_pos = Vector2i(x, y)
			if visited.has(tile_pos):
				continue
			if grid[x][y] != tile_type:
				continue
			
			var region = fill(x, y, tile_type, visited)
			if region.size() < min_size:
				var replace_with
				if tile_type == 0:
					replace_with = 1
				else:
					replace_with = 0
				for cell in region:
					grid[cell.x][cell.y] = replace_with

func fill(start_x, start_y, tile_type, visited):
	var stack = [Vector2i(start_x, start_y)]
	var region = []
	
	while stack.size() > 0:
		var pos = stack.pop_back()
		if (pos.x < 0) or (pos.x >= WIDTH) or (pos.y < 0) or (pos.y >= HEIGHT):
			continue
		if visited.has(pos):
			continue
		if grid[pos.x][pos.y] != tile_type:
			continue
		
		visited[pos] = true
		region.append(pos)
		
		stack.append(pos + Vector2i(1, 0)) 
		stack.append(pos + Vector2i(-1, 0)) 
		stack.append(pos + Vector2i(0, 1)) 
		stack.append(pos + Vector2i(0, -1)) 
	return region

func get_wall_neighbours(x, y):
	var count = 0
	for nx in range(-1, 2):
		for ny in range(-1, 2):
			if nx == 0 and ny == 0:
				continue
			var new_x = x + nx
			var new_y = y + ny
			
			if (new_x < 0) or (new_x >= WIDTH) or (new_y < 0) or (new_y >= HEIGHT):
				count += 1
			elif grid[new_x][new_y] == 0:
				count += 1
	return count

func add_border(thickness := 1):
	for x in range(WIDTH):
		for y in range(HEIGHT):
			if x < thickness or x >= WIDTH - thickness or y < thickness or y >= HEIGHT - thickness:
				grid[x][y] = 0
