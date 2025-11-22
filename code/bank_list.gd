extends VBoxContainer

@onready var example = $example_
var is_mistake_mode: bool = false  # 标记是否从错题本进入


func _ready() -> void:
	example.visible = false
	var file_path = "res://bank/"
	file_path=exe_get_file()
	item_sommon(file_path)
	is_mistake_mode = true
	file_path=exe_get_file()
	item_sommon(file_path)
	is_mistake_mode = false
	
	
func set_mode(mistake_mode: bool):
	is_mistake_mode = mistake_mode
	# 更新文件路径并重新加载文件
	var file_path = exe_get_file()
	# 遍历所有子项，根据模式设置可见性
	for child in get_children():
		if child == example:
			continue
		var filename = child.text
		var should_show = false
		# 错题本模式：只显示包含日期格式的文件
		if is_mistake_mode:
			# 匹配格式：原文件名_mistakes_年月日_时分
			var regex = RegEx.new()
			regex.compile(".*_mistakes_\\d{8}_\\d{4}$")
			should_show = regex.search(filename) != null
		# 题库模式：不显示包含日期格式的文件
		else:
			# 排除包含日期格式的文件
			var regex = RegEx.new()
			regex.compile(".*_mistakes_\\d{8}_\\d{4}$")
			should_show = regex.search(filename) == null
		child.visible = should_show
func item_sommon(folder_path:String):
	var dir = DirAccess.open(folder_path)
	if not dir:
		print("错误：无法访问文件夹 ", folder_path)
		return
	
	var json_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "json":
			json_files.append(file_name)
		file_name=dir.get_next()
	dir.list_dir_end()
	
	print("找到 ", json_files.size(), " 个JSON文件")
	json_files.sort()
	
	for json_file in json_files:
		var base_name = json_file.get_basename()
		var new_node = example.duplicate()
		new_node.text = base_name
		new_node.visible = true
		self.add_child(new_node)

#exe处理
func exe_get_file():
	var folder_path = "res://bank/"
	if Global_Setting.bank_host:
		var exe_dir = OS.get_executable_path().get_base_dir()
		folder_path = exe_dir.path_join("bank")
	# 检查文件夹是否存在
		var dir = DirAccess.open(folder_path)
		if dir:
			print("文件夹存在: " + folder_path)
	if is_mistake_mode:
		var exe_dir = OS.get_executable_path().get_base_dir()
		folder_path = exe_dir.path_join("mistake_note")
		var dir = DirAccess.open(folder_path)
		if dir:
			print("文件夹存在: " + folder_path)
		# 列出文件夹中的所有文件
	return(folder_path)
