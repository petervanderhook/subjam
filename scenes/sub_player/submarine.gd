extends CharacterBody2D
@export var debugging = false

@export var max_speed := 220.0
@export var acceleration := 120.0
@export var deceleration := 60.0


@export var sonar_rays := 96
@export var sonar_range := 2400.0
@export var sonar_speed := 1200.0
@export var sonar_duration := 0.6
@export var sonar_collision_mask := 1
@export var hit_radius := 5.0
@export var ring_width := 2.0
@onready var sonar_node = null
@onready var ping: AudioStreamPlayer2D = $Ping

@onready var light_left = $Components/LightLeft/PointLight2D
@onready var light_right = $Components/LightRight/PointLight2D
@onready var gun1 = $Components/Gun1/GunLight
@onready var gun1_sound = $Components/Gun1/Shoot
@onready var gun2 = $Components/Gun2/GunLight
@onready var gun2_sound = $Components/Gun2/Shoot
@onready var sub_sprite_base = $Sprites/SubSpriteBase
@onready var sub_light_occluder = $Sprites/LightOccluder
@onready var light_aura = $LightAura

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
	
	var args = get_tree().get_first_node_in_group("scene_root").launch_args
	print("ARGS: ", args)
	for arg in args:
		if arg == "debug":
			debugging = true
	if debugging:
		max_speed += 920.0
		acceleration += 520.0
		deceleration += 360.0
		light_aura.scale = Vector2(15.0, 15.0)
		light_aura.energy = 1.0

	scene_root = get_parent().get_parent().get_parent().get_parent()
	battery_bar = scene_root.ui_node.game_panel.battery_bar
	scene_root.camera_node.target = self
	set_gun('gun1', 'laser')
	set_gun('gun2', 'harpoon')
	await get_tree().process_frame
	change_sonar_mode("on")
	

func _physics_process(delta):
	if velocity.x < 0:
		sub_sprite_base.flip_h = true
		sub_light_occluder.scale = Vector2(-1, 1)
	elif velocity.x > 0:
		sub_sprite_base.flip_h = false
		sub_light_occluder.scale = Vector2(1, 1)
		
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

func set_gun(gun, type):
	if gun == "gun1":
		if type == "auto":
			gun1.gun_type = type
			gun1.shoot_speed = 0.2
			gun1.projectile_scene = "bullet"
			gun1.autofire = true
			gun1_sound.stream = load("res://audio/bullet.wav")
		if type == "semiauto":
			gun1.gun_type = type
			gun1.shoot_speed = 0.4
			gun1.projectile_scene = "bullet"
			gun1.autofire = false
			gun1_sound.stream = load("res://audio/bullet.wav")
		if type == "harpoon":
			gun1.gun_type = type
			gun1.shoot_speed = 2.0
			gun1.projectile_scene = "harpoon"
			gun1.autofire = false
			gun1_sound.stream = load("res://audio/harpoon.wav")
		if type == "torpedo":
			gun1.gun_type = type
			gun1.shoot_speed = 0.2
			gun1.projectile_scene = "torpedo"
			gun1.autofire = false
			gun1_sound.stream = load("res://audio/bullet.wav")
		if type == "laser":
			gun1.gun_type = type
			gun1.shoot_speed = 0.01
			gun1.projectile_scene = "laser"
			gun1.autofire = true
			gun1_sound.stream = load("res://audio/laser.wav")
		if type == "none":
			gun1.gun_type = type
			gun1.shoot_speed = 0.0
			gun1.projectile_scene = null
			gun1.autofire = false
			gun1_sound.stream = null
	elif gun == "gun2":
		if type == "auto":
			gun2.gun_type = type
			gun2.shoot_speed = 0.2
			gun2.projectile_scene = "bullet"
			gun2.autofire = true
			gun2_sound.stream = load("res://audio/bullet.wav")
		if type == "semiauto":
			gun2.gun_type = type
			gun2.shoot_speed = 0.4
			gun2.projectile_scene = "bullet"
			gun2.autofire = false
			gun2_sound.stream = load("res://audio/bullet.wav")
		if type == "harpoon":
			gun2.gun_type = type
			gun2.shoot_speed = 2.0
			gun2.projectile_scene = "harpoon"
			gun2.autofire = false
			gun2_sound.stream = load("res://audio/harpoon.wav")
		if type == "torpedo":
			gun2.gun_type = type
			gun2.shoot_speed = 0.2
			gun2.projectile_scene = "torpedo"
			gun2.autofire = false
			gun2_sound.stream = load("res://audio/bullet.wav")
		if type == "laser":
			gun2.gun_type = type
			gun2.shoot_speed = 0.01
			gun2.projectile_scene = "laser"
			gun2.autofire = true
			gun2_sound.stream = load("res://audio/laser.wav")
		if type == "none":
			gun2.gun_type = type
			gun2.shoot_speed = 0.0
			gun2.projectile_scene = null
			gun2.autofire = false
			gun2_sound.stream = null

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
	
	## AFTER ALL REVEALED HITS ARE FOUND
	#print("SONAR HITS")
	#print(sonar_hits)
