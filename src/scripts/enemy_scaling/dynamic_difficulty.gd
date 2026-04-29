## DynamicDifficulty
## dynamic_difficulty.gd
动态难度调整系统
实现基于玩家表现的动态难度调整
TR-enemy-scaling-005
##
## 主要功能：
## - 待补充

extends Node

class_name DynamicDifficulty

# 动态难度系数的范围
const MIN_COEFFICIENT = 0.7
const MAX_COEFFICIENT = 1.15

## 计算失败惩罚系数
##
## 根据连续失败次数计算难度降低系数
## 失败惩罚: dynamic_coefficient = 1.0 - (min(failure_count, 3) × 0.1)
##
## @param failure_count: 连续失败次数
## @return: 失败惩罚系数 (0.7-1.0)
static func calculate_failure_penalty(failure_count: int) -> float:
	if failure_count < 0:
		push_warning("Invalid failure count: %d. Using 0." % failure_count)
		failure_count = 0
	
	# 最多降低30% (3次失败)
	var clamped_failures = min(failure_count, 3)
	var coefficient = 1.0 - (clamped_failures * 0.1)
	
	# 确保不低于最小值
	coefficient = max(coefficient, MIN_COEFFICIENT)
	
	return coefficient


## 计算碾压奖励系数
##
## 根据连续无伤胜利次数计算难度提升系数
## 碾压奖励: dynamic_coefficient = 1.0 + (min(perfect_win_count, 3) × 0.05)
##
## @param perfect_win_count: 连续无伤胜利次数
## @return: 碾压奖励系数 (1.0-1.15)
static func calculate_perfect_win_bonus(perfect_win_count: int) -> float:
	if perfect_win_count < 0:
		push_warning("Invalid perfect win count: %d. Using 0." % perfect_win_count)
		perfect_win_count = 0
	
	# 最多提升15% (3次无伤胜利)
	var clamped_wins = min(perfect_win_count, 3)
	var coefficient = 1.0 + (clamped_wins * 0.05)
	
	# 确保不超过最大值
	coefficient = min(coefficient, MAX_COEFFICIENT)
	
	return coefficient


## 计算综合动态难度系数
##
## 综合考虑失败惩罚和碾压奖励
## 优先级: 失败惩罚 > 碾压奖励 (如果有失败,则不计算奖励)
##
## @param failure_count: 连续失败次数
## @param perfect_win_count: 连续无伤胜利次数
## @return: 综合动态难度系数 (0.7-1.15)
static func calculate_dynamic_coefficient(failure_count: int, perfect_win_count: int) -> float:
	# 如果有失败,优先应用失败惩罚
	if failure_count > 0:
		return calculate_failure_penalty(failure_count)
	
	# 否则应用碾压奖励
	return calculate_perfect_win_bonus(perfect_win_count)


## 应用动态难度系数到敌人属性
##
## @param base_hp: 基础HP
## @param base_attack: 基础攻击力
## @param dynamic_coefficient: 动态难度系数
## @return: 包含 adjusted_hp 和 adjusted_attack 的字典
static func apply_dynamic_difficulty(
	base_hp: float,
	base_attack: float,
	dynamic_coefficient: float
) -> Dictionary:
	# 确保系数在有效范围内
	var clamped_coefficient = clamp(dynamic_coefficient, MIN_COEFFICIENT, MAX_COEFFICIENT)
	
	return {
		"adjusted_hp": base_hp * clamped_coefficient,
		"adjusted_attack": base_attack * clamped_coefficient
	}


## 检查是否应该重置动态难度计数器
##
## 重置条件: 切换区域或升级
##
## @param current_region: 当前区域ID
## @param previous_region: 上一个区域ID
## @param current_level: 当前等级
## @param previous_level: 上一个等级
## @return: 是否应该重置
static func should_reset_counters(
	current_region: int,
	previous_region: int,
	current_level: int,
	previous_level: int
) -> bool:
	# 切换区域或升级时重置
	return current_region != previous_region or current_level != previous_level


## 获取动态难度描述
##
## @param failure_count: 连续失败次数
## @param perfect_win_count: 连续无伤胜利次数
## @return: 动态难度描述字符串
static func get_difficulty_description(failure_count: int, perfect_win_count: int) -> String:
	if failure_count > 0:
		var penalty = calculate_failure_penalty(failure_count)
		return "难度降低 (失败%d次, 系数%.2f)" % [failure_count, penalty]
	elif perfect_win_count > 0:
		var bonus = calculate_perfect_win_bonus(perfect_win_count)
		return "难度提升 (无伤%d场, 系数%.2f)" % [perfect_win_count, bonus]
	else:
		return "正常难度 (系数1.00)"