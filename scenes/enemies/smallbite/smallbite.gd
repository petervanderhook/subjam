extends CharacterBody2D

@export var max_speed := 420.0
@export var accel := 750.0

@export var circle_radius := 180.0
@export var circle_time_min := 1.5
@export var circle_time_max := 3.5

@export var bite_speed := 1100.0
@export var bite_accel := 2600.0
@export var bite_range := 70.0
@export var bite_damage_knockback := 180.0
@export var bite_duration := 0.95

@export var turn_speed := 5.5


@export var health := 100.0

@onready var hitsplat_scene = preload("res://interface/hitsplat/hitsplat.tscn")

@onready var up_ray = $Up
@onready var straight_ray = $Straight
@onready var down_ray = $Down

@onready var blood1 = $Blood1
@onready var hp_bar: TextureProgressBar = $HPBar
@onready var harvest_tooltip = $HarvestTooltip
@onready var harvest_area = $HarvestArea
@onready var animation_node: AnimatedSprite2D = $AnimatedSprite2D

const SPRITE_FORWARD := Vector2.LEFT

enum State {
	IDLE,
	CIRCLE,
	BITE,
	RETREAT,
	DEAD
}

var state: State = State.IDLE
var current_state_time := 0.0
var next_bite_time := 2.5

var max_health := 100.0
var player_node: Node2D = null

var bite_start_position := Vector2.ZERO
var bite_target_position := Vector2.ZERO
var has_bit_player := false

var player_in_range := false
var harvested := false

var ray_data := []

var last_flip_time := 0.0
var flip_cooldown := 0.35
var facing_left := false
var flip_threshold := 110.0


func _ready() -> void:
	max_health = health

	ray_data = [
		{ "ray": up_ray, "weight": 1.0 },
		{ "ray": straight_ray, "weight": 1.8 },
		{ "ray": down_ray, "weight": 1.0 }
	]

	harvest_tooltip.visible = false
	harvest_area.monitoring = false
	update_health_visuals()


func _physics_process(delta: float) -> void:
	current_state_time += delta

	if !player_node or !is_instance_valid(player_node):
		set_player()

	match state:
		State.IDLE:
			process_idle()

		State.CIRCLE:
			process_circle(delta)

		State.BITE:
			process_bite(delta)

		State.RETREAT:
			process_retreat(delta)

		State.DEAD:
			process_dead(delta)


func process_idle() -> void:
	if player_node:
		if global_position.distance_to(player_node.global_position) < 3000.0:
			state = State.CIRCLE
			current_state_time = 0.0
			next_bite_time = randf_range(circle_time_min, circle_time_max)
			animation_node.play("swim")


func process_circle(delta: float) -> void:
	turn_speed = 4.0
	if !player_node:
		return

	var to_player := player_node.global_position - global_position
	var dist := to_player.length()

	if dist <= 0.001:
		return

	var to_player_dir := to_player / dist
	var tangent := to_player_dir.rotated(PI / 2.0)

	var radial := Vector2.ZERO
	var radial_strength := 1.5

	if dist > circle_radius + 25.0:
		radial = to_player_dir * radial_strength
	elif dist < circle_radius - 25.0:
		radial = -to_player_dir * radial_strength

	var desired_dir := (tangent + radial).normalized()

	var avoid_dir := get_wall_avoidance()
	if avoid_dir != Vector2.ZERO:
		desired_dir = (desired_dir + avoid_dir.normalized() * 1.8).normalized()

	steer_towards(desired_dir, max_speed, accel, delta)

	move_and_slide()
	update_sprite_flip()

	if current_state_time >= next_bite_time:
		start_bite()


func start_bite() -> void:
	if !player_node:
		return

	bite_start_position = global_position
	has_bit_player = false

	var player_velocity := Vector2.ZERO
	if "velocity" in player_node:
		player_velocity = player_node.velocity

	var to_player := player_node.global_position - global_position
	var distance := to_player.length()
	var prediction_time = clamp(distance / bite_speed, 0.05, 0.35)

	bite_target_position = player_node.global_position + player_velocity * prediction_time
	velocity = Vector2.ZERO
	turn_speed = 8.0
	state = State.BITE
	current_state_time = 0.0

	animation_node.play("bite")


func process_bite(delta: float) -> void:
	turn_speed = 6.0

	if !player_node:
		end_bite()
		return

	var player_velocity := Vector2.ZERO
	if "velocity" in player_node:
		player_velocity = player_node.velocity

	var prediction_time := 0.18
	bite_target_position = player_node.global_position + player_velocity * prediction_time

	var to_target := bite_target_position - global_position
	var dist := to_target.length()

	if dist > 0.001:
		var desired_dir := to_target / dist
		steer_towards(desired_dir, bite_speed, bite_accel, delta)

	move_and_slide()
	update_sprite_flip()

	if current_state_time >= bite_duration:
		end_bite()

func end_bite() -> void:
	state = State.CIRCLE
	current_state_time = 0.0
	next_bite_time = randf_range(circle_time_min, circle_time_max)
	animation_node.play("swim")
	
func process_retreat(delta: float) -> void:
	if !player_node:
		state = State.CIRCLE
		current_state_time = 0.0
		return

	# After biting, go back into chasing/circling around the player's CURRENT position,
	# not the old bite_start_position.
	state = State.CIRCLE
	current_state_time = 0.0
	next_bite_time = randf_range(circle_time_min, circle_time_max)


func process_dead(delta: float) -> void:
	if not harvested:
		velocity = velocity.lerp(Vector2.DOWN * 45.0, 1.0 * delta)
		move_and_slide()

		if Input.is_action_just_pressed("interact"):
			if player_in_range:
				current_state_time = 0.0
				harvested = true
				harvest_tooltip.visible = false
	else:
		var player = get_tree().get_first_node_in_group("player")
		if !player:
			return

		var to_pos = player.global_position + Vector2(0, 10)
		global_position = global_position.lerp(to_pos, (3.0 + current_state_time) * delta)

		if global_position.distance_to(to_pos) <= 20.0:
			print("HARVESTED RIGHT AT THIS MOMENT")
			queue_free()


func steer_towards(desired_dir: Vector2, speed: float, acceleration: float, delta: float) -> void:
	if desired_dir == Vector2.ZERO:
		return

	var forward := SPRITE_FORWARD.rotated(rotation)
	var angle_diff := forward.angle_to(desired_dir)
	var max_turn := turn_speed * delta

	angle_diff = clamp(angle_diff, -max_turn, max_turn)
	rotation += angle_diff

	var desired_velocity := SPRITE_FORWARD.rotated(rotation) * speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)


func get_wall_avoidance() -> Vector2:
	var avoid := Vector2.ZERO
	var avoid_radius := 140.0
	var max_avoid_force := 2.5

	for data in ray_data:
		var ray: RayCast2D = data["ray"]
		var weight: float = data["weight"]

		if ray.is_colliding():
			var hit_point := ray.get_collision_point()
			var away := global_position - hit_point
			var dist := away.length()

			if dist > 0.001 and dist < avoid_radius:
				var strength := 1.0 - (dist / avoid_radius)
				strength = clamp(strength, 0.0, 1.0)
				strength *= strength

				avoid += away.normalized() * strength * max_avoid_force * weight

	return avoid


func update_sprite_flip() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var deg := rotation_degrees

	if deg > 180.0:
		deg -= 360.0

	if now - last_flip_time < flip_cooldown:
		return

	if not facing_left and (deg > flip_threshold or deg < -flip_threshold):
		facing_left = true
		animation_node.flip_v = true
		last_flip_time = now

	elif facing_left and deg < 70.0 and deg > -70.0:
		facing_left = false
		animation_node.flip_v = false
		last_flip_time = now


func damage(x: float) -> void:
	if state == State.DEAD:
		return

	if x > 0.0:
		spawn_hitsplat(int(x))

	health -= x
	health = max(health, 0.0)

	update_health_visuals()

	if health <= 0.0:
		die()


func update_health_visuals() -> void:
	hp_bar.max_value = max_health
	hp_bar.value = health

	if health < max_health * 0.5:
		blood1.visible = true
	else:
		blood1.visible = false


func die() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD
	current_state_time = 0.0

	animation_node.play("death")

	blood1.visible = false

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	hp_bar.visible = false
	harvest_area.monitoring = true


func spawn_hitsplat(amount: int) -> void:
	var hitsplat = hitsplat_scene.instantiate()
	get_parent().add_child(hitsplat)
	hitsplat.global_position = global_position
	hitsplat.setup(amount)


func set_player() -> void:
	player_node = get_tree().get_first_node_in_group("player")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("hit ", body, " in state ", state, State.BITE)

		if state == State.BITE and not has_bit_player:
			print("Player bitten!")
			has_bit_player = true
			
			var bite_dir := (body.global_position - global_position).normalized()
			body.velocity += bite_dir * bite_damage_knockback
			state = State.CIRCLE

func _on_harvest_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if state == State.DEAD:
			print("Dead and entered by player!")
			harvest_tooltip.visible = true
			player_in_range = true


func _on_harvest_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if state == State.DEAD:
			print("Dead and exited by player!")
			harvest_tooltip.visible = false
			player_in_range = false
