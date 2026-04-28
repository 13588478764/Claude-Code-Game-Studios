# 经验值获取管理器
# 实现EXP获取机制，包括战斗收益、探索与奇遇收益、任务进度收益

extends Node

# 信号定义
signal exp_granted(exp_amount: int, source_type: String, source_details: Dictionary)

# 常量定义
const EXP_SOURCE_COMBAT = "combat"
const EXP_SOURCE_EXPLORATION = "exploration"
const EXP_SOURCE_ENCOUNTER = "encounter"
const EXP_SOURCE_QUEST = "quest"

# 战斗EXP奖励基数
var combat_exp_base_values = {
	"weak_enemy": 10,
	"normal_enemy": 50,
	"strong_enemy": 100,
	"boss": 500
}

# 探索EXP奖励基数
var exploration_exp_base_values = {
	"first_exploration": 25,
	"discovery_point": 15,
	"treasure": 30
}

# 奇遇EXP奖励基数
var encounter_exp_base_values = {
	"story_encounter": 40,
	"puzzle_encounter": 50,
	"combat_encounter": 60,
	"collection_encounter": 35
}

# 任务EXP奖励基数
var quest_exp_base_values = {
	"main_quest": 100,
	"side_quest": 50,
	"daily_quest": 20
}

# 获取战斗EXP
func grant_combat_exp(enemy_data: Dictionary, battle_result: Dictionary) -> int:
	var base_exp = 0
	
	# 根据敌人类型获取基础EXP
	if enemy_data.has("type") and combat_exp_base_values.has(enemy_data.type):
		base_exp = combat_exp_base_values[enemy_data.type]
	elif enemy_data.has("name"):
		# 默认为普通敌人
		base_exp = combat_exp_base_values["normal_enemy"]
	
	# 根据战斗结果调整EXP
	var exp_multiplier = 1.0
	
	# 完美胜利奖励
	if battle_result.get("perfect_victory", false):
		exp_multiplier += 0.1  # 10%额外奖励
	
	# 无伤奖励
	if battle_result.get("no_damage_taken", false):
		exp_multiplier += 0.1  # 10%额外奖励
	
	# 连携/连招奖励
	if battle_result.get("combo_performed", false):
		exp_multiplier += 0.05  # 5%额外奖励
	
	# 计算最终EXP
	var final_exp = int(base_exp * exp_multiplier)
	
	# 发送信号通知其他系统
	var source_details = {
		"enemy_data": enemy_data,
		"battle_result": battle_result,
		"base_exp": base_exp,
		"multiplier": exp_multiplier
	}
	
	exp_granted.emit(final_exp, EXP_SOURCE_COMBAT, source_details)
	
	return final_exp

# 获取探索EXP
func grant_exploration_exp(region_data: Dictionary, discovery_type: String) -> int:
	var base_exp = 0
	
	# 根据探索类型获取基础EXP
	if exploration_exp_base_values.has(discovery_type):
		base_exp = exploration_exp_base_values[discovery_type]
	else:
		# 默认为首次探索
		base_exp = exploration_exp_base_values["first_exploration"]
	
	# 发送信号通知其他系统
	var source_details = {
		"region_data": region_data,
		"discovery_type": discovery_type,
		"base_exp": base_exp
	}
	
	exp_granted.emit(base_exp, EXP_SOURCE_EXPLORATION, source_details)
	
	return base_exp

# 获取奇遇EXP
func grant_encounter_exp(encounter_data: Dictionary, completion_result: Dictionary) -> int:
	var base_exp = 0
	
	# 根据奇遇类型获取基础EXP
	if encounter_data.has("type") and encounter_exp_base_values.has(encounter_data.type):
		base_exp = encounter_exp_base_values[encounter_data.type]
	else:
		# 默认为故事类奇遇
		base_exp = encounter_exp_base_values["story_encounter"]
	
	# 发送信号通知其他系统
	var source_details = {
		"encounter_data": encounter_data,
		"completion_result": completion_result,
		"base_exp": base_exp
	}
	
	exp_granted.emit(base_exp, EXP_SOURCE_ENCOUNTER, source_details)
	
	return base_exp

# 获取任务EXP
func grant_quest_exp(quest_data: Dictionary, completion_type: String) -> int:
	var base_exp = 0
	
	# 根据任务类型获取基础EXP
	if quest_data.has("type") and quest_exp_base_values.has(quest_data.type):
		base_exp = quest_exp_base_values[quest_data.type]
	else:
		# 默认为日常任务
		base_exp = quest_exp_base_values["daily_quest"]
	
	# 根据完成类型调整EXP（例如完美完成、快速完成等）
	var exp_multiplier = 1.0
	if completion_type == "perfect":
		exp_multiplier = 1.2
	elif completion_type == "quick":
		exp_multiplier = 1.1
	
	# 计算最终EXP
	var final_exp = int(base_exp * exp_multiplier)
	
	# 发送信号通知其他系统
	var source_details = {
		"quest_data": quest_data,
		"completion_type": completion_type,
		"base_exp": base_exp,
		"multiplier": exp_multiplier
	}
	
	exp_granted.emit(final_exp, EXP_SOURCE_QUEST, source_details)
	
	return final_exp

# 批量处理EXP获取
func grant_multiple_exp(exp_sources: Array) -> Dictionary:
	var total_exp = 0
	var source_breakdown = {}
	
	for source in exp_sources:
		var source_type = source.get("type", "")
		var source_data = source.get("data", {})
		var result_data = source.get("result", {})
		
		var exp_amount = 0
		match source_type:
			EXP_SOURCE_COMBAT:
				exp_amount = grant_combat_exp(source_data, result_data)
			EXP_SOURCE_EXPLORATION:
				exp_amount = grant_exploration_exp(source_data, result_data)
			EXP_SOURCE_ENCOUNTER:
				exp_amount = grant_encounter_exp(source_data, result_data)
			EXP_SOURCE_QUEST:
				exp_amount = grant_quest_exp(source_data, result_data)
		
		total_exp += exp_amount
		
		# 记录来源统计
		if not source_breakdown.has(source_type):
			source_breakdown[source_type] = 0
		source_breakdown[source_type] += exp_amount
	
	return {
		"total_exp": total_exp,
		"breakdown": source_breakdown
	}

# 获取EXP来源名称
func get_exp_source_name(source_type: String) -> String:
	match source_type:
		EXP_SOURCE_COMBAT: return "战斗"
		EXP_SOURCE_EXPLORATION: return "探索"
		EXP_SOURCE_ENCOUNTER: return "奇遇"
		EXP_SOURCE_QUEST: return "任务"
		_: return "未知"