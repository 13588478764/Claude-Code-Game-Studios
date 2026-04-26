# 武侠奇遇录 - 任务系统
# 负责管理游戏中的所有任务、目标追踪和奖励发放

extends Node

# 任务状态枚举
enum QuestState {
	LOCKED,      # 锁定（前置条件未满足）
	AVAILABLE,   # 可接取（条件满足）
	ACTIVE,      # 进行中（已接取）
	COMPLETED,   # 已完成（目标达成，等待提交）
	FINISHED     # 已结束（奖励已领取）
}

# 任务类型枚举
enum QuestType {
	MAIN,        # 主线任务
	SIDE,        # 支线任务
	BOUNTY,      # 悬赏任务
	ENCOUNTER    # 奇遇任务
}

# 目标类型枚举
enum TargetType {
	TALK_TO_NPC,    # 与NPC对话
	KILL_ENEMY,     # 击杀敌人
	COLLECT_ITEM,   # 收集物品
	GO_TO_LOCATION, # 到达地点
	USE_ITEM        # 使用物品
}

# 任务配置
var config = {
	"main_quest_exp_multiplier": 100,    # 主线任务EXP系数
	"main_quest_silver_multiplier": 50,  # 主线任务银两系数
	"side_quest_exp_multiplier": 50,     # 支线任务EXP系数
	"side_quest_silver_multiplier": 20,  # 支线任务银两系数
	"bounty_quest_exp_multiplier": 10,   # 悬赏任务EXP系数
	"bounty_quest_silver_multiplier": 5, # 悬赏任务银两系数
	"max_active_quests": 10,            # 最大进行中任务数
	"daily_bounty_refresh": 3,          # 每日悬赏刷新数量
	"weekly_bounty_refresh": 5         # 每周悬赏刷新数量
}

# 任务数据结构
class QuestData:
	var id = ""
	var name = ""
	var description = ""
	var type = QuestType.MAIN
	var state = QuestState.LOCKED
	var prerequisites = []  # 前置任务ID列表
	var required_level = 0
	var required_realm = 0
	var targets = []       # 目标列表
	var rewards = {}       # 奖励数据
	var npc_id = ""        # 相关NPC
	var location = ""      # 相关地点
	var is_repeatable = false  # 是否可重复
	var completion_count = 0   # 完成次数

# 目标数据结构
class TargetData:
	var type = TargetType.TALK_TO_NPC
	var target_id = ""      # 目标ID（NPC ID、敌人ID、物品ID等）
	var target_count = 1    # 目标数量
	var current_count = 0   # 当前完成数量
	var is_completed = false

# 当前任务状态
var active_quests = {}     # 进行中任务字典 {quest_id: QuestData}
var completed_quests = []  # 已完成任务ID列表
var available_quests = []  # 可接取任务ID列表
var locked_quests = []     # 锁定任务ID列表

func _ready():
	print("任务系统初始化完成")
	load_quest_data()

func load_quest_data():
	"""加载任务数据"""
	# 这里应该从JSON文件加载任务数据
	# 简化实现：暂时只打印信息
	print("加载任务数据...")

func check_quest_availability(quest_id, character_level, character_realm):
	"""检查任务是否可接取"""
	var quest_data = get_quest_data(quest_id)
	if quest_data == null:
		return false
	
	# 检查等级要求
	if character_level < quest_data.required_level:
		return false
	
	# 检查境界要求
	if character_realm < quest_data.required_realm:
		return false
	
	# 检查前置任务
	for prereq_id in quest_data.prerequisites:
		if not completed_quests.has(prereq_id):
			return false
	
	return true

func accept_quest(quest_id):
	"""接取任务"""
	if active_quests.size() >= config["max_active_quests"]:
		push_warning("进行中任务已达上限")
		return false
	
	var quest_data = get_quest_data(quest_id)
	if quest_data == null:
		push_warning("任务不存在: %s" % quest_id)
		return false
	
	if quest_data.state != QuestState.AVAILABLE:
		push_warning("任务不可接取: %s" % quest_id)
		return false
	
	# 创建新的任务实例
	var new_quest = QuestData.new()
	new_quest.id = quest_data.id
	new_quest.name = quest_data.name
	new_quest.description = quest_data.description
	new_quest.type = quest_data.type
	new_quest.state = QuestState.ACTIVE
	new_quest.prerequisites = quest_data.prerequisites.duplicate()
	new_quest.required_level = quest_data.required_level
	new_quest.required_realm = quest_data.required_realm
	new_quest.targets = duplicate_targets(quest_data.targets)
	new_quest.rewards = quest_data.rewards.duplicate()
	new_quest.npc_id = quest_data.npc_id
	new_quest.location = quest_data.location
	new_quest.is_repeatable = quest_data.is_repeatable
	new_quest.completion_count = 0
	
	# 添加到进行中任务
	active_quests[quest_id] = new_quest
	
	# 从可接取列表移除
	if available_quests.has(quest_id):
		available_quests.erase(quest_id)
	
	print("接取任务: %s" % quest_data.name)
	return true

func complete_quest_target(quest_id, target_type, target_id, count=1):
	"""完成任务目标"""
	if not active_quests.has(quest_id):
		return false
	
	var quest = active_quests[quest_id]
	
	# 查找匹配的目标
	for target in quest.targets:
		if target.type == target_type and target.target_id == target_id:
			target.current_count += count
			if target.current_count >= target.target_count:
				target.is_completed = true
			
			# 检查所有目标是否完成
			if check_all_targets_completed(quest):
				quest.state = QuestState.COMPLETED
				print("任务完成: %s" % quest.name)
			
			return true
	
	return false

func check_all_targets_completed(quest):
	"""检查所有目标是否完成"""
	for target in quest.targets:
		if not target.is_completed:
			return false
	return true

func submit_quest(quest_id):
	"""提交任务"""
	if not active_quests.has(quest_id):
		return false
	
	var quest = active_quests[quest_id]
	if quest.state != QuestState.COMPLETED:
		push_warning("任务未完成，无法提交: %s" % quest_id)
		return false
	
	# 发放奖励
	distribute_quest_rewards(quest)
	
	# 标记为已完成
	quest.state = QuestState.FINISHED
	completed_quests.append(quest_id)
	
	# 从进行中任务移除
	active_quests.erase(quest_id)
	
	print("提交任务: %s" % quest.name)
	return true

func distribute_quest_rewards(quest):
	"""发放任务奖励"""
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		push_warning("无法访问CharacterSystem")
		return
	
	var character_level = character_system.level
	
	# 计算基础奖励
	var exp_reward = 0
	var silver_reward = 0
	
	match quest.type:
		QuestType.MAIN:
			exp_reward = character_level * config["main_quest_exp_multiplier"]
			silver_reward = character_level * config["main_quest_silver_multiplier"]
		QuestType.SIDE:
			exp_reward = character_level * config["side_quest_exp_multiplier"]
			silver_reward = character_level * config["side_quest_silver_multiplier"]
		QuestType.BOUNTY:
			exp_reward = character_level * config["bounty_quest_exp_multiplier"]
			silver_reward = character_level * config["bounty_quest_silver_multiplier"]
		QuestType.ENCOUNTER:
			# 奇遇任务奖励由奇遇系统处理
			return
	
	# 发放EXP
	character_system.add_experience(exp_reward)
	print("获得经验值: %d" % exp_reward)
	
	# 发放银两
	# 这里应该调用经济系统
	print("获得银两: %d" % silver_reward)
	
	# 发放物品奖励
	if quest.rewards.has("items"):
		for item_reward in quest.rewards["items"]:
			var item_id = item_reward["item_id"]
			var quantity = item_reward["quantity"]
			# 这里应该调用物品系统
			print("获得物品: %s x%d" % [item_id, quantity])
	
	# 发放属性点奖励
	if quest.rewards.has("attribute_points"):
		var points = quest.rewards["attribute_points"]
		character_system.total_attribute_points += points
		print("获得属性点: %d" % points)
	
	# 发放天赋点奖励
	if quest.rewards.has("talent_points"):
		var points = quest.rewards["talent_points"]
		# 这里应该调用天赋系统
		print("获得天赋点: %d" % points)

func get_quest_data(quest_id):
	"""获取任务数据（从数据库）"""
	# 这里应该从任务数据库获取数据
	# 简化实现：支持测试任务
	
	# 如果是测试任务，返回测试数据
	if quest_id == "test_quest":
		var test_quest = QuestData.new()
		test_quest.id = "test_quest"
		test_quest.name = "测试任务"
		test_quest.description = "这是一个测试任务"
		test_quest.type = QuestType.MAIN
		test_quest.state = QuestState.AVAILABLE
		test_quest.required_level = 5
		test_quest.required_realm = 0
		test_quest.targets = []
		test_quest.rewards = {}
		test_quest.npc_id = ""
		test_quest.location = ""
		test_quest.is_repeatable = false
		test_quest.completion_count = 0
		return test_quest
	
	# 这里应该从任务数据库获取数据
	# 简化实现：返回null
	return null

func duplicate_targets(targets):
	"""深度复制目标列表"""
	var copied_targets = []
	for target in targets:
		var new_target = TargetData.new()
		new_target.type = target.type
		new_target.target_id = target.target_id
		new_target.target_count = target.target_count
		new_target.current_count = target.current_count
		new_target.is_completed = target.is_completed
		copied_targets.append(new_target)
	return copied_targets

func refresh_daily_bounties():
	"""刷新每日悬赏任务"""
	# 这里应该生成新的悬赏任务
	# 简化实现：暂时只打印信息
	print("刷新每日悬赏任务")

func refresh_weekly_bounties():
	"""刷新每周悬赏任务"""
	# 这里应该生成新的悬赏任务
	# 简化实现：暂时只打印信息
	print("刷新每周悬赏任务")

func get_active_quest_list():
	"""获取进行中任务列表"""
	return active_quests.values()

func get_quest_by_id(quest_id):
	"""根据ID获取任务"""
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	return null

func is_quest_active(quest_id):
	"""检查任务是否进行中"""
	return active_quests.has(quest_id)

func is_quest_completed(quest_id):
	"""检查任务是否已完成"""
	return completed_quests.has(quest_id)

# 事件监听函数
func on_enemy_killed(enemy_id):
	"""敌人被击杀事件"""
	for quest_id in active_quests:
		complete_quest_target(quest_id, TargetType.KILL_ENEMY, enemy_id, 1)

func on_item_collected(item_id, count=1):
	"""物品被收集事件"""
	for quest_id in active_quests:
		complete_quest_target(quest_id, TargetType.COLLECT_ITEM, item_id, count)

func on_npc_talked(npc_id):
	"""与NPC对话事件"""
	for quest_id in active_quests:
		complete_quest_target(quest_id, TargetType.TALK_TO_NPC, npc_id, 1)

func on_location_reached(location_id):
	"""到达地点事件"""
	for quest_id in active_quests:
		complete_quest_target(quest_id, TargetType.GO_TO_LOCATION, location_id, 1)

func on_item_used(item_id):
	"""使用物品事件"""
	for quest_id in active_quests:
		complete_quest_target(quest_id, TargetType.USE_ITEM, item_id, 1)

# 调试函数
func debug_print_quest_info():
	"""打印任务信息用于调试"""
	print("=== 任务系统信息 ===")
	print("进行中任务: %d" % active_quests.size())
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		print("  %s (状态: %s)" % [quest.name, get_state_name(quest.state)])
	
	print("已完成任务: %d" % completed_quests.size())
	print("可接取任务: %d" % available_quests.size())
	print("锁定任务: %d" % locked_quests.size())
	print("====================")

func get_state_name(state):
	"""获取任务状态名称"""
	match state:
		QuestState.LOCKED:
			return "锁定"
		QuestState.AVAILABLE:
			return "可接取"
		QuestState.ACTIVE:
			return "进行中"
		QuestState.COMPLETED:
			return "已完成"
		QuestState.FINISHED:
			return "已结束"
		_:
			return "未知"

func get_type_name(type):
	"""获取任务类型名称"""
	match type:
		QuestType.MAIN:
			return "主线"
		QuestType.SIDE:
			return "支线"
		QuestType.BOUNTY:
			return "悬赏"
		QuestType.ENCOUNTER:
			return "奇遇"
		_:
			return "未知"

# UI回调函数
func _on_test_accept_quest_pressed():
	"""测试接取任务按钮回调"""
	print("=== 接取任务测试 ===")
	
	# 初始化角色数据
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(1000)  # 升级到10级
	
	# 创建测试任务
	var test_quest = QuestData.new()
	test_quest.id = "test_main_quest"
	test_quest.name = "测试主线任务"
	test_quest.description = "这是一个测试主线任务"
	test_quest.type = QuestType.MAIN
	test_quest.state = QuestState.AVAILABLE
	test_quest.required_level = 5
	test_quest.required_realm = 0
	test_quest.targets = []
	
	# 添加击杀目标
	var kill_target = TargetData.new()
	kill_target.type = TargetType.KILL_ENEMY
	kill_target.target_id = "bandit"
	kill_target.target_count = 3
	kill_target.current_count = 0
	kill_target.is_completed = false
	test_quest.targets.append(kill_target)
	
	# 添加对话目标
	var talk_target = TargetData.new()
	talk_target.type = TargetType.TALK_TO_NPC
	talk_target.target_id = "village_elder"
	talk_target.target_count = 1
	talk_target.current_count = 0
	talk_target.is_completed = false
	test_quest.targets.append(talk_target)
	
	# 设置奖励
	test_quest.rewards = {
		"items": [{"item_id": "rare_sword", "quantity": 1}],
		"attribute_points": 5,
		"talent_points": 2
	}
	
	# 模拟任务数据获取
	# 这里应该从数据库获取，简化实现直接使用测试数据
	# 将测试任务添加到可用列表
	available_quests.append(test_quest.id)
	
	# 接取任务
	var success = accept_quest(test_quest.id)
	if success:
		print("成功接取任务: %s" % test_quest.name)
		print("任务目标数量: %d" % test_quest.targets.size())
	else:
		print("接取任务失败")
	
	print("====================")

func _on_test_complete_target_pressed():
	"""测试完成目标按钮回调"""
	print("=== 完成目标测试 ===")
	
	# 检查是否有进行中任务
	if active_quests.size() == 0:
		print("没有进行中任务")
		return
	
	var quest_id = active_quests.keys()[0]
	var quest = active_quests[quest_id]
	
	# 完成第一个目标
	if quest.targets.size() > 0:
		var first_target = quest.targets[0]
		complete_quest_target(quest_id, first_target.type, first_target.target_id, first_target.target_count)
		print("完成目标: %s (%s)" % [get_target_type_name(first_target.type), first_target.target_id])
	
	# 完成第二个目标（如果存在）
	if quest.targets.size() > 1:
		var second_target = quest.targets[1]
		complete_quest_target(quest_id, second_target.type, second_target.target_id, second_target.target_count)
		print("完成目标: %s (%s)" % [get_target_type_name(second_target.type), second_target.target_id])
	
	# 检查任务状态
	print("任务状态: %s" % get_state_name(quest.state))
	
	print("====================")

func _on_test_submit_quest_pressed():
	"""测试提交任务按钮回调"""
	print("=== 提交任务测试 ===")
	
	# 查找已完成的任务
	var completed_quest_id = null
	for quest_id in active_quests:
		if active_quests[quest_id].state == QuestState.COMPLETED:
			completed_quest_id = quest_id
			break
	
	if completed_quest_id == null:
		print("没有已完成的任务")
		return
	
	# 提交任务
	var success = submit_quest(completed_quest_id)
	if success:
		print("成功提交任务")
		print("已完成任务数量: %d" % completed_quests.size())
	else:
		print("提交任务失败")
	
	print("====================")

func _on_test_reward_calculation_pressed():
	"""测试奖励计算按钮回调"""
	print("=== 奖励计算测试 ===")
	
	# 测试不同等级的奖励计算
	var test_levels = [1, 10, 50, 99]
	
	for level in test_levels:
		var character_system = get_node_or_null("/root/CharacterSystem")
		if character_system != null:
			character_system.level = level
		
		# 主线任务奖励
		var main_exp = level * config["main_quest_exp_multiplier"]
		var main_silver = level * config["main_quest_silver_multiplier"]
		
		# 支线任务奖励
		var side_exp = level * config["side_quest_exp_multiplier"]
		var side_silver = level * config["side_quest_silver_multiplier"]
		
		# 悬赏任务奖励
		var bounty_exp = level * config["bounty_quest_exp_multiplier"]
		var bounty_silver = level * config["bounty_quest_silver_multiplier"]
		
		print("等级 %d 奖励:" % level)
		print("  主线: EXP=%d, 银两=%d" % [main_exp, main_silver])
		print("  支线: EXP=%d, 银两=%d" % [side_exp, side_silver])
		print("  悬赏: EXP=%d, 银两=%d" % [bounty_exp, bounty_silver])
	
	print("====================")

func get_target_type_name(target_type):
	"""获取目标类型名称"""
	match target_type:
		TargetType.TALK_TO_NPC:
			return "与NPC对话"
		TargetType.KILL_ENEMY:
			return "击杀敌人"
		TargetType.COLLECT_ITEM:
			return "收集物品"
		TargetType.GO_TO_LOCATION:
			return "到达地点"
		TargetType.USE_ITEM:
			return "使用物品"
		_:
			return "未知"