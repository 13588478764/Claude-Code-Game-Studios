# 任务管理器
# 管理游戏中所有任务的状态和进度

extends Node

class_name QuestManager

# 信号定义
signal quest_status_changed(quest_id: String, old_status: String, new_status: String)
signal quest_objective_updated(quest_id: String, objective_index: int, current_value: int, target_value: int)
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_finished(quest_id: String)

# 任务状态枚举
enum QuestStatus {
	LOCKED,      # 锁定：前置条件未满足
	AVAILABLE,   # 可接取：条件满足，玩家可接取
	ACTIVE,      # 进行中：玩家已接取，正在追踪目标
	COMPLETED,   # 已完成：目标达成，等待提交
	FINISHED     # 已结束：奖励已领取，任务归档
}

# 任务类型枚举
enum QuestType {
	MAIN,        # 主线任务
	SIDE,        # 支线任务
	BOUNTY,      # 悬赏任务
	ENCOUNTER    # 奇遇任务
}

# 目标类型枚举
enum ObjectiveType {
	TALK_TO_NPC,     # 与NPC对话
	KILL_ENEMY,      # 击杀敌人
	COLLECT_ITEM,    # 收集物品
	GO_TO_LOCATION,  # 到达指定位置
	USE_ITEM         # 使用物品
}

# 任务数据结构
class Quest:
	var id: String
	var title: String
	var description: String
	var quest_type: QuestType
	var status: QuestStatus
	var objectives: Array  # Array of Objective structs
	var rewards: Dictionary  # {exp: amount, silver: amount, items: [item_ids]}
	var prerequisites: Dictionary  # {min_level: level, required_quests: [quest_ids]}
	var npc_id: String  # 关联的NPC ID
	
	func _init(p_id: String, p_title: String, p_description: String, p_type: QuestType, p_npc_id: String = ""):
		id = p_id
		title = p_title
		description = p_description
		quest_type = p_type
		status = QuestStatus.LOCKED
		objectives = []
		rewards = {}
		prerequisites = {}
		npc_id = p_npc_id

# 目标数据结构
class Objective:
	var type: ObjectiveType
	var target_id: String  # NPC ID, enemy type, item ID, location ID, etc.
	var target_count: int
	var current_count: int
	var description: String
	
	func _init(p_type: ObjectiveType, p_target_id: String, p_target_count: int, p_description: String):
		type = p_type
		target_id = p_target_id
		target_count = p_target_count
		current_count = 0
		description = p_description

# 存储所有任务定义
var quest_definitions: Dictionary = {}

# 存储玩家当前的任务状态
var active_quests: Dictionary = {}

# 玩家相关信息
var player_level: int = 1
var player_completed_quests: Array = []  # 已完成任务ID列表
var player_inventory: Array = []  # 玩家物品列表

# 初始化
func _ready():
	print("Quest Manager initialized")

# 注册任务定义
func register_quest(quest_id: String, title: String, description: String, quest_type: QuestType, npc_id: String = "") -> bool:
	if quest_definitions.has(quest_id):
		print("Quest ID already exists: ", quest_id)
		return false
	
	var new_quest = Quest.new(quest_id, title, description, quest_type, npc_id)
	quest_definitions[quest_id] = new_quest
	print("Registered quest: ", quest_id)
	return true

# 添加任务目标
func add_quest_objective(quest_id: String, obj_type: ObjectiveType, target_id: String, target_count: int, description: String) -> bool:
	if not quest_definitions.has(quest_id):
		print("Quest not found: ", quest_id)
		return false
	
	var quest = quest_definitions[quest_id]
	var objective = Objective.new(obj_type, target_id, target_count, description)
	quest.objectives.append(objective)
	
	# 如果该任务已经处于 active 状态（已被 accept_quest 拷贝到 active_quests），
	# 同步把新目标也添加到 active_quests 的副本中。
	# 否则之后调用 update_objective_progress / get_quest_info 时会发现 active_quests
	# 中的 objectives 是空的（accept_quest 时拷贝的快照），导致进度无法更新。
	if active_quests.has(quest_id):
		# 单独 new 一个 Objective 实例，避免与 quest_definitions 共享引用
		var active_objective = Objective.new(obj_type, target_id, target_count, description)
		active_quests[quest_id].objectives.append(active_objective)
	
	print("Added objective to quest ", quest_id, ": ", description)
	return true

# 设置任务奖励
func set_quest_rewards(quest_id: String, rewards: Dictionary) -> bool:
	if not quest_definitions.has(quest_id):
		print("Quest not found: ", quest_id)
		return false
	
	quest_definitions[quest_id].rewards = rewards
	print("Set rewards for quest ", quest_id)
	return true

# 设置任务前置条件
func set_quest_prerequisites(quest_id: String, prerequisites: Dictionary) -> bool:
	if not quest_definitions.has(quest_id):
		print("Quest not found: ", quest_id)
		return false
	
	quest_definitions[quest_id].prerequisites = prerequisites
	print("Set prerequisites for quest ", quest_id)
	return true

# 检查任务前置条件
func check_quest_prerequisites(quest_id: String) -> bool:
	if not quest_definitions.has(quest_id):
		return false
	
	var quest = quest_definitions[quest_id]
	var prereqs = quest.prerequisites
	
	# 检查等级要求
	if prereqs.has("min_level"):
		if player_level < prereqs.min_level:
			return false
	
	# 检查前置任务要求
	if prereqs.has("required_quests"):
		for required_quest in prereqs.required_quests:
			if not player_completed_quests.has(required_quest):
				return false
	
	return true

# 更新任务状态
func update_quest_status(quest_id: String, new_status: QuestStatus) -> bool:
	var old_status: QuestStatus
	
	# 如果任务已在进行中，从active_quests获取
	if active_quests.has(quest_id):
		old_status = active_quests[quest_id].status
		active_quests[quest_id].status = new_status
	# 否则，从定义中获取并添加到active_quests
	elif quest_definitions.has(quest_id):
		var quest_def = quest_definitions[quest_id]
		old_status = quest_def.status
		quest_def.status = new_status
		
		# 将任务复制到active_quests（如果是进行中状态）
		if new_status == QuestStatus.ACTIVE:
			var active_quest = Quest.new(quest_def.id, quest_def.title, quest_def.description, quest_def.quest_type, quest_def.npc_id)
			active_quest.status = new_status
			active_quest.objectives = quest_def.objectives.duplicate(true)  # 深拷贝目标
			active_quest.rewards = quest_def.rewards.duplicate()
			active_quest.prerequisites = quest_def.prerequisites.duplicate()
			active_quests[quest_id] = active_quest
	
	if old_status != new_status:
		emit_signal("quest_status_changed", quest_id, QuestStatus.keys()[old_status], QuestStatus.keys()[new_status])
		
		# 根据状态变化发送特定信号
		if new_status == QuestStatus.AVAILABLE:
			pass  # 可接取状态
		elif new_status == QuestStatus.ACTIVE:
			emit_signal("quest_accepted", quest_id)
		elif new_status == QuestStatus.COMPLETED:
			emit_signal("quest_completed", quest_id)
		elif new_status == QuestStatus.FINISHED:
			emit_signal("quest_finished", quest_id)
		
		return true
	
	return false

# 接取任务
func accept_quest(quest_id: String) -> bool:
	if not quest_definitions.has(quest_id):
		print("Quest not found: ", quest_id)
		return false
	
	var quest = quest_definitions[quest_id]
	
	# 检查任务是否可接取
	if quest.status != QuestStatus.AVAILABLE and not check_quest_prerequisites(quest_id):
		print("Cannot accept quest ", quest_id, " - not available or prerequisites not met")
		return false
	
	# 更新任务状态为进行中
	if update_quest_status(quest_id, QuestStatus.ACTIVE):
		print("Accepted quest: ", quest_id)
		return true
	
	return false

# 更新任务目标进度
func update_objective_progress(quest_id: String, objective_index: int, increment: int = 1) -> bool:
	if not active_quests.has(quest_id):
		print("Active quest not found: ", quest_id)
		return false
	
	var quest = active_quests[quest_id]
	if objective_index < 0 or objective_index >= quest.objectives.size():
		print("Invalid objective index: ", objective_index)
		return false
	
	var objective = quest.objectives[objective_index]
	objective.current_count = min(objective.current_count + increment, objective.target_count)
	
	# 发送进度更新信号
	emit_signal("quest_objective_updated", quest_id, objective_index, objective.current_count, objective.target_count)
	
	# 检查是否所有目标都已完成
	if _are_all_objectives_complete(quest):
		update_quest_status(quest_id, QuestStatus.COMPLETED)
	
	print("Updated objective progress for quest ", quest_id, ", objective ", objective_index, ": ", objective.current_count, "/", objective.target_count)
	return true

# 检查所有目标是否完成
func _are_all_objectives_complete(quest) -> bool:
	for objective in quest.objectives:
		if objective.current_count < objective.target_count:
			return false
	return true

# 完成任务（提交任务，准备领取奖励）
func complete_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		print("Active quest not found: ", quest_id)
		return false
	
	var quest = active_quests[quest_id]
	
	# 检查任务是否已完成所有目标
	if quest.status != QuestStatus.COMPLETED:
		if not _are_all_objectives_complete(quest):
			print("Cannot complete quest ", quest_id, " - objectives not finished")
			return false
	
	# 更新任务状态为已完成
	if update_quest_status(quest_id, QuestStatus.FINISHED):
		# 将任务添加到已完成列表
		if not player_completed_quests.has(quest_id):
			player_completed_quests.append(quest_id)
		
		# 从进行中任务列表移除
		active_quests.erase(quest_id)
		
		print("Completed quest: ", quest_id)
		return true
	
	return false

# 获取任务信息
func get_quest_info(quest_id: String) -> Dictionary:
	var quest = null
	
	# 首先检查进行中的任务
	if active_quests.has(quest_id):
		quest = active_quests[quest_id]
	# 然后检查任务定义
	elif quest_definitions.has(quest_id):
		quest = quest_definitions[quest_id]
	else:
		return {}
	
	return {
		"id": quest.id,
		"title": quest.title,
		"description": quest.description,
		"type": quest.quest_type,
		"status": quest.status,
		"objectives": _get_objectives_info(quest.objectives),
		"rewards": quest.rewards,
		"prerequisites": quest.prerequisites,
		"npc_id": quest.npc_id
	}

# 获取目标信息
func _get_objectives_info(objectives_array) -> Array:
	var result = []
	for objective in objectives_array:
		result.append({
			"type": objective.type,
			"target_id": objective.target_id,
			"target_count": objective.target_count,
			"current_count": objective.current_count,
			"description": objective.description,
			"is_complete": objective.current_count >= objective.target_count
		})
	return result

# 获取指定状态的任务列表
func get_quests_by_status(status: QuestStatus) -> Array:
	var result = []
	
	# 检查进行中的任务
	for quest_id in active_quests:
		if active_quests[quest_id].status == status:
			result.append(quest_id)
	
	# 检查任务定义（对于锁定和可接取状态）
	for quest_id in quest_definitions:
		var quest = quest_definitions[quest_id]
		if quest.status == status and not active_quests.has(quest_id):
			result.append(quest_id)
	
	return result

# 获取进行中的任务列表
func get_active_quests() -> Array:
	var result = []
	for quest_id in active_quests:
		result.append(quest_id)
	return result

# 设置玩家等级
func set_player_level(level: int):
	player_level = level
	# 可能需要重新评估任务锁定状态
	_refresh_locked_quests()

# 刷新锁定的任务状态
func _refresh_locked_quests():
	for quest_id in quest_definitions:
		var quest = quest_definitions[quest_id]
		if quest.status == QuestStatus.LOCKED:
			if check_quest_prerequisites(quest_id):
				update_quest_status(quest_id, QuestStatus.AVAILABLE)

# 检查物品是否在背包中
func has_item(item_id: String) -> bool:
	return player_inventory.has(item_id)

# 添加物品到背包
func add_item_to_inventory(item_id: String):
	if not player_inventory.has(item_id):
		player_inventory.append(item_id)

# 移除背包中的物品
func remove_item_from_inventory(item_id: String):
	player_inventory.erase(item_id)

# 保存任务数据
func save_quest_data() -> Dictionary:
	var save_data = {
		"player_level": player_level,
		"player_completed_quests": player_completed_quests,
		"player_inventory": player_inventory,
		"active_quests": {}
	}
	
	# 保存进行中的任务状态
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		var quest_data = {
			"id": quest.id,
			"status": quest.status,
			"objectives": []
		}
		
		for objective in quest.objectives:
			quest_data.objectives.append({
				"type": objective.type,
				"target_id": objective.target_id,
				"target_count": objective.target_count,
				"current_count": objective.current_count,
				"description": objective.description
			})
		
		save_data.active_quests[quest_id] = quest_data
	
	return save_data

# 加载任务数据
func load_quest_data(data: Dictionary):
	if data.has("player_level"):
		player_level = data.player_level
	if data.has("player_completed_quests"):
		player_completed_quests = data.player_completed_quests
	if data.has("player_inventory"):
		player_inventory = data.player_inventory
	
	# 加载进行中的任务
	if data.has("active_quests"):
		for quest_id in data.active_quests:
			var quest_data = data.active_quests[quest_id]
			
			# 从定义中获取任务模板
			if quest_definitions.has(quest_id):
				var quest_template = quest_definitions[quest_id]
				var active_quest = Quest.new(quest_template.id, quest_template.title, 
											quest_template.description, quest_template.quest_type, 
											quest_template.npc_id)
				active_quest.status = quest_data.status
				active_quest.rewards = quest_template.rewards.duplicate()
				active_quest.prerequisites = quest_template.prerequisites.duplicate()
				
				# 重建目标
				for obj_data in quest_data.objectives:
					var objective = Objective.new(obj_data.type, obj_data.target_id, 
												 obj_data.target_count, obj_data.description)
					objective.current_count = obj_data.current_count
					active_quest.objectives.append(objective)
				
				active_quests[quest_id] = active_quest

# 获取任务类型奖励系数
func get_reward_coefficient(quest_type: QuestType) -> Dictionary:
	match quest_type:
		QuestType.MAIN:  # 主线任务
			return {"exp_factor": 100, "silver_factor": 50}
		QuestType.SIDE:  # 支线任务
			return {"exp_factor": 50, "silver_factor": 20}
		QuestType.BOUNTY:  # 悬赏任务
			return {"exp_factor": 10, "silver_factor": 5}
		_:  # 默认
			return {"exp_factor": 10, "silver_factor": 10}