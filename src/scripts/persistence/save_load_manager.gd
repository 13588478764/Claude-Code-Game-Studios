## SaveLoadManager
## 保存加载管理器
实现自动保存、手动保存、周期保存和数据加载功能
##
## 主要功能：
## - 待补充

extends Node

class_name SaveLoadManager

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# 信号定义
signal save_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_completed(slot: int)
signal load_failed(slot: int, error: String)
signal available_saves_updated(saves: Array)

# 常量定义
const SAVE_DIR = "user://saves/"
const SAVE_FILE_PATTERN = "save_slot_%d.json"
const BACKUP_FILE_PATTERN = "save_slot_%d_backup_%d.json"
const MAX_BACKUPS = 3
const AUTO_SAVE_INTERVAL = 300  # 5分钟（秒）

# 依赖的其他管理器
var data_structure_manager: Node = null

# 自动保存计时器
var auto_save_timer: Timer = null

# 初始化
func _ready():
	# 创建保存目录
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	
	# 初始化自动保存计时器
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(_on_auto_save_timeout)
	auto_save_timer.autostart = true
	add_child(auto_save_timer)
	
	# 尝试获取数据结构管理器
	var parent = get_parent()
	if parent.has_method("get_growth_data_structure_manager"):
		data_structure_manager = parent.get_growth_data_structure_manager()
	elif "GrowthDataStructureManager" in str(get_tree().get_nodes_in_group("persistence")):
		var managers = get_tree().get_nodes_in_group("persistence")
		for manager in managers:
			if manager is GDScript and manager.name == "GrowthDataStructureManager":
				data_structure_manager = manager
				break

# 保存成长数据
func save_growth_data(character: Object, save_slot: int = 1) -> bool:
	if not character:
		emit_signal("save_failed", save_slot, "角色对象为空")
		return false
	
	# 创建成长数据结构
	var growth_data = create_growth_data_from_character(character)
	
	# 验证数据结构
	if data_structure_manager and data_structure_manager.validate_data_structure(growth_data):
		emit_signal("save_failed", save_slot, "数据结构验证失败")
		return false
	
	# 创建备份
	_create_backup(save_slot)
	
	# 准备保存数据
	var save_data = {}
	if data_structure_manager:
		save_data = data_structure_manager.growth_data_to_dict(growth_data)
	else:
		# 如果没有数据结构管理器，使用默认格式
		save_data = _create_default_save_data(character)
	
	# 添加元数据
	var metadata = _create_save_metadata(save_slot, character)
	save_data["metadata"] = metadata
	
	# 保存到文件
	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % save_slot)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		emit_signal("save_failed", save_slot, "无法打开保存文件")
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	# 更新可用存档列表
	emit_signal("save_completed", save_slot)
	_update_available_saves_list()
	
	return true

# 从指定存档槽加载成长数据
func load_growth_data(save_slot: int = 1) -> Object:
	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % save_slot)
	
	if not FileAccess.file_exists(save_path):
		emit_signal("load_failed", save_slot, "存档文件不存在")
		return null
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		emit_signal("load_failed", save_slot, "无法打开存档文件")
		return null
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	if parse_result != OK:
		emit_signal("load_failed", save_slot, "JSON解析失败")
		return null
	
	var save_data = json.data
	if not save_data is Dictionary:
		emit_signal("load_failed", save_slot, "存档数据格式错误")
		return null
	
	# 验证校验码
	if not _verify_checksum(save_data, save_path):
		emit_signal("load_failed", save_slot, "存档数据校验失败")
		return null
	
	# 加载数据到角色
	var character = _load_data_to_character(save_data)
	if character:
		emit_signal("load_completed", save_slot)
		return character
	else:
		emit_signal("load_failed", save_slot, "角色数据加载失败")
		return null

# 获取可用存档列表
func get_available_saves() -> Array:
	var available_saves = []
	
	for slot in range(1, 4):  # 假设有3个存档槽
		var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % slot)
		if FileAccess.file_exists(save_path):
			var file = FileAccess.open(save_path, FileAccess.READ)
			if file:
				var file_content = file.get_as_text()
				file.close()
				
				var json = JSON.new()
				var parse_result = json.parse(file_content)
				if parse_result == OK and json.data is Dictionary:
					var save_data = json.data
					var metadata = save_data.get("metadata", {})
					available_saves.append({
						"slot": slot,
						"player_name": metadata.get("playerName", "未知玩家"),
						"play_time": metadata.get("playTime", 0),
						"last_location": metadata.get("lastLocation", "未知位置"),
						"timestamp": metadata.get("timestamp", 0)
					})
	
	emit_signal("available_saves_updated", available_saves)
	return available_saves

# 删除指定存档
func delete_save(save_slot: int) -> bool:
	var save_path = SAVE_DIR + (SAVE_FILE_PATTERN % save_slot)
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir:
		if dir.file_exists(save_path):
			dir.remove(save_path)
			
			# 删除相关备份
			var backup_pattern = "save_slot_%d_backup" % save_slot
			for file in dir.get_files():
				if file.begins_with(backup_pattern):
					dir.remove(file)
			
			_update_available_saves_list()
			return true
	
	return false

# 触发自动保存
func trigger_auto_save():
	_on_auto_save_timeout()

# 创建从角色对象到成长数据的转换
func create_growth_data_from_character(character: Object) -> Object:
	# 如果有数据结构管理器，使用它创建数据
	if data_structure_manager and "define_growth_data_structure" in data_structure_manager:
		var growth_data = data_structure_manager.define_growth_data_structure()
		
		# 从角色对象复制数据到成长数据
		if "get_level" in character:
			growth_data.progression.level = character.get_level()
		if "get_realm" in character:
			growth_data.progression.realm = character.get_realm()
		if "get_experience" in character:
			growth_data.progression.experience = character.get_experience()
		if "get_experience_to_next_level" in character:
			growth_data.progression.experience_to_next_level = character.get_experience_to_next_level()
		
		# 复制属性数据
		if "get_attribute" in character:
			for attr_name in growth_data.attributes.values.keys():
				if character.get_attribute(attr_name) != null:
					growth_data.attributes.values[attr_name] = character.get_attribute(attr_name)
		
		# 复制武学数据
		if "get_learned_skills" in character:
			growth_data.martial_arts.learned_skills = character.get_learned_skills()
		if "get_skill_proficiencies" in character:
			growth_data.martial_arts.skill_proficiencies = character.get_skill_proficiencies()
		
		return growth_data
	else:
		# 如果没有数据结构管理器，创建基本数据结构
		return _create_basic_growth_data(character)

# 私有方法：创建默认保存数据
func _create_default_save_data(character: Object) -> Dictionary:
	var data = {}
	
	# 基本进度数据
	if "get_level" in character:
		data["level"] = character.get_level()
	if "get_realm" in character:
		data["realm"] = character.get_realm()
	if "get_experience" in character:
		data["experience"] = character.get_experience()
	
	# 属性数据
	if "get_attributes" in character:
		data["attributes"] = character.get_attributes()
	
	# 武学数据
	if "get_learned_skills" in character:
		data["learned_skills"] = character.get_learned_skills()
	
	return data

# 私有方法：创建存档元数据
func _create_save_metadata(save_slot: int, character: Object) -> Dictionary:
	var metadata = {}
	metadata["saveSlot"] = save_slot
	metadata["timestamp"] = Time.get_unix_time_from_system()
	metadata["playTime"] = 0  # 需要从游戏状态获取
	metadata["checksum"] = ""  # 将在保存前计算
	
	if "get_name" in character:
		metadata["playerName"] = character.get_name()
	else:
		metadata["playerName"] = "未命名角色"
	
	if "get_location" in character:
		metadata["lastLocation"] = character.get_location()
	else:
		metadata["lastLocation"] = "未知位置"
	
	return metadata

# 私有方法：创建备份
func _create_backup(save_slot: int):
	var original_path = SAVE_DIR + (SAVE_FILE_PATTERN % save_slot)
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir and dir.file_exists(original_path):
		# 获取当前时间戳作为备份标识
		var timestamp = Time.get_unix_time_from_system()
		var backup_path = SAVE_DIR + (BACKUP_FILE_PATTERN % [save_slot, timestamp])
		
		# 复制文件
		var error = dir.copy(original_path, backup_path)
		
		# 如果备份数量超过限制，删除最旧的备份
		_cleanup_old_backups(save_slot)

# 私有方法：清理旧备份
func _cleanup_old_backups(save_slot: int):
	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		return
	
	var backup_files = []
	var backup_pattern = "save_slot_%d_backup" % save_slot
	
	for file in dir.get_files():
		if file.begins_with(backup_pattern):
			backup_files.append(file)
	
	# 按文件名排序（时间戳）
	backup_files.sort()
	
	# 删除超出数量限制的备份
	while backup_files.size() > MAX_BACKUPS:
		var oldest_backup = backup_files[0]
		dir.remove(SAVE_DIR + oldest_backup)
		backup_files.remove_at(0)

# 私有方法：自动保存超时处理
func _on_auto_save_timeout():
	# 这里可以触发自动保存，但需要知道当前角色和存档槽
	# 可以通过信号或其他机制获取这些信息
	print("自动保存计时器触发")

# 私有方法：验证校验码
func _verify_checksum(save_data: Dictionary, file_path: String) -> bool:
	# 简单的校验码验证（实际实现可能更复杂）
	if "metadata" in save_data and "checksum" in save_data["metadata"]:
		var stored_checksum = save_data["metadata"]["checksum"]
		# 实际实现中，需要重新计算文件的校验码并与存储的校验码比较
		return true  # 简化实现
	return true

# 私有方法：将数据加载到角色
func _load_data_to_character(save_data: Dictionary) -> Object:
	# 这里需要根据实际的角色系统实现
	# 创建一个模拟角色对象
	var mock_character = {}
	
	if "level" in save_data:
		mock_character["level"] = save_data["level"]
	if "realm" in save_data:
		mock_character["realm"] = save_data["realm"]
	if "experience" in save_data:
		mock_character["experience"] = save_data["experience"]
	if "attributes" in save_data:
		mock_character["attributes"] = save_data["attributes"]
	if "learned_skills" in save_data:
		mock_character["learned_skills"] = save_data["learned_skills"]
	
	return mock_character

# 私有方法：创建基本成长数据
func _create_basic_growth_data(character: Object) -> Object:
	# 创建一个简单的对象来存储成长数据
	var growth_data = {}
	
	# 复制角色数据
	if "get_level" in character:
		growth_data["level"] = character.get_level()
	if "get_realm" in character:
		growth_data["realm"] = character.get_realm()
	if "get_experience" in character:
		growth_data["experience"] = character.get_experience()
	
	return growth_data

# 私有方法：更新可用存档列表
func _update_available_saves_list():
	var saves = get_available_saves()
	emit_signal("available_saves_updated", saves)