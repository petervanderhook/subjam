extends RichTextLabel

@export var offsett := Vector2(-60, -100)
const MAX =  55
const MIN = 50
var current_scale = MIN
var ascending = false
var time = 0.0
func _ready() -> void:
	top_level = true
	ascending = true

func _process(delta: float) -> void:
	var p = get_parent()
	if p:
		global_position = p.global_position + offsett
		rotation = 0.0
		time += delta
		if time > 0.1:
			time -= 0.1
			if ascending:
				current_scale += 1
			else:
				current_scale -= 1
			
			if current_scale >= MAX:
				ascending = false
			elif current_scale <= MIN:
				ascending = true
			add_theme_font_size_override("normal_font_size", current_scale)
