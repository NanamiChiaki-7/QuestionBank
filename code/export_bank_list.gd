extends VBoxContainer

@onready var example = $example_

func _ready() -> void:
	example.visible = false
	var file_path = "res://export/"
	file_path=exe_get_file()
	item_sommon(file_path)
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
