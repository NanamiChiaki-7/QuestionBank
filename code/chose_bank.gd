extends Label

var random_TF = false
var timer_TF = false
var mistake_TF = false
var mistake_mode = false

func _ready():
	var botton = $Button
	var random_botton = $"../../../QuestionSettingsPanel/SettingsContainer/RandomOrderToggle"
	var timer_botton = $"../../../QuestionSettingsPanel/SettingsContainer/TimerToggle"
	var mistake_button = $"../../../QuestionSettingsPanel/SettingsContainer/MistakeBookToggle"
	botton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
	random_botton.pressed.connect(_random_botton_pressed)
	timer_botton.pressed.connect(_timer_botton_pressed)
	mistake_button.pressed.connect(_mistake_botton_pressed)
func _random_botton_pressed():
	random_TF = not random_TF
func _timer_botton_pressed():
	timer_TF = not timer_TF
func _mistake_botton_pressed():
	mistake_TF = not mistake_TF
func _on_button_pressed():
	var father = $"../../.."
	var target = $"../../../../QuizPanel"
	father.visible = false
	target.visible = true
	target.file_name = self.text
	target.random_mode = random_TF
	target.timer_enabled = timer_TF
	target.mistake_export_enabled = mistake_TF
	# 匹配格式：原文件名_mistakes_年月日_时分
	var regex = RegEx.new()
	regex.compile(".*_mistakes_\\d{8}_\\d{4}$")
	mistake_mode = regex.search(self.name) != null
	target.mistake_mode = mistake_mode
	target.initialize_quiz_system()
	# 在这里添加你的逻辑
