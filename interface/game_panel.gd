extends Control

var player_node : CharacterBody2D = null
@onready var sonar_toggle = $Panel/SonarToggle
@onready var sonar_slow = $Panel/SonarSlow
@onready var sonar_med = $Panel/SonarMed
@onready var sonar_fast = $Panel/SonarFast
@onready var battery_bar = $ProgressBar

var current_mode = "normal"

func _ready():
	sonar_slow.button_pressed = false
	sonar_med.button_pressed = true
	sonar_fast.button_pressed = false

func set_player(sub):
	player_node = sub



func _on_sonar_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		player_node.change_sonar_mode("on")
	else:
		player_node.change_sonar_mode("off")


func _on_sonar_fast_toggled(toggled_on: bool) -> void:
	if current_mode == "fast":
		if not toggled_on:
			sonar_fast.button_pressed = true
	if not toggled_on:
		return
	if player_node != null:
		current_mode = "fast"
		sonar_slow.button_pressed = false
		sonar_med.button_pressed = false
		player_node.change_sonar_mode("fast")


func _on_sonar_med_toggled(toggled_on: bool) -> void:
	if current_mode == "normal":
		if not toggled_on:
			sonar_med.button_pressed = true
	if not toggled_on:
		return
	if player_node != null:
		current_mode = "normal"
		sonar_slow.button_pressed = false
		sonar_fast.button_pressed = false
		player_node.change_sonar_mode("normal")


func _on_sonar_slow_toggled(toggled_on: bool) -> void:
	if current_mode == "slow":
		if not toggled_on:
			sonar_slow.button_pressed = true
	if not toggled_on:
		return
	if player_node != null:
		current_mode = "slow"
		sonar_med.button_pressed = false
		sonar_fast.button_pressed = false
		player_node.change_sonar_mode("slow")


func _on_light_right_toggled(toggled_on: bool) -> void:
	if player_node != null:
		player_node.set_light("right", toggled_on)


func _on_light_left_toggled(toggled_on: bool) -> void:
	if player_node != null:
		player_node.set_light("left", toggled_on)
