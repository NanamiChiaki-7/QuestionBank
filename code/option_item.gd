extends RichTextLabel

@onready var options = $"../../../AnswerInput"

func _ready():
	var botton = $Choice_text
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func _on_button_pressed():
	options.option_change(self.name,self)
	# 在这里添加你的逻辑
