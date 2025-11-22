extends Button
func _ready() -> void:
	self.pressed.connect(back_to_menu)
func back_to_menu():
	var main_ui = $"../../MainMenuPanel"
	var father = $".."
	father.visible = false
	main_ui.visible = true
