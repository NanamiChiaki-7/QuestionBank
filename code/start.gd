extends Label

func _ready():
	var botton = $Button
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func _on_button_pressed():
	var chose_bank_list = $"../../../BankSelectionPanel"
	var father = $"../.."
	var mode = $"../../../BankSelectionPanel/AvailableBanksScroll/AvailableBanksContainer"
	father.visible = false
	mode.set_mode(false)
	chose_bank_list.visible = true
	
	# 在这里添加你的逻辑
