## 对话加载器
## 在游戏启动时加载所有对话JSON文件到DialogueManager
extends Node

## 对话文件目录
const DIALOGUE_DIR := "res://data/dialogues/"

## 已加载的对话文件列表
var _loaded_dialogues: Array[String] = []

func _ready() -> void:
	# 等待DialogueManager准备好
	await get_tree().process_frame
	_load_all_dialogues()

## 加载所有对话JSON文件（包括子目录）
func _load_all_dialogues() -> void:
	_load_dialogues_recursive(DIALOGUE_DIR)
	print("[对话加载器] 加载完成，共加载 %d 个对话文件" % _loaded_dialogues.size())

## 递归加载对话JSON文件
func _load_dialogues_recursive(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("[对话加载器] 无法打开对话目录: %s" % dir_path)
		return
	
	var sub_dirs: Array[String] = []
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			sub_dirs.append(dir_path + file_name + "/")
		elif file_name.ends_with(".json"):
			var file_path := dir_path + file_name
			_load_dialogue_file(file_path)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# 递归加载子目录
	for sub_dir in sub_dirs:
		_load_dialogues_recursive(sub_dir)

## 加载单个对话JSON文件
func _load_dialogue_file(file_path: String) -> void:
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager == null:
		push_error("[对话加载器] DialogueManager未找到")
		return
	
	var result: bool = dialogue_manager.load_dialogue_from_json(file_path)
	if result:
		_loaded_dialogues.append(file_path)
		print("[对话加载器] 已加载: %s" % file_path)
	else:
		push_warning("[对话加载器] 加载失败: %s" % file_path)

## 获取已加载的对话文件列表
func get_loaded_dialogues() -> Array[String]:
	return _loaded_dialogues.duplicate()
