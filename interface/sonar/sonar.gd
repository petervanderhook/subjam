extends Node2D

var sonar_origin := Vector2.ZERO
var sonar_pulse_active := false
var sonar_pulse_radius := 0.0
var sonar_range := 1650.0
var sonar_duration := 2.4
var hit_radius := 6.0
var ring_width := 3.0
var sonar_wobble_offset := 0.0
var revealed_hits := []
@export var sonar_color = [0.2, 1.0, 0.4]

func set_sonar_state(
	p_origin: Vector2,
	p_active: bool,
	p_radius: float,
	p_range: float,
	p_duration: float,
	p_hit_radius: float,
	p_ring_width: float,
	p_wobble_offset: float,
	p_revealed_hits: Array
):
	sonar_origin = p_origin
	sonar_pulse_active = p_active
	sonar_pulse_radius = p_radius
	sonar_range = p_range
	sonar_duration = p_duration
	hit_radius = p_hit_radius
	ring_width = p_ring_width
	sonar_wobble_offset = p_wobble_offset
	revealed_hits = p_revealed_hits.duplicate(true)
	queue_redraw()

func world_to_screen(world_pos: Vector2) -> Vector2:
	var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_xform * world_pos

func world_radius_to_screen(radius: float) -> float:
	var canvas_xform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_xform.basis_xform(Vector2(radius, 0)).length()

func draw_wobbly_ring(center: Vector2, screen_radius: float, world_radius: float, alpha: float):
	var points := PackedVector2Array()
	var segments := 96
	var time := Time.get_ticks_msec() * 0.002
	var dist_ratio = clamp(world_radius / sonar_range, 0.0, 1.0)

	for i in range(segments):
		var t = float(i) / float(segments)
		var angle = t * TAU
		var wobble_angle = angle + sonar_wobble_offset

		var wobble_strength = lerp(2.0, 16.0, pow(dist_ratio, 1.4))

		var wobble = sin(wobble_angle * 2.0 + time) * wobble_strength
		wobble += sin(wobble_angle * 4.5 - time * 1.1) * (wobble_strength * 0.45)
		wobble += sin(wobble_angle * 9.0 + time * 0.6) * (wobble_strength * 0.18)

		var radius = screen_radius + wobble
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)

	points.append(points[0])

	var core = Color(sonar_color[0], sonar_color[1], sonar_color[2], alpha)
	var mid = Color(sonar_color[0], sonar_color[1], sonar_color[2], alpha * 0.45)
	var outer = Color(sonar_color[0], sonar_color[1], sonar_color[2], alpha * 0.18)

	draw_polyline(points, outer, ring_width * 4.0, true)
	draw_polyline(points, mid, ring_width * 2.2, true)
	draw_polyline(points, core, ring_width, true)

func _draw():
	if sonar_pulse_active:
		var dist_ratio = clamp(sonar_pulse_radius / sonar_range, 0.0, 1.0)
		var alpha = pow(1.0 - dist_ratio, 2.0)

		var center = world_to_screen(sonar_origin)
		var screen_radius = world_radius_to_screen(sonar_pulse_radius)
		draw_wobbly_ring(center, screen_radius, sonar_pulse_radius, alpha)

	for hit in revealed_hits:
		var dist = sonar_origin.distance_to(hit["position"])
		var dist_ratio = clamp(dist / sonar_range, 0.0, 1.0)
		var distance_fade = pow(1.0 - dist_ratio, 2.0)
		var time_fade = hit["time_left"] / sonar_duration
		var alpha = distance_fade * time_fade

		if hit["time_left"] < 0.2:
			continue

		var pos = world_to_screen(hit["position"])
		var core = Color(sonar_color[0], sonar_color[1], sonar_color[2], alpha)
		var mid = Color(sonar_color[0], sonar_color[1], sonar_color[2], alpha * 0.35)
		var outer = Color(sonar_color[0], sonar_color[1], sonar_color[2], alpha * 0.12)

		draw_circle(pos, hit_radius * 2.4, outer)
		draw_circle(pos, hit_radius * 1.6, mid)
		draw_circle(pos, hit_radius, core)
