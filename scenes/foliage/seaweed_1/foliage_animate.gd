extends AnimatedSprite2D
@export var play_speed = 1.5

func _ready():
	play("default", play_speed)
