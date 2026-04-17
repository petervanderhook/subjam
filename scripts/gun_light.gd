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
func _ready():
	pass
	

func _physics_process(delta: float) -> void:
	timer += delta
	
	if left_gun:
		## LEFT CLICK
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			left_held_timer += delta
			left_enabled = true
			look_at(get_global_mouse_position())
			rotation_degrees = rotation_degrees + 180
		else:
			left_held_timer = 0.0
			left_enabled = false
		if left_held_timer > 1.0:
			left_held_timer = 0
			get_parent().get_parent().get_parent().battery_bar.draw_power(0.1)
			
	if right_gun:
		## RIGHT CLICK
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			right_held_timer += delta
			right_enabled = true
			look_at(get_global_mouse_position())
			rotation_degrees = rotation_degrees + 180
		else:
			right_held_timer = 0.0
			right_enabled = false
		if right_held_timer > 1.0:
			right_held_timer = 0
			get_parent().get_parent().get_parent().battery_bar.draw_power(0.1)
	
	## MIDDLE CLICK
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
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
