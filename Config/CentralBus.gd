extends Node

# ==================== 事件总线部分 ====================
signal Debug
# ==================== 服务定位器部分 ====================
var _services = {}

func register_service(name: String, service):
	_services[name] = weakref(service)
	print("[CentralBus] 服务注册: ", name)

func get_service(name: String):
	if not _services.has(name):
		push_error("[CentralBus] 服务未找到: " + name)
		return null
	var ref = _services[name].get_ref()
	if not ref:
		push_error("[CentralBus] 服务已释放: " + name)
		_services.erase(name)
		return null
	return ref
	
# ==================== 快捷方法 ====================
# 事件发射快捷方式

# 服务获取快捷方式 
