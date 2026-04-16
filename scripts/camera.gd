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
	
	if Input.is_action_just_pressed("debug"):
		get_parent().load_level()
