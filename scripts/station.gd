extends Node2D

var truss_sets := []
var debug_rays := []

@export var truss_direction := Vector2i(0, 1)
@export var truss_start_offset := 8.0
@export var truss_spacing := 60.0
@export var max_truss_length := 12000.0
@export var collision_mask := 2147483647
@export var wall_embed := 4.0
@export var probe_radius := 8.0
@export var ignore_segments := 2
@export var debug_draw_rays := false

@export var truss_width := 6.0
@export var foundation_width := 16.0
@export var foundation_depth := 10.0
@export var foundation_color := Color(0.45, 0.45, 0.45)

@onready var truss_markers = $TrussMarkers

func build_truss():
	truss_sets.clear()
	debug_rays.clear()

	var space_state = get_world_2d().direct_space_state

	for truss_node in truss_markers.get_children():
		if not truss_node.visible:
			continue

		var truss_points := []

		var dir = Vector2(truss_direction).normalized()
		var start_pos = truss_node.global_position + dir * truss_start_offset
		var ignore_distance = truss_spacing * ignore_segments

		var hit_pos = find_collision_along_direction(space_state, start_pos, dir, ignore_distance)

		debug_rays.append({
			"start": start_pos,
			"end": hit_pos if hit_pos != null else start_pos + dir * max_truss_length,
			"hit": hit_pos != null
		})

		if hit_pos == null:
			continue

		hit_pos += dir * wall_embed

		var total_dist = start_pos.distance_to(hit_pos)
		var segment_count = int(total_dist / truss_spacing)

		for i in range(segment_count + 1):
			var p = start_pos + dir * truss_spacing * i
			if p.distance_to(start_pos) > total_dist:
				break
			truss_points.append(p)

		if truss_points.is_empty() or truss_points[-1].distance_to(hit_pos) > 1.0:
			truss_points.append(hit_pos)

		if truss_points.size() >= 2:
			truss_sets.append(truss_points)

	print("truss_sets count:", truss_sets.size())
	queue_redraw()


func find_collision_along_direction(
	space_state: PhysicsDirectSpaceState2D,
	start_pos: Vector2,
	dir: Vector2,
	ignore_distance: float
) -> Variant:
	var circle := CircleShape2D.new()
	circle.radius = probe_radius

	var step := truss_spacing * 0.5
	var traveled := 0.0

	while traveled <= max_truss_length:
		var probe_pos = start_pos + dir * traveled

		if traveled < ignore_distance:
			traveled += step
			continue

		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = circle
		params.transform = Transform2D(0.0, probe_pos)
		params.collision_mask = collision_mask
		params.collide_with_bodies = true
		params.collide_with_areas = false

		var hits = space_state.intersect_shape(params, 1)
		if hits.size() > 0:
			return probe_pos

		traveled += step

	return null


func _draw():
	if debug_draw_rays:
		for ray in debug_rays:
			var a = to_local(ray["start"])
			var b = to_local(ray["end"])
			var color = Color.GREEN if ray["hit"] else Color.RED
			draw_line(a, b, color, 3.0)
			draw_circle(a, 6.0, Color.YELLOW)
			draw_circle(b, 6.0, color)

	for truss_points in truss_sets:
		for i in range(truss_points.size() - 1):
			var a = to_local(truss_points[i])
			var b = to_local(truss_points[i + 1])
			draw_truss_segment(a, b)

		draw_foundation_cap(truss_points)


func draw_truss_segment(a: Vector2, b: Vector2):
	var dir = (b - a).normalized()
	var normal = Vector2(-dir.y, dir.x)
	var width = truss_width
	var color = Color(0.215, 0.346, 0.378, 1.0)

	var a_left = a + normal * width
	var a_right = a - normal * width
	var b_left = b + normal * width
	var b_right = b - normal * width

	draw_line(a_left, b_left, color, 2.0)
	draw_line(a_right, b_right, color, 2.0)
	draw_line(a_left, b_right, color, 1.5)
	draw_line(a_right, b_left, color, 1.5)
	draw_line(a_left, a_right, color, 1.5)
	draw_line(b_left, b_right, color, 1.5)


func draw_foundation_cap(truss_points: Array):
	if truss_points.size() < 2:
		return

	var end_world: Vector2 = truss_points[-1]
	var prev_world: Vector2 = truss_points[-2]

	var end_pos = to_local(end_world)
	var prev_pos = to_local(prev_world)

	var dir = (end_pos - prev_pos).normalized()
	var normal = Vector2(-dir.y, dir.x)

	var center = end_pos
	var left = center + normal * foundation_width
	var right = center - normal * foundation_width
	var back_left = left - dir * foundation_depth
	var back_right = right - dir * foundation_depth

	draw_polygon(
		PackedVector2Array([left, right, back_right, back_left]),
		PackedColorArray([foundation_color])
	)

	draw_line(left, right, Color(0.75, 0.75, 0.75), 2.0)
	draw_line(back_left, back_right, Color(0.3, 0.3, 0.3), 2.0)
	draw_line(left, back_left, Color(0.3, 0.3, 0.3), 2.0)
	draw_line(right, back_right, Color(0.3, 0.3, 0.3), 2.0)
