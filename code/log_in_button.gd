extends Button

func _pressed() -> void:
	var father = $"../../.."
	father.emit_signal("username_received")
	
