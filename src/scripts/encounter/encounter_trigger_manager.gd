## EncounterTriggerManager
## 奇遇触发管理器
##
## 负责处理奇遇触发时机、概率计算和保底机制。
## 主要功能：
## - 计算奇遇触发概率
## - 根据福缘值调整权重
## - 选择奇遇类型
## - 管理保底机制
## - 记录奇遇历史

extends Node

class_name EncounterTriggerManager

# ============================================================================
# 信号定义
# ============================================================================

signal encounter_triggered(encounter_type: String, encounter_id: String)

# ============================================================================
# 常量定义
# ============================================================================

const ENCOUNTER_TYPES = {
	"JiangHuRumor": { "weight": 40, "name": "江湖传闻" },
	"TianCaiDiBao": { "weight": 30, "name": "天材地宝" },
	"GaoRenZhiDian": { "weight": 15, "name": "高人指点" },
	"ShiChuanMiJi": { "weight": 10, "name": "失传秘籍" },
	"MiJingChallenge": { "weight": 5, "name": "秘境挑战" }
}

const TRIGGER_BASE_CHANCES = {
	"MAP_MOVE": 0.05,      # 大地图移动：5%
	"BATTLE_WIN": 0.02,    # 战斗胜利后：2%
	"REST_SAVE": 0.03,      # 休息/存档：3%
	"SPECIAL_LOCATION": 0.15 # 特定地点：15%
}

# 变量定义
var consecutive_failures: int = 0
var max_consecutive_failures: int = 20
var encounter_history: Array[String] = []
var encounter_weights: Dictionary = {}

# 初始化
func _ready():
	print("奇遇触发管理器已初始化")
	initialize_weights()
	
	# 连接相关信号（如果需要的话）
	# 例如：连接地图移动、战斗胜利等事件

# 初始化权重
func initialize_weights():
	for type_id in ENCOUNTER_TYPES:
		encounter_weights[type_id] = ENCOUNTER_TYPES[type_id]["weight"]

# 触发奇遇检查
func trigger_encounter_check(trigger_type: String, luck_stat: float = 0.0) -> bool:
	# 检查是否达到保底条件
	if consecutive_failures >= max_consecutive_failures - 1:
		# 保底触发
		force_trigger_encounter(trigger_type, luck_stat)
		consecutive_failures = 0
		return true
	
	# 计算触发概率
	var base_chance = TRIGGER_BASE_CHANCES.get(trigger_type, 0.05)
	var final_chance = calculate_trigger_probability(base_chance, luck_stat)
	
	# 进行概率判定
	var roll = randf()
	if roll <= final_chance:
		# 触发奇遇
		var encounter_type = select_encounter_type(luck_stat)
		var encounter_id = generate_encounter_id(encounter_type)
		
		# 检查是否已经完成过此奇遇
		if not has_completed_encounter(encounter_id):
			emit_signal("encounter_triggered", encounter_type, encounter_id)
			mark_encounter_completed(encounter_id)
			consecutive_failures = 0
			return true
		else:
			# 如果已触发过，增加失败计数
			consecutive_failures += 1
			return false
	else:
		# 未触发，增加失败计数
		consecutive_failures += 1
		return false

# 计算触发概率
func calculate_trigger_probability(base_chance: float, luck_stat: float) -> float:
	# 公式: 最终触发概率 = 基础概率 × (1 + 福缘加成系数)
	# 福缘加成系数采用软上限 (CharacterSystem.get_luck_bonus_coefficient), 100 点后边际递减,
	# 对齐 design/gdd/character-progression-system.md L146-L152
	var final_chance = base_chance * (1.0 + CharacterSystem.get_luck_bonus_coefficient(luck_stat))
	
	# 设置概率上限为20%
	if final_chance > 0.20:
		final_chance = 0.20
	
	return final_chance

# 根据福缘调整权重
func adjust_weights_by_luck(base_weights: Dictionary, luck_stat: float) -> Dictionary:
	var adjusted_weights = base_weights.duplicate()
	
	# 高福缘降低"江湖传闻"权重，增加"高人指点"和"秘境挑战"权重
	var high_tier_multiplier = 1.0 + luck_stat / 50.0
	var low_tier_multiplier = 1.0 / (1.0 + luck_stat / 50.0)
	
	adjusted_weights["JiangHuRumor"] = int(ENCOUNTER_TYPES["JiangHuRumor"]["weight"] / high_tier_multiplier)
	adjusted_weights["GaoRenZhiDian"] = int(ENCOUNTER_TYPES["GaoRenZhiDian"]["weight"] * high_tier_multiplier)
	adjusted_weights["MiJingChallenge"] = int(ENCOUNTER_TYPES["MiJingChallenge"]["weight"] * high_tier_multiplier)
	
	return adjusted_weights

# 选择奇遇类型
func select_encounter_type(luck_stat: float) -> String:
	var weights = adjust_weights_by_luck(encounter_weights, luck_stat)
	
	# 计算总权重
	var total_weight = 0
	for type_id in weights:
		total_weight += weights[type_id]
	
	if total_weight <= 0:
		return "JiangHuRumor"  # 默认返回最常见的类型
	
	# 随机选择
	var random_weight = randi() % total_weight
	var current_weight = 0
	
	for type_id in weights:
		current_weight += weights[type_id]
		if random_weight < current_weight:
			return type_id
	
	# 如果没有找到匹配项，返回第一个类型
	return weights.keys()[0]

# 强制触发奇遇
func force_trigger_encounter(trigger_type: String, luck_stat: float) -> void:
	var encounter_type = select_encounter_type(luck_stat)
	var encounter_id = generate_encounter_id(encounter_type)
	
	emit_signal("encounter_triggered", encounter_type, encounter_id)
	mark_encounter_completed(encounter_id)

# 生成奇遇ID
func generate_encounter_id(encounter_type: String) -> String:
	return encounter_type + "_" + str(Time.get_ticks_msec())

# 标记奇遇已完成
func mark_encounter_completed(encounter_id: String) -> void:
	if not encounter_history.has(encounter_id):
		encounter_history.append(encounter_id)

# 检查是否已完成奇遇
func has_completed_encounter(encounter_id: String) -> bool:
	return encounter_history.has(encounter_id)

# 重置连续失败计数器
func reset_failure_counter() -> void:
	consecutive_failures = 0

# 获取当前状态信息
func get_status_info() -> Dictionary:
	return {
		"consecutive_failures": consecutive_failures,
		"encounter_history_count": encounter_history.size(),
		"encounter_history": encounter_history
	}

# 测试函数
func test_trigger_system():
	print("开始测试奇遇触发系统...")
	
	# 测试概率计算
	var prob1 = calculate_trigger_probability(0.05, 0)  # 福缘0
	var prob2 = calculate_trigger_probability(0.05, 50) # 福缘50
	var prob3 = calculate_trigger_probability(0.05, 100) # 福缘100
	var prob4 = calculate_trigger_probability(0.05, 200) # 福缘200（应被限制）
	
	print("概率计算测试:")
	print("  福缘0: %.2f%%" % (prob1 * 100))
	print("  福缘50: %.2f%%" % (prob2 * 100))
	print("  福缘100: %.2f%%" % (prob3 * 100))
	print("  福缘200: %.2f%%" % (prob4 * 100))
	
	# 测试权重调整
	var original_weights = encounter_weights.duplicate()
	var adjusted_weights_0 = adjust_weights_by_luck(original_weights, 0)
	var adjusted_weights_100 = adjust_weights_by_luck(original_weights, 100)
	
	print("权重调整测试:")
	print("  福缘0: %s" % str(adjusted_weights_0))
	print("  福缘100: %s" % str(adjusted_weights_100))
	
	# 测试奇遇选择
	print("奇遇类型选择测试:")
	for i in range(5):
		var selected = select_encounter_type(50.0)
		print("  选择: %s" % ENCOUNTER_TYPES[selected]["name"])
	
	print("奇遇触发系统测试完成")
