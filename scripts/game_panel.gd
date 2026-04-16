extends Control

var player_node : CharacterBody2D = null
@onready var sonar_toggle = $Panel/SonarToggle

func set_player():
	player_node = get_tree().get_first_node_in_group("player")



func _on_sonar_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		player_node.change_sonar_mode("on")
	else:
		player_node.change_sonar_mode("off")
