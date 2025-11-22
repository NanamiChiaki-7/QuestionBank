# HTTPManager.gd
extends Node

signal verification_completed(success: bool, data: Dictionary)
signal verification_failed(error: String)

var _http_request: HTTPRequest

func _ready():
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)

# 验证用户函数 - 添加 username 和 version 参数
func verify_user(finger: String, allow_code: String, username: String, version: String = Global_Setting.version, server_url: String = "http://your_sever/verify"):
	var IPaddresses = IP.get_local_addresses()
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"finger": finger,
		"allow_code": allow_code,
		"username": username,  # 新增：用户名
		"version": version     # 新增：版本号
	})
	'''
	print("发送验证请求:")
	print("指纹: ", finger)
	print("验证码: ", allow_code)
	print("用户名: ", username)
	print("版本: ", version)
	print("服务器: ", server_url)
	'''
	var error = _http_request.request(server_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		verification_failed.emit("请求创建失败: " + str(error))

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		verification_failed.emit("网络请求失败: " + str(result))
		return

	# 解析响应
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result != OK:
		verification_failed.emit("响应解析失败")
		return

	var response = json.get_data()
	'''
	print("服务器响应:")
	print("状态码: ", response_code)
	print("响应数据: ", response)
	'''
	Global_Setting.UserData = response
	if response_code == 200 or response_code == 201:
		# 检查响应中是否包含必要的字段
		if response.has("success") and response["success"]:
			verification_completed.emit(true, response)
		else:
			verification_completed.emit(false, response)
	else:
		verification_completed.emit(false, response)
		


func get_user(allow_code: String, server_url: String = "http://your_sever/getuser"):
	var url = server_url + "?allow_code=" + allow_code
	'''
	print("发送获取用户信息请求:")
	print("验证码: ", allow_code)
	print("完整URL: ", url)
	'''
	var error = _http_request.request(url)
	if error != OK:
		verification_failed.emit("请求创建失败: " + str(error))
	
#func _on_get_user_completed()
