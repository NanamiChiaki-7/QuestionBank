extends Control

var other_show = false

func _ready() -> void:
	var BackButton = $Back
	var back_ground_setting = $SettingScroll/SettingContainer/back_ground_set
	var privacy = $SettingScroll/SettingContainer/privacy_policy
	var about_button = $SettingScroll/SettingContainer/about
	var ChangeUserName = $SettingScroll/SettingContainer/ChangeUserName
	BackButton.pressed.connect(back_to_main)
	back_ground_setting.pressed.connect(back_ground_setting_call)
	privacy.pressed.connect(privacy_ui)
	about_button.pressed.connect(about_ui_)
	ChangeUserName.pressed.connect(change_user_name)
func reset_ui():
	var setting_list = $SettingScroll
	var main_menu = $"../MainMenuPanel"
	for kid in self.get_children():
		if kid is not Label and kid is not Button:
			kid.visible = false
	setting_list.visible = true
	other_show = false
func back_to_main():
	var main_menu = $"../MainMenuPanel"
	var setting_list = $SettingScroll
	if other_show:
		for kid in self.get_children():
			if kid is not Label and kid is not Button:
				kid.visible = false
		setting_list.visible = true
		other_show = false
	else:
		self.visible = false
		main_menu.visible = true
func back_ground_setting_call():
	var back_ground_setting = $BackgroundSettingsPanel
	var background_list = $BackgroundSettingsPanel/BackgroundSettingsPanelScroll/BackgroundSettingsPanelContainer
	for kid in self.get_children():
		if kid is not Label and kid is not Button:
			kid.visible = false
	back_ground_setting.visible = true
	background_list.item_sommon(exe_get_file())
	other_show = true
func privacy_ui():
	var privacy_policy = $"Privacy Policy"
	for kid in self.get_children():
		if kid is not Label and kid is not Button:
			kid.visible = false
	privacy_policy.visible = true
	other_show = true
func about_ui_():
	var about_ui = $about
	for kid in self.get_children():
		if kid is not Label and kid is not Button:
			kid.visible = false
	about_ui.visible = true
	other_show = true
func change_user_name():
	var root = $".."
	self.visible = false
	root._handle_online_verification(true)
	back_to_main()
#获取文件夹下目录
func exe_get_file():
	var folder_path = "res://background/"
	if Global_Setting.theme_host:
		var exe_dir = OS.get_executable_path().get_base_dir()
		folder_path = exe_dir.path_join("background")
	# 检查文件夹是否存在
		var dir = DirAccess.open(folder_path)
		if dir:
			print("文件夹存在: " + folder_path)
		# 列出文件夹中的所有文件
	return(folder_path)
