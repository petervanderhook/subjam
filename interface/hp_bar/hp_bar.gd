extends TextureProgressBar

@export var offset := Vector2(-60, -100)

func _ready() -> void:
	top_level = true

func _process(_delta: float) -> void:
	var p = get_parent()
	if p:
		global_position = p.global_position + offset
		rotation = 0.0
