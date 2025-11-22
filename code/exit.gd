extends Label
func _ready():
	var botton = $Button
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func _on_button_pressed():
	get_tree().quit()
	# 在这里添加你的逻辑
