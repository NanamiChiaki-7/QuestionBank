extends Label

@export var file_name:String

@onready var taget_ = $"../../../../../Background"
@onready var file_path = "res://background/"
var texture:ImageTexture

func _ready() -> void:
	file_path = exe_get_file()
	var button = $Button
	button.z_index=-1
	button.pressed.connect(change_pic)
	
func change_pic():
	if self.name != "example_":
		file_path = exe_get_file()
		file_path = file_path.path_join(file_name)
		if not FileAccess.file_exists(file_path):
			print("文件不存在: ", file_path)
			return null
		# 直接加载纹理
		var image = Image.new()
		var error = image.load(file_path)
		texture = ImageTexture.new()
		texture.set_image(image)
		if not texture:
			print("无法加载纹理: ", file_path)
			return
		taget_.texture = texture
		#file_path = "res://background/"
		file_path = exe_get_file()
	else:
		taget_.visible = not taget_.visible

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
