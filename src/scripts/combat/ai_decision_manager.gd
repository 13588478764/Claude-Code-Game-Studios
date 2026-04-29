## AiDecisionManager
## AI决策管理器
##
## 实现优先级评分表方法，包含候选动作生成、评分计算和最佳动作选择。
## 根据战场情况和难度等级动态调整AI决策。
##
## 主要功能：
## - 候选动作生成
## - 动作评分计算
## - 最佳动作选择
## - 难度调整
## - 战场上下文分析

extends Node
class_name AiDecisionManager

# ============================================================================
# 成员变量
# ============================================================================

var combat_system = null
var enemy_behavior_manager = null
var ai_difficulty_manager = null

# ============================================================================
# 生命周期方法
# ============================================================================

func _ready():
	pass
REPLACE

# 生成候选动作列表
func generate_candidate_actions(enemy_data):
	var candidate_actions = []
	
	# 遍历敌人所有可用技能
	for skill in enemy_data.skills:
		if is_skill_available(skill, enemy_data):
			var action = {
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
	var basic_attack = {
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
	var defend_action = {
		"id": "defend",
		"name": "防御",
		"type": "defend",
		"target_type": "self",
		"expected_damage": 0,
		"cost": 0,
		"effects": ["reduce_damage", "restore_stamina"]
	}
	candidate_actions.append(defend_action)
	
	return candidate_actions

# 检查技能是否可用
func is_skill_available(skill, enemy_data):
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

# 检查是否有有效目标
func has_valid_targets(skill, enemy_data):
	# 根据技能的目标类型检查是否有有效目标
	if skill.target_type == "single" or skill.target_type == "multiple":
		# 检查是否有可攻击的目标
		return true  # 简化实现
	elif skill.target_type == "self":
		return true
	else:
		return true

# 计算伤害乘数
func calculate_damage_multiplier(skill, enemy_data):
	# 根据技能类型和敌人属性计算伤害乘数
	var multiplier = 1.0
	
	# 考虑敌人当前状态
	if enemy_data.buffed:
		multiplier *= 1.2
	if enemy_data.debuffed:
		multiplier *= 0.8
	
	# 考虑技能属性与目标抗性的关系
	# 这里可以实现属性克制逻辑
	
	return multiplier

# 计算动作评分
func calculate_action_score(action, target, battlefield_context):
	var base_score = 0
	
	# 基础评分：技能的预期伤害或治疗效果
	if action.type == "attack" or action.type == "skill":
		base_score = action.expected_damage * 10  # 伤害权重
	elif action.type == "heal":
		base_score = action.expected_heal * 8  # 治疗权重
	else:
		base_score = 50  # 其他动作的基础分数
	
	# 评分修正
	var modifiers = calculate_score_modifiers(action, target, battlefield_context)
	var total_score = base_score + modifiers
	
	return total_score

# 计算评分修正
func calculate_score_modifiers(action, target, battlefield_context):
	var total_modifier = 0
	
	# 弱点修正：+50分（克制属性）
	if is_weakness_target(action, target):
		total_modifier += 50
	
	# 破防修正：+100分（目标破防）
	if target.has_status and target.has_status("broken"):
		total_modifier += 100
	
	# 目标残血修正：+30分（目标残血）
	if target.hp_ratio < 0.3:
		total_modifier += 30
	
	# 自身状态修正：防御技能+40分（自身血量低）
	if action.type == "defend" and battlefield_context.self_hp_ratio < 0.3:
		total_modifier += 40
	
	# 连携修正：+20分（能触发连携）
	if can_trigger_combo(action, target, battlefield_context):
		total_modifier += 20
	
	# 消耗效率修正：非关键时刻高消耗=-50分
	if is_high_cost_and_not_important(action, battlefield_context):
		total_modifier -= 50
	
	return total_modifier

# 检查是否为弱点目标
func is_weakness_target(action, target):
	# 检查技能属性是否克制目标抗性
	if action.has("attribute") and target.has("resistances"):
		var skill_attr = action.attribute
		var target_resist = target.resistances.get(skill_attr, 0)
		return target_resist < 0  # 如果抗性为负值，则为弱点
	
	return false

# 检查是否能触发连携
func can_trigger_combo(action, target, battlefield_context):
	# 检查是否有连携机会
	return false  # 简化实现

# 检查是否为高消耗且非关键时刻
func is_high_cost_and_not_important(action, battlefield_context):
	# 检查技能消耗是否过高且当前不是关键时刻
	if action.has("cost") and action.cost > 50:  # 假设50为高消耗阈值
		# 如果敌人血量充足且没有紧急情况，则认为不是关键时刻
		return battlefield_context.self_hp_ratio > 0.7 and not battlefield_context.is_urgent_situation
	
	return false

# 应用评分修正
func apply_score_modifiers(base_score, battlefield_context):
	# 这个函数可以用于应用全局的评分修正
	# 例如：根据战场情况、难度等级等调整评分
	return base_score

# 选择最佳动作
func select_best_action(scored_actions):
	if scored_actions.is_empty():
		return null
	
	# 找到评分最高的动作
	var best_action = scored_actions[0]
	var best_score = best_action.score
	
	for action in scored_actions:
		if action.score > best_score:
			best_score = action.score
			best_action = action
	
	return best_action

# 执行选定的动作
func execute_selected_action(best_action):
	if best_action == null:
		print("错误：没有选定的动作")
		return false
	
	# 发出决策信号
	emit_signal("decision_made", best_action.action, best_action.target)
	
	# 在实际战斗系统中执行动作
	# combat_system.execute_action(best_action.action, best_action.target)
	
	print("AI执行动作: %s 目标: %s 评分: %f" % [best_action.action.name, best_action.target.id, best_action.score])
	return true

# 主决策函数
func make_decision(enemy_data, targets, allies):
	# 1. 生成候选动作
	var candidate_actions = generate_candidate_actions(enemy_data)
	
	# 2. 为每个候选动作计算评分
	var scored_actions = []
	for action in candidate_actions:
		for target in targets:
			# 创建战场上下文
			var battlefield_context = create_battlefield_context(enemy_data, target, allies)
			
			# 计算动作评分
			var score = calculate_action_score(action, target, battlefield_context)
			
			# 添加到评分列表
			scored_actions.append({
				"action": action,
				"target": target,
				"score": score
			})
		end
	end
	
	# 3. 应用难度调整
	var difficulty_adjusted_scores = []
	for scored_action in scored_actions:
		var adjusted_score = ai_difficulty_manager.apply_difficulty_modifiers({scored_action.action.id: scored_action.score})
		scored_action.score = adjusted_score[scored_action.action.id]
		difficulty_adjusted_scores.append(scored_action)
	end
	
	# 4. 选择最佳动作
	var best_action = select_best_action(difficulty_adjusted_scores)
	
	# 5. 执行选定的动作
	var execution_result = execute_selected_action(best_action)
	
	return {
		"action": best_action.action if best_action != null else null,
		"target": best_action.target if best_action != null else null,
		"score": best_action.score if best_action != null else 0,
		"all_scores": difficulty_adjusted_scores,
		"execution_success": execution_result
	}

# 创建战场上下文
func create_battlefield_context(enemy_data, target, allies):
	return {
		"self_hp_ratio": enemy_data.hp / enemy_data.max_hp,
		"target_hp_ratio": target.hp / target.max_hp,
		"allies_count": allies.size(),
		"allies_hp_ratio": calculate_average_hp_ratio(allies),
		"is_urgent_situation": is_urgent_battle_situation(enemy_data, allies),
		"turn_count": 1  # 假设当前是第几回合
	}

# 计算平均血量比例
func calculate_average_hp_ratio(entities):
	if entities.is_empty():
		return 0
	
	var total_ratio = 0
	for entity in entities:
		if entity.has("hp") and entity.has("max_hp"):
			total_ratio += entity.hp / entity.max_hp
	
	return total_ratio / entities.size()

# 检查是否为紧急情况
func is_urgent_battle_situation(enemy_data, allies):
	# 如果敌人或盟友血量较低，则认为是紧急情况
	if enemy_data.hp / enemy_data.max_hp < 0.3:
		return true
	
	for ally in allies:
		if ally.has("hp") and ally.has("max_hp"):
			if ally.hp / ally.max_hp < 0.3:
				return true
	
	return false

# 测试函数
func test_decision_system():
	print("开始测试AI决策系统...")
	
	# 创建测试数据
	var test_enemy = {
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
	
	var test_targets = [
		{
			"id": "player_1",
			"hp": 50,
			"max_hp": 100,
			"hp_ratio": 0.5,
			"resistances": {"fire": -0.2},  # 弱点
			"has_status": func(status): return status == "broken"
		}
	]
	
	var test_allies = [
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
	var decision_result = make_decision(test_enemy, test_targets, test_allies)
	
	print("决策结果: ", decision_result)
	
	print("AI决策系统测试完成")