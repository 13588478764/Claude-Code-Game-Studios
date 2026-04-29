## AiDecisionManager
## 武侠奇遇录 - AI决策管理器
##
## 实现优先级评分表方法，包含候选动作生成、评分计算和最佳动作选择。
## 根据战场情况和难度等级动态调整AI决策。
##
## 依赖关系：
## - AiDifficultyManager: 难度调整
## - EnemyBehaviorManager: 敌人行为管理
## - CombatSystem: 战斗系统
##
## 主要功能：
## - 候选动作生成（技能、攻击、防御）
## - 动作评分计算（基础评分 + 修正）
## - 最佳动作选择（优先级排序）
## - 难度调整（根据难度等级调整评分）
## - 战场上下文分析（血量、状态、紧急情况）

extends Node

class_name AiDecisionManager

# ============================================================================
# 常量定义
# ============================================================================

## 伤害权重系数
const DAMAGE_WEIGHT: float = 10.0

## 治疗权重系数
const HEAL_WEIGHT: float = 8.0

## 其他动作基础分数
const OTHER_ACTION_BASE_SCORE: float = 50.0

## 弱点修正分数
const WEAKNESS_MODIFIER: float = 50.0

## 破防修正分数
const BROKEN_MODIFIER: float = 100.0

## 残血修正分数
const LOW_HP_MODIFIER: float = 30.0

## 防御修正分数
const DEFEND_MODIFIER: float = 40.0

## 连携修正分数
const COMBO_MODIFIER: float = 20.0

## 高消耗惩罚分数
const HIGH_COST_PENALTY: float = -50.0

## 高消耗阈值
const HIGH_COST_THRESHOLD: float = 50.0

## 残血阈值
const LOW_HP_THRESHOLD: float = 0.3

## 防御触发阈值
const DEFEND_HP_THRESHOLD: float = 0.3

## 健康血量阈值
const HEALTHY_HP_THRESHOLD: float = 0.7

# ============================================================================
# 信号定义
# ============================================================================

## 决策完成信号
signal decision_made(action: Dictionary, target: Dictionary)

## 候选动作生成信号
signal candidate_actions_generated(actions: Array)

## 动作评分完成信号
signal action_scored(action: Dictionary, score: float)

## 最佳动作选择信号
signal best_action_selected(action: Dictionary)

# ============================================================================
# 成员变量
# ============================================================================

## 战斗系统引用
var combat_system: Node = null

## 敌人行为管理器引用
var enemy_behavior_manager: Node = null

## AI难度管理器引用
var ai_difficulty_manager: Node = null

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化AI决策管理器
func _ready() -> void:
	_initialize_managers()

## 初始化管理器引用
func _initialize_managers() -> void:
	if ai_difficulty_manager == null:
		push_warning("AiDecisionManager: ai_difficulty_manager 未设置")
	
	if enemy_behavior_manager == null:
		push_warning("AiDecisionManager: enemy_behavior_manager 未设置")
	
	if combat_system == null:
		push_warning("AiDecisionManager: combat_system 未设置")

# ============================================================================
# 候选动作生成
# ============================================================================

## 生成候选动作列表
## @param enemy_data: 敌人数据字典
## @return 候选动作数组
func generate_candidate_actions(enemy_data: Dictionary) -> Array:
	var candidate_actions: Array = []
	
	# 验证输入
	if not enemy_data.has("skills"):
		push_error("AiDecisionManager: enemy_data 缺少 skills 字段")
		return candidate_actions
	
	# 遍历敌人所有可用技能
	for skill in enemy_data.skills:
		if is_skill_available(skill, enemy_data):
			var action: Dictionary = {
				"id": skill.id,
				"name": skill.name,
				"type": "skill",
				"target_type": skill.target_type,  # single, multiple, self, etc.
				"expected_damage": skill.base_damage * calculate_damage_multiplier(skill, enemy_data),
				"cost": skill.cost,
				"effects": skill.effects
			}
			candidate_actions.append(action)
	
	# 添加普通攻击
	var basic_attack: Dictionary = {
		"id": "basic_attack",
		"name": "普通攻击",
		"type": "attack",
		"target_type": "single",
		"expected_damage": enemy_data.attack_power,
		"cost": 0,
		"effects": []
	}
	candidate_actions.append(basic_attack)
	
	# 添加防御动作
	var defend_action: Dictionary = {
		"id": "defend",
		"name": "防御",
		"type": "defend",
		"target_type": "self",
		"expected_damage": 0,
		"cost": 0,
		"effects": ["reduce_damage", "restore_stamina"]
	}
	candidate_actions.append(defend_action)
	
	emit_signal("candidate_actions_generated", candidate_actions)
	return candidate_actions

## 检查技能是否可用
## @param skill: 技能数据字典
## @param enemy_data: 敌人数据字典
## @return 技能是否可用
func is_skill_available(skill: Dictionary, enemy_data: Dictionary) -> bool:
	# 检查技能冷却
	if skill.cooldown_remaining > 0:
		return false
	
	# 检查资源是否足够（如内力、体力等）
	if skill.cost_type == "mana" and enemy_data.mana < skill.cost:
		return false
	if skill.cost_type == "stamina" and enemy_data.stamina < skill.cost:
		return false
	
	# 检查目标条件
	if skill.requires_target and not has_valid_targets(skill, enemy_data):
		return false
	
	return true

## 检查是否有有效目标
## @param skill: 技能数据字典
## @param enemy_data: 敌人数据字典
## @return 是否有有效目标
func has_valid_targets(skill: Dictionary, enemy_data: Dictionary) -> bool:
	# 根据技能的目标类型检查是否有有效目标
	if skill.target_type == "single" or skill.target_type == "multiple":
		# 检查是否有可攻击的目标
		return true  # 简化实现
	elif skill.target_type == "self":
		return true
	else:
		return true

## 计算伤害乘数
## @param skill: 技能数据字典
## @param enemy_data: 敌人数据字典
## @return 伤害乘数
func calculate_damage_multiplier(skill: Dictionary, enemy_data: Dictionary) -> float:
	# 根据技能类型和敌人属性计算伤害乘数
	var multiplier: float = 1.0
	
	# 考虑敌人当前状态
	if enemy_data.buffed:
		multiplier *= 1.2
	if enemy_data.debuffed:
		multiplier *= 0.8
	
	# 考虑技能属性与目标抗性的关系
	# 这里可以实现属性克制逻辑
	
	return multiplier

# ============================================================================
# 动作评分计算
# ============================================================================

## 计算动作评分
## @param action: 动作数据字典
## @param target: 目标数据字典
## @param battlefield_context: 战场上下文字典
## @return 动作总评分
func calculate_action_score(action: Dictionary, target: Dictionary, battlefield_context: Dictionary) -> float:
	var base_score: float = _calculate_base_score(action)
	var modifiers: float = calculate_score_modifiers(action, target, battlefield_context)
	var total_score: float = base_score + modifiers
	
	emit_signal("action_scored", action, total_score)
	return total_score

## 计算基础评分
## @param action: 动作数据字典
## @return 基础评分
func _calculate_base_score(action: Dictionary) -> float:
	var base_score: float = 0.0
	
	# 基础评分：技能的预期伤害或治疗效果
	if action.type == "attack" or action.type == "skill":
		base_score = action.expected_damage * DAMAGE_WEIGHT
	elif action.type == "heal":
		base_score = action.expected_heal * HEAL_WEIGHT
	else:
		base_score = OTHER_ACTION_BASE_SCORE
	
	return base_score

## 计算评分修正
## @param action: 动作数据字典
## @param target: 目标数据字典
## @param battlefield_context: 战场上下文字典
## @return 总修正值
func calculate_score_modifiers(action: Dictionary, target: Dictionary, battlefield_context: Dictionary) -> float:
	var total_modifier: float = 0.0
	
	# 弱点修正
	if is_weakness_target(action, target):
		total_modifier += WEAKNESS_MODIFIER
	
	# 破防修正
	if target.has("has_status") and target.has_status.call("broken"):
		total_modifier += BROKEN_MODIFIER
	
	# 目标残血修正
	if target.has("hp_ratio") and target.hp_ratio < LOW_HP_THRESHOLD:
		total_modifier += LOW_HP_MODIFIER
	
	# 自身状态修正：防御技能
	if action.type == "defend" and battlefield_context.self_hp_ratio < DEFEND_HP_THRESHOLD:
		total_modifier += DEFEND_MODIFIER
	
	# 连携修正
	if can_trigger_combo(action, target, battlefield_context):
		total_modifier += COMBO_MODIFIER
	
	# 消耗效率修正
	if is_high_cost_and_not_important(action, battlefield_context):
		total_modifier += HIGH_COST_PENALTY
	
	return total_modifier

## 检查是否为弱点目标
## @param action: 动作数据字典
## @param target: 目标数据字典
## @return 是否为弱点目标
func is_weakness_target(action: Dictionary, target: Dictionary) -> bool:
	# 检查技能属性是否克制目标抗性
	if action.has("attribute") and target.has("resistances"):
		var skill_attr = action.attribute
		var target_resist = target.resistances.get(skill_attr, 0)
		return target_resist < 0  # 如果抗性为负值，则为弱点
	
	return false

## 检查是否能触发连携
## @param action: 动作数据字典
## @param target: 目标数据字典
## @param battlefield_context: 战场上下文字典
## @return 是否能触发连携
func can_trigger_combo(action: Dictionary, target: Dictionary, battlefield_context: Dictionary) -> bool:
	# 检查是否有连携机会
	return false  # 简化实现

## 检查是否为高消耗且非关键时刻
## @param action: 动作数据字典
## @param battlefield_context: 战场上下文字典
## @return 是否为高消耗且非关键时刻
func is_high_cost_and_not_important(action: Dictionary, battlefield_context: Dictionary) -> bool:
	# 检查技能消耗是否过高且当前不是关键时刻
	if action.has("cost") and action.cost > HIGH_COST_THRESHOLD:
		# 如果敌人血量充足且没有紧急情况，则认为不是关键时刻
		return battlefield_context.self_hp_ratio > HEALTHY_HP_THRESHOLD and not battlefield_context.is_urgent_situation
	
	return false

# ============================================================================
# 最佳动作选择
# ============================================================================

## 选择最佳动作
## @param scored_actions: 已评分动作数组
## @return 最佳动作字典或null
func select_best_action(scored_actions: Array) -> Dictionary:
	if scored_actions.is_empty():
		push_warning("AiDecisionManager: 没有可用的候选动作")
		return {}
	
	# 找到评分最高的动作
	var best_action: Dictionary = scored_actions[0]
	var best_score: float = best_action.score
	
	for action in scored_actions:
		if action.score > best_score:
			best_score = action.score
			best_action = action
	
	emit_signal("best_action_selected", best_action)
	return best_action

# ============================================================================
# 动作执行
# ============================================================================

## 执行选定的动作
## @param best_action: 最佳动作字典
## @return 执行是否成功
func execute_selected_action(best_action: Dictionary) -> bool:
	if best_action.is_empty():
		push_error("AiDecisionManager: 没有选定的动作")
		return false
	
	# 验证动作数据
	if not best_action.has("action") or not best_action.has("target"):
		push_error("AiDecisionManager: 动作数据不完整")
		return false
	
	# 发出决策信号
	emit_signal("decision_made", best_action.action, best_action.target)
	
	# 在实际战斗系统中执行动作
	if combat_system != null:
		# combat_system.execute_action(best_action.action, best_action.target)
		pass
	
	print("AI执行动作: %s 目标: %s 评分: %f" % [best_action.action.name, best_action.target.id, best_action.score])
	return true

# ============================================================================
# 主决策流程
# ============================================================================

## 主决策函数
## @param enemy_data: 敌人数据字典
## @param targets: 目标数组
## @param allies: 盟友数组
## @return 决策结果字典
func make_decision(enemy_data: Dictionary, targets: Array, allies: Array) -> Dictionary:
	# 验证输入
	if targets.is_empty():
		push_error("AiDecisionManager: 没有可用目标")
		return _create_empty_decision_result()
	
	# 1. 生成候选动作
	var candidate_actions: Array = generate_candidate_actions(enemy_data)
	if candidate_actions.is_empty():
		push_warning("AiDecisionManager: 没有可用的候选动作")
		return _create_empty_decision_result()
	
	# 2. 为每个候选动作计算评分
	var scored_actions: Array = _score_all_actions(candidate_actions, targets, enemy_data, allies)
	
	# 3. 应用难度调整
	var difficulty_adjusted_scores: Array = _apply_difficulty_adjustments(scored_actions)
	
	# 4. 选择最佳动作
	var best_action: Dictionary = select_best_action(difficulty_adjusted_scores)
	
	# 5. 执行选定的动作
	var execution_result: bool = execute_selected_action(best_action)
	
	return _create_decision_result(best_action, difficulty_adjusted_scores, execution_result)

## 为所有动作计算评分
## @param candidate_actions: 候选动作数组
## @param targets: 目标数组
## @param enemy_data: 敌人数据字典
## @param allies: 盟友数组
## @return 已评分动作数组
func _score_all_actions(candidate_actions: Array, targets: Array, enemy_data: Dictionary, allies: Array) -> Array:
	var scored_actions: Array = []
	
	for action in candidate_actions:
		for target in targets:
			# 创建战场上下文
			var battlefield_context: Dictionary = create_battlefield_context(enemy_data, target, allies)
			
			# 计算动作评分
			var score: float = calculate_action_score(action, target, battlefield_context)
			
			# 添加到评分列表
			scored_actions.append({
				"action": action,
				"target": target,
				"score": score
			})
	
	return scored_actions

## 应用难度调整
## @param scored_actions: 已评分动作数组
## @return 难度调整后的动作数组
func _apply_difficulty_adjustments(scored_actions: Array) -> Array:
	if ai_difficulty_manager == null:
		return scored_actions
	
	var difficulty_adjusted_scores: Array = []
	for scored_action in scored_actions:
		var adjusted_score: Dictionary = ai_difficulty_manager.apply_difficulty_modifiers({scored_action.action.id: scored_action.score})
		scored_action.score = adjusted_score[scored_action.action.id]
		difficulty_adjusted_scores.append(scored_action)
	
	return difficulty_adjusted_scores

## 创建空决策结果
## @return 空决策结果字典
func _create_empty_decision_result() -> Dictionary:
	return {
		"action": null,
		"target": null,
		"score": 0.0,
		"all_scores": [],
		"execution_success": false
	}

## 创建决策结果
## @param best_action: 最佳动作字典
## @param all_scores: 所有评分数组
## @param execution_success: 执行是否成功
## @return 决策结果字典
func _create_decision_result(best_action: Dictionary, all_scores: Array, execution_success: bool) -> Dictionary:
	return {
		"action": best_action.get("action", null),
		"target": best_action.get("target", null),
		"score": best_action.get("score", 0.0),
		"all_scores": all_scores,
		"execution_success": execution_success
	}

# ============================================================================
# 战场上下文分析
# ============================================================================

## 创建战场上下文
## @param enemy_data: 敌人数据字典
## @param target: 目标数据字典
## @param allies: 盟友数组
## @return 战场上下文字典
func create_battlefield_context(enemy_data: Dictionary, target: Dictionary, allies: Array) -> Dictionary:
	return {
		"self_hp_ratio": enemy_data.hp / enemy_data.max_hp,
		"target_hp_ratio": target.hp / target.max_hp,
		"allies_count": allies.size(),
		"allies_hp_ratio": calculate_average_hp_ratio(allies),
		"is_urgent_situation": is_urgent_battle_situation(enemy_data, allies),
		"turn_count": 1  # 假设当前是第几回合
	}

## 计算平均血量比例
## @param entities: 实体数组
## @return 平均血量比例
func calculate_average_hp_ratio(entities: Array) -> float:
	if entities.is_empty():
		return 0.0
	
	var total_ratio: float = 0.0
	for entity in entities:
		if entity.has("hp") and entity.has("max_hp"):
			total_ratio += entity.hp / entity.max_hp
	
	return total_ratio / float(entities.size())

## 检查是否为紧急情况
## @param enemy_data: 敌人数据字典
## @param allies: 盟友数组
## @return 是否为紧急情况
func is_urgent_battle_situation(enemy_data: Dictionary, allies: Array) -> bool:
	# 如果敌人或盟友血量较低，则认为是紧急情况
	if enemy_data.hp / enemy_data.max_hp < LOW_HP_THRESHOLD:
		return true
	
	for ally in allies:
		if ally.has("hp") and ally.has("max_hp"):
			if ally.hp / ally.max_hp < LOW_HP_THRESHOLD:
				return true
	
	return false

# ============================================================================
# 测试函数
# ============================================================================

## 测试AI决策系统
func test_decision_system() -> void:
	print("开始测试AI决策系统...")
	
	# 创建测试数据
	var test_enemy: Dictionary = {
		"id": "test_enemy",
		"hp": 80,
		"max_hp": 100,
		"attack_power": 25,
		"mana": 50,
		"skills": [
			{
				"id": "skill_1",
				"name": "火球术",
				"target_type": "single",
				"base_damage": 30,
				"cost": 10,
				"cost_type": "mana",
				"cooldown_remaining": 0,
				"requires_target": true,
				"attribute": "fire",
				"effects": []
			},
			{
				"id": "skill_2",
				"name": "治疗术",
				"target_type": "self",
				"base_damage": -20,  # 负值表示治疗
				"cost": 15,
				"cost_type": "mana",
				"cooldown_remaining": 0,
				"requires_target": false,
				"attribute": "heal",
				"effects": []
			}
		]
	}
	
	var test_targets: Array = [
		{
			"id": "player_1",
			"hp": 50,
			"max_hp": 100,
			"hp_ratio": 0.5,
			"resistances": {"fire": -0.2},  # 弱点
			"has_status": func(status): return status == "broken"
		}
	]
	
	var test_allies: Array = [
		{
			"id": "ally_1",
			"hp": 70,
			"max_hp": 100
		}
	]
	
	# 设置难度管理器（如果已连接）
	if ai_difficulty_manager == null:
		ai_difficulty_manager = load("res://src/scripts/combat/ai_difficulty_manager.gd").new()
	
	# 执行决策
	var decision_result: Dictionary = make_decision(test_enemy, test_targets, test_allies)
	
	print("决策结果: ", decision_result)
	
	print("AI决策系统测试完成")