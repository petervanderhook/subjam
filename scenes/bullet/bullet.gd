extends Area2D

@export var speed := 1000.0
@export var max_trail_points := 12
@export var trail_point_spacing := 6.0
@export var wake_spawn_interval := 0.02
@export var wake_lifetime := 0.18
@onready var bullet_impact = preload("res://scenes/bullet/impact.tscn")

var direction := Vector2.RIGHT
var trail_points: Array[Vector2] = []
var wakes: Array = []
var wake_timer := 0.0

func _ready() -> void:
	top_level = true
	trail_points.append(global_position)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation = direction.angle()

	if trail_points.is_empty() or global_position.distance_to(trail_points[trail_points.size() - 1]) >= trail_point_spacing:
		trail_points.append(global_position)

	if trail_points.size() > max_trail_points:
		trail_points.pop_front()

	wake_timer += delta
	if wake_timer >= wake_spawn_interval:
		wake_timer = 0.0
		spawn_wake()

	for i in range(wakes.size() - 1, -1, -1):
		var w = wakes[i]
		w["age"] += delta
		w["pos"] += w["vel"] * delta
		w["vel"] *= 0.92
		wakes[i] = w

		if w["age"] >= w["life"]:
			wakes.remove_at(i)

	queue_redraw()

func spawn_wake() -> void:
	var dir := direction.normalized()
	var back := -dir
	var normal := Vector2(-dir.y, dir.x)

	var jitter := Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	var base_pos := global_position - dir * 8.0 + jitter

	wakes.append({
		"pos": base_pos,
		"vel": (normal * 0.15 + back * 1.0).normalized() * randf_range(140.0, 180.0),
		"life": randf_range(wake_lifetime * 0.8, wake_lifetime * 1.2),
		"age": 0.0,
		"length": 20.0,
	})

	wakes.append({
		"pos": base_pos,
		"vel": (-normal * 0.15 + back * 1.0).normalized() * randf_range(140.0, 180.0),
		"life": randf_range(wake_lifetime * 0.8, wake_lifetime * 1.2),
		"age": 0.0,
		"length": 20.0,
	})

func _draw() -> void:
	if trail_points.size() >= 2:
		for i in range(trail_points.size() - 1):
			var p1 = to_local(trail_points[i])
			var p2 = to_local(trail_points[i + 1])

			var t = float(i + 1) / float(trail_points.size())
			var alpha = t * 0.35
			var width = max(1.0, t * 5.0)

			draw_line(p1, p2, Color(0.4, 0.7, 1.0, alpha), width, true)

	for w in wakes:
		var alpha = 1.0 - (w["age"] / w["life"])
		var dir = w["vel"].normalized()

		var p1 = to_local(w["pos"])
		var p2 = to_local(w["pos"] + dir * w["length"])

		draw_line(p1, p2, Color(0.85, 0.95, 1.0, alpha * 0.35), 1.2, true)

	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.2, 1.0))
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.9, 0.2, 0.12))

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		#print("Hit: ", body)
		var new_impact = bullet_impact.instantiate()
		get_parent().add_child(new_impact)
		new_impact.global_position = global_position
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	pass
