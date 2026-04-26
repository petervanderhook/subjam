extends Node2D

@export var tilemap_path: NodePath

@export var foliage_scenes: Array[PackedScene] = []
@export var anemone_scenes: Array[PackedScene] = []

@export var chunk_size := 32
@export var load_radius := 2

@export var spawn_chance := 0.35
@export var anemone_spawn_chance := 1.0

@export var foliage_y_offset := 0.0
@export var anemone_y_offset := 0.0

@export var WATER_TILES: Array[Vector2i] = [
	Vector2i(3, 0),
	Vector2i(4, 0),
	Vector2i(5, 0),
	Vector2i(6, 0),
	Vector2i(7, 0)
]

@export var SOLID_TILES: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(8, 0),
	Vector2i(9, 0),
	Vector2i(10, 0),
	Vector2i(11, 0),
	Vector2i(12, 0),
	Vector2i(13, 0),
	Vector2i(14, 0),
	Vector2i(15, 0)
]

@onready var tilemap: TileMapLayer = get_node(tilemap_path)
@onready var player: CharacterBody2D = null

var chunk_spawn_points := {}
var loaded_chunks := {}

var update_timer := 0.0


func _ready() -> void:
	build_foliage_spawn_chunks()
	update_rendered_chunks()


func _process(delta: float) -> void:
	update_timer += delta

	if update_timer >= 0.25:
		update_timer = 0.0
		update_rendered_chunks()


func build_foliage_spawn_chunks() -> void:
	chunk_spawn_points.clear()

	for cell in tilemap.get_used_cells():
		if not is_solid_cell(cell):
			continue

		var h = abs(hash(str(cell.x) + "," + str(cell.y)))
		var roll := float(h % 10000) / 10000.0

		# Anemones use their own separate scene pool.
		if not anemone_scenes.is_empty() and can_spawn_anemone(cell):
			if roll <= anemone_spawn_chance:
				var anemone_type = h % anemone_scenes.size()
				add_spawn_point(cell, anemone_type, true, true)
				continue

		# Normal foliage.
		if foliage_scenes.is_empty():
			continue

		if not has_water_above_hex(cell):
			continue

		if roll > spawn_chance:
			continue

		var foliage_type = h % foliage_scenes.size()
		add_spawn_point(cell, foliage_type, false, false)


func add_spawn_point(cell: Vector2i, scene_type: int, centered_between_tiles: bool, is_anemone: bool) -> void:
	var chunk := get_chunk_from_cell(cell)

	if not chunk_spawn_points.has(chunk):
		chunk_spawn_points[chunk] = []

	chunk_spawn_points[chunk].append({
		"cell": cell,
		"type": scene_type,
		"centered_between_tiles": centered_between_tiles,
		"is_anemone": is_anemone
	})


func can_spawn_anemone(cell: Vector2i) -> bool:
	# Cell is the LEFT stone tile.
	if not is_solid_cell(cell):
		return false

	if not is_solid_cell(cell + Vector2i.RIGHT):
		return false

	# Three water tiles above the two stones.
	if not is_water_cell(cell + Vector2i(-1, -1)):
		return false

	if not is_water_cell(cell + Vector2i(0, -1)):
		return false

	if not is_water_cell(cell + Vector2i(1, -1)):
		return false

	return true


func has_water_above_hex(cell: Vector2i) -> bool:
	var above_a := cell + Vector2i(0, -1)
	var above_b: Vector2i

	if cell.y % 2 == 0:
		above_b = cell + Vector2i(-1, -1)
	else:
		above_b = cell + Vector2i(1, -1)

	return is_water_cell(above_a) and is_water_cell(above_b)


func is_solid_cell(cell: Vector2i) -> bool:
	var atlas := tilemap.get_cell_atlas_coords(cell)
	return SOLID_TILES.has(atlas)


func is_water_cell(cell: Vector2i) -> bool:
	var atlas_coords := tilemap.get_cell_atlas_coords(cell)
	return WATER_TILES.has(atlas_coords)


func get_chunk_from_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(cell.x) / float(chunk_size)),
		floori(float(cell.y) / float(chunk_size))
	)


func update_rendered_chunks() -> void:
	if player == null:
		await get_tree().physics_frame
		player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	var player_cell := tilemap.local_to_map(tilemap.to_local(player.global_position))
	var player_chunk := get_chunk_from_cell(player_cell)

	var wanted := {}

	for x in range(player_chunk.x - load_radius, player_chunk.x + load_radius + 1):
		for y in range(player_chunk.y - load_radius, player_chunk.y + load_radius + 1):
			var chunk := Vector2i(x, y)
			wanted[chunk] = true

			if not loaded_chunks.has(chunk):
				load_chunk(chunk)

	for chunk in loaded_chunks.keys():
		if not wanted.has(chunk):
			unload_chunk(chunk)


func load_chunk(chunk: Vector2i) -> void:
	if not chunk_spawn_points.has(chunk):
		return

	var container := Node2D.new()
	container.name = "FoliageChunk_%s_%s" % [chunk.x, chunk.y]
	add_child(container)

	for data in chunk_spawn_points[chunk]:
		var scene_index: int = data["type"]
		var is_anemone: bool = data.get("is_anemone", false)

		var foliage: Node2D = null

		if is_anemone:
			if scene_index < 0 or scene_index >= anemone_scenes.size():
				continue

			foliage = anemone_scenes[scene_index].instantiate() as Node2D
		else:
			if scene_index < 0 or scene_index >= foliage_scenes.size():
				continue

			foliage = foliage_scenes[scene_index].instantiate() as Node2D

		if foliage == null:
			continue

		container.add_child(foliage)

		var cell: Vector2i = data["cell"]
		var pos := tilemap.map_to_local(cell)

		if data.get("centered_between_tiles", false):
			pos.x += tilemap.tile_set.tile_size.x * 0.5
			pos.y += anemone_y_offset
		else:
			pos.y += foliage_y_offset

		foliage.global_position = tilemap.to_global(pos)

		var h = abs(hash(str(cell.x) + "," + str(cell.y)))

		if h % 2 == 0:
			foliage.scale.x *= -1.0

		foliage.rotation_degrees = float((h % 11) - 5)

	loaded_chunks[chunk] = container


func unload_chunk(chunk: Vector2i) -> void:
	if not loaded_chunks.has(chunk):
		return

	loaded_chunks[chunk].queue_free()
	loaded_chunks.erase(chunk)
