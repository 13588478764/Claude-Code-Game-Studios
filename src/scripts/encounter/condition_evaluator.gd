# ConditionEvaluator - 奇遇条件检查系统
#
# 负责评估所有奇遇触发条件，包括时空环境、角色状态、进度历史和随机概率
# 遵循 GDD 中定义的四种条件类型
#
# 信号:
#   - condition_evaluated(condition_type, result)

extends Node

class_name ConditionEvaluator

# 条件类型枚举
enum ConditionType {
	TEMPORAL_ENVIRONMENT,    # 时空环境条件
	CHARACTER_STATE,         # 角色状态条件
	PROGRESS_HISTORY,        # 进度历史条件
	RANDOM_PROBABILITY       # 随机概率条件
}

# 逻辑操作符枚举
enum LogicOperator {
	AND,                     # 逻辑与
	OR                       # 逻辑或
}

# 兼容性别名
enum LogicOp {
	AND,                     # 逻辑与
	OR                       # 逻辑或
}

# 信号定义
signal condition_evaluated(condition_type: int, result: bool)

# ============================================================================
# 内部类定义
# ============================================================================

## 玩家数据类
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
	
	func _init():
		position = Vector2.ZERO
		time = 0.0
		weather = ""
		luck = 0.0
		wisdom = 0.0
		health = 1.0
		qi = 1.0
		attributes = {}
		inventory = []
		skills = []
		realm = ""

## 进度数据类
class ProgressData:
	var quest_status: Dictionary
	var explored_areas: Array
	var encounter_history: Array
	var behavior_history: Dictionary
	
	func _init():
		quest_status = {}
		explored_areas = []
		encounter_history = []
		behavior_history = {}

## 条件类
class Condition:
	var type: int
	var parameters: Dictionary
	
	func _init():
		type = 0
		parameters = {}

## 条件组类
class ConditionGroup:
	var logic_op: int
	var conditions: Array
	
	func _init():
		logic_op = 0
		conditions = []

# ============================================================================
# 公共方法
# ============================================================================

## 评估时空环境条件
## 参数:
##   - player_data: 玩家数据字典
##     - location: 当前位置
##     - time_of_day: 时间 (morning/afternoon/evening/night)
##     - weather: 天气 (sunny/rainy/snowy/stormy)
## 返回: 条件是否满足
func evaluate_temporal_environment_conditions(player_data: Dictionary) -> bool:
	# 验证必需字段
	if not player_data.has("location") or not player_data.has("time_of_day") or not player_data.has("weather"):
		return false
	
	var location: String = player_data["location"]
	var time_of_day: String = player_data["time_of_day"]
	var weather: String = player_data["weather"]
	
	# 这里可以添加具体的时空环境条件评估逻辑
	# 例如: 特定位置 + 特定时间 + 特定天气
	
	# 示例: 破庙 + 深夜 + 雨天
	var is_temple: bool = location == "破庙"
	var is_night: bool = time_of_day == "night"
	var is_rainy: bool = weather == "rainy" or weather == "stormy"
	
	var result: bool = is_temple and is_night and is_rainy
	condition_evaluated.emit(ConditionType.TEMPORAL_ENVIRONMENT, result)
	
	return result


## 评估角色状态条件
## 参数:
##   - player_data: 玩家数据字典
##     - health: 当前生命值
##     - max_health: 最大生命值
##     - status_effects: 状态效果数组
## 返回: 条件是否满足
func evaluate_character_state_conditions(player_data: Dictionary) -> bool:
	# 验证必需字段
	if not player_data.has("health") or not player_data.has("max_health"):
		return false
	
	var health: int = player_data["health"]
	var max_health: int = player_data["max_health"]
	var status_effects: Array = player_data.get("status_effects", [])
	
	# 计算生命值百分比
	var health_percentage: float = float(health) / float(max_health)
	
	# 示例: 生命值低于 20%
	var is_low_health: bool = health_percentage < 0.2
	
	# 示例: 没有特定的负面状态
	var has_negative_status: bool = false
	for effect in status_effects:
		if effect in ["中毒", "燃烧", "冻结"]:
			has_negative_status = true
			break
	
	var result: bool = is_low_health and not has_negative_status
	condition_evaluated.emit(ConditionType.CHARACTER_STATE, result)
	
	return result


## 评估进度历史条件
## 参数:
##   - progress_data: 进度数据字典
##     - encounters_completed: 完成的奇遇数组
##     - quests_completed: 完成的任务数组
##     - level: 当前等级
## 返回: 条件是否满足
func evaluate_progress_history_conditions(progress_data: Dictionary) -> bool:
	# 验证必需字段
	if not progress_data.has("encounters_completed") or not progress_data.has("level"):
		return false
	
	var encounters_completed: Array = progress_data["encounters_completed"]
	var level: int = progress_data["level"]
	
	# 示例: 已完成特定奇遇且等级达到要求
	var has_prerequisite_encounter: bool = "避雨遇高僧" in encounters_completed
	var level_requirement_met: bool = level >= 10
	
	var result: bool = has_prerequisite_encounter and level_requirement_met
	condition_evaluated.emit(ConditionType.PROGRESS_HISTORY, result)
	
	return result


## 评估随机概率条件
## 参数:
##   - luck_value: 福缘值 (0-100)
##   - base_probability: 基础概率 (0.0-1.0)
## 返回: 条件是否满足
func evaluate_random_probability_conditions(luck_value: float, base_probability: float = 0.05) -> bool:
	# 验证参数范围
	luck_value = clamp(luck_value, 0.0, 100.0)
	base_probability = clamp(base_probability, 0.0, 1.0)
	
	# 计算福缘修正系数
	# 福缘值 50 时修正系数为 1.0（无修正）
	# 福缘值 100 时修正系数为 1.5（增加 50%）
	# 福缘值 0 时修正系数为 0.5（减少 50%）
	var luck_modifier: float = 0.5 + (luck_value / 100.0)
	
	# 计算最终概率
	var final_probability: float = base_probability * luck_modifier
	
	# 限制最终概率在 0.0-1.0 之间
	final_probability = clamp(final_probability, 0.0, 1.0)
	
	# 生成随机数进行判断
	var random_value: float = randf()
	var result: bool = random_value < final_probability
	
	condition_evaluated.emit(ConditionType.RANDOM_PROBABILITY, result)
	
	return result


## 评估复合条件（使用逻辑操作符组合多个条件）
## 参数:
##   - conditions: 条件结果数组 (布尔值)
##   - operator: 逻辑操作符 (AND 或 OR)
## 返回: 复合条件结果
func evaluate_composite_conditions(conditions: Array, operator: int = LogicOperator.AND) -> bool:
	if conditions.is_empty():
		return false
	
	match operator:
		LogicOperator.AND:
			# AND 逻辑: 所有条件都为 true 才返回 true
			for condition in conditions:
				if not condition:
					return false
			return true
		
		LogicOperator.OR:
			# OR 逻辑: 至少一个条件为 true 就返回 true
			for condition in conditions:
				if condition:
					return true
			return false
	
	return false


## 评估条件组
## 参数:
##   - condition_group: 条件组对象
##   - player_data: 玩家数据对象
##   - progress_data: 进度数据对象
## 返回: 条件组评估结果
func evaluate_condition_group(condition_group: ConditionGroup, player_data: Object, progress_data: Object) -> bool:
	if condition_group.conditions.is_empty():
		return false
	
	var results: Array = []
	
	# 评估每个条件
	for condition in condition_group.conditions:
		var result: bool = false
		
		# 如果条件有 is_met 参数，直接使用它
		if condition.parameters.has("is_met"):
			result = condition.parameters["is_met"]
		else:
			# 否则根据条件类型进行评估
			match condition.type:
				ConditionType.TEMPORAL_ENVIRONMENT:
					# 将 PlayerData 对象转换为字典
					var player_dict = _player_data_to_dict(player_data)
					result = evaluate_temporal_environment_conditions(player_dict)
				
				ConditionType.CHARACTER_STATE:
					# 将 PlayerData 对象转换为字典
					var player_dict = _player_data_to_dict(player_data)
					result = evaluate_character_state_conditions(player_dict)
				
				ConditionType.PROGRESS_HISTORY:
					# 将 ProgressData 对象转换为字典
					var progress_dict = _progress_data_to_dict(progress_data)
					result = evaluate_progress_history_conditions(progress_dict)
				
				ConditionType.RANDOM_PROBABILITY:
					var luck = player_data.luck if player_data.has_method("get") or player_data is Object else 50.0
					result = evaluate_random_probability_conditions(luck)
		
		results.append(result)
	
	# 根据逻辑操作符组合结果
	return evaluate_composite_conditions(results, condition_group.logic_op)


## 计算触发概率
## 参数:
##   - base_probability: 基础概率 (0.0-1.0)
##   - luck_value: 福缘值 (0-150+，支持超过100的福缘值)
## 返回: 修正后的触发概率
func calculate_trigger_probability(base_probability: float, luck_value: float) -> float:
	# 验证参数范围
	base_probability = clamp(base_probability, 0.0, 1.0)
	luck_value = max(luck_value, 0.0)  # 只限制下限，不限制上限
	
	# 计算福缘修正系数（分段计算）
	# 福缘值 0 时修正系数为 0.0（无修正）
	# 福缘值 50 时修正系数为 0.5（增加 50%）
	# 福缘值 100 时修正系数为 1.0（增加 100%）
	# 福缘值 150 时修正系数为 3.0（增加 300%）
	var luck_modifier: float
	if luck_value <= 100.0:
		luck_modifier = luck_value / 100.0
	else:
		# 当福缘值超过 100 时，修正系数增长加快
		luck_modifier = 1.0 + (luck_value - 100.0) / 25.0
	
	# 计算最终概率
	var final_probability: float = base_probability * (1.0 + luck_modifier)
	
	# 限制最终概率在 0.0-0.2 之间（上限20%）
	final_probability = clamp(final_probability, 0.0, 0.2)
	
	return final_probability


# ============================================================================
# 私有方法
# ============================================================================

## 验证玩家数据完整性
## 参数:
##   - player_data: 玩家数据字典
##   - required_fields: 必需字段数组
## 返回: 数据是否完整
func _validate_player_data(player_data: Dictionary, required_fields: Array) -> bool:
	for field in required_fields:
		if not player_data.has(field):
			return false
	return true


## 将 PlayerData 对象转换为字典
## 参数:
##   - player_data: PlayerData 对象
## 返回: 转换后的字典
func _player_data_to_dict(player_data: Object) -> Dictionary:
	var result = {}
	
	if player_data is PlayerData:
		result["position"] = player_data.position
		result["time"] = player_data.time
		result["weather"] = player_data.weather
		result["luck"] = player_data.luck
		result["wisdom"] = player_data.wisdom
		result["health"] = player_data.health
		result["max_health"] = 1.0
		result["qi"] = player_data.qi
		result["attributes"] = player_data.attributes
		result["inventory"] = player_data.inventory
		result["skills"] = player_data.skills
		result["realm"] = player_data.realm
	
	return result


## 将 ProgressData 对象转换为字典
## 参数:
##   - progress_data: ProgressData 对象
## 返回: 转换后的字典
func _progress_data_to_dict(progress_data: Object) -> Dictionary:
	var result = {}
	
	if progress_data is ProgressData:
		result["quest_status"] = progress_data.quest_status
		result["explored_areas"] = progress_data.explored_areas
		result["encounter_history"] = progress_data.encounter_history
		result["behavior_history"] = progress_data.behavior_history
		result["encounters_completed"] = progress_data.encounter_history
		result["level"] = 1
	
	return result