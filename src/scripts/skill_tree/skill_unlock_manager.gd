class_name SkillUnlockManager
extends Node

## 技能解锁管理器
## 实现前置武学熟练度、境界门槛、物品/秘籍消耗和奇遇/事件解锁四种解锁机制

# 解锁条件类型枚举
enum UnlockConditionType {
	PROFICIENCY,    # 前置武学熟练度
	REALM,          # 境界门槛
	ITEM_COST,      # 物品/秘籍消耗
	EVENT           # 奇遇/事件解锁
}

# 解锁结果结构
class UnlockResult:
	var success: bool = false
	var message: String = ""
	var missing_conditions: Array = []
	
	func _init(is_success: bool, msg: String = "", missing: Array = []):
		success = is_success
		message = msg
		missing_conditions = missing

# 玩家数据引用（通过依赖注入设置）
var player_data: Dictionary = {}
var inventory_manager = null
var event_manager = null

# 解锁记录
var unlock_history: Dictionary = {}  # {skill_id: unlock_timestamp}

func _init():
	# 初始化默认玩家数据结构
	player_data = {
		"proficiency": {},  # {martial_art_id: level}
		"realm": 1,         # 当前境界等级
		"unlocked_skills": []  # 已解锁技能列表
	}

# 设置玩家数据（依赖注入）
func set_player_data(data: Dictionary) -> void:
	player_data = data

# 设置物品管理器（依赖注入）
func set_inventory_manager(manager) -> void:
	inventory_manager = manager

# 设置事件管理器（依赖注入）
func set_event_manager(manager) -> void:
	event_manager = manager

# 验证武学解锁条件（主验证函数）
func validate_unlock_conditions(
	school_id: String,
	skill_id: String,
	required_proficiency: int = 0,
	required_realm: int = 0,
	required_items: Dictionary = {},
	required_event: String = ""
) -> UnlockResult:
	var missing_conditions = []
	
	# 检查前置武学熟练度
	if required_proficiency > 0:
		if not validate_proficiency_requirement(school_id, required_proficiency):
			missing_conditions.append({
				"type": UnlockConditionType.PROFICIENCY,
				"required": required_proficiency,
				"current": get_proficiency_level(school_id)
			})
	
	# 检查境界门槛
	if required_realm > 0:
		if not validate_realm_requirement(required_realm):
			missing_conditions.append({
				"type": UnlockConditionType.REALM,
				"required": required_realm,
				"current": get_current_realm()
			})
	
	# 检查物品/秘籍消耗
	if not required_items.is_empty():
		var item_check = validate_item_requirements(required_items)
		if not item_check.success:
			missing_conditions.append({
				"type": UnlockConditionType.ITEM_COST,
				"required": required_items,
				"missing": item_check.missing_conditions
			})
	
	# 检查奇遇/事件解锁
	if not required_event.is_empty():
		if not validate_event_requirement(required_event):
			missing_conditions.append({
				"type": UnlockConditionType.EVENT,
				"required": required_event,
				"triggered": false
			})
	
	# 生成结果
	if missing_conditions.is_empty():
		return UnlockResult.new(true, "所有解锁条件满足")
	else:
		var msg = "缺少以下解锁条件: "
		for condition in missing_conditions:
			match condition.type:
				UnlockConditionType.PROFICIENCY:
					msg += "熟练度不足(需要%d，当前%d) " % [condition.required, condition.current]
				UnlockConditionType.REALM:
					msg += "境界不足(需要%d，当前%d) " % [condition.required, condition.current]
				UnlockConditionType.ITEM_COST:
					msg += "物品不足 "
				UnlockConditionType.EVENT:
					msg += "未触发奇遇事件 "
		return UnlockResult.new(false, msg, missing_conditions)

# 验证前置武学熟练度
func validate_proficiency_requirement(school_id: String, required_level: int) -> bool:
	var current_level = get_proficiency_level(school_id)
	return current_level >= required_level

# 获取武学熟练度等级
func get_proficiency_level(school_id: String) -> int:
	return player_data.get("proficiency", {}).get(school_id, 0)

# 设置武学熟练度等级（用于测试和游戏进度）
func set_proficiency_level(school_id: String, level: int) -> void:
	if not player_data.has("proficiency"):
		player_data["proficiency"] = {}
	player_data["proficiency"][school_id] = clampi(level, 0, 15)

# 验证境界门槛
func validate_realm_requirement(required_realm: int) -> bool:
	var current_realm = get_current_realm()
	return current_realm >= required_realm

# 获取当前境界等级
func get_current_realm() -> int:
	return player_data.get("realm", 1)

# 设置当前境界等级（用于测试和游戏进度）
func set_current_realm(realm: int) -> void:
	player_data["realm"] = clampi(realm, 1, 10)

# 验证物品/秘籍消耗条件
func validate_item_requirements(required_items: Dictionary) -> UnlockResult:
	if not inventory_manager:
		return UnlockResult.new(false, "物品管理器未初始化")
	
	var missing_items = []
	
	for item_id in required_items.keys():
		var required_count = required_items[item_id]
		var owned_count = inventory_manager.get_item_count(item_id)
		
		if owned_count < required_count:
			missing_items.append({
				"item_id": item_id,
				"required": required_count,
				"owned": owned_count,
				"missing": required_count - owned_count
			})
	
	if missing_items.is_empty():
		return UnlockResult.new(true, "物品条件满足")
	else:
		return UnlockResult.new(false, "物品不足", missing_items)

# 消耗物品解锁武学
func consume_items_for_unlock(required_items: Dictionary) -> bool:
	if not inventory_manager:
		return false
	
	# 先验证物品是否足够
	var validation = validate_item_requirements(required_items)
	if not validation.success:
		return false
	
	# 消耗物品
	for item_id in required_items.keys():
		var count = required_items[item_id]
		if not inventory_manager.remove_item(item_id, count):
			# 如果消耗失败，回滚（这里简化处理，实际应该有事务机制）
			push_error("消耗物品失败: %s" % item_id)
			return false
	
	return true

# 验证奇遇/事件解锁条件
func validate_event_requirement(event_id: String) -> bool:
	if not event_manager:
		return false
	
	return event_manager.is_event_triggered(event_id)

# 触发奇遇事件解锁
func trigger_event_unlock(event_id: String, skill_id: String) -> bool:
	if not event_manager:
		return false
	
	# 标记事件已触发
	event_manager.mark_event_triggered(event_id)
	
	# 解锁武学
	return unlock_skill(skill_id, "event_unlock")

# 解锁武学（核心解锁函数）
func unlock_skill(skill_id: String, unlock_source: String = "manual") -> bool:
	# 检查是否已解锁
	if is_skill_unlocked(skill_id):
		return false
	
	# 添加到已解锁列表
	if not player_data.has("unlocked_skills"):
		player_data["unlocked_skills"] = []
	
	player_data["unlocked_skills"].append(skill_id)
	
	# 记录解锁历史
	unlock_history[skill_id] = {
		"timestamp": Time.get_unix_time_from_system(),
		"source": unlock_source
	}
	
	return true

# 检查武学是否已解锁
func is_skill_unlocked(skill_id: String) -> bool:
	var unlocked_skills = player_data.get("unlocked_skills", [])
	return unlocked_skills.has(skill_id)

# 获取已解锁武学列表
func get_unlocked_skills() -> Array:
	return player_data.get("unlocked_skills", [])

# 完整解锁流程（包含所有条件验证和物品消耗）
func unlock_skill_with_conditions(
	school_id: String,
	skill_id: String,
	required_proficiency: int = 0,
	required_realm: int = 0,
	required_items: Dictionary = {},
	required_event: String = ""
) -> UnlockResult:
	# 验证所有条件
	var validation = validate_unlock_conditions(
		school_id,
		skill_id,
		required_proficiency,
		required_realm,
		required_items,
		required_event
	)
	
	if not validation.success:
		return validation
	
	# 消耗物品（如果需要）
	if not required_items.is_empty():
		if not consume_items_for_unlock(required_items):
			return UnlockResult.new(false, "消耗物品失败")
	
	# 解锁武学
	if unlock_skill(skill_id, "normal_unlock"):
		return UnlockResult.new(true, "武学解锁成功")
	else:
		return UnlockResult.new(false, "武学已解锁或解锁失败")

# 获取解锁历史
func get_unlock_history(skill_id: String) -> Dictionary:
	return unlock_history.get(skill_id, {})

# 清除解锁历史（用于测试）
func clear_unlock_history() -> void:
	unlock_history.clear()

# 重置玩家数据（用于测试）
func reset_player_data() -> void:
	player_data = {
		"proficiency": {},
		"realm": 1,
		"unlocked_skills": []
	}
	unlock_history.clear()

# 简化的物品管理器（用于测试，实际应使用真实的物品管理器）
class MockInventoryManager:
	var items: Dictionary = {}
	
	func get_item_count(item_id: String) -> int:
		return items.get(item_id, 0)
	
	func add_item(item_id: String, count: int) -> void:
		items[item_id] = items.get(item_id, 0) + count
	
	func remove_item(item_id: String, count: int) -> bool:
		var current = items.get(item_id, 0)
		if current >= count:
			items[item_id] = current - count
			return true
		return false
	
	func clear() -> void:
		items.clear()

# 简化的事件管理器（用于测试，实际应使用真实的事件管理器）
class MockEventManager:
	var triggered_events: Array = []
	
	func is_event_triggered(event_id: String) -> bool:
		return triggered_events.has(event_id)
	
	func mark_event_triggered(event_id: String) -> void:
		if not triggered_events.has(event_id):
			triggered_events.append(event_id)
	
	func clear() -> void:
		triggered_events.clear()