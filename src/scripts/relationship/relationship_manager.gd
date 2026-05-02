## 角色关系管理器
## 管理所有NPC关系和玩家道心值
extends Node

## 信号
signal relationship_changed(npc_id: String, old_value: int, new_value: int)
signal relationship_level_changed(npc_id: String, old_level: RelationshipData.RelationshipLevel, new_level: RelationshipData.RelationshipLevel)
signal dao_heart_changed(old_value: int, new_value: int)
signal dao_heart_level_changed(old_level: RelationshipData.DaoHeartLevel, new_level: RelationshipData.DaoHeartLevel)
signal dao_heart_extreme_change()

## NPC关系数据字典 {npc_id: NPCRelationship}
var _npc_relationships: Dictionary = {}

## 玩家道心数据
var _player_dao_heart: RelationshipData.PlayerDaoHeart = null

## 关系变化历史
var _relationship_history: Array[RelationshipData.RelationshipChangeEvent] = []

## 道心变化历史
var _dao_heart_history: Array[RelationshipData.DaoHeartChangeEvent] = []

## 全局倍率（可用于难度调整）
var global_multiplier: float = 1.0

## 时间衰减开关
var enable_time_decay: bool = true

## 当前游戏时间（天）
var current_game_day: int = 0

func _init() -> void:
	_player_dao_heart = RelationshipData.PlayerDaoHeart.new(0)

## 获取或创建NPC关系
func get_or_create_relationship(npc_id: String) -> RelationshipData.NPCRelationship:
	if not _npc_relationships.has(npc_id):
		_npc_relationships[npc_id] = RelationshipData.NPCRelationship.new(npc_id, 0)
	return _npc_relationships[npc_id]

## 获取关系值
func get_relationship_value(npc_id: String) -> int:
	var rel := get_or_create_relationship(npc_id)
	return rel.relationship_value

## 获取关系等级
func get_relationship_level(npc_id: String) -> RelationshipData.RelationshipLevel:
	var rel := get_or_create_relationship(npc_id)
	return rel.relationship_level

## 获取关系等级名称
func get_relationship_level_name(npc_id: String) -> String:
	var level := get_relationship_level(npc_id)
	return RelationshipData.NPCRelationship.get_level_name(level)

## 修改关系值
func modify_relationship(npc_id: String, delta: int, reason: String = "") -> void:
	var rel := get_or_create_relationship(npc_id)
	var old_value := rel.relationship_value
	var old_level := rel.relationship_level
	
	# 应用变化
	rel.update_value(delta, global_multiplier)
	rel.total_interactions += 1
	rel.last_interaction_time = current_game_day
	
	# 记录历史
	var event := RelationshipData.RelationshipChangeEvent.new(npc_id, delta, reason)
	_relationship_history.append(event)
	
	# 发送信号
	relationship_changed.emit(npc_id, old_value, rel.relationship_value)
	
	if old_level != rel.relationship_level:
		relationship_level_changed.emit(npc_id, old_level, rel.relationship_level)
		_on_relationship_level_changed(npc_id, old_level, rel.relationship_level)

## 设置关系值（直接设置，不触发历史记录）
func set_relationship_value(npc_id: String, value: int) -> void:
	var rel := get_or_create_relationship(npc_id)
	var old_value := rel.relationship_value
	var old_level := rel.relationship_level
	
	rel.relationship_value = clamp(value, RelationshipData.RELATIONSHIP_MIN, RelationshipData.RELATIONSHIP_MAX)
	rel.relationship_level = RelationshipData.NPCRelationship.get_level_from_value(rel.relationship_value)
	
	relationship_changed.emit(npc_id, old_value, rel.relationship_value)
	
	if old_level != rel.relationship_level:
		relationship_level_changed.emit(npc_id, old_level, rel.relationship_level)

## 获取道心值
func get_dao_heart_value() -> int:
	return _player_dao_heart.dao_heart_value

## 获取道心等级
func get_dao_heart_level() -> RelationshipData.DaoHeartLevel:
	return _player_dao_heart.dao_heart_level

## 获取道心等级名称
func get_dao_heart_level_name() -> String:
	return RelationshipData.PlayerDaoHeart.get_level_name(_player_dao_heart.dao_heart_level)

## 修改道心值
func modify_dao_heart(delta: int, reason: String = "") -> void:
	var old_value := _player_dao_heart.dao_heart_value
	var old_level := _player_dao_heart.dao_heart_level
	
	# 应用变化
	_player_dao_heart.update_value(delta, global_multiplier)
	
	# 记录历史
	var event := RelationshipData.DaoHeartChangeEvent.new(delta, reason)
	_dao_heart_history.append(event)
	
	# 发送信号
	dao_heart_changed.emit(old_value, _player_dao_heart.dao_heart_value)
	
	if old_level != _player_dao_heart.dao_heart_level:
		dao_heart_level_changed.emit(old_level, _player_dao_heart.dao_heart_level)
		_on_dao_heart_level_changed(old_level, _player_dao_heart.dao_heart_level)
	
	# 检查极端转换
	if (old_value >= 60 and _player_dao_heart.dao_heart_value <= -60) or \
	   (old_value <= -60 and _player_dao_heart.dao_heart_value >= 60):
		dao_heart_extreme_change.emit()
		_on_dao_heart_extreme_change()

## 设置道心值（直接设置）
func set_dao_heart_value(value: int) -> void:
	var old_value := _player_dao_heart.dao_heart_value
	var old_level := _player_dao_heart.dao_heart_level
	
	_player_dao_heart.dao_heart_value = clamp(value, RelationshipData.DAO_HEART_MIN, RelationshipData.DAO_HEART_MAX)
	_player_dao_heart.dao_heart_level = RelationshipData.PlayerDaoHeart.get_level_from_value(_player_dao_heart.dao_heart_value)
	
	dao_heart_changed.emit(old_value, _player_dao_heart.dao_heart_value)
	
	if old_level != _player_dao_heart.dao_heart_level:
		dao_heart_level_changed.emit(old_level, _player_dao_heart.dao_heart_level)

## 检查是否可以解锁任务
func can_unlock_quest(npc_id: String, required_level: RelationshipData.RelationshipLevel) -> bool:
	var current_level := get_relationship_level(npc_id)
	return current_level >= required_level

## 检查是否可以学习功法
func can_learn_martial_art(alignment: String) -> bool:
	var dao_value := get_dao_heart_value()
	
	match alignment:
		"righteous":
			return dao_value >= 0  # 正道功法需要非负道心值
		"evil":
			return dao_value <= 0  # 魔道功法需要非正道心值
		"neutral":
			return true  # 中立功法无限制
		_:
			return false

## 获取NPC态度修正值（基于道心值）
func get_npc_attitude_modifier(npc_id: String, npc_alignment: String) -> int:
	var dao_value := get_dao_heart_value()
	var modifier := 0
	
	# 根据NPC立场和玩家道心值计算态度修正
	match npc_alignment:
		"righteous":
			if dao_value >= 60:
				modifier = 20  # 正道宗师，正道NPC非常友好
			elif dao_value >= 30:
				modifier = 10  # 正道倾向，正道NPC友好
			elif dao_value <= -60:
				modifier = -30  # 魔道宗师，正道NPC敌视
			elif dao_value <= -30:
				modifier = -15  # 魔道倾向，正道NPC冷淡
		"evil":
			if dao_value <= -60:
				modifier = 20  # 魔道宗师，魔道NPC非常友好
			elif dao_value <= -30:
				modifier = 10  # 魔道倾向，魔道NPC友好
			elif dao_value >= 60:
				modifier = -30  # 正道宗师，魔道NPC敌视
			elif dao_value >= 30:
				modifier = -15  # 正道倾向，魔道NPC冷淡
	
	return modifier

## 获取商店折扣率
func get_shop_discount(npc_id: String) -> float:
	var level := get_relationship_level(npc_id)
	
	match level:
		RelationshipData.RelationshipLevel.FRIENDLY:
			return 0.10  # 10%折扣
		RelationshipData.RelationshipLevel.INTIMATE:
			return 0.20  # 20%折扣
		RelationshipData.RelationshipLevel.BEST_FRIEND:
			return 0.30  # 30%折扣
		_:
			return 0.0  # 无折扣

## 处理时间衰减（每游戏周调用一次）
func process_time_decay() -> void:
	if not enable_time_decay:
		return
	
	for npc_id in _npc_relationships.keys():
		var rel: RelationshipData.NPCRelationship = _npc_relationships[npc_id]
		
		# 只对友好以上等级生效
		if rel.relationship_level >= RelationshipData.RelationshipLevel.FRIENDLY:
			# 检查是否长期未互动（超过7天）
			if current_game_day - rel.last_interaction_time >= 7:
				modify_relationship(npc_id, -1, "时间衰减")

## 更新游戏时间
func update_game_day(day: int) -> void:
	current_game_day = day

## 获取关系历史
func get_relationship_history(npc_id: String = "") -> Array[RelationshipData.RelationshipChangeEvent]:
	if npc_id.is_empty():
		return _relationship_history
	
	var filtered: Array[RelationshipData.RelationshipChangeEvent] = []
	for event in _relationship_history:
		if event.npc_id == npc_id:
			filtered.append(event)
	return filtered

## 获取道心历史
func get_dao_heart_history() -> Array[RelationshipData.DaoHeartChangeEvent]:
	return _dao_heart_history

## 清空历史记录
func clear_history() -> void:
	_relationship_history.clear()
	_dao_heart_history.clear()

## 保存数据
func save_data() -> Dictionary:
	var data := {
		"npc_relationships": {},
		"dao_heart": {
			"value": _player_dao_heart.dao_heart_value,
			"level": _player_dao_heart.dao_heart_level,
			"righteous_actions": _player_dao_heart.righteous_actions,
			"evil_actions": _player_dao_heart.evil_actions
		},
		"current_game_day": current_game_day,
		"global_multiplier": global_multiplier
	}
	
	# 保存NPC关系
	for npc_id in _npc_relationships.keys():
		var rel: RelationshipData.NPCRelationship = _npc_relationships[npc_id]
		data["npc_relationships"][npc_id] = {
			"value": rel.relationship_value,
			"level": rel.relationship_level,
			"last_interaction_time": rel.last_interaction_time,
			"total_interactions": rel.total_interactions,
			"gifts_given": rel.gifts_given,
			"quests_completed": rel.quests_completed,
			"betrayals": rel.betrayals
		}
	
	return data

## 加载数据
func load_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	# 加载道心数据
	if data.has("dao_heart"):
		var dh: Dictionary = data["dao_heart"]
		_player_dao_heart.dao_heart_value = dh.get("value", 0)
		_player_dao_heart.dao_heart_level = dh.get("level", RelationshipData.DaoHeartLevel.NEUTRAL)
		_player_dao_heart.righteous_actions = dh.get("righteous_actions", 0)
		_player_dao_heart.evil_actions = dh.get("evil_actions", 0)
	
	# 加载NPC关系
	if data.has("npc_relationships"):
		_npc_relationships.clear()
		for npc_id in data["npc_relationships"].keys():
			var rel_data: Dictionary = data["npc_relationships"][npc_id]
			var rel := RelationshipData.NPCRelationship.new(npc_id, rel_data.get("value", 0))
			rel.relationship_level = rel_data.get("level", RelationshipData.RelationshipLevel.NEUTRAL)
			rel.last_interaction_time = rel_data.get("last_interaction_time", 0)
			rel.total_interactions = rel_data.get("total_interactions", 0)
			rel.gifts_given = rel_data.get("gifts_given", 0)
			rel.quests_completed = rel_data.get("quests_completed", 0)
			rel.betrayals = rel_data.get("betrayals", 0)
			_npc_relationships[npc_id] = rel
	
	# 加载其他数据
	current_game_day = data.get("current_game_day", 0)
	global_multiplier = data.get("global_multiplier", 1.0)

## 重置所有数据
func reset_all() -> void:
	_npc_relationships.clear()
	_player_dao_heart = RelationshipData.PlayerDaoHeart.new(0)
	_relationship_history.clear()
	_dao_heart_history.clear()
	current_game_day = 0
	global_multiplier = 1.0

## 关系等级改变回调
func _on_relationship_level_changed(npc_id: String, old_level: RelationshipData.RelationshipLevel, new_level: RelationshipData.RelationshipLevel) -> void:
	print("[关系系统] %s 的关系等级变化: %s -> %s" % [
		npc_id,
		RelationshipData.NPCRelationship.get_level_name(old_level),
		RelationshipData.NPCRelationship.get_level_name(new_level)
	])
	
	# 这里可以触发UI通知、解锁内容等

## 道心等级改变回调
func _on_dao_heart_level_changed(old_level: RelationshipData.DaoHeartLevel, new_level: RelationshipData.DaoHeartLevel) -> void:
	print("[关系系统] 道心等级变化: %s -> %s" % [
		RelationshipData.PlayerDaoHeart.get_level_name(old_level),
		RelationshipData.PlayerDaoHeart.get_level_name(new_level)
	])

## 道心极端转换回调
func _on_dao_heart_extreme_change() -> void:
	print("[关系系统] 道心剧变！")
	
	# 触发所有NPC的态度重新评估
	for npc_id in _npc_relationships.keys():
		var rel: RelationshipData.NPCRelationship = _npc_relationships[npc_id]
		# 这里可以根据NPC立场调整关系值