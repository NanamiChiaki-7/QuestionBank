extends Control

# ==============================================================================
# 导出变量区域
# ==============================================================================

@export var file_name: String
@export var random_mode: bool  # 随机模式
@export var timer_enabled: bool  # 计时器开关
@export var mistake_export_enabled: bool  # 错题导出开关
@export var mistake_mode: bool = false  # 错题模式
@export var done_questions: Array = []  # 已完成的题目ID
@export var mistake_questions: Array = []  # 错题ID
@export var correct_questions: Array = []  # 正确题目ID
@export var current_question_id: int = 0  # 当前题目ID
@export var mistake_count_dict: Dictionary = {}  # 错题计数字典
@export var elapsed_time: float = 0.0  # 已用时间

# ==============================================================================
# 节点引用区域
# ==============================================================================

@onready var file_path: String = "res://bank/"
@onready var main_menu: Control = $"../MainMenuPanel"
@onready var completion_notice: Button = $CompletionNotice
@onready var back_button: Button = $AnswerInput/back
@onready var current_time_label: Label = $QuizContainer/HeaderContainer/QuestionIdLabel/CurrentTimeLabel
@onready var timer_label: Label = $QuizContainer/HeaderContainer/QuestionIdLabel/TimerLabel
@onready var counter_label: Label = $QuizContainer/HeaderContainer/CounterLabel
@onready var accuracy_label: Label = $QuizContainer/HeaderContainer/AccuracyLabel
@onready var settings_panel: Control = $"../SettingsPanel"
@onready var answer_input: Control = $AnswerInput
@onready var parent: Control = $".."
@onready var question_image:TextureRect = $QuizContainer/ImageContainer/QuestionImage
# 题目图片
var question_texture: ImageTexture

# ==============================================================================
# 数据存储区域
# ==============================================================================

var file_name_cache: String  # 文件名缓存
var history_data: Dictionary  # 历史数据
var json_data: Dictionary  # JSON数据
var json_array: Array  # JSON数组

# 计时器相关
var last_time: float = 0.0

# ==============================================================================
# 信号定义区域
# ==============================================================================

signal answer_submitted  # 答案提交信号

# ==============================================================================
# 主流程函数区域
# ==============================================================================

func _process(delta: float) -> void:
	update_current_time()
	
	if timer_enabled:
		elapsed_time += delta
		update_timer_display()
	
	if Input.is_action_just_pressed("ui_esc_"):  # ESC键处理
		handle_escape_key()

func _ready() -> void:
	connect_signals()

# ==============================================================================
# 初始化函数区域
# ==============================================================================

# 初始化题库系统
func initialize_quiz_system():
	file_name_cache = file_name
	reset_quiz_data()
	completion_notice.visible = false
	
	var load_result = load_json_data()
	if load_result == null:
		return
	
	if mistake_mode:
		validate_mistake_mode_access()
	
	current_question_id = 0
	display_next_question()
	update_ui_counters()

# 重置答题数据
func reset_quiz_data() -> void:
	elapsed_time = 0.0
	done_questions.clear()
	mistake_questions.clear()
	correct_questions.clear()

# 连接信号
func connect_signals() -> void:
	answer_submitted.connect(wait_for_submit)
	completion_notice.pressed.connect(exit_to_main_menu)
	back_button.pressed.connect(exit_to_main_menu)

# ==============================================================================
# 数据加载和处理区域
# ==============================================================================

# 加载JSON数据
func load_json_data() -> Array:
	var full_file_path = get_file_path() + file_name + ".json"
	
	if not FileAccess.file_exists(full_file_path):
		print("文件不存在: ", full_file_path)
		return []
	
	var file = FileAccess.open(full_file_path, FileAccess.READ)
	if not file:
		print("无法打开文件: ", full_file_path)
		return []
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) == OK:
		json_array = json.get_data()
		print("JSON数据已加载到内存")
		return json_array
	else:
		print("JSON解析错误: ", json.get_error_message())
		return []

# 验证错题模式访问权限
func validate_mistake_mode_access() -> void:
	for question_data in json_array:
		current_question_id = question_data["id"]
		if current_question_id == 1:
			if question_data["answer"] != extract_12_digit_code(_get_stable_device_id()):
				exit_to_main_menu()

# ==============================================================================
# 题目展示区域
# ==============================================================================

# 显示下一道题目
func display_next_question() -> void:
	if not random_mode:
		display_sequential_questions()
	else:
		display_random_questions()

# 顺序显示题目
func display_sequential_questions() -> void:
	while done_questions.size() < json_array.size():
		for question_data in json_array:
			configure_question_input_type(question_data["question"])
			current_question_id = question_data["id"]
			
			if "作者" not in question_data["question"] and current_question_id not in done_questions:
				display_question_data(question_data)
				await answer_submitted
			elif "作者" in question_data["question"] and current_question_id not in done_questions:
				done_questions.append(current_question_id)
	
	complete_quiz_session()

# 随机显示题目
func display_random_questions() -> void:
	var error_count = 0
	var max_errors = 3000

	while error_count < max_errors:
		var random_id = randi_range(0, json_array.size())
		
		for question_data in json_array:
			print(current_question_id,done_questions)
			current_question_id = question_data["id"]
			
			if "作者" not in question_data["question"] and current_question_id not in done_questions and current_question_id == random_id:
				error_count = 0
				display_question_data(question_data)
				await answer_submitted
			elif "作者" in question_data["question"] and current_question_id not in done_questions:
				done_questions.append(current_question_id)
			else:
				error_count += 1
	
	complete_quiz_session()

# 显示题目数据
func display_question_data(question_data: Dictionary) -> void:
	var image_container = $QuizContainer/ImageContainer
	var question_id_label = $QuizContainer/HeaderContainer/QuestionIdLabel
	var tags_label = $QuizContainer/HeaderContainer/TagsLabel
	var question_text_label = $QuizContainer/QuestionText
	var options_container = $QuizContainer/OptionsContainer
	
	image_container.visible = false
	question_id_label.text = str(question_data["id"]) + "."
	tags_label.text = question_data["tags"]
	question_text_label.text = question_data["question"]
	answer_input.answer = question_data["answer"]
	
	if "img" in question_data["options"]:
		options_container.visible = false
		display_question_image(question_data["options"])
	else:
		options_container.visible = true
		options_container.re_(question_data["options"])

# ==============================================================================
# 图片处理区域
# ==============================================================================

# 显示题目图片
func display_question_image(options_text: String) -> void:
	var image_container = $QuizContainer/ImageContainer
	var start_index = options_text.find("img")
	
	if start_index != -1:
		var image_name = options_text.substr(start_index + 3).strip_edges()
		var image_path = get_image_directory().path_join(image_name)
		
		if not FileAccess.file_exists(image_path):
			print("图片文件不存在: ", image_path)
			#Tool.debug("图片文件不存在")
			return
		
		var image = Image.new()
		var error = image.load(image_path)
		
		if image.get_width() / image.get_height() < 0.95:
			image.rotate_90(CLOCKWISE)
		
		question_texture = ImageTexture.new()
		question_texture.set_image(image)
		
		if not question_texture:
			print("无法加载图片纹理: ", image_path)
			return
		
		question_image.texture = question_texture
		image_container.visible = true

# ==============================================================================
# 答题处理区域
# ==============================================================================

# 等待答案提交
func wait_for_submit(answer_count: int) -> void:
	if answer_count > 1:
		handle_wrong_answer()
	else:
		handle_correct_answer()
	
	update_ui_counters()
	await get_tree().create_timer(0.5).timeout

# 处理错误答案
func handle_wrong_answer() -> void:
	if current_question_id not in mistake_questions:
		mistake_questions.append(current_question_id)
		if mistake_count_dict.has(current_question_id):
			mistake_count_dict[current_question_id] += 1
		else:
			mistake_count_dict[current_question_id] = 1

# 处理正确答案
func handle_correct_answer() -> void:
	if current_question_id not in mistake_questions:
		correct_questions.append(current_question_id)
	done_questions.append(current_question_id)

# ==============================================================================
# UI更新区域
# ==============================================================================

# 更新UI计数器
func update_ui_counters() -> void:
	counter_label.text = str(done_questions.size(), "/", json_array.size() - 1)
	
	if done_questions.size() == 0:
		accuracy_label.text = str("正确率:", 0, "%")
	else:
		var accuracy_percentage = round((float(correct_questions.size()) / (float(json_array.size() - 1))) * 100)
		accuracy_label.text = str("正确率:", accuracy_percentage, "%")

# ==============================================================================
# 时间处理区域
# ==============================================================================

# 更新当前时间显示
func update_current_time() -> void:
	var time_dict = Time.get_datetime_dict_from_system(false)
	var current_time_string = "%02d:%02d" % [time_dict["hour"], time_dict["minute"]]
	current_time_label.text = str("当前时间：", current_time_string)

# 更新计时器显示
func update_timer_display() -> void:
	var hours = int(elapsed_time) / 3600
	var minutes = (int(elapsed_time) % 3600) / 60
	var seconds = int(elapsed_time) % 60
	var milliseconds = int((elapsed_time - int(elapsed_time)) * 100)
	
	timer_label.text = str("计时：", format_time_string(hours, minutes, seconds, milliseconds))

# 格式化时间字符串
func format_time_string(hours: int, minutes: int, seconds: int, milliseconds: int) -> String:
	if hours > 0:
		return "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, milliseconds]
	else:
		return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

# ==============================================================================
# 退出和完成处理区域
# ==============================================================================

# 完成答题会话
func complete_quiz_session() -> void:
	timer_enabled = false
	completion_notice.visible = true
	save_quiz_data()

# 退出到主菜单
func exit_to_main_menu() -> void:
	file_path = get_file_path()
	done_questions.clear()
	mistake_questions.clear()
	
	var main_menu_panel = $"../MainMenuPanel"
	self.visible = false
	main_menu_panel.visible = true

# 处理ESC键
func handle_escape_key() -> void:
	if self.visible:
		save_quiz_data()
	
	for child in parent.get_children():
		if child is not TextureRect and child.name != "VersionLabel":
			child.visible = false
			
	
	settings_panel.reset_ui()
	main_menu.visible = true

# ==============================================================================
# 数据保存和导出区域
# ==============================================================================

# 保存答题数据
func save_quiz_data() -> void:
	var history_file_path = get_history_directory().path_join("history.json")
	print(history_file_path)
	
	if not FileAccess.file_exists(history_file_path):
		print("文件不存在: " + history_file_path)
		return
	
	var file = FileAccess.open(history_file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_string) == OK:
		history_data = json.get_data()
		print("JSON数据已加载到内存")
	else:
		print("JSON解析错误: ", json.get_error_message())
		return
	
	var save_data = create_save_data()
	var final_save_data = {get_current_time_string(): save_data}
	
	print(save_data)
	
	var final_json_string = JSON.stringify(merge_dictionaries(history_data, final_save_data), "\t")
	var write_file = FileAccess.open(history_file_path, FileAccess.WRITE)

	write_file.store_string(final_json_string)
	write_file.close()
	print("历史数据已保存: ", history_file_path)
	
	if mistake_questions.size() > 0 and mistake_export_enabled:
		export_mistake_collection()

# 创建保存数据
func create_save_data() -> Dictionary:
	var save_data = {}
	
	if done_questions.size() < json_array.size():
		save_data["中途退出"] = "是"
	else:
		save_data["中途退出"] = "否"
	
	save_data["错题题号"] = mistake_questions
	save_data["正确率"] = str(round((float(correct_questions.size()) / (float(json_array.size() - 1))) * 100), "%")
	save_data["耗时"] = get_timer_text()
	save_data["章节"] = file_name_cache
	
	return save_data

# 合并字典
func merge_dictionaries(target: Dictionary, updates: Dictionary) -> Dictionary:
	for key in updates.keys():
		target[key] = updates[key]
	return target

# ==============================================================================
# 错题导出区域
# ==============================================================================

# 导出错题集合
func export_mistake_collection() -> void:
	if json_array == null or mistake_questions.size() == 0:
		return
	
	var mistake_collection = collect_mistake_data()
	
	if mistake_collection.size() <= 1:
		return
	
	var mistake_file_path = generate_mistake_filename()
	save_mistake_file(mistake_collection, mistake_file_path)

# 收集错题数据
func collect_mistake_data() -> Array:
	var mistake_collection = []
	var header_added = false
	
	for problem in json_array:
		var problem_id = problem["id"]
		
		if "作者" in problem["question"]:
			if not header_added:
				var header_problem = problem.duplicate()
				header_problem["question"] = "错题集合 - 源自: " + file_name_cache + " - 导出时间: " + get_current_time_string() + "作者"
				header_problem["answer"] = extract_12_digit_code(_get_stable_device_id())
				mistake_collection.append(header_problem)
				header_added = true
			continue
		
		if problem_id in mistake_questions:
			var mistake_problem = problem.duplicate()
			if mistake_count_dict.has(problem_id):
				mistake_problem["mistake_count"] = mistake_count_dict[problem_id]
			else:
				mistake_problem["mistake_count"] = 1
			mistake_collection.append(mistake_problem)
	
	return mistake_collection

# 生成错题文件名
func generate_mistake_filename() -> String:
	var time_dict = Time.get_datetime_dict_from_system(false)
	var filename_suffix = "%04d%02d%02d_%02d%02d" % [
		time_dict["year"], time_dict["month"], time_dict["day"],
		time_dict["hour"], time_dict["minute"]
	]
	
	var mistake_filename = file_name_cache + "_mistakes_" + filename_suffix + ".json"
	return get_mistake_note_directory().path_join(mistake_filename)

# 保存错题文件
func save_mistake_file(mistake_collection: Array, file_path: String) -> void:
	var json_string = JSON.stringify(mistake_collection, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		file.store_string(json_string)
		file.close()
		print("错题集合已导出: ", file_path)
		print("包含错题数量: ", mistake_collection.size() - 1)
	else:
		print("错题集合导出失败: ", file_path)

# ==============================================================================
# 工具函数区域
# ==============================================================================

# 配置题目输入类型
func configure_question_input_type(question_text: String) -> void:
	if "填空" in question_text or "简答" in question_text:
		answer_input.editable = true
	else:
		answer_input.editable = true  # 不确定# 这里可能需要调整

# 获取计时器文本
func get_timer_text() -> String:
	var hours = int(elapsed_time) / 3600
	var minutes = (int(elapsed_time) % 3600) / 60
	var seconds = int(elapsed_time) % 60
	var milliseconds = int((elapsed_time - int(elapsed_time)) * 100)
	return format_time_string(hours, minutes, seconds, milliseconds)

# 获取当前时间字符串
func get_current_time_string() -> String:
	return Time.get_datetime_string_from_system()

# ==============================================================================
# 设备ID和安全验证区域
# ==============================================================================

# 获取稳定设备ID
func _get_stable_device_id() -> String:
	var components = []
	
	if OS.has_method("get_unique_id"):
		var system_id = OS.get_unique_id()
		if not system_id.is_empty() and system_id != "unknown":
			components.append("sys_" + system_id)
	elif OS.has_method("get_static_memory_usage"):
		var memory_mb = OS.get_static_memory_usage()
		var memory_rounded = snapped(memory_mb, 512)
		components.append("mem_" + str(int(memory_rounded)))
	
	if components.size() == 1:
		components.append("cpu_" + str(OS.get_processor_count()))
		components.append("os_" + str(OS.get_name().hash()))
	
	var combined_string = "_".join(components)
	print(combined_string)
	return combined_string.sha256_text().substr(0, 48)

# 提取12位数字代码
func extract_12_digit_code(hash: String) -> String:
	var positions = [2, 7, 13, 19, 23, 29, 31, 37, 41, 43, 47, 53]
	var code = ""
	
	for pos in positions:
		if pos < hash.length():
			code += hash[pos]
		else:
			code += hash[pos % hash.length()]
	
	return code

# ==============================================================================
# 文件路径处理区域
# ==============================================================================

# 获取文件目录
func get_file_directory() -> String:
	var folder_path = "res://bank/"
	
	if Global_Setting.bank_host or mistake_mode:
		var exe_dir = OS.get_executable_path().get_base_dir()
		if mistake_mode:
			folder_path = exe_dir.path_join("mistake_note")
		else:
			folder_path = exe_dir.path_join("bank")
		
		var dir = DirAccess.open(folder_path)
		if dir:
			print("文件夹存在: " + folder_path)
	
	return folder_path

# 获取错题笔记目录
func get_mistake_note_directory() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	var folder_path = exe_dir.path_join("mistake_note")
	
	var dir = DirAccess.open(exe_dir)
	if dir:
		dir.make_dir("mistake_note")
		print("错题笔记文件夹: " + folder_path)
	
	return folder_path

# 获取图片目录
func get_image_directory() -> String:
	var folder_path = "res://IMG/"
	
	if Global_Setting.IMG_host:
		var exe_dir = OS.get_executable_path().get_base_dir()
		folder_path = exe_dir.path_join("IMG")
		
		var dir = DirAccess.open(folder_path)
		if dir:
			print("文件夹存在: " + folder_path)
	
	return folder_path

# 获取历史文件目录
func get_history_directory() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	var folder_path = exe_dir.path_join("history")
	
	var dir = DirAccess.open(folder_path)
	if dir:
		print("文件夹存在: " + folder_path)
	
	return folder_path

# ==============================================================================
# 文件路径别名（保持兼容性）
# ==============================================================================

func get_file_path() -> String:
	return get_file_directory()

func exe_get_file() -> String:
	return get_file_directory()

func exe_get_mistake_note_file() -> String:
	return get_mistake_note_directory()

func exe_get_IMG() -> String:
	return get_image_directory()

func exe_get_history_file() -> String:
	return get_history_directory()
