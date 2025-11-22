extends Control

@export var file_name :String
var answer_item_list = {
	"A": "", "B": "", "C": "", "D": "", "E": "", "F": "", "G": "", "H": "", "I": "",
	"J": "", "K": "", "L": "", "M": "", "N": "", "O": "", "P": "", "Q": "", "R": "",
	"S": "", "T": "", "U": "", "V": "", "W": "", "X": "", "Y": "", "Z": ""
}
static var dic_26 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


signal del_from_list
signal add_str
func _ready() -> void:
	var submit = $submit
	del_from_list.connect(del_choice)
	add_str.connect(add_choice)
	submit.pressed.connect(submit_)
func calling_():
	var file_path = exe_get_file().path_join(str(file_name,".json"))
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return null
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	#print(json_string)
	var json = JSON.new()
	if json.parse(json_string) == OK:
		var json_data = json.get_data()
		print("JSON数据已加载到内存")
		#print(content)
	else:
		print("JSON解析错误: ", json.get_error_message())
		return null
	refresh_()
func submit_():
	#准备新数据块
	var new_ = {}
	var id = get_last_id()+1
	var tags = $TagsInput
	var question = $QuestionInput
	var answer = $CorrectAnswerInput
	var options = ""
	for key in answer_item_list.keys():
		if answer_item_list[key] != "":
			options = options + key + answer_item_list[key] +"\n"
	if id == 1:
		new_["id"] = id
		new_["tags"]= "Version:2.01.5"
		new_["question"]="\u4f5c\u8005:\u9648\u5764 Author:ChenKun"
		new_["options"]="\nA\u7981\u6b62\u4e8c\u6b21\u5206\u53d1\nB Prohibit secondary distribution\n"
		new_["answer"]="\u6821\u9a8c\u7801\u5360\u4f4d\u7b26 Verification code placeholder"
		new_["nextd"]=[]
	else:
		new_["id"] = id
		new_["tags"]= tags.text
		new_["question"]=question.text
		new_["options"]=options
		new_["answer"]=answer.text
		new_["nextd"]=[]
	for kid in self.get_children():
		if kid is TextEdit and kid.name != "tags":
			kid.text = ""
	answer_item_list = {
	"A": "", "B": "", "C": "", "D": "", "E": "", "F": "", "G": "", "H": "", "I": "",
	"J": "", "K": "", "L": "", "M": "", "N": "", "O": "", "P": "", "Q": "", "R": "",
	"S": "", "T": "", "U": "", "V": "", "W": "", "X": "", "Y": "", "Z": ""
	}
	refresh_()
	#读取
	var content = []
	var file_path = exe_get_file().path_join(str(file_name,".json"))
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return null
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	#print(json_string)
	var json = JSON.new()
	if json.parse(json_string) == OK:
		content = json.get_data()
		print("JSON数据已加载到内存")
		#print(content)
	else:
		print("JSON解析错误: ", json.get_error_message())
		return null
	content.append(new_)
	#print(content)
	file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("无法创建或打开文件: ", file_path)
		return false
	
	# 将数组转换为JSON字符串
	var new_json_string = JSON.stringify(content, "\t", false)
	file.store_string(new_json_string)
	file.close()
	
	print("数据已成功写入文件")
	return true


#刷新答案列表
func refresh_():
	var ID = $ID
	ID.text = str(get_last_id(),". ")
	var example = $OptionsScrollContainer/OptionsContainer/done_example_
	var item_list = $OptionsScrollContainer/OptionsContainer
	var inport_ = $OptionInput
	var change = false
	var _key
	var child_name = []
	var keys_to_display = []
	if answer_item_list:
		# 首先收集所有需要显示或更新的 key
		for key in answer_item_list.keys():
			if answer_item_list[key] == "/空/":
				for i in range(0,answer_item_list.size()-1):
					if dic_26[i] == key and answer_item_list[dic_26[i+1]]:
						for j in range(i,answer_item_list.size()-1):
							answer_item_list[dic_26[j]] = answer_item_list[dic_26[j+1]]
		#print(answer_item_list)
		if answer_item_list["A"] == "/空/":
			answer_item_list["A"] = ""
		for key in answer_item_list.keys():
			if answer_item_list[key] == "" :
				inport_.placeholder_text = str("输入选项 ",key)
				break
		# 处理现有子节点
		for key in answer_item_list.keys():
			if answer_item_list[key] != "" and answer_item_list[key] != "/空/":
				keys_to_display.append(key)
			#print(keys_to_display)
		for child in item_list.get_children():
			if child.name in keys_to_display:
				# 更新现有节点的文本
				child.text = "{key}. {value}".format({"key": child.name, "value": answer_item_list[child.name]})
				child.visible = true
				# 从待处理列表中移除，表示这个key已经处理过了
				keys_to_display.erase(child.name)
			else:
				# 如果节点不在当前要显示的key中，隐藏它
				child.visible = false
				# 为剩余的key创建新节点
		for key in keys_to_display:
			var new_node = example.duplicate()
			#print("创建新节点，key: ", key)
			# 确保文本正确显示
			new_node.text = "{key}.{value}".format({"key": key, "value": answer_item_list[key]})
			new_node.name = str(key)  # 确保name是字符串
			new_node.visible = true
			item_list.add_child(new_node)
			#print("节点文本设置为: ", new_node.text)
		for child in item_list.get_children():
			if "@" in child.name: 
				child.queue_free()
#添加选项
func add_choice(val):
	for key in answer_item_list.keys():
		if val == "":
			break
		if answer_item_list[key] == "":
			answer_item_list[key]=val
			break
	refresh_()
	#print(answer_item_list)
#删除选项
func del_choice(val):
	for key in answer_item_list.keys():	
		if key in val:
			answer_item_list[key] = "/空/"
	refresh_()
#获得最后的ID
func get_last_id():
	var file_path = exe_get_file().path_join(str(file_name,".json"))
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return null
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		var json_data = json.get_data()
		print("JSON数据已加载到内存")
		if json_data != null and json_data.size() > 0:
			# 获取最后一个元素的 ID
			var last_element = json_data[json_data.size() - 1]
			var last_id = last_element["id"]
			#print("最后一个ID是: ", last_id)
			return last_id
		else:
			print("没有数据或文件为空")
			return 0  # 或者返回 0，取决于你的需求
#exe文件获取部分
func exe_get_file():
	var folder_path = "res://export/"
	if Global_Setting.inport_:
		var exe_dir = OS.get_executable_path().get_base_dir()
		folder_path = exe_dir.path_join("export")
	# 检查文件夹是否存在
		var dir = DirAccess.open(folder_path)
		if dir:
			print("文件夹存在: " + folder_path)
		# 列出文件夹中的所有文件
	return(folder_path)
