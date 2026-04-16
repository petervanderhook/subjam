extends Node2D
var level_node
var ui_node
var camera_node
var level_scene = preload("res://scenes/Level.tscn")

func _ready():
	level_node = $Level
	ui_node = $UI
	camera_node = $Camera
	ui_node.clear_ui()
	ui_node.show_menu()
	


func load_level():
	level_scene = preload("res://scenes/Level.tscn")
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


func _on_options_pressed() -> void:
	pass # Replace with function body.
