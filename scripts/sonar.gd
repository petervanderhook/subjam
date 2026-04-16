extends Node2D

var sonar_origin := Vector2.ZERO
var sonar_pulse_active := false
var sonar_pulse_radius := 0.0
var sonar_range := 650.0
var sonar_duration := 1.2
var hit_radius := 6.0
var ring_width := 3.0
var sonar_wobble_offset := 0.0
var revealed_hits := []

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
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return world_pos
	
	return (world_pos - camera.global_position) * camera.zoom + get_viewport_rect().size * 0.5

func draw_wobbly_ring(center: Vector2, base_radius: float, alpha: float):
	var points := PackedVector2Array()
	var segments := 128
	var time := Time.get_ticks_msec() * 0.002
	var dist_ratio = clamp(base_radius / sonar_range, 0.0, 1.0)

	for i in range(segments):
		var t = float(i) / float(segments)
		var angle = t * TAU
		var wobble_angle = angle + sonar_wobble_offset

		var wobble_strength = lerp(0.8, 8.0, pow(dist_ratio, 1.3))

		var wobble = sin(wobble_angle * 2.0 + time) * wobble_strength
		wobble += sin(wobble_angle * 4.5 - time * 1.1) * (wobble_strength * 0.45)
		wobble += sin(wobble_angle * 9.0 + time * 0.6) * (wobble_strength * 0.18)

		var radius = base_radius + wobble
		points.append(center + Vector2.RIGHT.rotated(angle) * radius)

	points.append(points[0])
	draw_polyline(points, Color(0.4, 1.0, 1.0, alpha), ring_width, true)

func _draw():
	if sonar_pulse_active:
		var dist_ratio = clamp(sonar_pulse_radius / sonar_range, 0.0, 1.0)
		var alpha = pow(1.0 - dist_ratio, 2.0)

		var center = world_to_screen(sonar_origin)
		draw_wobbly_ring(center, sonar_pulse_radius, alpha)

	for hit in revealed_hits:
		var dist = sonar_origin.distance_to(hit["position"])
		var dist_ratio = clamp(dist / sonar_range, 0.0, 1.0)
		var distance_fade = pow(1.0 - dist_ratio, 2.0)
		var time_fade = hit["time_left"] / sonar_duration
		var alpha = distance_fade * time_fade

		draw_circle(
			world_to_screen(hit["position"]),
			hit_radius,
			Color(0.8, 1.0, 1.0, alpha)
		)
