# 武侠奇遇录 - 奇遇触发系统
# 实现基于福缘属性的概率触发机制，包含多种触发时机和保底机制

extends Node

# 信号定义
signal encounter_triggered(encounter_type, encounter_id)
signal probability_calculated(base_chance, luck_modifier, final_chance)
signal guarantee_mechanism_activated

# 奇遇类型枚举
enum EncounterType {
	JIANGHU_RUMOR,      # 江湖传闻
	TIANCAI_DIBAO,      # 天材地宝
	GAOREN_ZHIDIAN,     # 高人指点
	SHICHUAN_MIJI,      # 失传秘籍
	MIJING_CHALLENGE    # 秘境挑战
}

# 奇遇触发时机枚举
enum TriggerType {
	MAP_MOVEMENT,       # 大地图移动
	BATTLE_VICTORY,     # 战斗胜利后
	REST_SAVE,          # 休息/存档
	SPECIAL_LOCATION    # 特定地点
}

# 基础触发概率常量
const BASE_CHANCE_MAP_MOVEMENT = 0.05  # 5%
const BASE_CHANCE_BATTLE_VICTORY = 0.02  # 2%
const BASE_CHANCE_REST_SAVE = 0.03  # 3%
const BASE_CHANCE_SPECIAL_LOCATION = 0.12  # 12% (平均值)

# 类型分布权重
var base_weights = {
	EncounterType.JIANGHU_RUMOR: 40,      # 江湖传闻: 权重40
	EncounterType.TIANCAI_DIBAO: 30,      # 天材地宝: 权重30
	EncounterType.GAOREN_ZHIDIAN: 15,     # 高人指点: 权重15
	EncounterType.SHICHUAN_MIJI: 10,      # 失传秘籍: 权重10
	EncounterType.MIJING_CHALLENGE: 5     # 秘境挑战: 权重5
}

# 触发概率上限
const TRIGGER_CHANCE_CAP = 0.20  # 20%

# 保底机制阈值
const GUARANTEE_THRESHOLD = 20  # 连续20次未触发后强制触发

# 福缘属性影响系数
const LUCK_INFLUENCE_FACTOR = 1.0
const WEIGHT_ADJUSTMENT_FACTOR = 0.5

# 状态变量
var consecutive_failures = 0  # 连续失败次数
var character_luck = 0  # 角色福缘属性
var rng = RandomNumberGenerator.new()  # 随机数生成器

func _ready():
	rng.randomize()
	print("奇遇触发系统初始化完成")

# 设置角色福缘属性
func set_character_luck(luck_value: int) -> void:
	character_luck = max(0, min(100, luck_value))  # 限制福缘在0-100之间

# 获取角色福缘属性
func get_character_luck() -> int:
	return character_luck

# 检查是否触发奇遇
func trigger_encounter_check(trigger_type: TriggerType) -> Dictionary:
	var result = {
		"triggered": false,
		"encounter_type": null,
		"encounter_id": "",
		"message": ""
	}
	
	# 检查是否激活保底机制
	if consecutive_failures >= GUARANTEE_THRESHOLD - 1:
		result.triggered = true
		result.encounter_type = select_encounter_type_by_weight()
		result.encounter_id = generate_encounter_id(result.encounter_type)
		result.message = "保底机制激活 - 连续%d次未触发奇遇" % GUARANTEE_THRESHOLD
		consecutive_failures = 0  # 重置计数器
		emit_signal("guarantee_mechanism_activated")
		emit_signal("encounter_triggered", result.encounter_type, result.encounter_id)
		return result
	
	# 计算触发概率
	var base_chance = get_base_chance_for_trigger(trigger_type)
	var final_chance = calculate_trigger_probability(base_chance, character_luck)
	
	# 生成随机数进行判定
	var roll = rng.randf()  # 0.0 to 1.0
	
	if roll <= final_chance:
		result.triggered = true
		result.encounter_type = select_encounter_type_by_weight()
		result.encounter_id = generate_encounter_id(result.encounter_type)
		result.message = "奇遇触发成功"
		
		# 重置连续失败计数器
		consecutive_failures = 0
		
		# 发送信号
		emit_signal("probability_calculated", base_chance, final_chance - base_chance, final_chance)
		emit_signal("encounter_triggered", result.encounter_type, result.encounter_id)
	else:
		result.triggered = false
		result.message = "奇遇触发失败"
		
		# 增加连续失败计数器
		consecutive_failures += 1
	
	return result

# 计算触发概率
func calculate_trigger_probability(base_chance: float, luck_stat: int) -> float:
	"""
	使用GDD中的公式：最终触发概率 = 基础概率 × (1 + 福缘/100)
	变量:
	- base_chance: 基础概率 (float) - 不同触发时机的基础概率（2%-15%）
	- luck_stat: 福缘 (int) - 玩家的福缘属性值
	- 返回: 最终触发概率 (float) - 最终的奇遇触发概率（上限20%）
	"""
	if luck_stat < 0:
		luck_stat = 0
	
	var modifier = float(luck_stat) / 100.0
	var final_chance = base_chance * (1.0 + modifier)
	
	# 应用概率上限
	final_chance = min(final_chance, TRIGGER_CHANCE_CAP)
	
	return final_chance

# 根据权重选择奇遇类型（考虑福缘影响）
func select_encounter_type_by_weight() -> EncounterType:
	# 根据福缘调整权重
	var adjusted_weights = adjust_weights_by_luck(base_weights, character_luck)
	
	# 计算总权重
	var total_weight = 0
	for weight in adjusted_weights.values():
		total_weight += weight
	
	# 生成随机数选择类型
	var random_value = rng.randf_range(0, total_weight)
	var current_weight = 0
	
	for encounter_type in adjusted_weights:
		current_weight += adjusted_weights[encounter_type]
		if random_value <= current_weight:
			return encounter_type
	
	# 默认返回江湖传闻（理论上不应该到达这里）
	return EncounterType.JIANGHU_RUMOR

# 根据福缘调整权重
func adjust_weights_by_luck(base_weights_dict: Dictionary, luck_stat: int) -> Dictionary:
	var adjusted_weights = {}
	
	# 计算高阶和低阶权重调整
	for encounter_type in base_weights_dict:
		var base_weight = base_weights_dict[encounter_type]
		
		# 根据奇遇类型确定是高阶还是低阶
		var is_high_tier = encounter_type in [EncounterType.GAOREN_ZHIDIAN, EncounterType.SHICHUAN_MIJI, EncounterType.MIJING_CHALLENGE]
		var is_low_tier = encounter_type in [EncounterType.JIANGHU_RUMOR]
		
		if is_high_tier:
			# 高阶权重 = 基础权重 × (1 + 福缘/50)
			adjusted_weights[encounter_type] = base_weight * (1.0 + (float(luck_stat) * WEIGHT_ADJUSTMENT_FACTOR / 50.0))
		elif is_low_tier:
			# 低阶权重 = 基础权重 / (1 + 福缘/50)
			adjusted_weights[encounter_type] = base_weight / (1.0 + (float(luck_stat) * WEIGHT_ADJUSTMENT_FACTOR / 50.0))
		else:
			# 中等权重保持不变或轻微调整
			adjusted_weights[encounter_type] = base_weight * (1.0 + (float(luck_stat) * 0.1 / 100.0))
	
	return adjusted_weights

# 获取特定触发类型的基准概率
func get_base_chance_for_trigger(trigger_type: TriggerType) -> float:
	match trigger_type:
		TriggerType.MAP_MOVEMENT:
			return BASE_CHANCE_MAP_MOVEMENT
		TriggerType.BATTLE_VICTORY:
			return BASE_CHANCE_BATTLE_VICTORY
		TriggerType.REST_SAVE:
			return BASE_CHANCE_REST_SAVE
		TriggerType.SPECIAL_LOCATION:
			return BASE_CHANCE_SPECIAL_LOCATION
		_:
			return BASE_CHANCE_MAP_MOVEMENT  # 默认为地图移动

# 生成奇遇ID
func generate_encounter_id(encounter_type: EncounterType) -> String:
	var type_prefix = ""
	match encounter_type:
		EncounterType.JIANGHU_RUMOR:
			type_prefix = "JHR"
		EncounterType.TIANCAI_DIBAO:
			type_prefix = "TCD"
		EncounterType.GAOREN_ZHIDIAN:
			type_prefix = "GRZ"
		EncounterType.SHICHUAN_MIJI:
			type_prefix = "SCM"
		EncounterType.MIJING_CHALLENGE:
			type_prefix = "MJC"
	
	return "%s_%d_%d" % [type_prefix, OS.get_unix_time(), rng.randi() % 10000]

# 重置连续失败计数器
func reset_failure_counter():
	consecutive_failures = 0

# 获取当前状态信息
func get_status_info() -> Dictionary:
	return {
		"consecutive_failures": consecutive_failures,
		"next_guarantee_in": max(0, GUARANTEE_THRESHOLD - consecutive_failures),
		"character_luck": character_luck,
		"current_trigger_chance_cap": TRIGGER_CHANCE_CAP
	}

# 设置随机种子（用于测试）
func set_seed(seed: int):
	rng.seed = seed

# 获取当前连续失败次数
func get_consecutive_failures() -> int:
	return consecutive_failures