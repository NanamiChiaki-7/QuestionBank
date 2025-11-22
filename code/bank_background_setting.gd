extends VBoxContainer

@onready var example = $example_

func _ready() -> void:
	var file_path = "res://background/"
	file_path = exe_get_file()
	item_sommon(file_path)
func item_sommon(folder_path:String):
	var dir = DirAccess.open(folder_path)
	if not dir:
		print("错误：无法访问文件夹 ", folder_path)
		return
	for child in $".".get_children():
			if "@Label@" in child.name: 
				child.queue_free()
	var pic_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() in ["png","jpg","jpeg"]:
			pic_files.append(file_name)
		file_name=dir.get_next()
	dir.list_dir_end()
	
	print("找到 ", pic_files.size(), " 个图像文件")
	pic_files.sort()
	
	for pic_file in pic_files:
		var base_name = pic_file
		#print(base_name)
		var new_node = example.duplicate()
		new_node.text = base_name
		new_node.file_name = base_name
		new_node.visible = true
		self.add_child(new_node)
		
#exe处理
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
