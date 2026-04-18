extends Control
var target = null



func _ready():
	pass
	
func _physics_process(_delta):
	if target:
		get_child(0).global_position = get_child(0).global_position.lerp(target.global_position, 0.2)
		
		
	
	if Input.is_action_just_pressed("debug"):
		get_parent().load_level()
		get_tree().get_first_node_in_group("player").queue_free()
		get_tree().get_first_node_in_group("level").queue_free()
	
	#print(global_position)
