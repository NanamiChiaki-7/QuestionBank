extends Control

@onready var file_path = "res://history/history.json"
@onready var bank_history = $HistoryContent
var history_data

#按钮管理
func _ready() -> void:
	file_path = exe_get_file()
	file_path = file_path.path_join("history.json")
	var BackButton = $BackButton
	var ClearHistoryButton = $ClearHistoryButton
	BackButton.pressed.connect(back_button)
	ClearHistoryButton.pressed.connect(delete_button)
func back_button():
	var bank_ui = $"../BankSelectionPanel"
	self.visible = false
	bank_ui.visible = true
func delete_button():
	 # 直接以写入模式打开，会自动覆盖原有内容
	var json_string = JSON.stringify({}, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		push_error("文件创建失败: " + file_path)
		return false
	file.store_string(json_string)
	file.close()
	print("文件已覆盖: ", file_path)
	return true
#展示
func history_call():
	var words = ""
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return null
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	#print(json_string)
	var json = JSON.new()
	if json.parse(json_string) == OK:
		history_data = json.get_data()
		print("JSON数据已加载到内存")
	else:
		print("JSON解析错误: ", json.get_error_message())
		return null
	for key in history_data.keys():
		words = "\n"+words
		for key_ in history_data[key].keys():
			words =  " , "+str(key_) + "：" + str(history_data[key][key_])+words
		words = str(key)+":" + words
	bank_history.text = words

#exe处理
func exe_get_file():
	var folder_path = "res://history/"
	if Global_Setting.mobile_:
		folder_path = "user://history/"
	else:
		if Global_Setting.history_host:
			var exe_dir = OS.get_executable_path().get_base_dir()
			folder_path = exe_dir.path_join("history")
		# 检查文件夹是否存在
			var dir = DirAccess.open(folder_path)
			if dir:
				print("文件夹存在: " + folder_path)
			# 列出文件夹中的所有文件
	return(folder_path)
