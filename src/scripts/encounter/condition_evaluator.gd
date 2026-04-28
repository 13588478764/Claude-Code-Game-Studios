extends Node

# 条件评估器
# 实现四大类条件类型（时空环境、角色状态、进度历史、随机概率）的评估逻辑

# 条件类型枚举
enum ConditionType {
	TEMPORAL_ENVIRONMENT,  # 时空环境条件
	CHARACTER_STATE,       # 角色状态条件
	PROGRESS_HISTORY,      # 进度历史条件
	RANDOM_PROBABILITY     # 随机概率条件
}

# 逻辑操作枚举
enum LogicOp {
	AND,  # 与操作
	OR,   # 或操作
	XOR   # 异或操作
}

# 条件结构
class Condition:
	var type: ConditionType
	var parameters: Dictionary
	var is_negated: bool = false  # 是否取反

# 条件组合结构
class ConditionGroup:
	var logic_op: LogicOp
	var conditions: Array[Condition]
	var sub_groups: Array

# 评估结果结构
class EvaluationResult:
	var is_met: bool
	var details: Dictionary

# 评估玩家数据结构
class PlayerData:
	var position: Vector2
	var time: float
	var weather: String
	var luck: float
	var wisdom: float
	var health: float
	var qi: float
	var attributes: Dictionary
	var inventory: Array
	var skills: Array
	var realm: String

# 评估进度数据结构
class ProgressData:
	var quest_status: Dictionary
	var explored_areas: Array
	var encounter_history: Array
	var behavior_history: Dictionary

# 评估时空环境条件
func evaluate_temporal_environment_conditions(player_data: PlayerData) -> bool:
	# 检查位置条件
	if has_position_condition():
		var pos_result = check_position(player_data.position)
		if not pos_result:
			return false
	
	# 检查时间条件
	if has_time_condition():
		var time_result = check_time(player_data.time)
		if not time_result:
			return false
	
	# 检查天气条件
	if has_weather_condition():
		var weather_result = check_weather(player_data.weather)
		if not weather_result:
			return false
	
	return true

# 评估角色状态条件
func evaluate_character_state_conditions(player_data: PlayerData) -> bool:
	# 检查属性阈值
	if has_attribute_threshold_condition():
		var attr_result = check_attribute_thresholds(player_data.attributes)
		if not attr_result:
			return false
	
	# 检查资源状态
	if has_resource_condition():
		var resource_result = check_resource_status(player_data.health, player_data.qi)
		if not resource_result:
			return false
	
	# 检查武学/境界
	if has_skill_realm_condition():
		var skill_result = check_skills_and_realm(player_data.skills, player_data.realm)
		if not skill_result:
			return false
	
	return true

# 评估进度历史条件
func evaluate_progress_history_conditions(progress_data: ProgressData) -> bool:
	# 检查任务状态
	if has_quest_condition():
		var quest_result = check_quest_status(progress_data.quest_status)
		if not quest_result:
			return false
	
	# 检查探索记录
	if has_exploration_condition():
		var explore_result = check_exploration(progress_data.explored_areas)
		if not explore_result:
			return false
	
	# 检查行为历史
	if has_behavior_condition():
		var behavior_result = check_behavior_history(progress_data.behavior_history)
		if not behavior_result:
			return false
	
	return true

# 评估随机概率条件
func evaluate_random_probability_conditions(luck_value: float, base_probability: float = 0.05) -> bool:
	# 计算最终触发概率
	var final_probability = calculate_trigger_probability(base_probability, luck_value)
	
	# 生成随机数并比较
	var random_value = randf()
	return random_value <= final_probability

# 计算触发概率（考虑福缘修正）
func calculate_trigger_probability(base_probability: float, luck_value: float) -> float:
	# 福缘修正系数：每10点福缘+10%概率
	var luck_bonus = luck_value / 100.0  # 每10点福缘提供0.1倍修正
	
	# 计算最终概率
	var final_probability = base_probability * (1.0 + luck_bonus)
	
	# 限制概率上限为20%
	return min(final_probability, 0.20)

# 检查位置
func check_position(position: Vector2) -> bool:
	# 这里会根据具体奇遇的触发区域进行检查
	# 例如：检查玩家是否在破庙区域
	return true  # 简化实现

# 检查时间
func check_time(time: float) -> bool:
	# 这里会检查游戏内时间是否符合要求
	# 例如：检查是否为子时（23:00-1:00）
	return true  # 简化实现

# 检查天气
func check_weather(weather: String) -> bool:
	# 这里会检查当前天气是否符合要求
	# 例如：检查是否为雨天
	return true  # 简化实现

# 检查属性阈值
func check_attribute_thresholds(attributes: Dictionary) -> bool:
	# 检查各种属性是否满足阈值
	# 例如：福缘 > 80, 悟性 > 50
	return true  # 简化实现

# 检查资源状态
func check_resource_status(health: float, qi: float) -> bool:
	# 检查生命值、内力等资源状态
	# 例如：生命值 < 20%, 内力 < 10%
	return true  # 简化实现

# 检查技能和境界
func check_skills_and_realm(skills: Array, realm: String) -> bool:
	# 检查是否已学会特定武学或达到特定境界
	# 例如：已学会《太极拳》、处于筑基期
	return true  # 简化实现

# 检查任务状态
func check_quest_status(quest_status: Dictionary) -> bool:
	# 检查任务完成状态
	# 例如：主线任务完成至第3章
	return true  # 简化实现

# 检查探索记录
func check_exploration(explored_areas: Array) -> bool:
	# 检查已探索区域
	# 例如：已解锁"青云山"地图
	return true  # 简化实现

# 检查行为历史
func check_behavior_history(behavior_history: Dictionary) -> bool:
	# 检查行为历史
	# 例如：累计击杀强盗超过50人
	return true  # 简化实现

# 检查是否有位置条件
func has_position_condition() -> bool:
	return true  # 简化实现

# 检查是否有时间条件
func has_time_condition() -> bool:
	return true  # 简化实现

# 检查是否有天气条件
func has_weather_condition() -> bool:
	return true  # 简化实现

# 检查是否有属性阈值条件
func has_attribute_threshold_condition() -> bool:
	return true  # 简化实现

# 检查是否有资源条件
func has_resource_condition() -> bool:
	return true  # 简化实现

# 检查是否有技能境界条件
func has_skill_realm_condition() -> bool:
	return true  # 简化实现

# 检查是否有任务条件
func has_quest_condition() -> bool:
	return true  # 简化实现

# 检查是否有探索条件
func has_exploration_condition() -> bool:
	return true  # 简化实现

# 检查是否有行为条件
func has_behavior_condition() -> bool:
	return true  # 简化实现

# 评估复合条件组
func evaluate_condition_group(group: ConditionGroup, player_data: PlayerData, progress_data: ProgressData) -> bool:
	var results: Array[bool] = []
	
	# 评估单个条件
	for condition in group.conditions:
		var result = evaluate_single_condition(condition, player_data, progress_data)
		if condition.is_negated:
			result = not result
		results.append(result)
	
	# 评估子组
	for sub_group in group.sub_groups:
		var sub_result = evaluate_condition_group(sub_group, player_data, progress_data)
		results.append(sub_result)
	
	# 根据逻辑操作符组合结果
	match group.logic_op:
		LogicOp.AND:
			for result in results:
				if not result:
					return false
			return true
		LogicOp.OR:
			for result in results:
				if result:
					return true
			return false
		LogicOp.XOR:
			var true_count = 0
			for result in results:
				if result:
					true_count += 1
			return true_count % 2 == 1
		_:
			return false

# 评估单个条件
func evaluate_single_condition(condition: Condition, player_data: PlayerData, progress_data: ProgressData) -> bool:
	match condition.type:
		ConditionType.TEMPORAL_ENVIRONMENT:
			return evaluate_temporal_environment_conditions(player_data)
		ConditionType.CHARACTER_STATE:
			return evaluate_character_state_conditions(player_data)
		ConditionType.PROGRESS_HISTORY:
			return evaluate_progress_history_conditions(progress_data)
		ConditionType.RANDOM_PROBABILITY:
			return evaluate_random_probability_conditions(player_data.luck)
		_:
			return false

# 测试函数
func test_condition_evaluation():
	print("开始测试条件评估...")
	
	# 创建测试数据
	var test_player_data = PlayerData.new()
	test_player_data.luck = 50.0
	test_player_data.position = Vector2(100, 200)
	test_player_data.time = 22.5  # 晚上10:30
	test_player_data.weather = "rain"
	test_player_data.health = 0.15  # 15%
	test_player_data.qi = 0.05    # 5%
	test_player_data.attributes = {"luck": 50, "wisdom": 60}
	test_player_data.inventory = ["mysterious_jade"]
	test_player_data.skills = ["taijiquan"]
	test_player_data.realm = "ZhuJi"  # 筑基期
	
	var test_progress_data = ProgressData.new()
	test_progress_data.quest_status = {"main_chapter": 3}
	test_progress_data.explored_areas = ["Qingyun_Mountain", "Black_Wind_Fortress"]
	test_progress_data.encounter_history = ["encounter_001", "encounter_002"]
	test_progress_data.behavior_history = {"bandits_killed": 55, "npc_helped": 12}
	
	# 测试各类条件
	var temporal_result = evaluate_temporal_environment_conditions(test_player_data)
	print("时空环境条件评估结果: ", temporal_result)
	
	var character_result = evaluate_character_state_conditions(test_player_data)
	print("角色状态条件评估结果: ", character_result)
	
	var progress_result = evaluate_progress_history_conditions(test_progress_data)
	print("进度历史条件评估结果: ", progress_result)
	
	var random_result = evaluate_random_probability_conditions(test_player_data.luck)
	print("随机概率条件评估结果: ", random_result)
	
	# 计算最终触发概率
	var trigger_prob = calculate_trigger_probability(0.05, test_player_data.luck)
	print("福缘50时的触发概率: ", trigger_prob)
	
	print("条件评估测试完成")