extends Node


func _ready():
# 定义需要预留的文件夹名称
	var folders = ["bank","background"]
	# 创建每个文件夹
	for folder in folders:
		var path = "user://" + folder
		# 如果文件夹不存在，则创建
		DirAccess.make_dir_recursive_absolute(path)
		print("创建文件夹: ", path)
