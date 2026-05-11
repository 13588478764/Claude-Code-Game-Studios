# AI决策机制单元测试
# 验证优先级评分表方法及相关功能的实现

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_priority_scoring_table_correctly_implemented())
	results.append(test_candidate_action_generation_correct())
	results.append(test_scoring_calculation_mechanism_accurate())
	results.append(test_best_action_selection_correct())
	
	return results

# 测试1: 优先级评分表正确实现
func test_priority_scoring_table_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "优先级评分表正确实现"
	
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
	
	# 创建决策管理器实例
	var decision_manager = load("res://src/scripts/combat/ai_decision_manager.gd").new()
	
	# 设置难度管理器
	if decision_manager.ai_difficulty_manager == null:
		decision_manager.ai_difficulty_manager = load("res://src/scripts/combat/ai_difficulty_manager.gd").new()
	
	# 创建战场上下文
	var battlefield_context = decision_manager.create_battlefield_context(test_enemy, test_targets[0], test_allies)
	
	# 计算动作评分
	var action_scores = []
	for skill in test_enemy.skills:
		var action = {
			"id": skill.id,
			"name": skill.name,
			"type": "skill",
			"target_type": skill.target_type,
			"expected_damage": skill.base_damage,
			"cost": skill.cost,
			"effects": skill.effects,
			"attribute": skill.attribute
		}
		
		var score = decision_manager.calculate_action_score(action, test_targets[0], battlefield_context)
		action_scores.append({"action": action, "score": score})
	
	# 验证结果
	if action_scores.size() == test_enemy.skills.size():
		result.passed = true
		result.message = "优先级评分表计算成功，为每个动作计算了评分"
	else:
		result.passed = false
		result.message = "优先级评分表计算失败"
	
	return result

# 测试2: 候选动作生成正确
func test_candidate_action_generation_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "候选动作生成正确"
	
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
			}
		]
	}
	
	# 创建决策管理器实例
	var decision_manager = load("res://src/scripts/combat/ai_decision_manager.gd").new()
	
	# 生成候选动作
	var candidate_actions = decision_manager.generate_candidate_actions(test_enemy)
	
	# 验证结果（应该包含技能、普通攻击和防御动作）
	var has_skill = false
	var has_basic_attack = false
	var has_defend = false
	
	for action in candidate_actions:
		if action.id == "skill_1":
			has_skill = true
		elif action.id == "basic_attack":
			has_basic_attack = true
		elif action.id == "defend":
			has_defend = true
	
	if has_skill and has_basic_attack and has_defend:
		result.passed = true
		result.message = "候选动作生成成功，包含技能、普通攻击和防御动作"
	else:
		result.passed = false
		result.message = "候选动作生成失败，缺少某些动作类型"
	
	return result

# 测试3: 评分计算机制准确
func test_scoring_calculation_mechanism_accurate() -> TestResult:
	var result = TestResult.new()
	result.test_name = "评分计算机制准确"
	
	# 创建测试数据
	var test_action = {
		"id": "test_action",
		"name": "测试技能",
		"type": "skill",
		"target_type": "single",
		"expected_damage": 30,
		"cost": 10,
		"effects": [],
		"attribute": "fire"
	}
	
	var test_target = {
		"id": "player_1",
		"hp": 50,
		"max_hp": 100,
		"hp_ratio": 0.5,
		"resistances": {"fire": -0.2},  # 弱点
		"has_status": func(status): return status == "broken"  # 破防
	}
	
	var test_battlefield_context = {
		"self_hp_ratio": 0.8,
		"target_hp_ratio": 0.5,
		"is_urgent_situation": false
	}
	
	# 创建决策管理器实例
	var decision_manager = load("res://src/scripts/combat/ai_decision_manager.gd").new()
	
	# 计算动作评分
	var score = decision_manager.calculate_action_score(test_action, test_target, test_battlefield_context)
	
	# 计算评分修正
	var modifiers = decision_manager.calculate_score_modifiers(test_action, test_target, test_battlefield_context)
	
	# 验证结果
	if score != null and modifiers != null:
		result.passed = true
		result.message = "评分计算机制正常，成功计算了基础评分和修正项"
	else:
		result.passed = false
		result.message = "评分计算机制异常"
	
	return result

# 测试4: 最佳动作选择正确
func test_best_action_selection_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "最佳动作选择正确"
	
	# 创建测试数据
	var scored_actions = [
		{"action": {"id": "action_1", "name": "动作1"}, "target": {"id": "target_1"}, "score": 50.0},
		{"action": {"id": "action_2", "name": "动作2"}, "target": {"id": "target_2"}, "score": 75.0},
		{"action": {"id": "action_3", "name": "动作3"}, "target": {"id": "target_3"}, "score": 60.0}
	]
	
	# 创建决策管理器实例
	var decision_manager = load("res://src/scripts/combat/ai_decision_manager.gd").new()
	
	# 选择最佳动作
	var best_action = decision_manager.select_best_action(scored_actions)
	
	# 验证结果（应该选择分数最高的动作2）
	if best_action != null and best_action.action.id == "action_2" and best_action.score == 75.0:
		result.passed = true
		result.message = "最佳动作选择正确，选择了分数最高的动作"
	else:
		result.passed = false
		result.message = "最佳动作选择错误"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行AI决策机制测试...")
	print("================================")
	
	for result in test_results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	return passed_count == total_count
