## HistoryPersistenceManager
## HistoryPersistenceManager系统
##
## 主要功能：
## - 待补充

extends Node

class_name HistoryPersistenceManager

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

# 历史记录持久化管理器
# 实现历史记录的序列化、存档加载、内存管理和存储空间管理

# 信号定义
signal data_persisted(save_path: String)
signal data_loaded(save_path: String)
signal memory_limit_exceeded(record_count: int)

# 历史记录数据结构
class HistoryRecord:
	var id: String
	var encounter_id: String
	var timestamp: float
	var player_state: Dictionary
	var outcome: String
	var rewards: Array
	var metadata: Dictionary

# 配置参数
var MAX_ACTIVE_RECORDS: int = 100  # 最大活跃记录数
var MAX_SAVE_SIZE: int = 1048576  # 最大存档大小（1MB）
var SAVE_FILE_PATH: String = "user://encounter_history.json"

# 存储历史记录
var history_records: Array[HistoryRecord] = []
var record_id_counter: int = 0

# 初始化
func _ready():
	print("历史记录持久化管理器已初始化")
	
	# 尝试从存档加载历史记录
	load_from_save()

# 添加历史记录
func add_history_record(encounter_id: String, player_state: Dictionary, outcome: String, rewards: Array, metadata: Dictionary = {}) -> String:
	var record = HistoryRecord.new()
	record.id = "record_" + str(record_id_counter)
	record.encounter_id = encounter_id
	record.timestamp = Time.get_unix_time_from_system()
	record.player_state = player_state
	record.outcome = outcome
	record.rewards = rewards
	record.metadata = metadata
	
	history_records.append(record)
	record_id_counter += 1
	
	# 检查内存限制
	manage_memory()
	
	return record.id

# 管理内存（限制活跃记录数）
func manage_memory():
	if history_records.size() > MAX_ACTIVE_RECORDS:
		# 移除最旧的记录
		var excess_count = history_records.size() - MAX_ACTIVE_RECORDS
		for i in range(excess_count):
			history_records.remove_at(0)  # 移除最旧的记录
		
		emit_signal("memory_limit_exceeded", history_records.size())
		print("内存管理：移除了 %d 条最旧的记录，当前记录数: %d" % [excess_count, history_records.size()])

# 序列化到存档
func serialize_to_save(data: Array[HistoryRecord] = null) -> String:
	if data == null:
		data = history_records
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"record_count": data.size(),
		"records": []
	}
	
	for record in data:
		var record_dict = {
			"id": record.id,
			"encounter_id": record.encounter_id,
			"timestamp": record.timestamp,
			"player_state": record.player_state,
			"outcome": record.outcome,
			"rewards": record.rewards,
			"metadata": record.metadata
		}
		save_data.records.append(record_dict)
	
	# 转换为JSON字符串
	var json_string = JSON.stringify(save_data)
	
	# 检查存档大小
	var size = json_string.length() * 2  # 估算字节大小（每个字符约2字节）
	if size > MAX_SAVE_SIZE:
		print("警告：存档大小超限，当前大小: %d 字节，限制: %d 字节" % [size, MAX_SAVE_SIZE])
		# 尝试压缩数据
		json_string = compress_data_if_needed(json_string)
	
	return json_string

# 从存档反序列化
func deserialize_from_save(save_data: String) -> Array[HistoryRecord]:
	var json = JSON.new()
	var parse_result = json.parse(save_data)
	
	if parse_result != OK:
		print("错误：无法解析存档数据")
		return []
	
	var data = json.data
	
	# 验证存档完整性
	if not validate_save_integrity(data):
		print("错误：存档完整性验证失败")
		return []
	
	var records: Array[HistoryRecord] = []
	
	if data.has("records"):
		for record_data in data.records:
			var record = HistoryRecord.new()
			record.id = record_data.get("id", "")
			record.encounter_id = record_data.get("encounter_id", "")
			record.timestamp = record_data.get("timestamp", 0.0)
			record.player_state = record_data.get("player_state", {})
			record.outcome = record_data.get("outcome", "")
			record.rewards = record_data.get("rewards", [])
			record.metadata = record_data.get("metadata", {})
			
			records.append(record)
	
	# 更新记录ID计数器
	if not records.is_empty():
		var last_id = records[-1].id
		if last_id.begins_with("record_"):
			record_id_counter = int(last_id.replace("record_", "")) + 1
	
	return records

# 验证存档完整性
func validate_save_integrity(data: Dictionary) -> bool:
	if not data.has("version") or not data.has("records"):
		return false
	
	# 检查版本兼容性
	var version = data.version
	if version != "1.0":
		print("警告：存档版本不兼容，当前版本: %s，期望版本: 1.0" % version)
		# 尝试兼容处理
		return attempt_version_compatibility(data)
	
	return true

# 尝试版本兼容性处理
func attempt_version_compatibility(data: Dictionary) -> bool:
	# 当前只处理1.0版本
	return false

# 保存到文件
func save_to_file(file_path: String = "") -> bool:
	if file_path == "":
		file_path = SAVE_FILE_PATH
	
	var serialized_data = serialize_to_save()
	
	# 写入文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("错误：无法打开文件进行写入: %s" % file_path)
		return false
	
	file.store_string(serialized_data)
	file.close()
	
	emit_signal("data_persisted", file_path)
	print("历史记录已保存到: %s" % file_path)
	
	return true

# 从文件加载
func load_from_file(file_path: String = "") -> bool:
	if file_path == "":
		file_path = SAVE_FILE_PATH
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		print("存档文件不存在: %s，将使用空数据" % file_path)
		return false
	
	# 读取文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("错误：无法打开文件进行读取: %s" % file_path)
		return false
	
	var file_content = file.get_as_text()
	file.close()
	
	# 反序列化
	var loaded_records = deserialize_from_save(file_content)
	if loaded_records.is_empty():
		print("错误：无法从存档加载记录")
		return false
	
	# 更新历史记录
	history_records = loaded_records
	
	emit_signal("data_loaded", file_path)
	print("从 %s 加载了 %d 条历史记录" % [file_path, history_records.size()])
	
	return true

# 压缩数据（如果需要）
func compress_data_if_needed(data: String) -> String:
	# 简单的压缩策略：移除一些非关键数据
	var json = JSON.new()
	var parse_result = json.parse(data)
	
	if parse_result != OK:
		return data
	
	var parsed_data = json.data
	
	# 移除一些可能占用大量空间的非关键字段
	if parsed_data.has("records"):
		for record in parsed_data.records:
			# 移除过大的元数据字段
			if record.has("metadata") and record.metadata.has("debug_info"):
				record.metadata.erase("debug_info")
	
	return JSON.stringify(parsed_data)

# 获取历史记录数量
func get_record_count() -> int:
	return history_records.size()

# 获取所有历史记录
func get_all_records() -> Array[HistoryRecord]:
	return history_records.duplicate()

# 根据ID获取历史记录
func get_record_by_id(record_id: String) -> HistoryRecord:
	for record in history_records:
		if record.id == record_id:
			return record
	return null

# 清除所有历史记录
func clear_all_records():
	history_records.clear()
	record_id_counter = 0
	print("所有历史记录已清除")

# 设置最大活跃记录数
func set_max_active_records(limit: int):
	MAX_ACTIVE_RECORDS = limit
	print("最大活跃记录数设置为: %d" % limit)

# 设置最大存档大小
func set_max_save_size(size: int):
	MAX_SAVE_SIZE = size
	print("最大存档大小设置为: %d 字节" % size)

# 获取当前存档大小估算
func get_current_save_size_estimate() -> int:
	var serialized = serialize_to_save()
	return serialized.length() * 2  # 估算字节大小

# 测试函数
func test_persistence():
	print("开始测试历史记录持久化...")
	
	# 添加一些测试记录
	for i in range(5):
		var player_state = {"level": i+1, "health": 100.0, "position": Vector2(i*10, i*10)}
		var rewards = ["item_%d" % i, "exp_%d" % (i*100)]
		var metadata = {"test": true, "iteration": i}
		
		add_history_record("encounter_%d" % i, player_state, "success", rewards, metadata)
	
	print("添加了 %d 条测试记录" % history_records.size())
	
	# 序列化测试
	var serialized = serialize_to_save()
	print("序列化完成，数据长度: %d 字符" % serialized.length())
	
	# 保存到文件测试
	var save_success = save_to_file("user://test_encounter_history.json")
	print("保存到文件: %s" % save_success)
	
	# 从文件加载测试
	var load_success = load_from_file("user://test_encounter_history.json")
	print("从文件加载: %s，当前记录数: %d" % [load_success, history_records.size()])
	
	# 测试内存管理
	set_max_active_records(3)  # 设置为3条记录的限制
	for i in range(3):
		var player_state = {"level": i+10, "health": 80.0, "position": Vector2(i*20, i*20)}
		var rewards = ["item_%d_extra" % i]
		var metadata = {"extra_test": true, "iteration": i}
		
		add_history_record("encounter_extra_%d" % i, player_state, "success", rewards, metadata)
	
	print("内存管理测试后记录数: %d" % history_records.size())
	
	print("历史记录持久化测试完成")