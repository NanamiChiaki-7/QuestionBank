extends Label
func _ready():
	var botton = $Button
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func _on_button_pressed():
	var target = $"../../../ImportPanel"
	var father = $"../.."
	father.visible = false
	target.visible = true
	for kid in target.get_children():
		if kid is not Label and kid is not Button:
			kid.visible = false
	target.get_child(1).visible = true
	
