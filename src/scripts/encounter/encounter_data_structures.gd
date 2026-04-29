# 奇遇系统统一数据结构定义
#
# 本文件定义了奇遇系统中使用的所有数据结构，确保数据一致性
# 所有管理器都应该使用这些统一的数据结构

extends Node

class_name EncounterDataStructures

# ============================================================================
# 奇遇记录数据结构
# ============================================================================

## 统一的奇遇记录类
class EncounterRecord:
	var id: String                          # 记录唯一ID
	var encounter_id: String                # 奇遇ID
	var title: String                       # 奇遇标题
	var encounter_type: String              # 奇遇类型 (random, location, event)
	var outcome: String                     # 结果 (success, partial_success, failure)
	var rewards: Array                      # 奖励数组
	var timestamp: float                    # 时间戳
	var position: Vector2                   # 位置
	var weather: String                     # 天气
	var player_level: int                   # 玩家等级
	var player_realm: String                # 玩家境界
	var player_attributes: Dictionary       # 玩家属性快照
	var metadata: Dictionary                # 元数据
	
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
		metadata = {}
	
	## 转换为字典格式（用于序列化）
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"encounter_id": encounter_id,
			"title": title,
			"encounter_type": encounter_type,
			"outcome": outcome,
			"rewards": rewards,
			"timestamp": timestamp,
			"position": {"x": position.x, "y": position.y},
			"weather": weather,
			"player_level": player_level,
			"player_realm": player_realm,
			"player_attributes": player_attributes,
			"metadata": metadata
		}
	
	## 从字典格式创建记录
	static func from_dict(data: Dictionary) -> EncounterRecord:
		var record = EncounterRecord.new()
		record.id = data.get("id", "")
		record.encounter_id = data.get("encounter_id", "")
		record.title = data.get("title", "")
		record.encounter_type = data.get("encounter_type", "")
		record.outcome = data.get("outcome", "")
		record.rewards = data.get("rewards", [])
		record.timestamp = data.get("timestamp", 0.0)
		
		var pos = data.get("position", {"x": 0, "y": 0})
		record.position = Vector2(pos.get("x", 0), pos.get("y", 0))
		
		record.weather = data.get("weather", "")
		record.player_level = data.get("player_level", 0)
		record.player_realm = data.get("player_realm", "")
		record.player_attributes = data.get("player_attributes", {})
		record.metadata = data.get("metadata", {})
		
		return record