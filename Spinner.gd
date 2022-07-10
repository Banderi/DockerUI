tool
extends TextureRect

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rect_rotation += delta * 300
	pass
