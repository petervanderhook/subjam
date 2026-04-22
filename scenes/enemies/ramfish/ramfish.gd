extends CharacterBody2D

@export var max_speed := 650.0
@export var accel := 250.0

@export var min_turn_speed := 3.5   # radians/sec at low speed
@export var max_turn_speed := 0.5   # radians/sec at high speed
@onready var hitsplat_scene = preload("res://interface/hitsplat/hitsplat.tscn")
@onready var up_ray = $Up
@onready var straight_ray = $Straight
@onready var down_ray = $Down
@onready var blood1 = $Blood1
@onready var blood2 = $Blood2
@onready var blood3 = $Blood3
@onready var splurt = $Splurt
@onready var hp_bar : TextureProgressBar = $HPBar
@onready var collision_node = $CollisionShape2D
const SPRITE_FORWARD := Vector2.LEFT

@export var health = 100.0
@onready var max_health = health
var ray_data = []
var player_node = null
enum State {
	IDLE,
	CIRCLE,
	ATTACK,
	DEAD
}
@onready var animation_node: AnimatedSprite2D = $AnimatedSprite2D

var last_flip_time := 0.0
var flip_cooldown := 1.0   # seconds between flips

var facing_left := false   # current state (prevents jitter)
var flip_threshold := 110.0  # degrees (buffer)
var state = State.IDLE
var current_state_time = 0.0
func _ready():
	ray_data = [
		{ "ray": up_ray, "weight": 1.0 },
		{ "ray": straight_ray, "weight": 1.8 },
		{ "ray": down_ray, "weight": 1.0 }
	]
	damage(0)
	
	
func _physics_process(delta: float) -> void:
	current_state_time += delta
	if !player_node or !is_instance_valid(player_node):
		set_player()
	match state:
		State.IDLE:
			if player_node:
				if global_position.distance_to(player_node.global_position) < 3000.0:
					state = State.ATTACK
					current_state_time = 0.0
					animation_node.play()
		State.ATTACK:
			if player_node:
				var to_player = (player_node.global_position - global_position).normalized()
				var forward := SPRITE_FORWARD.rotated(rotation)

				# 🔑 speed ratio (0 → 1)
				var speed_ratio = clamp(velocity.length() / max_speed, 0.0, 1.0)

				# 🔑 turn speed scales with velocity
				var turn_speed = 3

				var angle_diff := forward.angle_to(to_player)
				var max_turn = turn_speed * delta
				angle_diff = clamp(angle_diff, -max_turn, max_turn)

				rotation += angle_diff

				var desired_velocity := SPRITE_FORWARD.rotated(rotation) * max_speed
				velocity = velocity.move_toward(desired_velocity, accel * delta)
			move_and_slide()
			update_sprite_flip()
			
			if current_state_time > 7.0:
				state = State.CIRCLE
				current_state_time = 0.0


		State.CIRCLE:
			if player_node:
				var to_player = (player_node.global_position - global_position).normalized()
				var tangent = to_player.rotated(PI / 2.0)

				var dist = global_position.distance_to(player_node.global_position)
				var radius = 150.0
				var radial = Vector2.ZERO
				var radial_strength = 1.5

				if dist > radius + 25.0:
					radial = to_player * radial_strength
				elif dist < radius - 25.0:
					radial = -to_player * radial_strength

				var circle_dir = (tangent + radial).normalized()
				var avoid_dir = get_wall_avoidance()

				var desired_dir = circle_dir

				if avoid_dir != Vector2.ZERO:
					desired_dir = avoid_dir.normalized()

				var forward := SPRITE_FORWARD.rotated(rotation)
				desired_dir = (desired_dir + forward * 0.3).normalized()
				var turn_speed = 3.0
				var angle_diff := forward.angle_to(desired_dir)
				var max_turn = turn_speed * delta
				angle_diff = clamp(angle_diff, -max_turn, max_turn)

				rotation += angle_diff

				var desired_velocity := SPRITE_FORWARD.rotated(rotation) * max_speed
				velocity = velocity.move_toward(desired_velocity, accel * delta)
				
				#Debug draw collision avoidance points
				if true:
					queue_redraw()
				move_and_slide()
				update_sprite_flip()
				
				if current_state_time > 15.0:
					state = State.ATTACK
					current_state_time = 0.0
		State.DEAD:
			velocity = Vector2.DOWN * 450 * delta
			move_and_slide()
	#
	
func _draw():
	for ray in [up_ray, straight_ray, down_ray]:
		if ray.is_colliding():
			var p = ray.get_collision_point()
			draw_circle(to_local(p), 4.0, Color.RED)

func get_wall_avoidance() -> Vector2:
	var avoid = Vector2.ZERO
	var avoid_radius = 140.0
	var max_avoid_force = 2.5

	for data in ray_data:
		var ray = data["ray"]
		var weight = data["weight"]
		#print(data)
		if ray.is_colliding():
			var hit_point = ray.get_collision_point()
			var away = global_position - hit_point
			var dist = away.length()

			if dist > 0.001 and dist < avoid_radius:
				var strength = 1.0 - (dist / avoid_radius)
				strength = clamp(strength, 0.0, 1.0)

				# stronger falloff near wall
				strength *= strength

				avoid += away.normalized() * strength * max_avoid_force * weight

	return avoid
	
func update_sprite_flip() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	var deg = rotation_degrees

	# Normalize to -180 → 180
	if deg > 180:
		deg -= 360

	# Only allow flip if cooldown passed
	if now - last_flip_time < flip_cooldown:
		return

	# Hysteresis: different thresholds for flipping ON vs OFF
	if not facing_left and (deg > flip_threshold or deg < -flip_threshold):
		facing_left = true
		animation_node.flip_v = true
		last_flip_time = now

	elif facing_left and deg < 70 and deg > -70:
		facing_left = false
		animation_node.flip_v = false
		last_flip_time = now

func spawn_hitsplat(amount):
	var hitsplat = hitsplat_scene.instantiate()
	get_parent().add_child(hitsplat)
	hitsplat.global_position = global_position
	hitsplat.setup(amount)
	
func damage(x):
	if state != 3:
		if x > 0:
			splurt.emitting = true
			spawn_hitsplat(int(x))
			hp_bar.value = health
		health = health - x
		
		if health < (max_health *  0.25):
			blood3.visible = true
		elif health < (max_health *  0.5):
			blood2.visible = true
		elif health < (max_health *  0.75):
			blood1.visible = true
		else:
			blood1.visible = false
			blood2.visible = false
			blood3.visible = false
		if health <= 0:
			die()
func die():
	if state != 3:
		state = State.DEAD
		animation_node.play("death")
		blood1.visible = false
		blood2.visible = false
		blood3.amount = 4
		collision_node.set_deferred("disabled", true)
		hp_bar.visible = false

func set_player() -> void:
	player_node = get_tree().get_first_node_in_group("player")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		match state:
			State.ATTACK:
				print("Player hit!")
				body.velocity += velocity * 1.5  # tweak strength
				state = State.CIRCLE
