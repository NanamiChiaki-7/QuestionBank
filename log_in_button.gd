extends Button

func _pressed() -> void:
	var father = $"../../.."
	father.emit_signal("user_name_received")
