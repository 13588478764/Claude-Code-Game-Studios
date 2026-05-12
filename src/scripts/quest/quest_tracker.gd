# 任务追踪器
# 负责追踪任务目标进度并与UI系统交互

extends Node

class_name QuestTracker

# 信号定义
signal objective_progress_updated(quest_id: String, objective_index: int, current: int, target: int)
signal quest_target_location_updated(quest_id: String, location: Vector2)
signal active_quest_changed(old_quest_id: String, new_quest_id: String)

# 引用任务管理器
var quest_manager: Node = null

# 当前追踪的任务
var current_tracked_quest: String = ""
var current_tracked_objective: int = -1

# 初始化
func _ready():
	print("Quest Tracker initialized")

# 设置任务管理器引用
func set_quest_manager(manager: Node):
	quest_manager = manager
	if quest_manager:
		quest_manager.connect("quest_status_changed", _on_quest_status_changed)
		quest_manager.connect("quest_objective_updated", _on_quest_objective_updated)
		quest_manager.connect("quest_accepted", _on_quest_accepted)
		quest_manager.connect("quest_completed", _on_quest_completed)

# 连接到任务管理器信号的回调函数
func _on_quest_status_changed(quest_id: String, old_status: String, new_status: String):
	# 当任务状态改变时的处理
	if new_status == "ACTIVE":
		# 如果有正在进行的任务，停止追踪旧任务
		if current_tracked_quest != "":
			var old_quest_id = current_tracked_quest
			current_tracked_quest = ""
			emit_signal("active_quest_changed", old_quest_id, "")
		
		# 开始追踪新任务
		current_tracked_quest = quest_id
		emit_signal("active_quest_changed", "", quest_id)
		print("Started tracking quest: ", quest_id)
	elif new_status == "COMPLETED" or new_status == "FINISHED":
		# 如果完成的是当前追踪的任务，停止追踪
		if current_tracked_quest == quest_id:
			var old_quest_id = current_tracked_quest
			current_tracked_quest = ""
			emit_signal("active_quest_changed", old_quest_id, "")
			print("Stopped tracking completed quest: ", quest_id)

func _on_quest_objective_updated(quest_id: String, objective_index: int, current_value: int, target_value: int):
	# 当任务目标进度更新时
	emit_signal("objective_progress_updated", quest_id, objective_index, current_value, target_value)
	
	# 如果这是当前追踪的任务，更新追踪信息
	if current_tracked_quest == quest_id:
		print("Objective progress updated for tracked quest ", quest_id, ": ", current_value, "/", target_value)

func _on_quest_accepted(quest_id: String):
	# 任务被接取时的处理
	print("Quest accepted: ", quest_id)

func _on_quest_completed(quest_id: String):
	# 任务完成时的处理
	print("Quest completed: ", quest_id)

# 追踪指定任务
func track_quest(quest_id: String) -> bool:
	if not quest_manager:
		print("No quest manager assigned to tracker")
		return false
	
	var quest_info = quest_manager.get_quest_info(quest_id)
	if quest_info.is_empty():
		print("Quest not found: ", quest_id)
		return false
	
	if quest_info.status != quest_manager.QuestStatus.ACTIVE:
		print("Cannot track inactive quest: ", quest_id)
		return false
	
	# 停止追踪当前任务
	var old_tracked_quest = current_tracked_quest
	if old_tracked_quest != "":
		emit_signal("active_quest_changed", old_tracked_quest, "")
	
	# 开始追踪新任务
	current_tracked_quest = quest_id
	emit_signal("active_quest_changed", "", current_tracked_quest)
	
	print("Now tracking quest: ", quest_id)
	return true

# 停止追踪当前任务
func stop_tracking() -> bool:
	if current_tracked_quest == "":
		return false
	
	var old_tracked_quest = current_tracked_quest
	current_tracked_quest = ""
	emit_signal("active_quest_changed", old_tracked_quest, "")
	
	print("Stopped tracking quest: ", old_tracked_quest)
	return true

# 获取当前追踪的任务信息
func get_current_tracked_quest_info() -> Dictionary:
	if current_tracked_quest == "":
		return {}
	
	if not quest_manager:
		return {}
	
	return quest_manager.get_quest_info(current_tracked_quest)

# 获取当前追踪的任务ID
func get_current_tracked_quest_id() -> String:
	return current_tracked_quest

# 获取所有进行中的任务信息
func get_active_quests_info() -> Array:
	if not quest_manager:
		return []
	
	var active_quests_ids = quest_manager.get_active_quests()
	var result = []
	
	for quest_id in active_quests_ids:
		var quest_info = quest_manager.get_quest_info(quest_id)
		if not quest_info.is_empty():
			result.append(quest_info)
	
	return result

# 处理外部事件以更新任务进度
func handle_external_event(event_type: String, data: Dictionary):
	if not quest_manager:
		return
	
	# 根据事件类型更新相应的任务目标
	match event_type:
		"enemy_killed":
			_handle_enemy_killed_event(data)
		"item_collected":
			_handle_item_collected_event(data)
		"location_reached":
			_handle_location_reached_event(data)
		"npc_talked_to":
			_handle_npc_talked_to_event(data)
		"item_used":
			_handle_item_used_event(data)

# 处理敌人被击杀事件
func _handle_enemy_killed_event(data: Dictionary):
	if not data.has("enemy_type"):
		return
	
	var enemy_type = data.enemy_type
	
	# 遍历所有进行中的任务，查找需要击杀此类型敌人的目标
	var active_quests = quest_manager.get_active_quests()
	for quest_id in active_quests:
		var quest_info = quest_manager.get_quest_info(quest_id)
		if quest_info.is_empty():
			continue
		
		# 检查任务的每个目标
		for i in range(quest_info.objectives.size()):
			var objective = quest_info.objectives[i]
			if objective.type == quest_manager.ObjectiveType.KILL_ENEMY and objective.target_id == enemy_type:
				# 更新目标进度
				quest_manager.update_objective_progress(quest_id, i)
				break

# 处理物品被收集事件
func _handle_item_collected_event(data: Dictionary):
	if not data.has("item_id"):
		return
	
	var item_id = data.item_id
	
	# 遍历所有进行中的任务，查找需要收集此物品的目标
	var active_quests = quest_manager.get_active_quests()
	for quest_id in active_quests:
		var quest_info = quest_manager.get_quest_info(quest_id)
		if quest_info.is_empty():
			continue
		
		# 检查任务的每个目标
		for i in range(quest_info.objectives.size()):
			var objective = quest_info.objectives[i]
			if objective.type == quest_manager.ObjectiveType.COLLECT_ITEM and objective.target_id == item_id:
				# 更新目标进度
				quest_manager.update_objective_progress(quest_id, i)
				break

# 处理到达位置事件
func _handle_location_reached_event(data: Dictionary):
	if not data.has("location_id"):
		return
	
	var location_id = data.location_id
	
	# 遍历所有进行中的任务，查找需要到达此位置的目标
	var active_quests = quest_manager.get_active_quests()
	for quest_id in active_quests:
		var quest_info = quest_manager.get_quest_info(quest_id)
		if quest_info.is_empty():
			continue
		
		# 检查任务的每个目标
		for i in range(quest_info.objectives.size()):
			var objective = quest_info.objectives[i]
			if objective.type == quest_manager.ObjectiveType.GO_TO_LOCATION and objective.target_id == location_id:
				# 更新目标进度
				quest_manager.update_objective_progress(quest_id, i)
				# 发送位置更新信号
				if data.has("world_position"):
					emit_signal("quest_target_location_updated", quest_id, data.world_position)
				break

# 处理与NPC对话事件
func _handle_npc_talked_to_event(data: Dictionary):
	if not data.has("npc_id"):
		return
	
	var npc_id = data.npc_id
	
	# 遍历所有进行中的任务，查找需要与此NPC对话的目标
	var active_quests = quest_manager.get_active_quests()
	for quest_id in active_quests:
		var quest_info = quest_manager.get_quest_info(quest_id)
		if quest_info.is_empty():
			continue
		
		# 检查任务的每个目标
		for i in range(quest_info.objectives.size()):
			var objective = quest_info.objectives[i]
			if objective.type == quest_manager.ObjectiveType.TALK_TO_NPC and objective.target_id == npc_id:
				# 更新目标进度
				quest_manager.update_objective_progress(quest_id, i)
				break

# 处理物品使用事件
func _handle_item_used_event(data: Dictionary):
	if not data.has("item_id"):
		return
	
	var item_id = data.item_id
	
	# 遍历所有进行中的任务，查找需要使用此物品的目标
	var active_quests = quest_manager.get_active_quests()
	for quest_id in active_quests:
		var quest_info = quest_manager.get_quest_info(quest_id)
		if quest_info.is_empty():
			continue
		
		# 检查任务的每个目标
		for i in range(quest_info.objectives.size()):
			var objective = quest_info.objectives[i]
			if objective.type == quest_manager.ObjectiveType.USE_ITEM and objective.target_id == item_id:
				# 更新目标进度
				quest_manager.update_objective_progress(quest_id, i)
				break

# 获取追踪的UI数据显示
func get_tracking_ui_data() -> Dictionary:
	var ui_data = {
		"tracked_quest": null,
		"active_quests": [],
		"has_tracked_quest": false
	}
	
	if current_tracked_quest != "":
		ui_data.tracked_quest = get_current_tracked_quest_info()
		ui_data.has_tracked_quest = true
	
	ui_data.active_quests = get_active_quests_info()
	
	return ui_data

# 检查是否有紧急任务需要关注（即将完成的任务）
func get_urgent_quests() -> Array:
	var urgent_quests = []
	var active_quests = get_active_quests_info()
	
	for quest_info in active_quests:
		# 检查是否接近完成（任意目标完成度达到90%以上）
		for objective in quest_info.objectives:
			if objective.target_count > 0:
				var progress_ratio = float(objective.current_count) / float(objective.target_count)
				if progress_ratio >= 0.9:
					urgent_quests.append(quest_info.id)
					break  # 找到一个接近完成的目标就够了
	
	return urgent_quests

# 获取指定任务的追踪数据
func get_quest_tracking_data(quest_id: String) -> Dictionary:
	if not quest_manager:
		return {}
	
	var quest_info = quest_manager.get_quest_info(quest_id)
	if quest_info.is_empty():
		return {}
	
	var tracking_data = {
		"quest_id": quest_info.id,
		"title": quest_info.title,
		"status": quest_info.status,
		"objectives": [],
		"is_tracked": (current_tracked_quest == quest_id)
	}
	
	for objective in quest_info.objectives:
		tracking_data.objectives.append({
			"description": objective.description,
			"current_count": objective.current_count,
			"target_count": objective.target_count,
			"is_complete": objective.is_complete,
			"progress_ratio": (float(objective.current_count) / float(objective.target_count)) if objective.target_count > 0 else 0
		})
	
	return tracking_data
