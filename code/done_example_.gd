extends Label

@onready var father = $"../../.."

func _ready() -> void:
	var button = $Button
	button.pressed.connect(del_self)
	
func del_self():
	father.emit_signal("del_from_list",self.name)
	
