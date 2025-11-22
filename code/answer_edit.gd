extends TextEdit

@onready var father = $".."

func _ready() -> void:
	var submit_ = $Button
	submit_.pressed.connect(submit_add)
func submit_add():
	father.emit_signal("add_str",self.text)
	self.text = ""
