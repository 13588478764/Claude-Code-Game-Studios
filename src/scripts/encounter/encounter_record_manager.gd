# 武侠奇遇录 - 奇遇记录管理系统
# 实现奇遇完成状态记录、连续失败计数器和历史记录管理

extends Node

# 信号定义
signal record_updated(record_type, encounter_id)
signal save_data_requested
signal load_data_requested

# 奇遇类型枚举（与触发系统保持一致）
enum EncounterType {
	JIANGHU_RUMOR,      # 江湖传闻
	TIANCAI_DIBAO,      # 天材地宝
	GAOREN_ZHIDIAN,     # 高人指点
	SHICHUAN_MIJI,      # 失传秘籍
	MIJING_CHALLENGE    # 秘境挑战
}

# 奇遇记录结构定义
class EncounterRecord:
	var encounter_id: String
	var encounter_type: EncounterType
	var timestamp: int
	var rewards_received: Array
	var luck_stat: int
	var is_completed: bool
	
	func _init(id: String, type: EncounterType, time: int, rewards: Array, luck: int):
		encounter_id = id
		encounter_type = type
		timestamp = time
		rewards_received = rewards
		luck_stat = luck
		is_completed = true

# 状态变量
var completed_encounters: Dictionary = {}  # 存储已完成的奇遇ID
var encounter_history: Array[EncounterRecord] = []  # 奇遇历史记录
var consecutive_failures: int = 0  # 连续失败计数器
var max_history_size: int = 50  # 最大历史记录数量

func _ready():
	print("奇遇记录管理系统初始化完成")

# 标记奇遇为已完成
func mark_encounter_completed(encounter_id: String) -> bool:
	if completed_encounters.has(encounter_id):
		print("警告: 奇遇ID %s 已经被标记为完成" % encounter_id)
		return false
	
	completed_encounters[encounter_id] = OS.get_ticks_msec()
	emit_signal("record_updated", "completed", encounter_id)
	return true

# 检查奇遇是否已完成
func is_encounter_completed(encounter_id: String) -> bool:
	return completed_encounters.has(encounter_id)

# 更新失败计数器
func update_failure_counter(success: bool) -> void:
	if success:
		consecutive_failures = 0
	else:
		consecutive_failures += 1
	
	emit_signal("record_updated", "failure_counter", consecutive_failures)

# 获取连续失败次数
func get_consecutive_failures() -> int:
	return consecutive_failures

# 重置失败计数器
func reset_failure_counter() -> void:
	consecutive_failures = 0
	emit_signal("record_updated", "failure_counter", 0)

# 添加奇遇历史记录
func add_encounter_to_history(encounter_id: String, encounter_type: EncounterType, rewards: Array, luck_stat: int) -> void:
	var new_record = EncounterRecord.new(encounter_id, encounter_type, OS.get_ticks_msec(), rewards, luck_stat)
	encounter_history.append(new_record)
	
	# 限制历史记录大小
	if encounter_history.size() > max_history_size:
		encounter_history.pop_front()  # 移除最旧的记录
	
	emit_signal("record_updated", "history", encounter_id)

# 获取奇遇历史记录
func get_encounter_history() -> Array[EncounterRecord]:
	return encounter_history.duplicate()

# 获取特定类型的奇遇历史
func get_encounters_by_type(encounter_type: EncounterType) -> Array[EncounterRecord]:
	var filtered_history = []
	for record in encounter_history:
		if record.encounter_type == encounter_type:
			filtered_history.append(record)
	return filtered_history

# 获取已完成的奇遇数量
func get_completed_encounter_count() -> int:
	return completed_encounters.size()

# 获取指定时间段内的历史记录
func get_encounters_in_time_range(start_time: int, end_time: int) -> Array[EncounterRecord]:
	var filtered_history = []
	for record in encounter_history:
		if record.timestamp >= start_time and record.timestamp <= end_time:
			filtered_history.append(record)
	return filtered_history

# 清除所有记录（谨慎使用）
func clear_all_records() -> void:
	completed_encounters.clear()
	encounter_history.clear()
	consecutive_failures = 0
	print("所有奇遇记录已被清除")

# 保存记录数据
func save_records() -> Dictionary:
	var save_data = {
		"completed_encounters": completed_encounters,
		"consecutive_failures": consecutive_failures,
		"encounter_history": []
	}
	
	# 序列化历史记录
	for record in encounter_history:
		var serialized_record = {
			"encounter_id": record.encounter_id,
			"encounter_type": record.encounter_type,
			"timestamp": record.timestamp,
			"rewards_received": record.rewards_received,
			"luck_stat": record.luck_stat,
			"is_completed": record.is_completed
		}
		save_data.encounter_history.append(serialized_record)
	
	emit_signal("save_data_requested")
	return save_data

# 加载记录数据
func load_records(save_data: Dictionary) -> void:
	if save_data.has("completed_encounters"):
		completed_encounters = save_data.completed_encounters
	if save_data.has("consecutive_failures"):
		consecutive_failures = save_data.consecutive_failures
	if save_data.has("encounter_history"):
		encounter_history.clear()
		for serialized_record in save_data.encounter_history:
			var record = EncounterRecord.new(
				serialized_record.encounter_id,
				serialized_record.encounter_type,
				serialized_record.timestamp,
				serialized_record.rewards_received,
				serialized_record.luck_stat
			)
			record.is_completed = serialized_record.is_completed
			encounter_history.append(record)
	
	emit_signal("load_data_requested")
	print("奇遇记录数据已加载")

# 获取状态信息
func get_status_info() -> Dictionary:
	return {
		"completed_count": completed_encounters.size(),
		"history_count": encounter_history.size(),
		"consecutive_failures": consecutive_failures,
		"max_history_size": max_history_size
	}

# 导出记录为JSON字符串
func export_records_to_json() -> String:
	var data_to_export = save_records()
	return JSON.stringify(data_to_export)

# 从JSON字符串导入记录
func import_records_from_json(json_string: String) -> bool:
	var json_conv = JSON.new()
	var parse_result = json_conv.parse(json_string)
	
	if parse_result == OK:
		load_records(json_conv.data)
		return true
	else:
		print("错误: 无法解析JSON数据 - %s" % json_conv.error_message)
		return false

# 获取特定奇遇类型的完成次数
func get_encounter_type_completion_count(encounter_type: EncounterType) -> int:
	var count = 0
	for record in encounter_history:
		if record.encounter_type == encounter_type and record.is_completed:
			count += 1
	return count

# 检查是否在指定时间内完成过特定类型的奇遇
func has_completed_encounter_type_recently(encounter_type: EncounterType, minutes: int) -> bool:
	var current_time = OS.get_ticks_msec()
	var time_threshold = minutes * 60 * 1000  # 转换为毫秒
	
	for record in encounter_history:
		if record.encounter_type == encounter_type and record.is_completed:
			if current_time - record.timestamp <= time_threshold:
				return true
	return false