extends PointLight2D
var left_held_timer = 0.0
var right_held_timer = 0.0
var middle_held_timer = 0.0
var timer = 0.0
var left_enabled = false
var middle_enabled = false
var right_enabled = false

@export var left_gun = false
@export var right_gun = false
@onready var level_node = get_tree().get_first_node_in_group("level")
@onready var scene_root = get_tree().get_first_node_in_group("scene_root")


@onready var bullet = preload("res://scenes/bullet/bullet.tscn")
@export var gun_type = "none"

var shoot_speed = 0.0
var projectile_scene = "none"
var autofire = false
var proj_dict = {
	"bullet": bullet
}

func _ready():
	scene_root = get_tree().get_first_node_in_group("scene_root")
	level_node = get_tree().get_first_node_in_group("level")
	

func _physics_process(delta: float) -> void:
	timer += delta
	if left_gun:
		## LEFT CLICK
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (get_viewport().get_mouse_position().y <= 800):
			left_held_timer += delta
			left_enabled = true
			look_at(get_global_mouse_position())
			rotation_degrees = rotation_degrees + 180
			
			shoot_gun()
			
		else:
			left_held_timer = 0.0
			left_enabled = false
		if left_held_timer > 1.0:
			left_held_timer = 0
			get_parent().get_parent().get_parent().battery_bar.draw_power(0.1)
			
	if right_gun:
		## RIGHT CLICK
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and (get_viewport().get_mouse_position().y <= 800):
			right_held_timer += delta
			right_enabled = true
			look_at(get_global_mouse_position())
			rotation_degrees = rotation_degrees + 180
			
			shoot_gun()
			
		else:
			right_held_timer = 0.0
			right_enabled = false
		if right_held_timer > 1.0:
			right_held_timer = 0
			get_parent().get_parent().get_parent().battery_bar.draw_power(0.1)
	
	## MIDDLE CLICK
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and (get_viewport().get_mouse_position().y <= 800):
		middle_held_timer += delta
		middle_enabled = true
		look_at(get_global_mouse_position())
		rotation_degrees = rotation_degrees + 180
	else:
		middle_held_timer = 0.0
		middle_enabled = false
	if middle_held_timer > 1.0:
		middle_held_timer = 0
		get_parent().get_parent().get_parent().battery_bar.draw_power(0.1)
		
	if left_enabled or middle_enabled or right_enabled:
		enabled = true
	else:
		enabled = false




func shoot_gun():
	if gun_type != 'none':
		if projectile_scene == "bullet":
			if (left_held_timer > shoot_speed) or (right_held_timer > shoot_speed):
				left_held_timer = 0.0
				right_held_timer = 0.0
				var new_bullet = bullet.instantiate()
				level_node.projectile_node.add_child(new_bullet)
				new_bullet.global_position = global_position
				
				var dir = (get_global_mouse_position() - new_bullet.global_position).normalized()
				new_bullet.direction = dir
				new_bullet.rotation = dir.angle()
				get_parent().get_child(1).pitch_scale = randf_range(0.5, 1.5)
				get_parent().get_child(1).playing = true
				scene_root.camera_node.shake(5.0)
