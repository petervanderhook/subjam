extends Control
@onready var label: RichTextLabel  = $Label

var velocity := Vector2.ZERO
var lifetime := 1.2
var age := 0.0

func setup(value: int) -> void:
	label.text = str(value)
	#print("Spawned! ", get_parent(), label.text)
	velocity = Vector2(
	randf_range(-30.0, 30.0),  # X stays constant
	randf_range(-200.0, -140.0) # strong upward burst
	)
	


func _process(delta: float) -> void:
	age += delta
	position += velocity * delta

	# gravity
	velocity.y += 300.0 * delta

	var t = age / lifetime
	modulate.a = 1.0 - t
	scale = Vector2.ONE * (1.0 + sin(t * PI) * 0.15)

	if age >= lifetime:
		queue_free()
