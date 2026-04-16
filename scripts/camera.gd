extends Control



func _ready():
	pass
	
func _physics_process(_delta):
	if Input.is_action_pressed("up"):
		global_position.y -= 10
	if Input.is_action_pressed("down"):
		global_position.y += 10
	if Input.is_action_pressed("left"):
		global_position.x -= 10
	if Input.is_action_pressed("right"):
		global_position.x += 10
	
	#if Input.is_action_pressed("debug"):
	#	print(get_parent().get_parent().get_child(0).get_child(0).cell_node.get_children().size())
