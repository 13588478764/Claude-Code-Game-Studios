# HistoryLogger - 奇遇历史记录系统
#
# 负责记录所有奇遇的详细信息，包括基础标识、时空上下文、结果奖励和玩家状态快照
# 遵循 GDD 中定义的历史记录机制
#
# 信号:
#   - encounter_logged(record_id, record_data)

extends Node

class_name HistoryLogger

# 信号定义
signal encounter_logged(record_id: String, record_data: Object)

# ============================================================================
# 内部类定义
# ============================================================================

## 奇遇记录类
class EncounterRecord:
	var id: String
	var encounter_id: String
	var title: String
	var encounter_type: String
	var outcome: String
	var rewards: Array
	var timestamp: float
	var position: Vector2
	var weather: String
	var player_level: int
	var player_realm: String
	var player_attributes: Dictionary
	
	func _init():
		id = ""
		encounter_id = ""
		title = ""
		encounter_type = ""
		outcome = ""
		rewards = []
		timestamp = 0.0
		position = Vector2.ZERO
		weather = ""
		player_level = 0
		player_realm = ""
		player_attributes = {}

# ============================================================================
# 成员变量
# ============================================================================

var records: Dictionary = {}  # 记录字典，key 为记录 ID
var record_counter: int = 0   # 记录计数器

# ============================================================================
# 公共方法
# ============================================================================

## 记录奇遇完成事件
## 参数:
##   - encounter_data: 奇遇数据字典
##     - id: 奇遇ID
##     - title: 奇遇标题
##     - type: 奇遇类型
##     - outcome: 结果
##     - rewards: 奖励数组
##     - position: 位置
##     - weather: 天气
##     - player_data: 玩家数据
## 返回: 记录ID
func log_encounter(encounter_data: Dictionary) -> String:
	# 创建记录对象
	var record = EncounterRecord.new()
	
	# 生成记录ID
	record_counter += 1
	record.id = "record_%d" % record_counter
	
	# 记录奇遇基础标识
	record.encounter_id = encounter_data.get("id", "")
	record.title = encounter_data.get("title", "")
	record.encounter_type = encounter_data.get("type", "")
	
	# 记录结果与奖励
	record.outcome = encounter_data.get("outcome", "")
	record.rewards = encounter_data.get("rewards", [])
	
	# 记录时空上下文
	record.timestamp = Time.get_unix_time_from_system()
	record.position = encounter_data.get("position", Vector2.ZERO)
	record.weather = encounter_data.get("weather", "")
	
	# 记录玩家状态快照
	var player_data = encounter_data.get("player_data", {})
	record.player_level = player_data.get("level", 0)
	record.player_realm = player_data.get("realm", "")
	record.player_attributes = player_data.get("attributes", {})
	
	# 保存记录
	records[record.id] = record
	
	# 发送信号
	encounter_logged.emit(record.id, record)
	
	return record.id


## 获取记录
## 参数:
##   - record_id: 记录ID
## 返回: 记录对象
func get_record_by_id(record_id: String) -> Object:
	if records.has(record_id):
		return records[record_id]
	return null


## 获取所有记录
## 返回: 记录数组
func get_all_records() -> Array:
	var result = []
	for record_id in records:
		result.append(records[record_id])
	return result


## 获取记录数量
## 返回: 记录数量
func get_record_count() -> int:
	return records.size()


## 清空所有记录
func clear_all_records() -> void:
	records.clear()
	record_counter = 0