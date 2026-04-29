# WorldStateLoader - 世界状态加载器
#
# 负责从本地存储读取和解析加密的存档文件
# 符合 ADR-001 架构决策：使用 JSON 格式本地存储，组件化设计

class_name WorldStateLoader
extends Node

# ============================================================================
# 常量定义
# ============================================================================

const ENCRYPTION_KEY: String = "wuxia_jianghu_2026"
const LOG_PREFIX: String = "[WorldStateLoader]"
const MAX_BACKUP_ATTEMPTS: int = 3

# ============================================================================
# 信号定义
# ============================================================================

## 加载完成信号
signal load_completed(save_data: Dictionary)

## 加载失败信号
signal load_failed(error_message: String)

# ============================================================================
# 成员变量
# ============================================================================

var debug_enabled: bool = true

# 从指定路径加载游戏状态
func load_game(save_path: String) -> void:
	# 在后台线程中执行加载操作，避免阻塞主线程
	var thread = Thread.new()
	thread.start(_load_game_thread.bind(save_path))

# 后台线程加载函数
func _load_game_thread(save_path: String) -> void:
	var result = _perform_load(save_path)
	if result.success:
		call_deferred("emit_signal", "load_completed", result.save_data)
	else:
		call_deferred("emit_signal", "load_failed", result.error_message)

# 执行实际的加载操作
func _perform_load(save_path: String) -> Dictionary:
	var result = {"success": false, "error_message": "", "save_data": null}
	
	# 检查文件是否存在
	var dir = Directory.new()
	if not dir.file_exists(save_path):
		# 尝试从备份文件恢复
		var backup_data = _try_load_from_backup(save_path)
		if backup_data != null:
			result.success = true
			result.save_data = backup_data
			return result
		
		result.error_message = "Save file does not exist: " + save_path
		return result
	
	# 读取文件内容
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		# 尝试从备份文件恢复
		var backup_data = _try_load_from_backup(save_path)
		if backup_data != null:
			result.success = true
			result.save_data = backup_data
			return result
		
		result.error_message = "Failed to open file for reading: " + save_path
		return result
	
	var encrypted_data = file.get_as_text()
	file.close()
	
	# 解密数据
	var json_string = _decrypt_data(encrypted_data)
	if json_string == "":
		# 尝试从备份文件恢复
		var backup_data = _try_load_from_backup(save_path)
		if backup_data != null:
			result.success = true
			result.save_data = backup_data
			return result
		
		result.error_message = "Failed to decrypt save data"
		return result
	
	# 解析JSON
	var parse_result = JSON.parse_string(json_string)
	if typeof(parse_result) != TYPE_DICTIONARY:
		# 尝试从备份文件恢复
		var backup_data = _try_load_from_backup(save_path)
		if backup_data != null:
			result.success = true
			result.save_data = backup_data
			return result
		
		result.error_message = "Failed to parse JSON: " + str(parse_result)
		return result
	
	# 验证JSON格式
	if not _validate_save_data(parse_result):
		# 尝试从备份文件恢复
		var backup_data = _try_load_from_backup(save_path)
		if backup_data != null:
			result.success = true
			result.save_data = backup_data
			return result
		
		result.error_message = "Invalid save data format"
		return result
	
	# 处理版本兼容性
	var compatible_data = _handle_version_compatibility(parse_result)
	
	result.success = true
	result.save_data = compatible_data
	return result

# 尝试从备份文件恢复
func _try_load_from_backup(save_path: String) -> Dictionary:
	var backup_dir = save_path.get_base_dir() + "/backups/"
	var dir = Directory.new()
	
	if not dir.dir_exists(backup_dir):
		return null
	
	dir.open(backup_dir)
	dir.list_dir_begin()
	
	var backup_files = []
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("backup_") and file_name.ends_with(".sav"):
			backup_files.append(file_name)
		file_name = dir.get_next()
	
	# 按时间戳排序（最新的在前面）
	backup_files.sort_custom(func(a, b): return a > b)
	
	# 尝试加载最近的3个备份文件
	for i in range(min(3, backup_files.size())):
		var backup_path = backup_dir + backup_files[i]
		var backup_result = _perform_load(backup_path)
		if backup_result.success:
			return backup_result.save_data
	
	return null

# 解密数据（Base64 + XOR的逆过程）
func _decrypt_data(encrypted_data: String) -> String:
	if encrypted_data == "":
		return ""
	
	# XOR解密
	var xor_result = ""
	for i in range(encrypted_data.length()):
		var char_code = encrypted_data.ord_at(i)
		var key_char = ENCRYPTION_KEY.ord_at(i % ENCRYPTION_KEY.length())
		xor_result += char(char_code ^ key_char)
	
	# Base64解码
	var base64_bytes = Marshalls.base64_to_raw(xor_result)
	if base64_bytes == null:
		return ""
	
	return base64_bytes.get_string()

# 验证保存数据格式
func _validate_save_data(data: Dictionary) -> bool:
	if not data.has("player_core_state"):
		return false
	if not data.has("world_exploration_state"):
		return false
	if not data.has("quest_narrative_progress"):
		return false
	if not data.has("environment_entity_state"):
		return false
	
	# 验证玩家核心状态
	var player_data = data["player_core_state"]
	if not player_data.has("level") or not player_data.has("realm"):
		return false
	
	# 验证其他必需字段...
	# 这里可以添加更详细的验证逻辑
	
	return true

# 处理版本兼容性
func _handle_version_compatibility(data: Dictionary) -> Dictionary:
	# 获取当前游戏版本
	var current_version = ProjectSettings.get_setting("application/config/version")
	
	# 检查存档版本（如果存档中有版本信息）
	# 如果没有版本信息，假设是最新版本
	
	# 处理字段缺失的情况
	if not data.has("version"):
		# 这是一个旧版本的存档，需要填充默认值
		data = _migrate_old_save_data(data)
	
	# 处理特定版本的迁移
	# if data["version"] == "1.0.0":
	#     data = _migrate_v1_to_v2(data)
	
	return data

# 迁移旧版本存档数据
func _migrate_old_save_data(data: Dictionary) -> Dictionary:
	# 为缺失的字段添加默认值
	
	# 确保玩家核心状态包含所有必需字段
	if not data["player_core_state"].has("talent_tree_points"):
		data["player_core_state"]["talent_tree_points"] = 0
	
	if not data["player_core_state"].has("talent_tree_allocation"):
		data["player_core_state"]["talent_tree_allocation"] = {}
	
	# 确保世界探索状态包含所有必需字段
	if not data["world_exploration_state"].has("unique_encounters_triggered"):
		data["world_exploration_state"]["unique_encounters_triggered"] = []
	
	# 确保任务进度包含所有必需字段
	if not data["quest_narrative_progress"].has("npc_states"):
		data["quest_narrative_progress"]["npc_states"] = {}
	
	# 确保环境状态包含所有必需字段
	if not data["environment_entity_state"].has("game_time"):
		data["environment_entity_state"]["game_time"] = 0
	
	if not data["environment_entity_state"].has("weather"):
		data["environment_entity_state"]["weather"] = "clear"
	
	# 添加当前版本号
	data["version"] = ProjectSettings.get_setting("application/config/version")
	
	return data

# 获取存档信息（不加载完整数据）
func get_save_info(save_path: String) -> Dictionary:
	var result = {"exists": false, "timestamp": 0, "size": 0, "error": ""}
	
	var dir = Directory.new()
	if not dir.file_exists(save_path):
		result.error = "File does not exist"
		return result
	
	result.exists = true
	result.timestamp = dir.get_modified_time(save_path)
	result.size = dir.get_modified_time(save_path)
	
	return result

# 列出所有可用的存档槽位
func list_save_slots(base_path: String) -> Array:
	var slots = []
	var dir = Directory.new()
	
	if not dir.dir_exists(base_path):
		return slots
	
	dir.open(base_path)
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".sav") and not file_name.begins_with("backup_"):
			slots.append(file_name)
		file_name = dir.get_next()
	
	return slots

# 删除存档文件
func delete_save(save_path: String) -> bool:
	var dir = Directory.new()
	if not dir.file_exists(save_path):
		return false
	
	# 删除主存档文件
	if not dir.remove(save_path):
		return false
	
	# 删除备份目录
	var backup_dir = save_path.get_base_dir() + "/backups/"
	if dir.dir_exists(backup_dir):
		dir.remove(backup_dir)
	
	return true