extends Node

# 历史记录器
# 负责记录奇遇的详细信息，包括基础标识、时空上下文、结果奖励和玩家状态快照

# 信号定义
signal encounter_logged(record_id: String)

# 历史记录数据结构
class HistoryRecord:
	var id: String
	var encounter_id: String
	var title: String
	var encounter_type: String
	var timestamp: float
	var position: Vector2
	var weather: String
	var outcome: String
	var rewards: Array
	var player_level: int
	var player_realm: String
	var player_attributes: Dictionary
	var metadata: Dictionary

# 存储历史记录
var history_records: Array[HistoryRecord] = []
var record_id_counter: int = 0

# 统计信息
var statistics: Dictionary = {
	"total_encounters": 0,
	"encounter_types": {},
	"rewards_collected": 0
}

# 记录奇遇
func log_encounter(encounter_data: Dictionary) -> String:
	var record = create_encounter_record(
		encounter_data.get("id", ""),
		encounter_data.get("title", ""),
		encounter_data.get("type", ""),
		encounter_data.get("outcome", ""),
		encounter_data.get("rewards", [])
	)
	
	# 添加时空上下文
	record.timestamp = Time.get_unix_time_from_system()
	record.position = encounter_data.get("position", Vector2(0, 0))
	record.weather = encounter_data.get("weather", "unknown")
	
	# 添加玩家状态快照
	var player_data = encounter_data.get("player_data", {})
	record.player_level = player_data.get("level", 1)
	record.player_realm = player_data.get("realm", "QiRefining")
	record.player_attributes = player_data.get("attributes", {})
	
	# 添加元数据
	record.metadata = encounter_data.get("metadata", {})
	
	# 存储到内存
	store_in_memory(record)
	
	# 更新统计信息
	maintain_statistics(record.encounter_id)
	
	# 发出信号
	emit_signal("encounter_logged", record.id)
	
	return record.id

# 创建记录对象
func create_encounter_record(encounter_id: String, title: String, encounter_type: String, outcome: String, rewards: Array) -> HistoryRecord:
	var record = HistoryRecord.new()
	record.id = "record_" + str(record_id_counter)
	record.encounter_id = encounter_id
	record.title = title
	record.encounter_type = encounter_type
	record.outcome = outcome
	record.rewards = rewards.duplicate()
	
	record_id_counter += 1
	
	return record

# 将记录存储在内存列表中
func store_in_memory(record_object: HistoryRecord):
	history_records.append(record_object)
	print("已记录奇遇: %s (ID: %s)" % [record_object.title, record_object.id])

# 维护统计信息
func maintain_statistics(encounter_id: String):
	statistics["total_encounters"] += 1
	
	# 更新奇遇类型统计
	if not statistics["encounter_types"].has(encounter_id):
		statistics["encounter_types"][encounter_id] = 0
	statistics["encounter_types"][encounter_id] += 1
	
	# 更新奖励统计
	# 注意：实际奖励统计会在记录创建时完成，因为需要访问record_object.rewards

# 获取所有历史记录
func get_all_records() -> Array[HistoryRecord]:
	return history_records.duplicate()

# 根据ID获取记录
func get_record_by_id(record_id: String) -> HistoryRecord:
	for record in history_records:
		if record.id == record_id:
			return record
	return null

# 根据奇遇ID获取记录
func get_records_by_encounter_id(encounter_id: String) -> Array[HistoryRecord]:
	var result = []
	for record in history_records:
		if record.encounter_id == encounter_id:
			result.append(record)
	return result

# 获取统计信息
func get_statistics() -> Dictionary:
	var stats = statistics.duplicate()
	
	# 计算奖励总数
	stats["rewards_collected"] = 0
	for record in history_records:
		stats["rewards_collected"] += record.rewards.size()
	
	return stats

# 清除所有记录
func clear_all_records():
	history_records.clear()
	record_id_counter = 0
	statistics = {
		"total_encounters": 0,
		"encounter_types": {},
		"rewards_collected": 0
	}
	print("所有历史记录已清除")

# 测试函数
func test_history_logging():
	print("开始测试历史记录机制...")
	
	# 创建测试数据
	var test_encounter_data = {
		"id": "test_encounter_001",
		"title": "测试奇遇",
		"type": "random",
		"outcome": "success",
		"rewards": ["item1", "exp100"],
		"position": Vector2(100, 200),
		"weather": "sunny",
		"player_data": {
			"level": 5,
			"realm": "ZhuJi",
			"attributes": {"luck": 80, "wisdom": 75}
		},
		"metadata": {"test": true}
	}
	
	# 记录奇遇
	var record_id = log_encounter(test_encounter_data)
	print("记录ID: %s" % record_id)
	
	# 验证记录
	var record = get_record_by_id(record_id)
	if record:
		print("记录验证成功:")
		print("  ID: %s" % record.id)
		print("  奇遇ID: %s" % record.encounter_id)
		print("  标题: %s" % record.title)
		print("  类型: %s" % record.encounter_type)
		print("  结果: %s" % record.outcome)
		print("  奖励: %s" % str(record.rewards))
		print("  位置: %s" % str(record.position))
		print("  天气: %s" % record.weather)
		print("  等级: %d" % record.player_level)
		print("  境界: %s" % record.player_realm)
		print("  属性: %s" % str(record.player_attributes))
	else:
		print("记录验证失败")
	
	# 验证统计信息
	var stats = get_statistics()
	print("统计信息:")
	print("  总奇遇数: %d" % stats["total_encounters"])
	print("  奖励总数: %d" % stats["rewards_collected"])
	
	print("历史记录机制测试完成")