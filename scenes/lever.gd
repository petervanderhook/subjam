extends TextureButton

func _ready():
	var bitmap = BitMap.new()

	var img = preload("res://textures/lever/mask.bmp").get_image()
	bitmap.create_from_image_alpha(img)

	texture_click_mask = bitmap
