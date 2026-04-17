extends CharacterBody2D

@export var max_speed := 220.0
@export var acceleration := 120.0
@export var deceleration := 60.0

@export var sonar_rays := 96
@export var sonar_range := 1200.0
@export var sonar_speed := 800.0
@export var sonar_duration := 1.2
@export var sonar_collision_mask := 1
@export var hit_radius := 5.0
@export var ring_width := 2.0
@onready var sonar_node = null
@onready var ping: AudioStreamPlayer2D = $Ping

@onready var light_left = $Components/LightLeft/PointLight2D
@onready var light_right = $Components/LightRight/PointLight2D

var sonar_wobble_offset := 0.0
var sonar_origin := Vector2.ZERO
var sonar_enabled = false
var sonar_pulse_active := false
var sonar_pulse_radius := 0.0
var sonar_hits := []      # waiting hits for current pulse
var revealed_hits := []   # visible/fading hits
var sonar_count = 0.0
var sonar_timer = 3.0
var current_mode = "normal"
var scene_root = null
var battery_bar = null

var left_light_enabled = false
var right_light_enabled = false

var light_timer = 0.0

func _ready():
	scene_root = get_parent().get_parent().get_parent().get_parent()
	battery_bar = scene_root.ui_node.game_panel.battery_bar
	scene_root.camera_node.target = self
	change_sonar_mode("off")

func _physics_process(delta):
	## LIGHTS (Power Draw)
	light_timer += delta
	if light_timer > 3.0:
		light_timer = 0.0
		if left_light_enabled:
			battery_bar.draw_power(0.25)
		if right_light_enabled:
			battery_bar.draw_power(0.25)
	
	## MOVEMENT ##
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("up"):
		input_dir.y -= 1
	if Input.is_action_pressed("down"):
		input_dir.y += 1
	if Input.is_action_pressed("left"):
		input_dir.x -= 1
	if Input.is_action_pressed("right"):
		input_dir.x += 1

	input_dir = input_dir.normalized()

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	move_and_slide()

	## SONAR ##
	sonar_count += delta
	if sonar_count >= sonar_timer:
		sonar_count = 0.0
		if sonar_enabled and not sonar_pulse_active:
			revealed_hits = []
			start_sonar_pulse()
	if sonar_pulse_active:
		sonar_pulse_radius += sonar_speed * delta

		for hit in sonar_hits:
			if not hit["revealed"] and sonar_pulse_radius >= hit["distance"]:
				hit["revealed"] = true
				revealed_hits.append({
					"position": hit["position"],
					"time_left": sonar_duration
				})

		if sonar_pulse_radius >= sonar_range:
			sonar_pulse_active = false

	for hit in revealed_hits:
		hit["time_left"] -= delta

	revealed_hits = revealed_hits.filter(func(h): return h["time_left"] > 0.0)
	if sonar_node:
		sonar_node.set_sonar_state(
			sonar_origin,
			sonar_pulse_active,
			sonar_pulse_radius,
			sonar_range,
			sonar_duration,
			hit_radius,
			ring_width,
			sonar_wobble_offset,
			revealed_hits
		)

func set_sonar_node(node):
	sonar_node = node
func set_light(light, toggled):
	if light == "left":
		light_left.enabled = toggled
		left_light_enabled = toggled
	if light == "right":
		light_right.enabled = toggled
		right_light_enabled = toggled

func change_sonar_mode(mode):
	if mode == "off":
		print("Sonar disabled")
		sonar_enabled = false
	if mode == "on":
		print("Sonar enabled")
		sonar_count = 4.0
		sonar_enabled = true
	if mode == "fast":
		print("Sonar switched to ", mode)
		current_mode = mode
		sonar_speed = 800.0
		sonar_timer = 1.5
	if mode == "normal":
		print("Sonar switched to ", mode)
		current_mode = mode
		sonar_speed = 800.0
		sonar_timer = 2.5
	if mode == "slow":
		print("Sonar switched to ", mode)
		current_mode = mode
		sonar_speed = 800.0
		sonar_timer = 4.0
	
	
	
func start_sonar_pulse():
	battery_bar.draw_power(0.5)
	ping.play()
	sonar_pulse_active = true
	sonar_pulse_radius = 0.0
	sonar_hits.clear()
	sonar_origin = global_position
	sonar_wobble_offset = randf() * TAU
	var space_state = get_world_2d().direct_space_state

	for i in range(sonar_rays):
		var angle = TAU * float(i) / float(sonar_rays)
		var dir = Vector2.RIGHT.rotated(angle)
		var from = sonar_origin
		var to = sonar_origin + dir * sonar_range

		var query = PhysicsRayQueryParameters2D.create(from, to)
		query.exclude = [get_rid()]
		query.collision_mask = sonar_collision_mask

		var result = space_state.intersect_ray(query)

		if not result.is_empty():
			var pos = result["position"]
			sonar_hits.append({
				"position": pos,
				"distance": sonar_origin.distance_to(pos),
				"revealed": false
			})
