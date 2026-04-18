extends AudioStreamPlayer2D


func _physics_process(delta: float) -> void:
	if not playing:
		queue_free()
	else:
		get_child(0).energy -=0.1
