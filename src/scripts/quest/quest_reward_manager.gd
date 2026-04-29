# 任务奖励管理器
# 负责处理和分发任务奖励

extends Node

class_name QuestRewardManager

# 信号定义
signal reward_given(quest_id: String, reward_type: String, amount: int)
signal inventory_full_handling(inventory_full: bool, quest_id: String, rewards: Dictionary)

# 引用任务管理器
var quest_manager: Node = null

# 临时储物箱（当背包满了的时候）
var temporary_storage: Dictionary = {}

# 初始化
func _ready():
	print("Quest Reward Manager initialized")

# 设置任务管理器引用
func set_quest_manager(manager: Node):
	quest_manager = manager

# 分发任务奖励
func distribute_rewards(quest_id: String) -> bool:
	if not quest_manager:
		print("No quest manager assigned to reward manager")
		return false
	
	var quest_info = quest_manager.get_quest_info(quest_id)
	if quest_info.empty():
		print("Quest not found: ", quest_id)
		return false
	
	var rewards = quest_info.rewards
	if rewards.empty():
		print("No rewards defined for quest: ", quest_id)
		# 即使没有奖励，也算作成功完成任务
		return true
	
	# 计算基于玩家等级和任务类型的奖励
	var calculated_rewards = _calculate_rewards(quest_info)
	
	# 分发各种奖励
	var success = true
	
	# 经验值奖励
	if calculated_rewards.has("exp"):
		_give_exp_reward(calculated_rewards.exp)
		emit_signal("reward_given", quest_id, "exp", calculated_rewards.exp)
	
	# 银两奖励
	if calculated_rewards.has("silver"):
		_give_silver_reward(calculated_rewards.silver)
		emit_signal("reward_given", quest_id, "silver", calculated_rewards.silver)
	
	# 物品奖励
	if calculated_rewards.has("items"):
		var items_success = _give_item_rewards(calculated_rewards.items, quest_id)
		if not items_success:
			success = false
	
	# 特殊道具奖励（如突破丹、天赋点等）
	if calculated_rewards.has("special_items"):
		var special_success = _give_special_item_rewards(calculated_rewards.special_items, quest_id)
		if not special_success:
			success = false
	
	if success:
		print("Successfully distributed rewards for quest: ", quest_id)
	else:
		print("Some rewards could not be distributed for quest: ", quest_id)
	
	return success

# 计算奖励（根据任务类型和玩家等级）
func _calculate_rewards(quest_info: Dictionary) -> Dictionary:
	var calculated = {}
	var player_level = 1
	if quest_manager:
		player_level = quest_manager.player_level
	
	# 如果任务中有明确的奖励设定，优先使用
	if quest_info.rewards.has("exp"):
		calculated.exp = quest_info.rewards.exp
	else:
		# 根据任务类型和玩家等级计算经验值
		var coeff = quest_manager.get_reward_coefficient(quest_info.type)
		calculated.exp = player_level * coeff.exp_factor
	
	if quest_info.rewards.has("silver"):
		calculated.silver = quest_info.rewards.silver
	else:
		# 根据任务类型和玩家等级计算银两
		var coeff = quest_manager.get_reward_coefficient(quest_info.type)
		calculated.silver = player_level * coeff.silver_factor
	
	# 物品奖励
	if quest_info.rewards.has("items"):
		calculated.items = quest_info.rewards.items
	else:
		calculated.items = []
	
	# 特殊物品奖励
	if quest_info.rewards.has("special_items"):
		calculated.special_items = quest_info.rewards.special_items
	else:
		calculated.special_items = []
	
	return calculated

# 给予经验值奖励
func _give_exp_reward(exp_amount: int):
	if quest_manager:
		# 这里应该调用角色成长系统的函数
		# 例如: character_growth_system.add_experience(exp_amount)
		print("Granted ", exp_amount, " EXP to player")
		# 模拟调用角色成长系统
		if "add_experience" in quest_manager:
			quest_manager.add_experience(exp_amount)

# 给予银两奖励
func _give_silver_reward(silver_amount: int):
	if quest_manager:
		# 这里应该调用经济系统的函数
		# 例如: economy_system.add_silver(silver_amount)
		print("Granted ", silver_amount, " silver to player")
		# 模拟调用经济系统
		if "add_silver" in quest_manager:
			quest_manager.add_silver(silver_amount)

# 给予物品奖励
func _give_item_rewards(items_list: Array, quest_id: String) -> bool:
	if not quest_manager:
		return false
	
	var success = true
	
	for item_id in items_list:
		# 检查背包是否已满（模拟检查）
		var inventory_full = _is_inventory_full()
		
		if inventory_full:
			# 如果背包满了，将物品放入临时储物箱
			if not temporary_storage.has(quest_id):
				temporary_storage[quest_id] = {"items": [], "silver": 0, "exp": 0}
			temporary_storage[quest_id].items.append(item_id)
			
			emit_signal("inventory_full_handling", true, quest_id, {"items": [item_id]})
			print("Inventory full, storing item in temporary storage: ", item_id)
		else:
			# 添加物品到背包
			quest_manager.add_item_to_inventory(item_id)
			emit_signal("reward_given", quest_id, "item", item_id)
			print("Granted item to player: ", item_id)
	
	return success

# 给予特殊物品奖励
func _give_special_item_rewards(special_items_list: Array, quest_id: String) -> bool:
	if not quest_manager:
		return false
	
	var success = true
	
	for special_item in special_items_list:
		# 特殊物品可能包括突破丹、天赋点等
		if special_item == "talent_point":
			# 增加天赋点
			# 这里应该调用角色成长系统的函数
			print("Granted talent point to player")
		elif special_item == "breakthrough_pill":
			# 增加突破丹
			print("Granted breakthrough pill to player")
		elif special_item == "attribute_point":
			# 增加属性点
			print("Granted attribute point to player")
		else:
			# 其他特殊物品
			print("Granted special item to player: ", special_item)
	
	return success

# 检查背包是否已满（模拟实现）
func _is_inventory_full() -> bool:
	# 在实际实现中，这里会检查玩家背包的实际容量
	# 模拟：随机返回false，表示背包未满
	return false

# 从临时储物箱获取物品
func retrieve_from_temporary_storage(quest_id: String = "") -> Dictionary:
	if quest_id != "":
		# 获取特定任务的储物箱内容
		if temporary_storage.has(quest_id):
			var content = temporary_storage[quest_id]
			temporary_storage.erase(quest_id)
			return content
		else:
			return {}
	else:
		# 获取所有储物箱内容
		var all_content = temporary_storage.duplicate()
		temporary_storage.clear()
		return all_content

# 获取临时储物箱状态
func get_temporary_storage_status() -> Dictionary:
	var status = {
		"is_empty": temporary_storage.is_empty(),
		"quests_stored": temporary_storage.keys(),
		"total_items": 0
	}
	
	for quest_id in temporary_storage:
		status.total_items += temporary_storage[quest_id].items.size()
	
	return status

# 保存奖励数据
func save_reward_data() -> Dictionary:
	var save_data = {
		"temporary_storage": temporary_storage
	}
	
	return save_data

# 加载奖励数据
func load_reward_data(data: Dictionary):
	if data.has("temporary_storage"):
		temporary_storage = data.temporary_storage

# 获取奖励公式参数
func get_reward_parameters(quest_type: int, player_level: int) -> Dictionary:
	var params = {}
	
	match quest_type:
		0:  # MAIN
			params.exp = player_level * 100
			params.silver = player_level * 50
		1:  # SIDE
			params.exp = player_level * 50
			params.silver = player_level * 20
		2:  # BOUNTY
			params.exp = player_level * 10
			params.silver = player_level * 5
		_:  # ENCOUNTER and default
			params.exp = player_level * 20
			params.silver = int(randf() * 500)  # 随机银两(0-500)
	
	return params