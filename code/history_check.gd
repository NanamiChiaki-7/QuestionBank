extends Button

func _ready() -> void:
	self.pressed.connect(jump_to_history)
func jump_to_history():
	var history_ui = $"../../HistoryPanel"
	var father = $".."
	history_ui.history_call()
	father.visible = false
	history_ui.visible = true
