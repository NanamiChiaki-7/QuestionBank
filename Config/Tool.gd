extends Node

func _ready() -> void:
	CentralBus.register_service("tool", self)

func debug(err) -> void:
	$VersionLabel.text = err
