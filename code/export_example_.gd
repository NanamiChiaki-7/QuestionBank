extends Label

func _ready():
	var botton = $Button
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func _on_button_pressed():
	var father = $"../../../.."
	var target = $"../../../../../ImportStep1"
	father.visible = false
	target.visible = true
	target.file_name = self.text
	target.calling_()
	# 在这里添加你的逻辑
