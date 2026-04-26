extends Node2D
var level_node
var ui_node
var camera_node
var level_scene = preload("res://scenes/world/Level.tscn")
var launch_args = []

func _ready():
	level_node = $Level
	ui_node = $UI
	camera_node = $Camera
	ui_node.clear_ui()
	ui_node.show_menu()
	launch_args = OS.get_cmdline_args()
	print(launch_args)
	


func load_level():
	level_scene = preload("res://scenes/world/Level.tscn")
	if level_node.get_children().size() > 0:
		level_node.get_child(0).queue_free()
	var level = level_scene.instantiate()
	level_node.add_child(level)
	ui_node.show_game_panel()
	print("regen level")
	camera_node.global_position = Vector2i(3000,1500)


func _on_play_pressed() -> void:
	ui_node.clear_ui()
	load_level()
	
	camera_node.setup_camera_limits()


func _on_options_pressed() -> void:
	pass # Replace with function body.
