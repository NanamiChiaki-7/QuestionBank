extends Label
func _ready():
	var botton = $Button
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func _on_button_pressed():
	self.text = "即将更新!!!"
	# 在这里添加你的逻辑
