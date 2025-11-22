extends VBoxContainer

@onready var example = $example_
@onready var father = $"../.."

func _ready() -> void:
	for i in range(26):
		var dic_26 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		var new_node = example.duplicate()
		new_node.name = dic_26[i]
		new_node.visible = false
		self.add_child(new_node)
func re_(options_text:String):
	var lines = options_text.split("\n")
	var dic_26 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var count_ = 0
	var options = []
	for line in lines:
		line = line.strip_edges()  # 去除前后空格
		if not line.is_empty():    # 跳过空行
			options.append(line)
	for child in self.get_children():
		child.self_modulate = Color.WHITE
		child.visible = false  # 安全删除
		if child.name != "example_" and count_ < options.size():
			var option = options[count_]
			if option.length() > 1 and option[0] in dic_26:
				option = option[0] + ". " + option.substr(1)
			child.text = option
			child.visible = true
			count_+=1
