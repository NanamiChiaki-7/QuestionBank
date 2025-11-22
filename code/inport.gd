extends Control

func _ready() -> void:
	var BackButton = $Back
	BackButton.pressed.connect(back_to_main)
	
func back_to_main():
	var main_menu = $"../MainMenuPanel"
	for kid in self.get_children():
		if kid is not Label and kid is not Button:
			if kid.visible:
				kid.visible = false
			else:
				self.visible = false
				main_menu.visible = true
				return
