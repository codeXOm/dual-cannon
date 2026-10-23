@tool
extends SceneTree

func _init() -> void:
	print("GODOT 4 RUNNER INITIALIZED SUCCESSFULLY")
	print("Engine version: ", Engine.get_version_info()["string"])
	quit(0)
