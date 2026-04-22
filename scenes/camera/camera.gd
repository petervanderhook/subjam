extends Control

var target = null
@onready var cam: Camera2D = $Camera2D

@export var tilemap: TileMapLayer

@export var shake_decay := 20.0
@export var max_shake_offset := Vector2(8, 8)

@export var zoom_step := 0.1
@export var min_zoom := 0.2
@export var max_zoom := 0.5
@export var zoom_lerp_speed := 10.0
@export var follow_lerp_speed := 8.0

var target_zoom := 0.2
var shake_strength := 0.0
var shake_offset := Vector2.ZERO

func _ready() -> void:
	target_zoom = max_zoom
	cam.zoom = Vector2(target_zoom, target_zoom)

func _physics_process(delta: float) -> void:
	if target:
		cam.global_position = cam.global_position.lerp(
			target.global_position,
			1.0 - exp(-follow_lerp_speed * delta)
		)

	var current_zoom = cam.zoom.x
	current_zoom = lerp(current_zoom, target_zoom, 1.0 - exp(-zoom_lerp_speed * delta))
	cam.zoom = Vector2(current_zoom, current_zoom)

	if shake_strength > 0.0:
		shake_strength = move_toward(shake_strength, 0.0, shake_decay * delta)
		shake_offset = Vector2(
			randf_range(-max_shake_offset.x, max_shake_offset.x),
			randf_range(-max_shake_offset.y, max_shake_offset.y)
		) * (shake_strength / 10.0)
	else:
		shake_offset = Vector2.ZERO

	cam.offset = shake_offset

	if Input.is_action_just_pressed("debug"):
		get_parent().load_level()
		get_tree().get_first_node_in_group("player").queue_free()
		get_tree().get_first_node_in_group("level").queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom -= zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom += zoom_step
		else:
			return

		target_zoom = clamp(target_zoom, min_zoom, max_zoom)

func setup_camera_limits() -> void:
	if tilemap == null:
		push_warning("No tilemap assigned to camera script.")
		return

	var used := tilemap.get_used_rect()
	if used.size == Vector2i.ZERO:
		push_warning("Tilemap used rect is empty.")
		return

	# top-left cell in world space
	var top_left_local = tilemap.map_to_local(used.position)
	var top_left_global = tilemap.to_global(top_left_local)

	# bottom-right corner: use position + size - 1 for last cell,
	# then add one full cell so the limit reaches the outer edge
	var bottom_right_cell = used.position + used.size
	var bottom_right_local = tilemap.map_to_local(bottom_right_cell)
	var bottom_right_global = tilemap.to_global(bottom_right_local)

	cam.limit_left = int(top_left_global.x)
	cam.limit_top = int(top_left_global.y)
	cam.limit_right = int(bottom_right_global.x)
	cam.limit_bottom = int(bottom_right_global.y)

func shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)
