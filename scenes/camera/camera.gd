extends Control

var target = null
@onready var cam: Camera2D = $Camera2D

@export var shake_decay := 20.0
@export var max_shake_offset := Vector2(8, 8)

var shake_strength := 0.0
var shake_offset := Vector2.ZERO

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if target:
		cam.global_position = cam.global_position.lerp(target.global_position, 0.2)

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

func shake(amount: float) -> void:
	shake_strength = max(shake_strength, amount)
