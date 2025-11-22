extends Label

func _ready() -> void:
	var button = $Button
	button.z_index=-1
	button.pressed.connect(filp_H)
func filp_H():
	var target = $"../../../../../Background"
	target.flip_h = not target.flip_h
