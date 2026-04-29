## AiDifficultyManager
## 武侠奇遇录 - AI难度管理器
##
## 管理三种难度等级（简单、普通、困难）及对应的AI行为特征。
## 通过调整评分系数、随机因素和特殊机制来实现不同难度的AI表现。
##
## 依赖关系：
## - CombatSystem: 战斗系统
## - EnemyBehaviorManager: 敌人行为管理
## - MartialArtsSystem: 武学系统
##
## 主要功能：
## - 难度等级管理（简单、普通、困难）
## - 评分调整（基于难度的评分修正）
## - 随机因素控制（不同难度的随机性）
## - 资源管理（困难难度的资源保留）
## - 玩家行为预测（困难难度的预测机制）
## - 打断机制（困难难度的打断逻辑）

extends Node

class_name AiDifficultyManager

# ============================================================================
# 常量定义
# ============================================================================

## 难度等级定义
const DIFFICULTY_LEVELS: Dictionary = {
	"EASY": { "name": "简单", "description": "莽夫模式" },
	"NORMAL": { "name": "普通", "description": "武者模式" },
	"HARD": { "name": "困难", "description": "宗师模式" }
}

## 难度修正参数
const DIFFICULTY_MODIFIERS: Dictionary = {
	"EASY": {
		"random_factor": 0.7,      # 70%概率随机选择
		"skill_factor": 0.3,       # 30%概率选择最高伤害技能
		"ignore_weakness": true,   # 无视弱点
		"ignore_status": true,     # 无视状态
		"preserve_resources": false # 不保留内力
	},
	"NORMAL": {
		"random_factor": 0.1,      # 10%概率随机选择
		"skill_factor": 0.9,       # 90%概率基于评分选择
		"ignore_weakness": false,  # 考虑弱点
		"ignore_status": false,    # 考虑状态
		"preserve_resources": false # 不保留内力
	},
	"HARD": {
		"random_factor": 0.02,     # 2%概率随机选择
		"skill_factor": 0.98,     # 98%概率基于评分选择
		"ignore_weakness": false,  # 考虑弱点
		"ignore_status": false,    # 考虑状态
		"preserve_resources": true, # 保留内力
		"predict_player": true,    # 预测玩家行为
		"interrupt_mechanics": true # 打断机制
	}
}

## 简单难度评分系数
const EASY_SCORE_MULTIPLIER: float = 0.5

## 普通难度评分系数
const NORMAL_SCORE_MULTIPLIER: float = 1.0

## 困难难度评分系数
const HARD_SCORE_MULTIPLIER: float = 1.2

## 简单难度随机扰动范围
const EASY_RANDOM_NOISE_RANGE: float = 100.0

## 普通难度随机扰动范围
const NORMAL_RANDOM_NOISE_RANGE: float = 20.0

## 困难难度随机扰动范围
const HARD_RANDOM_NOISE_RANGE: float = 5.0

## 打断奖励分数
const INTERRUPT_BONUS_SCORE: float = 150.0

## 打断概率阈值
const INTERRUPT_PROBABILITY_THRESHOLD: float = 0.7

# ============================================================================
# 信号定义
# ============================================================================

## 难度等级改变信号
signal difficulty_changed(new_difficulty: String)

## 评分调整完成信号
signal scores_adjusted(difficulty: String, adjusted_scores: Dictionary)

## 玩家行为预测信号
signal player_action_predicted(predictions: Array)

## 资源管理激活信号
signal resource_management_activated()

# ============================================================================
# 成员变量
# ============================================================================

## 当前难度等级
var current_difficulty: String = "NORMAL"

## 战斗系统引用
var combat_system: Node = null

## 敌人行为管理器引用
var enemy_behavior_manager: Node = null

## 武学系统引用
var martial_arts_system: Node = null

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化AI难度管理器
func _ready() -> void:
	_initialize_difficulty()

## 初始化难度设置
func _initialize_difficulty() -> void:
	set_difficulty_level("NORMAL")
	print("AI难度管理器已初始化，当前难度: %s" % current_difficulty)

# ============================================================================
# 难度等级管理
# ============================================================================

## 设置难度等级
## @param difficulty_type: 难度类型（EASY、NORMAL、HARD）
## @return 设置是否成功
func set_difficulty_level(difficulty_type: String) -> bool:
	if not DIFFICULTY_LEVELS.has(difficulty_type):
		push_error("AiDifficultyManager: 无效的难度等级: %s" % difficulty_type)
		return false
	
	current_difficulty = difficulty_type
	emit_signal("difficulty_changed", current_difficulty)
	print("难度已设置为: %s (%s)" % [DIFFICULTY_LEVELS[difficulty_type].name, DIFFICULTY_LEVELS[difficulty_type].description])
	return true

## 获取当前难度等级
## @return 当前难度等级字符串
func get_current_difficulty() -> String:
	return current_difficulty

# ============================================================================
# 评分调整
# ============================================================================

## 应用简单难度调整
## @param base_scores: 基础评分字典
## @return 调整后的评分字典
func apply_easy_modifiers(base_scores: Dictionary) -> Dictionary:
	var modified_scores: Dictionary = {}
	
	# 简单难度：70%概率随机选择可用技能，30%概率选择最高伤害技能
	for action_id in base_scores:
		var base_score: float = base_scores[action_id]
		
		# 随机扰动（±100分）
		var random_noise: float = randf_range(-EASY_RANDOM_NOISE_RANGE, EASY_RANDOM_NOISE_RANGE)
		
		# 调整后评分 = 基础评分 × 难度系数 + 随机扰动
		var adjusted_score: float = base_score * EASY_SCORE_MULTIPLIER + random_noise
		modified_scores[action_id] = adjusted_score
	
	emit_signal("scores_adjusted", "EASY", modified_scores)
	return modified_scores

## 应用普通难度调整
## @param base_scores: 基础评分字典
## @return 调整后的评分字典
func apply_normal_modifiers(base_scores: Dictionary) -> Dictionary:
	var modified_scores: Dictionary = {}
	
	for action_id in base_scores:
		var base_score: float = base_scores[action_id]
		
		# 随机扰动（±20分）
		var random_noise: float = randf_range(-NORMAL_RANDOM_NOISE_RANGE, NORMAL_RANDOM_NOISE_RANGE)
		
		# 调整后评分 = 基础评分 × 难度系数 + 随机扰动
		var adjusted_score: float = base_score * NORMAL_SCORE_MULTIPLIER + random_noise
		modified_scores[action_id] = adjusted_score
	
	emit_signal("scores_adjusted", "NORMAL", modified_scores)
	return modified_scores

## 应用困难难度调整
## @param base_scores: 基础评分字典
## @return 调整后的评分字典
func apply_hard_modifiers(base_scores: Dictionary) -> Dictionary:
	var modifier: Dictionary = DIFFICULTY_MODIFIERS["HARD"]
	var modified_scores: Dictionary = {}
	
	for action_id in base_scores:
		var base_score: float = base_scores[action_id]
		
		# 随机扰动（±5分）
		var random_noise: float = randf_range(-HARD_RANDOM_NOISE_RANGE, HARD_RANDOM_NOISE_RANGE)
		
		# 调整后评分 = 基础评分 × 难度系数 + 随机扰动
		var adjusted_score: float = base_score * HARD_SCORE_MULTIPLIER + random_noise
		
		# 额外的困难难度逻辑
		if modifier.predict_player:
			# 预测性打断逻辑
			adjusted_score += calculate_interrupt_bonus(action_id)
		
		modified_scores[action_id] = adjusted_score
	
	emit_signal("scores_adjusted", "HARD", modified_scores)
	return modified_scores

## 应用难度调整
## @param base_scores: 基础评分字典
## @return 调整后的评分字典
func apply_difficulty_modifiers(base_scores: Dictionary) -> Dictionary:
	match current_difficulty:
		"EASY":
			return apply_easy_modifiers(base_scores)
		"NORMAL":
			return apply_normal_modifiers(base_scores)
		"HARD":
			return apply_hard_modifiers(base_scores)
		_:
			push_warning("AiDifficultyManager: 未知难度等级，使用普通难度")
			return apply_normal_modifiers(base_scores)

# ============================================================================
# 打断机制
# ============================================================================

## 计算打断奖励
## @param action_id: 动作ID
## @return 打断奖励分数
func calculate_interrupt_bonus(action_id: String) -> float:
	# 检查是否有打断玩家大招的机会
	var interrupt_bonus: float = 0.0
	
	# 这里可以实现检测玩家是否有即将释放的大招
	# 如果有，则对能够打断的技能增加分数
	if can_interrupt_player_ult(action_id):
		interrupt_bonus = INTERRUPT_BONUS_SCORE
	
	return interrupt_bonus

## 检查是否能打断玩家大招
## @param action_id: 动作ID
## @return 是否能打断
func can_interrupt_player_ult(action_id: String) -> bool:
	# 简化实现：假设某些技能类型可以打断
	# 在实际实现中，这里会检查玩家当前的行动意图
	return randf() > INTERRUPT_PROBABILITY_THRESHOLD  # 30%概率可以打断

# ============================================================================
# 玩家行为预测
# ============================================================================

## 预测玩家行为（困难难度）
## @return 预测的玩家动作数组
func predict_player_actions() -> Array:
	if current_difficulty != "HARD":
		return []
	
	# 在困难难度下，AI会尝试预测玩家的下一步行动
	var predicted_actions: Array = []
	
	# 这里可以实现更复杂的预测逻辑
	# 例如：分析玩家历史行为、当前状态、可用技能等
	predicted_actions.append({
		"player_id": "player_1",
		"predicted_action": "high_damage_skill",
		"confidence": 0.8,
		"threat_level": 100
	})
	
	emit_signal("player_action_predicted", predicted_actions)
	return predicted_actions

# ============================================================================
# 资源管理
# ============================================================================

## 管理资源（困难难度）
## @return 资源管理是否激活
func manage_resources_efficiently() -> bool:
	if current_difficulty != "HARD":
		return false
	
	# 在困难难度下，AI会保留一定资源应对突发情况
	var resource_management_active: bool = true
	
	# 这里可以实现资源管理逻辑
	# 例如：保留一定比例的内力、避免一次性耗尽资源等
	emit_signal("resource_management_activated")
	print("困难难度：启用资源管理策略")
	
	return resource_management_active

# ============================================================================
# 难度信息查询
# ============================================================================

## 获取难度描述
## @param difficulty_type: 难度类型（可选，默认为当前难度）
## @return 难度描述字典或null
func get_difficulty_description(difficulty_type: String = "") -> Dictionary:
	var dt: String = difficulty_type if difficulty_type != "" else current_difficulty
	
	if not DIFFICULTY_LEVELS.has(dt):
		push_warning("AiDifficultyManager: 无效的难度类型: %s" % dt)
		return {}
	
	var level: Dictionary = DIFFICULTY_LEVELS[dt]
	var modifier: Dictionary = DIFFICULTY_MODIFIERS[dt]
	
	return {
		"name": level.name,
		"description": level.description,
		"random_factor": modifier.random_factor,
		"skill_factor": modifier.skill_factor,
		"ignore_weakness": modifier.ignore_weakness,
		"preserve_resources": modifier.preserve_resources,
		"predict_player": modifier.get("predict_player", false),
		"interrupt_mechanics": modifier.get("interrupt_mechanics", false)
	}

# ============================================================================
# 测试函数
# ============================================================================

## 测试AI难度系统
func test_difficulty_system() -> void:
	print("开始测试AI难度系统...")
	
	# 创建测试评分数据
	var test_scores: Dictionary = {
		"skill_1": 100,
		"skill_2": 150,
		"skill_3": 80,
		"skill_4": 200
	}
	
	print("原始评分: ", test_scores)
	
	# 测试简单难度
	set_difficulty_level("EASY")
	var easy_scores = apply_difficulty_modifiers(test_scores)
	print("简单难度调整后: ", easy_scores)
	
	# 测试普通难度
	set_difficulty_level("NORMAL")
	var normal_scores = apply_difficulty_modifiers(test_scores)
	print("普通难度调整后: ", normal_scores)
	
	# 测试困难难度
	set_difficulty_level("HARD")
	var hard_scores = apply_difficulty_modifiers(test_scores)
	print("困难难度调整后: ", hard_scores)
	
	# 测试预测功能
	if current_difficulty == "HARD":
		var predictions: Array = predict_player_actions()
		print("玩家行为预测: ", predictions)
	
	# 测试资源管理
	var resource_mgmt: bool = manage_resources_efficiently()
	print("资源管理激活: ", resource_mgmt)
	
	print("AI难度系统测试完成")