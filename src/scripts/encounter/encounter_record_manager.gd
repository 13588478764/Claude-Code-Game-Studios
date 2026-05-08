## EncounterRecordManager
## EncounterRecordManager系统
##
## 主要功能：
## - 待补充

extends Node

class_name EncounterRecordManager

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

# 奇遇记录管理器
# 负责管理奇遇完成状态、连续失败计数器和历史记录

# 信号定义
signal record_updated(record_type: String, data: Dictionary)

# 常量定义
const SAVE_FILE_PATH = "user://encounter_records.json"

# 变量定义
var completed_encounters: Array[String] = []
var consecutive_failures: int = 0
var max_consecutive_failures: int = 20
var encounter_history: Array[Dictionary] = []
var save_data_version: String = "1.0"

# 初始化
func _ready():
	print("奇遇记录管理器已初始化")
	
	# 尝试从存档加载数据
	load_records()

# 标记奇遇已完成
func mark_encounter_completed(encounter_id: String) -> void:
	if not completed_encounters.has(encounter_id):
		completed_encounters.append(encounter_id)
		
		# 添加到历史记录
		var history_entry = {
			"id": encounter_id,
			"timestamp": Time.get_unix_time_from_system(),
			"type": extract_encounter_type_from_id(encounter_id),
			"status": "completed"
		}
		encounter_history.append(history_entry)
		
		# 发出更新信号
		emit_signal("record_updated", "completed_encounter", {"id": encounter_id, "history_entry": history_entry})
		
		print("奇遇 '%s' 已标记为完成" % encounter_id)

# 更新失败计数器
func update_failure_counter(success: bool) -> void:
	if success:
		consecutive_failures = 0
	else:
		consecutive_failures += 1
		
		# 检查是否达到保底触发条件
		if consecutive_failures >= max_consecutive_failures:
			print("达到保底触发条件，下次触发概率为100%")
			consecutive_failures = max_consecutive_failures - 1  # 保持在触发状态
	
	emit_signal("record_updated", "failure_counter", {"count": consecutive_failures, "success": success})

# 获取奇遇历史记录
func get_encounter_history() -> Array[Dictionary]:
	return encounter_history.duplicate()

# 获取特定类型的历史记录
func get_encounters_by_type(encounter_type: String) -> Array:
	var result: Array[Dictionary] = []
	for entry in encounter_history:
		if entry.get("type", "") == encounter_type:
			result.append(entry)
	return result

# 检查奇遇是否已完成
func is_encounter_completed(encounter_id: String) -> bool:
	return completed_encounters.has(encounter_id)

# 保存记录到存档
func save_records() -> bool:
	var save_data = {
		"version": save_data_version,
		"timestamp": Time.get_unix_time_from_system(),
		"completed_encounters": completed_encounters,
		"consecutive_failures": consecutive_failures,
		"encounter_history": encounter_history
	}
	
	var json_string = JSON.stringify(save_data)
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		print("错误：无法打开文件进行写入: %s" % SAVE_FILE_PATH)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("奇遇记录已保存到: %s" % SAVE_FILE_PATH)
	return true

# 从存档加载记录
func load_records() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("存档文件不存在: %s，将使用默认数据" % SAVE_FILE_PATH)
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		print("错误：无法打开文件进行读取: %s" % SAVE_FILE_PATH)
		return false
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	if parse_result != OK:
		print("错误：无法解析存档数据")
		return false
	
	var save_data = json.data
	
	# 验证版本
	if not save_data.has("version"):
		print("错误：存档数据缺少版本信息")
		return false
	
	# 加载数据（JSON解析的数组需要转换为正确类型）
	if save_data.has("completed_encounters"):
		completed_encounters.clear()
		for eid in save_data.completed_encounters:
			completed_encounters.append(eid)
	if save_data.has("consecutive_failures"):
		consecutive_failures = save_data.consecutive_failures
	if save_data.has("encounter_history"):
		encounter_history.clear()
		for entry in save_data.encounter_history:
			encounter_history.append(entry)
	
	print("从 %s 加载了 %d 个完成的奇遇记录和 %d 条历史记录" % [
		SAVE_FILE_PATH, 
		completed_encounters.size(), 
		encounter_history.size()
	])
	
	return true

# 重置所有记录
func reset_all_records() -> void:
	completed_encounters.clear()
	encounter_history.clear()
	consecutive_failures = 0
	
	print("所有奇遇记录已重置")

# 获取当前状态信息
func get_status_info() -> Dictionary:
	return {
		"completed_count": completed_encounters.size(),
		"consecutive_failures": consecutive_failures,
		"history_count": encounter_history.size(),
		"completed_encounters": completed_encounters.duplicate(),
		"encounter_history": encounter_history.duplicate()
	}

# 从ID提取奇遇类型
func extract_encounter_type_from_id(encounter_id: String) -> String:
	# ID格式通常是 "type_timestamp"，例如 "JiangHuRumor_1234567890"
	var parts = encounter_id.split("_")
	if parts.size() > 0:
		return parts[0]
	else:
		return "Unknown"

# 获取统计信息
func get_statistics() -> Dictionary:
	var stats = {
		"total_completed": completed_encounters.size(),
		"consecutive_failures": consecutive_failures,
		"total_history": encounter_history.size(),
		"type_distribution": {}
	}
	
	# 计算各类型分布
	for entry in encounter_history:
		var encounter_type = entry.get("type", "Unknown")
		if not stats.type_distribution.has(encounter_type):
			stats.type_distribution[encounter_type] = 0
		stats.type_distribution[encounter_type] += 1
	
	return stats

# 清除特定类型的记录
func clear_encounters_by_type(encounter_type: String) -> int:
	var count = 0
	var i = 0
	while i < completed_encounters.size():
		if extract_encounter_type_from_id(completed_encounters[i]) == encounter_type:
			completed_encounters.remove_at(i)
			count += 1
		else:
			i += 1
	
	# 同样清除历史记录中的对应条目
	i = 0
	while i < encounter_history.size():
		if encounter_history[i].get("type", "") == encounter_type:
			encounter_history.remove_at(i)
		else:
			i += 1
	
	return count

# 测试函数
func test_record_system():
	print("开始测试奇遇记录系统...")
	
	# 测试标记完成
	mark_encounter_completed("JiangHuRumor_1234567890")
	mark_encounter_completed("TianCaiDiBao_1234567891")
	
	# 测试检查完成状态
	var is_completed = is_encounter_completed("JiangHuRumor_1234567890")
	print("检查奇遇完成状态: %s" % is_completed)
	
	# 测试更新失败计数器
	update_failure_counter(false)  # 模拟失败
	update_failure_counter(false)  # 模拟失败
	update_failure_counter(true)  # 模拟成功
	print("当前失败计数: %d" % consecutive_failures)
	
	# 测试获取历史记录
	var history = get_encounter_history()
	print("历史记录数量: %d" % history.size())
	
	# 测试统计信息
	var stats = get_statistics()
	print("统计信息: %s" % str(stats))
	
	# 测试保存和加载
	save_records()
	
	# 重置并重新加载
	reset_all_records()
	load_records()
	
	print("奇遇记录系统测试完成")

# 获取最近的奇遇记录
func get_recent_encounters(count: int) -> Array[Dictionary]:
	var recent = encounter_history.duplicate()
	recent.reverse()  # 最新的在前
	
	if recent.size() > count:
		recent.resize(count)
	
	return recent

# 检查是否达到保底触发条件
func is_guaranteed_trigger() -> bool:
	return consecutive_failures >= max_consecutive_failures - 1