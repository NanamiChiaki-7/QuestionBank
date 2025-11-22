extends TextEdit

@onready var father = $".."
@onready var question_type = $"../QuizContainer/QuestionText"
@export var options = []
@export var answer:String
var submit = false
var user_answer = ""
var count = 0 #计数器
var words = "你的回答是:"

func _ready():
	var botton = $SubmitAnswerButton
	var BackButton = $back
	botton.z_index=-1
	BackButton.z_index=-1
	botton.pressed.connect(_on_button_pressed)
func option_change(option,Node_):
	print(answer)
	if option not in options:
		options.append(option)
		Node_.self_modulate = Color.YELLOW_GREEN
	else:
		options.erase(option)
		Node_.self_modulate = Color.WHITE
	for word in options:
		words += word
	self.text = words
	words = "你的回答是:"
func sign_change(val):
	user_answer = val
func _on_button_pressed():
	if submit or count >= 1:
		words = "你的回答是:"
		self.text = words
		submit=false
		options = []
		self.self_modulate = Color.WHITE
		#print(count)
		father.emit_signal("answer_submitted",count)
		count = 0
	else:
		count+=1
		#print(question_type)
		if "填空" in question_type.text or "简答" in question_type.text:
			if self.text.substr(0,6) == "你的回答是:":
				user_answer = self.text.substr(6)
			else:
				user_answer = self.text
			#print(self.text.substr(6))
			var err = 0
			if user_answer.length() > answer.length()*3 or user_answer.length() < answer.length()*0.5:
				submit=true
			for word in user_answer:
				if word not in answer:
					err += 1
					if err >= answer.length()*0.2:
						submit=true
		else:
			if self.text.length() > 6:
				if self.text.substr(6).length() != answer.length():
					submit=true
				for word in self.text.substr(6):
					if word.to_upper() not in answer:
						submit=true
			else:
				if self.text.length() != answer.length():
					submit=true
				for word in self.text:
					if word.to_upper() not in answer:
						submit=true
			
		if submit:
			words = "正确答案是:"
			self.text = words + answer + "," + self.text
			self.self_modulate = Color.FIREBRICK
			count+=1
		else:
			words = "正确答案是:"
			self.text = words + answer + ",回答正确"
			self.self_modulate = Color.GREEN_YELLOW
	# 在这里添加你的逻辑

func back_to_main():
	var main_menu = $"../../MainMenuPanel"
	var grandfather = $"../.."
	if self.visible:
		father.return_data()
		for child in grandfather.get_children():
			if child is not TextureRect:
				child.visible = false
		main_menu.visible = true
