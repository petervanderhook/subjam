extends PointLight2D
var left_held_timer = 0.0
var batt_left_held_timer = 0.0
var right_held_timer = 0.0
var batt_right_held_timer = 0.0
var middle_held_timer = 0.0
var timer = 0.0
var left_enabled = false
var middle_enabled = false
var right_enabled = false

@export var left_gun = false
@export var right_gun = false
@onready var level_node = get_tree().get_first_node_in_group("level")
@onready var scene_root = get_tree().get_first_node_in_group("scene_root")
@onready var bullet = preload("res://scenes/player_bullet/bullet.tscn")
@onready var harpoon = preload("res://scenes/player_harpoon/harpoon.tscn")
@export var gun_type = "none"

var outside = Color.RED
var inside = Color.PALE_VIOLET_RED
var core = Color.LIGHT_PINK
var shoot_speed = 0.0
var projectile_scene = "none"
var autofire = false
var fired = false
var from : Vector2
var to : Vector2
var proj_dict = {
	"bullet": bullet
}
var laser_active = false
func _ready():
	set_scenes()
	
func set_scenes():
	scene_root = get_tree().get_first_node_in_group("scene_root")
	level_node = get_tree().get_first_node_in_group("level")
	
func _physics_process(delta: float) -> void:
	timer += delta
	if left_gun:
		left_held_timer += delta
		## LEFT CLICK
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and (get_viewport().get_mouse_position().y <= 800):
			batt_left_held_timer += delta
			left_enabled = true
			look_at(get_global_mouse_position())
			rotation_degrees = rotation_degrees + 180
			
			shoot_gun()
		else:
			if fired:
				fired = false
			batt_left_held_timer = 0.0
			left_enabled = false
			queue_redraw()
			if laser_active:
				get_parent().get_child(1).playing = false
			laser_active = false
		if batt_left_held_timer > 1.0:
			batt_left_held_timer = 0
			get_parent().get_parent().get_parent().battery_bar.draw_power(0.3)
			
	if right_gun:
		right_held_timer += delta
		## RIGHT CLICK
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and (get_viewport().get_mouse_position().y <= 800):
			batt_right_held_timer += delta
			right_enabled = true
			look_at(get_global_mouse_position())
			rotation_degrees = rotation_degrees + 180
			
			shoot_gun()
		else:
			if fired:
				fired = false
			batt_right_held_timer = 0.0
			right_enabled = false
			queue_redraw()
			if laser_active:
				get_parent().get_child(1).playing = false
			laser_active = false
		if batt_right_held_timer > 1.0:
			batt_right_held_timer = 0
			get_parent().get_parent().get_parent().battery_bar.draw_power(0.3)
	
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


func _draw():
	
	if not laser_active: return
	draw_line(from, to, outside, 16.0, true)
	draw_line(from, to, inside, 10.0, true)
	draw_line(from , to, core, 7.0, true)
	


func shoot_gun():
	if level_node == null:
		set_scenes()
	if gun_type != 'none':
		if projectile_scene == "bullet":
			print(" If not autofire")
			if not autofire:
				print (" IF not fired ")
				if not fired:
					print(" If held long enough, ", shoot_speed, ' ', left_held_timer)
					if (left_held_timer > shoot_speed) or (right_held_timer > shoot_speed):
						print(" Shoot")
						left_held_timer = 0.0
						right_held_timer = 0.0
						var new_bullet = bullet.instantiate()
						new_bullet.damage = 5.0
						new_bullet.speed = 2000.0
						level_node.projectile_node.add_child(new_bullet)
						new_bullet.global_position = global_position
						
						var dir = (get_global_mouse_position() - new_bullet.global_position).normalized()
						new_bullet.direction = dir
						new_bullet.rotation = dir.angle()
						get_parent().get_child(1).pitch_scale = randf_range(0.5, 1.5)
						get_parent().get_child(1).playing = true
						scene_root.camera_node.shake(5.0)
						fired = true
			else:
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
				
		elif projectile_scene == "harpoon":
			#print(right_held_timer, ' ', shoot_speed)
			if not autofire:
				if not fired:
					if (left_held_timer > shoot_speed) or (right_held_timer > shoot_speed):
						left_held_timer = 0.0
						right_held_timer = 0.0
						var new_harpoon = harpoon.instantiate()
						level_node.projectile_node.add_child(new_harpoon)
						new_harpoon.global_position = global_position
						
						var dir = (get_global_mouse_position() - new_harpoon.global_position).normalized()
						new_harpoon.direction = dir
						new_harpoon.rotation = dir.angle()
						get_parent().get_child(1).pitch_scale = randf_range(0.1, 0.2)
						get_parent().get_child(1).playing = true
						scene_root.camera_node.shake(5.0)
						fired = true
			else:
				if (left_held_timer > shoot_speed) or (right_held_timer > shoot_speed):
					left_held_timer = 0.0
					right_held_timer = 0.0
					var new_harpoon = harpoon.instantiate()
					level_node.projectile_node.add_child(new_harpoon)
					new_harpoon.global_position = global_position
					
					var dir = (get_global_mouse_position() - new_harpoon.global_position).normalized()
					new_harpoon.direction = dir
					new_harpoon.rotation = dir.angle()
					get_parent().get_child(1).pitch_scale = randf_range(0.1, 0.2)
					get_parent().get_child(1).playing = true
					scene_root.camera_node.shake(5.0)
		elif projectile_scene == "laser":
			if (left_held_timer > shoot_speed) or (right_held_timer > shoot_speed):
				
				get_parent().get_child(1).playing = true
				laser_active = true
				left_held_timer = 0.0
				right_held_timer = 0.0
				print("Shooting laser")
				scene_root.camera_node.shake(5.0)
				
				var dir = (get_global_mouse_position() - global_position).normalized()
				var local_mouse_pos = global_position + dir * 800.0
				var local_pos = global_position
				var space = get_world_2d().direct_space_state
				var query = PhysicsRayQueryParameters2D.create(local_pos, local_mouse_pos)
				query.exclude = [self]
				query.collision_mask &= ~(1 << (7 - 1))
				
				var result = space.intersect_ray(query)
				
				print("Drawing Lines")
				if result:
					if not result.collider.is_in_group("enemy"):
						local_mouse_pos = result.position
					else:
						result.collider.damage(1)
				from = to_local(local_pos)
				to = to_local(local_mouse_pos)
				print(local_pos, local_mouse_pos)
				queue_redraw()
				
