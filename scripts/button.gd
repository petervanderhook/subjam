extends TextureButton
@export var button_mask_image: Texture2D
func _ready():
	var bitmap = BitMap.new()

	var img = button_mask_image.get_image()
	bitmap.create_from_image_alpha(img)

	texture_click_mask = bitmap
