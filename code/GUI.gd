extends Panel

# ========================================================
# 节点引用
# ========================================================
@onready var http_manager = $HTTPManager
@onready var main_menu = $MainMenuPanel/MenuOptionsContainer
@onready var user_info_label = $MainMenuPanel/UserInfoLabel
@onready var username_input = $MainMenuPanel/LoginPanel/UsernameInput

# ========================================================
# 变量声明
# ========================================================
var online = true
var username = ""
signal username_received

# ========================================================
# 生命周期函数
# ========================================================
func _ready() -> void:
	main_menu.visible = false
	_setup_application_directories()
	_handle_verification_process()
	_setup_admin_permissions()

# ========================================================
# 目录管理函数
# ========================================================
func _setup_application_directories() -> void:
	"""创建应用所需的目录结构"""
	for folder_name in ["bank", "background", "history", "export", "mistake_note", "IMG"]:
		var exe_dir = OS.get_executable_path().get_base_dir()
		var folder_path = exe_dir.path_join(folder_name)
		var dir = DirAccess.open(exe_dir)
		
		if dir:
			if not dir.dir_exists(folder_name):
				var error = dir.make_dir(folder_name)
				if error == OK:
					print("文件夹创建成功: " + folder_path)
				else:
					print("文件夹创建失败，错误代码: " + str(error))
			else:
				print("文件夹已存在: " + folder_path)
		else:
			print("无法访问目录: " + exe_dir)

# ========================================================
# 验证流程函数
# ========================================================
func _handle_verification_process() -> void:
	"""处理用户验证流程"""
	if Global_Setting.off_line:
		_handle_offline_verification()
	else:
		_handle_online_verification()

func _handle_offline_verification() -> void:
	"""处理离线验证"""
	var fingerprint = _get_usb_fingerprint()
	if fingerprint not in Verification_Code.dic and not Global_Setting.admin:
		_show_anti_piracy_warning()
		print("生成的设备指纹: ", fingerprint)

func _handle_online_verification(change=false) -> void:
	"""处理在线验证"""
	var login_panel = $MainMenuPanel/LoginPanel
	http_manager.verification_completed.connect(_on_verification_completed)
	http_manager.verification_failed.connect(_on_verification_failed)
	
	var device_fingerprint = _get_stable_device_id()
	var verification_code = _extract_12_digit_code(device_fingerprint)
	user_info_label.text = verification_code
	http_manager.get_user(verification_code)
	await http_manager.verification_completed
	if not Global_Setting.UserData["success"] or change:
		var main_menu_choices = $MainMenuPanel/MenuOptionsContainer
		for child in main_menu_choices.get_children():
			child.visible = false
		login_panel.visible = true
		await _get_username_input()
		for child in main_menu_choices.get_children():
			child.visible = true
		login_panel.visible = false
		verify_user(device_fingerprint, verification_code, username)
	else:
		login_panel.visible = false
		verify_user(device_fingerprint, verification_code, "NULL")#NULL为魔法 不更改用户名的更改
	

func _get_username_input() -> void:
	"""获取用户名输入"""
	await username_received
	username = username_input.text
	while username == "" or username =="NULL":
		username_input.placeholder_text = "请输入用户名"
		await username_received
		username = username_input.text
	if username.length() > 24:
		username = username.substr(0, 24)
	if Global_Setting.mobile_:
		username = "手机用户|" + username
	else:
		username = "电脑用户|" + username
	username_input.text= ""

# ========================================================
# 权限管理函数
# ========================================================
func _setup_admin_permissions() -> void:
	"""设置管理员权限"""
	if not Global_Setting.admin:
		var main_menu_choices = $MainMenuPanel/MenuOptionsContainer
		for child in main_menu_choices.get_children():
			if child.name == "ImportPanel":
				child.visible = false

# ========================================================
# 设备指纹相关函数
# ========================================================
func _get_usb_fingerprint() -> String:
	"""获取USB设备指纹"""
	var output = []
	OS.execute("cmd", ["/c", "wmic diskdrive where \"InterfaceType='USB'\" get Size,Model,SerialNumber,InterfaceType /value"], output, true)
	
	var combined_data = ""
	for line in output:
		combined_data += line.strip_edges()
	
	return combined_data.sha256_text()

func _get_stable_device_id() -> String:
	"""获取稳定的设备标识符"""
	var components = []
	
	# 系统唯一识别码
	if OS.has_method("get_unique_id"):
		var system_id = OS.get_unique_id()
		if not system_id.is_empty() and system_id != "unknown":
			components.append("sys_" + system_id)
	elif OS.has_method("get_static_memory_usage"):
		# 内存大小信息作为备选
		var memory_mb = OS.get_static_memory_usage()
		var memory_rounded = snapped(memory_mb, 512)
		components.append("mem_" + str(int(memory_rounded)))
	
	# 后备硬件信息
	if components.size() == 1:  # 只有内存信息
		components.append("cpu_" + str(OS.get_processor_count()))
		components.append("os_" + str(OS.get_name().hash()))
	
	var combined_string = "_".join(components)
	print(combined_string)
	return combined_string.sha256_text().substr(0, 48)

func _get_fallback_device_id() -> String:
	"""获取备用设备标识符"""
	var fallback_data = {}
	
	# 用户目录路径
	var user_dir = OS.get_user_data_dir()
	fallback_data["user_dir_base"] = user_dir.get_base_dir().replace("\\", "/").split("/")[-1]
	
	# 操作系统版本
	fallback_data["os_version"] = OS.get_version().split(" ")[0]
	
	# 设备型号
	fallback_data["model"] = OS.get_model_name()
	
	var fallback_string = JSON.stringify(fallback_data)
	return fallback_string.sha256_text().substr(0, 16)

func _get_architecture() -> String:
	"""获取系统架构信息"""
	var version_info = Engine.get_version_info()
	var arch = version_info.get("build_type", "unknown")
	
	if "64" in arch:
		return "x64"
	elif "32" in arch:
		return "x86"
	else:
		return "unknown"

func _extract_12_digit_code(hash: String) -> String:
	"""从哈希值中提取12位验证码"""
	var positions = [2, 7, 13, 19, 23, 29, 31, 37, 41, 43, 47, 53]
	var code = ""
	
	for pos in positions:
		if pos < hash.length():
			code += hash[pos]
		else:
			# 位置超出时使用模运算回绕
			code += hash[pos % hash.length()]
	
	return code

# ========================================================
# 用户验证函数
# ========================================================
func verify_user(fingerprint: String, verification_code: String, username: String):
	"""验证用户权限"""
	print("开始验证用户...")
	http_manager.verify_user(fingerprint, verification_code, username)

func _on_verification_completed(success: bool, data: Dictionary):
	"""验证完成回调"""
	if success:
		print("验证成功!")
		print("用户ID: ", data.get("user_id", ""))
		print("用户名: ", data.get("username", ""))
		print("权限等级: ", data.get("level", -1))
		print("有效期至: ", data.get("end_date", ""))
		print("是否有效: ", data.get("valid", false))
		print("版本: ", data.get("version", ""))
		print("最后验证时间: ", data.get("last_verify_time", ""))
		Global_Setting.UserData = data
		if "用户|" in Global_Setting.UserData["username"]:
			user_info_label.text = "你好,%s" % Global_Setting.UserData["username"].substr(5,-1)#欢迎
		else:
			user_info_label.text = "你好,%s" % Global_Setting.UserData["username"]
		
		if not data.get("valid", false):
			_handle_expired_verification()
		elif data.get("end_date", "") < "2060-1-1":
			var version_label = $VersionLabel
			version_label.text = str(Global_Setting.version) + " 有效期至：" + data.get("end_date", "")
			_handle_user_level(data.get("level", -1))
		else:
			_handle_user_level(data.get("level", -1))
		
		_save_verification_data(data)
	else:
		print("验证失败: ", data.get("message", "未知错误"))

func _on_verification_failed(error: String):
	"""验证失败回调"""
	online = false
	print("验证过程出错: ", error)
	
	var title = $MainMenuPanel/AppTitle
	var name_label = $MainMenuPanel/NameLabel
	var main_menu_choices = $MainMenuPanel/MenuOptionsContainer
	
	#Tool.debug(error)
	
	var device_hash = _get_stable_device_id()
	var temp_code = _extract_12_digit_code(device_hash)
	
	if Global_Setting.mobile_:
		Global_Setting.bank_host = false
		Global_Setting.history_host = false
		Global_Setting.theme_host = false
		Global_Setting.inport_ = false
		Global_Setting.IMG_host = false
		
	if temp_code in Verification_Code.dic:
		title.text = "题库系统(不稳定 移动版)"
		main_menu_choices.visible = true
	else:
		title.text = "验证超时"
		for child in main_menu_choices.get_children():
			child.visible = false
		name_label.text = temp_code
		await get_tree().create_timer(20).timeout
		get_tree().quit()

# ========================================================
# 验证数据处理函数
# ========================================================
func _save_verification_data(data: Dictionary):
	"""保存验证数据到本地配置文件"""
	var config = ConfigFile.new()
	config.set_value("auth", "user_id", data.get("user_id", ""))
	config.set_value("auth", "finger", data.get("finger", ""))
	config.set_value("auth", "allow_code", data.get("allow_code", ""))
	config.set_value("auth", "level", data.get("level", -1))
	config.set_value("auth", "end_date", data.get("end_date", ""))
	config.set_value("auth", "valid", data.get("valid", false))

	config.save("user://auth.cfg")

func _handle_expired_verification():
	"""处理验证过期情况"""
	main_menu.visible = true
	var title = $MainMenuPanel/AppTitle
	title.text = "验    证    过    期"
	var main_menu_choices = $MainMenuPanel/MenuOptionsContainer
	for child in main_menu_choices.get_children():
		child.visible = false
	await get_tree().create_timer(10).timeout
	get_tree().quit()

func _show_anti_piracy_warning():
	"""显示反盗版警告"""
	var title = $MainMenuPanel/AppTitle
	title.text = "请勿使用盗版！！！"
	var main_menu_choices = $MainMenuPanel/MenuOptionsContainer
	for child in main_menu_choices.get_children():
		child.visible = false
	await get_tree().create_timer(10).timeout
	get_tree().quit()

# ========================================================
# 用户权限处理函数 (尽量不改变原逻辑)
# ========================================================
func _handle_user_level(level: int):
	"""根据用户权限等级设置功能可用性"""
	var history_content = $HistoryPanel/HistoryContent
	var timer = $BankSelectionPanel/QuestionSettingsPanel/SettingsContainer/timer_
	var import_panel = $MainMenuPanel/MenuOptionsContainer/Inport
	var mistake_notebook = $MainMenuPanel/MenuOptionsContainer/mistake_notebook
	var favorites = $MainMenuPanel/MenuOptionsContainer/Favorites
	var setting = $MainMenuPanel/MenuOptionsContainer/Setting
	var mistake_import = $BankSelectionPanel/QuestionSettingsPanel/SettingsContainer/mistake_book_
	
	match level:
		-1:
			print("等待管理员授权")
			main_menu.visible = true
			var title = $MainMenuPanel/AppTitle
			title.text = "等    待    授    权"
			var main_menu_choices = $MainMenuPanel/MenuOptionsContainer
			for child in main_menu_choices.get_children():
				child.visible = false
			await get_tree().create_timer(10).timeout
			get_tree().quit()
		0:
			print("普通用户权限")
			main_menu.visible = true
			history_content.visible = false
			timer.visible = false
			mistake_notebook.visible = false
			mistake_import.visible = false
			favorites.visible = false
			setting.visible = true
			import_panel.visible = false
			Global_Setting.theme_host = false
		1:
			print("亚高级用户权限")
			main_menu.visible = true
			mistake_notebook.visible = false
			mistake_import.visible = false
			favorites.visible = false
			import_panel.visible = false
			Global_Setting.theme_host = false
		2:
			print("高级用户权限")
			main_menu.visible = true
			favorites.visible = false
			import_panel.visible = false
			Global_Setting.theme_host = false
		3:
			print("次高用户权限")
			main_menu.visible = true
			import_panel.visible = false
			Global_Setting.theme_host = false
		4:
			print("至高用户权限")
			main_menu.visible = true
			import_panel.visible = false
			Global_Setting.theme_host = true
		-4:
			print("试用至高用户权限")
			var title = $MainMenuPanel/AppTitle
			title.text = "题  库  系  统"
			main_menu.visible = true
			import_panel.visible = false
			Global_Setting.theme_host = true
		5:
			print("代理级用户权限")
			main_menu.visible = true
			import_panel.visible = true
			Global_Setting.theme_host = true
			Global_Setting.bank_host = true
		999:
			print("管理员权限")
			main_menu.visible = true
			Global_Setting.admin = true
			Global_Setting.theme_host = false
		_:
			print("未知权限等级")
			main_menu.visible = false
