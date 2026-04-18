extends ProgressBar

var timer = 0.0
var last_power = 0.0
func _ready():
	value = 100.0
	last_power = value

func _physics_process(delta):
	timer += delta
	if timer >= 5.0:
		timer = 0.0
		if value == last_power:
			value += 1
		last_power = value



func draw_power(amount):
	value -= amount
