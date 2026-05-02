## 角色关系数据结构
## 定义关系值、道心值和关系等级的数据结构
extends RefCounted
class_name RelationshipData

## 关系值常量
const RELATIONSHIP_MIN: int = -100  # 仇敌
const RELATIONSHIP_MAX: int = 100   # 挚友/恋人

## 道心值常量
const DAO_HEART_MIN: int = -100  # 纯魔道
const DAO_HEART_MAX: int = 100   # 纯正道

## 关系等级阈值
const LEVEL_ENEMY: int = -50        # 仇敌
const LEVEL_COLD: int = -10         # 冷淡
const LEVEL_NEUTRAL: int = 10       # 中立->友好
const LEVEL_FRIENDLY: int = 10      # 友好
const LEVEL_INTIMATE: int = 50      # 亲密
const LEVEL_BEST_FRIEND: int = 80   # 挚友/恋人

## 道心等级阈值
const DAO_EVIL_MASTER: int = -60    # 魔道宗师
const DAO_EVIL_LEANING: int = -30   # 魔道倾向
const DAO_NEUTRAL_MIN: int = -29    # 中立下限
const DAO_NEUTRAL_MAX: int = 29     # 中立上限
const DAO_RIGHTEOUS_LEANING: int = 30   # 正道倾向
const DAO_RIGHTEOUS_MASTER: int = 60    # 正道宗师

## 关系等级枚举
enum RelationshipLevel {
	ENEMY = -3,      # 仇敌
	COLD = -2,       # 冷淡
	NEUTRAL = -1,    # 中立
	FRIENDLY = 0,    # 友好
	INTIMATE = 1,    # 亲密
	BEST_FRIEND = 2  # 挚友/恋人
}

## 道心等级枚举
enum DaoHeartLevel {
	EVIL_MASTER = -2,      # 魔道宗师
	EVIL_LEANING = -1,     # 魔道倾向
	NEUTRAL = 0,           # 中立
	RIGHTEOUS_LEANING = 1, # 正道倾向
	RIGHTEOUS_MASTER = 2   # 正道宗师
}

## NPC关系数据
class NPCRelationship:
	var npc_id: String = ""
	var relationship_value: int = 0  # -100到100
	var relationship_level: RelationshipLevel = RelationshipLevel.NEUTRAL
	var last_interaction_time: int = 0  # 游戏时间（天）
	var total_interactions: int = 0
	var gifts_given: int = 0
	var quests_completed: int = 0
	var betrayals: int = 0
	
	func _init(id: String = "", value: int = 0) -> void:
		npc_id = id
		relationship_value = clamp(value, RELATIONSHIP_MIN, RELATIONSHIP_MAX)
		relationship_level = get_level_from_value(relationship_value)
	
	## 根据关系值获取等级
	static func get_level_from_value(value: int) -> RelationshipLevel:
		if value <= -50:
			return RelationshipLevel.ENEMY
		elif value <= -10:
			return RelationshipLevel.COLD
		elif value < 10:
			return RelationshipLevel.NEUTRAL
		elif value < 50:
			return RelationshipLevel.FRIENDLY
		elif value < 80:
			return RelationshipLevel.INTIMATE
		else:
			return RelationshipLevel.BEST_FRIEND
	
	## 获取等级名称（中文）
	static func get_level_name(level: RelationshipLevel) -> String:
		match level:
			RelationshipLevel.ENEMY:
				return "仇敌"
			RelationshipLevel.COLD:
				return "冷淡"
			RelationshipLevel.NEUTRAL:
				return "中立"
			RelationshipLevel.FRIENDLY:
				return "友好"
			RelationshipLevel.INTIMATE:
				return "亲密"
			RelationshipLevel.BEST_FRIEND:
				return "挚友"
			_:
				return "未知"
	
	## 更新关系值
	func update_value(delta: int, multiplier: float = 1.0) -> void:
		var old_level := relationship_level
		relationship_value = clamp(relationship_value + int(delta * multiplier), RELATIONSHIP_MIN, RELATIONSHIP_MAX)
		relationship_level = get_level_from_value(relationship_value)
		
		# 如果等级改变，触发事件
		if old_level != relationship_level:
			_on_level_changed(old_level, relationship_level)
	
	## 等级改变回调
	func _on_level_changed(old_level: RelationshipLevel, new_level: RelationshipLevel) -> void:
		# 这里可以触发游戏事件
		print("关系等级变化: %s -> %s" % [get_level_name(old_level), get_level_name(new_level)])

## 玩家道心数据
class PlayerDaoHeart:
	var dao_heart_value: int = 0  # -100到100
	var dao_heart_level: DaoHeartLevel = DaoHeartLevel.NEUTRAL
	var righteous_actions: int = 0
	var evil_actions: int = 0
	var last_extreme_change_time: int = 0  # 上次极端转换时间
	
	func _init(value: int = 0) -> void:
		dao_heart_value = clamp(value, DAO_HEART_MIN, DAO_HEART_MAX)
		dao_heart_level = get_level_from_value(dao_heart_value)
	
	## 根据道心值获取等级
	static func get_level_from_value(value: int) -> DaoHeartLevel:
		if value <= -60:
			return DaoHeartLevel.EVIL_MASTER
		elif value <= -30:
			return DaoHeartLevel.EVIL_LEANING
		elif value <= 29:
			return DaoHeartLevel.NEUTRAL
		elif value <= 59:
			return DaoHeartLevel.RIGHTEOUS_LEANING
		else:
			return DaoHeartLevel.RIGHTEOUS_MASTER
	
	## 获取等级名称（中文）
	static func get_level_name(level: DaoHeartLevel) -> String:
		match level:
			DaoHeartLevel.EVIL_MASTER:
				return "魔道宗师"
			DaoHeartLevel.EVIL_LEANING:
				return "魔道倾向"
			DaoHeartLevel.NEUTRAL:
				return "中立"
			DaoHeartLevel.RIGHTEOUS_LEANING:
				return "正道倾向"
			DaoHeartLevel.RIGHTEOUS_MASTER:
				return "正道宗师"
			_:
				return "未知"
	
	## 更新道心值
	func update_value(delta: int, multiplier: float = 1.0) -> void:
		var old_value := dao_heart_value
		var old_level := dao_heart_level
		
		dao_heart_value = clamp(dao_heart_value + int(delta * multiplier), DAO_HEART_MIN, DAO_HEART_MAX)
		dao_heart_level = get_level_from_value(dao_heart_value)
		
		# 检测极端转换（从+60降到-60，或从-60升到+60）
		if (old_value >= 60 and dao_heart_value <= -60) or (old_value <= -60 and dao_heart_value >= 60):
			_on_extreme_change()
		
		# 如果等级改变，触发事件
		if old_level != dao_heart_level:
			_on_level_changed(old_level, dao_heart_level)
		
		# 统计行为
		if delta > 0:
			righteous_actions += 1
		elif delta < 0:
			evil_actions += 1
	
	## 等级改变回调
	func _on_level_changed(old_level: DaoHeartLevel, new_level: DaoHeartLevel) -> void:
		print("道心等级变化: %s -> %s" % [get_level_name(old_level), get_level_name(new_level)])
	
	## 极端转换回调
	func _on_extreme_change() -> void:
		print("道心剧变！")
		last_extreme_change_time = Time.get_ticks_msec()

## 关系变化事件
class RelationshipChangeEvent:
	var npc_id: String = ""
	var delta: int = 0
	var reason: String = ""
	var timestamp: int = 0
	
	func _init(id: String, change: int, cause: String) -> void:
		npc_id = id
		delta = change
		reason = cause
		timestamp = Time.get_ticks_msec()

## 道心变化事件
class DaoHeartChangeEvent:
	var delta: int = 0
	var reason: String = ""
	var timestamp: int = 0
	
	func _init(change: int, cause: String) -> void:
		delta = change
		reason = cause
		timestamp = Time.get_ticks_msec()